package com.cevheri.flutter.flutter_bloc_advance

import com.google.gson.Gson
import io.sentry.Breadcrumb
import io.sentry.Hint
import io.sentry.SentryEvent
import io.sentry.SentryOptions
import io.sentry.protocol.Message
import io.sentry.protocol.Request
import io.sentry.protocol.SentryException
import io.sentry.protocol.User
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeSentryScrubberTest {
    private val jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart"
    private val logged = mutableListOf<String>()
    private val loggedClasses = mutableListOf<String>()
    private val logError: (String, String) -> Unit = { message, errorClass ->
        logged.add(message)
        loggedClasses.add(errorClass)
    }

    /** A value whose text cannot be read, so scrubbing it throws. */
    private val unreadable = object {
        override fun toString(): String = throw IllegalStateException("unreadable")
    }

    @Test
    fun masksAnEmailAndAJwtInTheMessageTheExceptionValueAndBreadcrumbData() {
        val crumb = Breadcrumb("user jane.doe@example.com").apply { setData("auth", "Bearer $jwt") }
        val event = SentryEvent().apply {
            message = Message().apply {
                formatted = "user jane.doe@example.com token $jwt"
                message = "user %s token %s"
                params = listOf("jane.doe@example.com", jwt)
            }
            exceptions = listOf(SentryException().apply { value = "jane.doe@example.com $jwt" })
            breadcrumbs = listOf(crumb)
        }

        val result = NativeSentryScrubber.beforeSend(event, logError)!!

        assertEquals("user [REDACTED_EMAIL] token [REDACTED_JWT]", result.message!!.formatted)
        assertEquals("user %s token %s", result.message!!.message)
        assertEquals(listOf("[REDACTED_EMAIL]", "[REDACTED_JWT]"), result.message!!.params)
        assertEquals("[REDACTED_EMAIL] [REDACTED_JWT]", result.exceptions!![0].value)
        assertEquals("user [REDACTED_EMAIL]", crumb.message)
        assertEquals("Bearer [REDACTED_JWT]", crumb.data["auth"])
    }

    @Test
    fun masksAnEmailAndAJwtInTheMessageAndDataOfABreadcrumb() {
        val crumb = Breadcrumb("GET /admin/users/jane.doe@example.com").apply {
            category = "http"
            setData("url", "https://api.example.test/users/jane.doe@example.com?access_token=$jwt")
            setData("status_code", 503)
            setData(
                "form",
                mapOf("login" to "admin", "newPassword" to "Adm1nSet!Pw", "emails" to listOf("j@example.org")),
            )
            setData("otp", "493817")
        }

        val result = NativeSentryScrubber.beforeBreadcrumb(crumb, logError)

        assertSame(crumb, result)
        assertEquals("GET /admin/users/[REDACTED_EMAIL]", crumb.message)
        assertEquals("https://api.example.test/users/[REDACTED_EMAIL]?access_token=[REDACTED_JWT]", crumb.data["url"])
        assertEquals(503, crumb.data["status_code"])
        assertEquals(
            mapOf("login" to "admin", "newPassword" to "[REDACTED]", "emails" to listOf("[REDACTED_EMAIL]")),
            crumb.data["form"],
        )
        assertEquals("[REDACTED]", crumb.data["otp"])
    }

    @Test
    fun keepsTheNavigatorEventOfANavigationBreadcrumb() {
        val crumb = Breadcrumb().apply {
            category = "navigation"
            setData("state", "didPush")
            setData("to", "login-otp-verify")
        }

        NativeSentryScrubber.beforeBreadcrumb(crumb, logError)

        assertEquals(mapOf("state" to "didPush", "to" to "login-otp-verify"), crumb.data)
    }

    @Test
    fun masksStateInABreadcrumbThatIsNotANavigationOne() {
        val event = Breadcrumb().apply { category = "event"; setData("state", "didPop") }
        val callback = Breadcrumb().apply { category = "navigation"; setData("state", "st4te999") }

        NativeSentryScrubber.beforeBreadcrumb(event, logError)
        NativeSentryScrubber.beforeBreadcrumb(callback, logError)

        assertEquals("[REDACTED]", event.data["state"])
        assertEquals("[REDACTED]", callback.data["state"])
    }

    @Test
    fun keepsTheStateOfAnActivityLifecycleBreadcrumb() {
        val activity = Breadcrumb().apply {
            type = "navigation"
            category = "ui.lifecycle"
            setData("state", "resumed")
            setData("screen", "MainActivity")
        }
        val app = Breadcrumb().apply { type = "navigation"; category = "app.lifecycle"; setData("state", "foreground") }

        NativeSentryScrubber.beforeBreadcrumb(activity, logError)
        NativeSentryScrubber.beforeBreadcrumb(app, logError)

        assertEquals(mapOf("state" to "resumed", "screen" to "MainActivity"), activity.data)
        assertEquals("foreground", app.data["state"])
    }

    @Test
    fun masksAStateThatIsNoLifecycleStateInALifecycleBreadcrumb() {
        val activity = Breadcrumb().apply { category = "ui.lifecycle"; setData("state", "foreground") }
        val app = Breadcrumb().apply { category = "app.lifecycle"; setData("state", "st4te999") }

        NativeSentryScrubber.beforeBreadcrumb(activity, logError)
        NativeSentryScrubber.beforeBreadcrumb(app, logError)

        assertEquals("[REDACTED]", activity.data["state"])
        assertEquals("[REDACTED]", app.data["state"])
    }

    // A Dart breadcrumb reaches the native hook already masked, when Sentry syncs it to the native scope.
    @Test
    fun masksTheSameTextTwiceToTheSameResult() {
        val once = NativeSentryScrubber.maskText("""{"password":"x"} jane.doe@example.com $jwt code=4f2a9c""")

        assertEquals("""{"password":"[REDACTED]"} [REDACTED_EMAIL] [REDACTED_JWT] code=[REDACTED]""", once)
        assertEquals(once, NativeSentryScrubber.maskText(once))
    }

    @Test
    fun masksEveryCaseOfTheFixtureSharedWithTheDartScrubber() {
        val json = File("../../test/fixtures/native_scrub_cases.json").readText()
        val cases = Gson().fromJson(json, Array<FixtureCase>::class.java)

        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            assertEquals(case.input, case.expected, NativeSentryScrubber.maskText(case.input))
        }
    }

    @Test
    fun masksTheRequestLikeTheDartScrubber() {
        val event = SentryEvent().apply {
            request = Request().apply {
                url = "https://api.example.test/users/jane.doe@example.com"
                queryString = "token=$jwt"
                fragment = "/login-otp-verify/jane.doe@example.com"
                cookies = "sid=abc"
                data = mapOf("login" to "jane.doe@example.com", "password" to "p@ss")
                headers = mapOf(
                    "Authorization" to "Bearer $jwt",
                    "Cookie" to "sid=abc",
                    "X-Auth-Token" to "at-opaque-0a1b2c3d",
                    "X-Debug-Context" to "session $jwt",
                    "Accept" to "application/json",
                )
                envs = mapOf("REMOTE_USER" to "jane.doe@example.com", "QUERY_STRING" to "code=4f2a9c&state=st4te999")
            }
            transaction = "/login-otp-verify/jane.doe@example.com"
        }

        val request = NativeSentryScrubber.beforeSend(event, logError)!!.request!!

        assertEquals("https://api.example.test/users/[REDACTED_EMAIL]", request.url)
        assertEquals("token=[REDACTED_JWT]", request.queryString)
        assertEquals("/login-otp-verify/[REDACTED_EMAIL]", request.fragment)
        assertNull(request.cookies)
        assertEquals(mapOf("login" to "[REDACTED_EMAIL]", "password" to "[REDACTED]"), request.data)
        assertEquals(
            mapOf(
                "X-Auth-Token" to "[REDACTED]",
                "X-Debug-Context" to "session [REDACTED_JWT]",
                "Accept" to "application/json",
            ),
            request.headers,
        )
        assertEquals(
            mapOf("REMOTE_USER" to "[REDACTED_EMAIL]", "QUERY_STRING" to "code=[REDACTED]&state=[REDACTED]"),
            request.envs,
        )
        assertEquals("/login-otp-verify/[REDACTED_EMAIL]", event.transaction)
    }

    @Test
    fun masksTheExtrasAndTheTags() {
        val event = SentryEvent().apply {
            setExtra("user", "jane.doe@example.com")
            setExtra("session", mapOf("refreshToken" to "rt-9f8e7d6c", "count" to 3))
            setTag("login", "jane.doe@example.com")
            setTag("event.origin", "android")
        }

        NativeSentryScrubber.beforeSend(event, logError)

        assertEquals("[REDACTED_EMAIL]", event.getExtra("user"))
        assertEquals(mapOf("refreshToken" to "[REDACTED]", "count" to 3), event.getExtra("session"))
        assertEquals("[REDACTED_EMAIL]", event.getTag("login"))
        assertEquals("android", event.getTag("event.origin"))
    }

    @Test
    fun masksTheValueOfATagNamedLikeACredential() {
        val event = SentryEvent().apply {
            setTag("otp", "493817")
            setTag("event.origin", "android")
        }

        NativeSentryScrubber.beforeSend(event, logError)

        assertEquals("[REDACTED]", event.getTag("otp"))
        assertEquals("android", event.getTag("event.origin"))
    }

    @Test
    fun masksTheWholeValueOfAnAuthorizationOrApiKeyHeader() {
        val event = SentryEvent().apply {
            request = Request().apply {
                headers = mapOf(
                    "Proxy-Authorization" to "Basic dXNlcjpwYXNz",
                    "X-Api-Key" to "k-0a1b2c3d4e",
                    "X-Keyboard-Layout" to "tr-q",
                )
            }
        }

        val headers = NativeSentryScrubber.beforeSend(event, logError)!!.request!!.headers

        assertEquals(
            mapOf("Proxy-Authorization" to "[REDACTED]", "X-Api-Key" to "[REDACTED]", "X-Keyboard-Layout" to "tr-q"),
            headers,
        )
    }

    // Scope sync copies the Dart user to the native scope, so a fork that calls setUserId with an email sends it in
    // every native crash.
    @Test
    fun masksTheUserLikeTheDartScrubber() {
        val event = SentryEvent().apply {
            user = User().apply {
                id = "jane.doe@example.com"
                username = "jane $jwt"
                email = "jane.doe@example.com"
                ipAddress = "203.0.113.7"
                name = "Jane token=at-0a1b"
                data = mapOf("refreshToken" to "rt-9f8e7d6c", "plan" to "pro", "contact" to "j@example.org")
            }
        }

        val user = NativeSentryScrubber.beforeSend(event, logError)!!.user!!

        assertEquals("[REDACTED_EMAIL]", user.id)
        assertEquals("jane [REDACTED_JWT]", user.username)
        assertEquals("[REDACTED_EMAIL]", user.email)
        assertEquals("203.0.113.7", user.ipAddress)
        assertEquals("Jane token=[REDACTED]", user.name)
        assertEquals(mapOf("refreshToken" to "[REDACTED]", "plan" to "pro", "contact" to "[REDACTED_EMAIL]"), user.data)
    }

    @Test
    fun masksEveryMapCaseOfTheFixtureSharedWithTheDartScrubber() {
        val json = File("../../test/fixtures/native_scrub_map_cases.json").readText()
        val cases = Gson().fromJson(json, Array<MapFixtureCase>::class.java)

        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val event = SentryEvent()
            when (case.field) {
                "headers" -> event.request = Request().apply { headers = case.input }
                "tags" -> event.tags = case.input
                else -> throw AssertionError("unknown field ${case.field}")
            }
            val result = NativeSentryScrubber.beforeSend(event, logError)!!
            val masked = if (case.field == "headers") result.request!!.headers else result.tags
            assertEquals(case.field, case.expected, masked)
        }
    }

    @Test
    fun dropsTheEventAndLogsWhenScrubbingThrows() {
        val event = SentryEvent().apply { setExtra("value", unreadable) }

        assertNull(NativeSentryScrubber.beforeSend(event, logError))
        assertEquals(listOf("Dropped a native event: scrubbing it failed"), logged)
    }

    @Test
    fun dropsTheBreadcrumbAndLogsWhenScrubbingThrows() {
        val crumb = Breadcrumb("jane.doe@example.com").apply { setData("value", unreadable) }

        assertNull(NativeSentryScrubber.beforeBreadcrumb(crumb, logError))
        assertEquals(listOf("Dropped a native breadcrumb: scrubbing it failed"), logged)
    }

    // The message of the exception that stopped the scrub can hold the value it failed on, and logcat is readable over
    // adb, so the drop line names only the hook and the class of the exception.
    @Test
    fun logsOnlyTheClassOfTheExceptionThatDroppedAnEventOrABreadcrumb() {
        val leaking = object {
            override fun toString(): String = throw IllegalStateException("jane.doe@example.com $jwt")
        }

        NativeSentryScrubber.beforeSend(SentryEvent().apply { setExtra("value", leaking) }, logError)
        NativeSentryScrubber.beforeBreadcrumb(Breadcrumb().apply { setData("value", leaking) }, logError)

        assertEquals(
            listOf("Dropped a native event: scrubbing it failed", "Dropped a native breadcrumb: scrubbing it failed"),
            logged,
        )
        assertEquals(listOf("java.lang.IllegalStateException", "java.lang.IllegalStateException"), loggedClasses)
    }

    // sentry_flutter tags the origin of an event in the callback SentryFlutterPlugin.setupBeforeSend installs; the
    // host keeps it and runs it on the scrubbed event.
    @Test
    fun runsTheOriginTagCallbackOnTheScrubbedEvent() {
        var seen: String? = null
        val tagOrigin = SentryOptions.BeforeSendCallback { event, _ ->
            seen = event.exceptions!![0].value
            event.apply { setTag("event.origin", "android") }
        }
        val callback = NativeSentry.scrubbingBeforeSend(tagOrigin, logError)
        val event = SentryEvent().apply {
            exceptions = listOf(SentryException().apply { value = "jane.doe@example.com" })
        }

        val result = callback.execute(event, Hint())

        assertEquals("[REDACTED_EMAIL]", seen)
        assertEquals("android", result!!.getTag("event.origin"))
    }

    @Test
    fun neitherTagsNorSendsAnEventWhoseScrubbingThrows() {
        var tagged = false
        val tagOrigin = SentryOptions.BeforeSendCallback { event, _ -> tagged = true; event }
        val callback = NativeSentry.scrubbingBeforeSend(tagOrigin, logError)

        assertNull(callback.execute(SentryEvent().apply { setExtra("value", unreadable) }, Hint()))
        assertFalse(tagged)
    }

    @Test
    fun dropsAnEventThatTheOriginTagCallbackDrops() {
        val tagOrigin = SentryOptions.BeforeSendCallback { _, _ -> null }
        val callback = NativeSentry.scrubbingBeforeSend(tagOrigin, logError)

        assertNull(callback.execute(SentryEvent(), Hint()))
    }

    private class FixtureCase(val input: String, val expected: String)

    private class MapFixtureCase(val field: String, val input: Map<String, String>, val expected: Map<String, String>)
}
