package com.cevheri.flutter.flutter_bloc_advance

import android.util.Log
import io.sentry.Breadcrumb
import io.sentry.SentryEvent
import io.sentry.protocol.Request
import io.sentry.protocol.User

/**
 * Masks what sentry-android records and sends itself: its own breadcrumbs (activity and app lifecycle, system
 * events, network changes), Java and Kotlin exceptions, ANR events and NDK crash reports, none of which pass through
 * the Dart hooks. [NativeSentry] installs [beforeSend] and [beforeBreadcrumb] as the hooks of the native SDK.
 *
 * A port of maskSecrets and maskEmails (lib/core/security/sensitive_data_scrubber.dart) and of sentryBeforeSend and
 * sentryBeforeBreadcrumb (lib/infrastructure/analytics/sentry_scrub.dart), with the patterns of
 * [NativeScrubPatterns]. test/fixtures/native_scrub_cases.json holds cases that both copies must mask alike.
 *
 * Masking is idempotent: a Dart breadcrumb reaches [beforeBreadcrumb] already masked when Sentry syncs it to the
 * native scope. When scrubbing throws, the hook drops the event or the breadcrumb and logs that it did, without its
 * content and without the message of the exception; it never sends one unmasked.
 */
object NativeSentryScrubber {
    private const val TAG = "NativeSentryScrubber"

    private val jwt = Regex(NativeScrubPatterns.JWT_PATTERN)
    private val email = Regex(NativeScrubPatterns.EMAIL_PATTERN)
    private val jsonMember = Regex(NativeScrubPatterns.JSON_MEMBER_PATTERN)
    private val namedValue = Regex(NativeScrubPatterns.NAMED_VALUE_PATTERN)
    private val bearer = Regex(NativeScrubPatterns.BEARER_PATTERN)

    private val sensitiveHeaderNames = NativeScrubPatterns.SENSITIVE_HEADER_NAMES.split(",").toSet()
    private val sensitiveHeaderNameSubstrings = NativeScrubPatterns.SENSITIVE_HEADER_NAME_SUBSTRINGS.split(",").toSet()
    private val sensitiveBodyKeySubstrings = NativeScrubPatterns.SENSITIVE_BODY_KEY_SUBSTRINGS.split(",").toSet()
    private val sensitiveExactKeys = NativeScrubPatterns.SENSITIVE_EXACT_KEYS.split(",").toSet()
    private val navigationTypes = NativeScrubPatterns.NAVIGATION_TYPES.split(",").toSet()

    /**
     * The states sentry-android 8.61.0 records under the key `state` in its lifecycle breadcrumbs, by category:
     * ActivityBreadcrumbsIntegration under `ui.lifecycle` and LifecycleWatcher under `app.lifecycle`. The key also
     * carries the OIDC state, so only these values are kept, and only in these categories. Native only: the Dart
     * hook still masks them in the copies that LoadContextsIntegration merges into a Dart event.
     */
    private val lifecycleStates = mapOf(
        "ui.lifecycle" to setOf("created", "started", "resumed", "paused", "stopped", "saveInstanceState", "destroyed"),
        "app.lifecycle" to setOf("foreground", "background"),
    )

    /**
     * The `beforeSend` hook of the native SDK: [event] masked in place, or null when scrubbing it failed. [logError]
     * gets the line and the class name of the exception, never its message, which can hold the value it failed on.
     */
    fun beforeSend(event: SentryEvent, logError: (String, String) -> Unit = ::logToLogcat): SentryEvent? = try {
        scrubEvent(event)
    } catch (error: Throwable) {
        logError("Dropped a native event: scrubbing it failed", error.javaClass.name)
        null
    }

    /** The `beforeBreadcrumb` hook of the native SDK: [breadcrumb] masked in place, or null when scrubbing failed. */
    fun beforeBreadcrumb(breadcrumb: Breadcrumb, logError: (String, String) -> Unit = ::logToLogcat): Breadcrumb? =
        try {
            scrubBreadcrumb(breadcrumb)
        } catch (error: Throwable) {
            logError("Dropped a native breadcrumb: scrubbing it failed", error.javaClass.name)
            null
        }

    /** Masks emails, JWTs and the other secrets [maskSecrets] finds in [value]. */
    fun maskText(value: String): String = maskEmails(maskSecrets(value))

