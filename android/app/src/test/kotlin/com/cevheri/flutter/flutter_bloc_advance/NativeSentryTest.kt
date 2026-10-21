package com.cevheri.flutter.flutter_bloc_advance

import io.sentry.Breadcrumb
import io.sentry.Hint
import io.sentry.SentryEvent
import io.sentry.android.core.SentryAndroidOptions
import io.sentry.protocol.SdkVersion
import io.sentry.protocol.SentryException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The options the host app starts sentry-android with, built as [NativeSentry.start] builds them. */
class NativeSentryTest {
    private val jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart"

    private fun configured() = SentryAndroidOptions().also {
        NativeSentry.configure(
            it,
            dsn = "https://public@example.invalid/1",
            release = "0.22.2+1",
            dist = "1",
            environment = "production",
        )
    }

    @Test
    fun installsABeforeSendThatScrubsTheEventAndTagsItsOrigin() {
        val options = configured()
        val event = SentryEvent().apply {
            sdk = SdkVersion("sentry.java.android.flutter", "8.61.0")
            exceptions = listOf(SentryException().apply { value = "user jane.doe@example.com token $jwt" })
        }

        val sent = options.beforeSend!!.execute(event, Hint())!!

        assertEquals("user [REDACTED_EMAIL] token [REDACTED_JWT]", sent.exceptions!![0].value)
        assertEquals("android", sent.getTag("event.origin"))
    }

    @Test
    fun installsABeforeBreadcrumbThatScrubsTheBreadcrumb() {
        val options = configured()
        val crumb = Breadcrumb("user jane.doe@example.com").apply { setData("email", "jane.doe@example.com") }

        val kept = options.beforeBreadcrumb!!.execute(crumb, Hint())!!

        assertEquals("user [REDACTED_EMAIL]", kept.message)
        assertEquals("[REDACTED_EMAIL]", kept.data["email"])
    }

    // sentry_flutter passes its Dart timeouts of 5 seconds to the native SDK, whose defaults are 30 seconds.
    @Test
    fun setsTheOptionsThatSentryFlutterWouldPass() {
        val options = configured()

        assertEquals("https://public@example.invalid/1", options.dsn)
        assertEquals("0.22.2+1", options.release)
        assertEquals("1", options.dist)
        assertEquals("production", options.environment)
        assertEquals(5000, options.connectionTimeoutMillis)
        assertEquals(5000, options.readTimeoutMillis)
        assertTrue(options.isEnableScopeSync)
        assertFalse(options.isEnableAutoTraceIdGeneration)
        assertEquals("sentry.java.android.flutter", options.sdkVersion!!.name)
        assertEquals("sentry.native.android.flutter", options.nativeSdkName)
    }
}