    /** The port of maskSecrets. */
    fun maskSecrets(input: String): String {
        var text = if (input.contains("eyJ")) jwt.replace(input) { NativeScrubPatterns.JWT_MASK } else input
        val lower = text.lowercase()
        if (lower.contains("bearer")) {
            text = bearer.replace(text) { "${it.groupValues[1]} ${NativeScrubPatterns.SECRET_MASK}" }
        }
        if (sensitiveBodyKeySubstrings.none { lower.contains(it) } && sensitiveExactKeys.none { lower.contains(it) }) {
            return text
        }
        if (text.contains('"')) {
            text = jsonMember.replace(text) { match ->
                val name = match.groupValues[1]
                val value = match.groupValues[3]
                if (!isSensitiveKey(name) || value.startsWith("\"[REDACTED")) {
                    match.value
                } else {
                    val mask = NativeScrubPatterns.SECRET_MASK
                    "\"$name\"${match.groupValues[2]}${if (value.startsWith("\"")) "\"$mask\"" else mask}"
                }
            }
        }
        if (text.contains('=')) {
            text = namedValue.replace(text) { match ->
                val name = match.groupValues[1]
                if (isSensitiveKey(name)) "$name=${NativeScrubPatterns.SECRET_MASK}" else match.value
            }
        }
        return text
    }

    /** The port of maskEmails. */
    fun maskEmails(input: String): String {
        if (!input.contains('@') && !input.contains("%40")) return input
        return email.replace(input) { NativeScrubPatterns.EMAIL_MASK }
    }

    private fun isSensitiveKey(key: Any?): Boolean {
        val lower = key.toString().lowercase()
        return sensitiveBodyKeySubstrings.any { lower.contains(it) } || sensitiveExactKeys.contains(lower)
    }

    /**
     * Masks every string in [value] at any depth, and the whole value of every credential key of a map. A value that
     * is not a number or a boolean is masked as its text, as the Dart scrubber does.
     */
    private fun maskValue(value: Any?): Any? = when (value) {
        null, is Number, is Boolean -> value
        is String -> maskText(value)
        is Map<*, *> -> maskMap(value)
        is Iterable<*> -> value.map { maskValue(it) }
        is Array<*> -> value.map { maskValue(it) }
        else -> maskText(value.toString())
    }

    private fun maskMap(map: Map<*, *>): Map<String, Any?> = map.entries.associate { (key, value) ->
        val masked = if (isSensitiveKey(key) && value != null) NativeScrubPatterns.SECRET_MASK else maskValue(value)
        key.toString() to masked
    }

    private fun scrubBreadcrumb(breadcrumb: Breadcrumb): Breadcrumb {
        breadcrumb.message?.let { breadcrumb.message = maskText(it) }
        val data = breadcrumb.data
        val state = data["state"]
        val masked = maskMap(data)
        for ((key, value) in masked) breadcrumb.setData(key, value)
        if (keepsState(breadcrumb.category, state)) breadcrumb.setData("state", state)
        return breadcrumb
    }

    private fun keepsState(category: String?, state: Any?): Boolean = when (category) {
        "navigation" -> state in navigationTypes
        else -> lifecycleStates[category]?.contains(state) == true
    }

    private fun scrubEvent(event: SentryEvent): SentryEvent {
        event.message?.let { message ->
            message.formatted?.let { message.formatted = maskText(it) }
            message.message?.let { message.message = maskText(it) }
            message.params?.let { params -> message.params = params.map { maskText(it) } }
        }
        event.exceptions?.forEach { exception -> exception.value?.let { exception.value = maskText(it) } }
        event.breadcrumbs?.forEach { scrubBreadcrumb(it) }
        event.extras?.let { extras -> event.extras = maskMap(extras) }
        event.tags?.let { tags -> event.tags = maskTextMap(tags) }
        event.user?.let { scrubUser(it) }
        event.request?.let { scrubRequest(it) }
        event.transaction?.let { event.transaction = maskText(it) }
        return event
    }

    /**
     * Masks [request] as sentryBeforeSend does: the url parts and the body masked, the cookies dropped, the
     * [NativeScrubPatterns.SENSITIVE_HEADER_NAMES] dropped, a header whose name names a credential (a body key, or one
     * of [NativeScrubPatterns.SENSITIVE_HEADER_NAME_SUBSTRINGS]) masked whole, and every other header value and every
     * env value masked as text.
     */
    private fun scrubRequest(request: Request) {
        request.url?.let { request.url = maskText(it) }
        request.queryString?.let { request.queryString = maskText(it) }
        request.fragment?.let { request.fragment = maskText(it) }
        request.data?.let { request.data = maskValue(it) }
        request.cookies = null
        request.headers?.let { headers ->
            request.headers = headers
                .filterKeys { it.lowercase() !in sensitiveHeaderNames }
                .mapValues { (name, value) ->
                    if (isSensitiveKey(name) || namesHeaderCredential(name)) {
                        NativeScrubPatterns.SECRET_MASK
                    } else {
                        maskText(value)
                    }
                }
        }
        request.envs?.let { envs -> request.envs = envs.mapValues { (_, value) -> maskText(value) } }
        request.others?.let { others -> request.others = others.mapValues { (_, value) -> maskText(value) } }
    }

    /** Masks the text fields of [user] as text, and its data as a breadcrumb's data, as sentryBeforeSend does. */
    private fun scrubUser(user: User) {
        user.id?.let { user.id = maskText(it) }
        user.username?.let { user.username = maskText(it) }
        user.email?.let { user.email = maskText(it) }
        user.ipAddress?.let { user.ipAddress = maskText(it) }
        user.name?.let { user.name = maskText(it) }
        user.data?.let { data -> user.data = maskTextMap(data) }
    }

    /** [map] with the whole value of every credential key masked and every other value masked as text. */
    private fun maskTextMap(map: Map<String, String>): Map<String, String> =
        maskMap(map).mapValues { (_, value) -> value.toString() }

    private fun namesHeaderCredential(name: String): Boolean {
        val lower = name.lowercase()
        return sensitiveHeaderNameSubstrings.any { lower.contains(it) }
    }

    internal fun logToLogcat(message: String, errorClass: String) {
        Log.e(TAG, "$message ($errorClass)")
    }
}
