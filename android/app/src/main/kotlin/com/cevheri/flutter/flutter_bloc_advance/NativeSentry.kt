package com.cevheri.flutter.flutter_bloc_advance

import android.content.Context
import android.content.pm.PackageInfo
import android.os.Build
import io.sentry.SentryOptions
import io.sentry.android.core.SentryAndroid
import io.sentry.flutter.SentryFlutterPlugin
import io.sentry.protocol.SdkVersion

/**
 * Starts sentry-android from the host app, before the Flutter engine, with the scrubbing hooks of
 * [NativeSentryScrubber], so what the native SDK records itself leaves the device masked. On Android the Dart side
 * turns `autoInitializeNativeSdk` off (configureNativeSdkStart in
 * lib/infrastructure/analytics/native_sentry_start.dart) and its events leave through this SDK.
 *
 * It starts only when the build carries a DSN: android/app/build.gradle.kts puts SENTRY_DSN into [BuildConfig] only
 * for a lib/main/main_prod.dart build, the only one in which the Dart side starts Sentry.
 *
 * sentry_flutter passes no Dart option to this SDK, so the options below repeat what it would set
 * (configureAndroidOptions in sentry_flutter 10.1.0, lib/src/native/java/sentry_native_java_init.dart); every other
 * option keeps the default, which is the same in both SDKs. A native option set on the Dart side in
 * lib/app/bootstrap/app_bootstrap.dart must be set here too, or it does nothing on Android. Session Replay is not
 * wired: its recorder callbacks are created in Dart.
 */
object NativeSentry {
    private const val JAVA_SDK_NAME = "sentry.java.android.flutter"
    private const val NATIVE_SDK_NAME = "sentry.native.android.flutter"

    fun start(context: Context) {
        val dsn = BuildConfig.SENTRY_DSN
        if (dsn.isEmpty()) return
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        val buildNumber = buildNumber(packageInfo)
        SentryAndroid.init(context) { options ->
            options.dsn = dsn
            // The release AppBootstrap sets on the Dart side, from the same package info.
            options.release = "${packageInfo.versionName.orEmpty()}+$buildNumber"
            options.dist = BuildConfig.SENTRY_DIST.ifEmpty { buildNumber.toString() }
            options.environment = BuildConfig.SENTRY_ENVIRONMENT.ifEmpty { environmentFor(BuildConfig.BUILD_TYPE) }
            options.isEnableScopeSync = true
            // Dart owns the trace and pushes it to the native SDK.
            options.isEnableAutoTraceIdGeneration = false
            options.logs.isEnabled = true
            options.metrics.isEnabled = true
            val version = io.sentry.android.core.BuildConfig.VERSION_NAME
            options.sdkVersion =
                (options.sdkVersion ?: SdkVersion(JAVA_SDK_NAME, version)).apply { name = JAVA_SDK_NAME }
            options.sentryClientName = "$JAVA_SDK_NAME/$version"
            options.nativeSdkName = NATIVE_SDK_NAME
            // Installs the callback that tags the origin of each event by its SDK name.
            SentryFlutterPlugin.setupBeforeSend(options)
            options.beforeSend = scrubbingBeforeSend(options.beforeSend)
            options.beforeBreadcrumb = SentryOptions.BeforeBreadcrumbCallback { breadcrumb, _ ->
                NativeSentryScrubber.beforeBreadcrumb(breadcrumb)
            }
        }
    }

    /**
     * Scrubs each event, then runs [tagOrigin] on it and returns its result; an event whose scrubbing failed is
     * neither tagged nor sent.
     */
    fun scrubbingBeforeSend(
        tagOrigin: SentryOptions.BeforeSendCallback?,
        logError: (String, Throwable) -> Unit = NativeSentryScrubber::logToLogcat,
    ) = SentryOptions.BeforeSendCallback { event, hint ->
        NativeSentryScrubber.beforeSend(event, logError)?.let { scrubbed ->
            if (tagOrigin == null) scrubbed else tagOrigin.execute(scrubbed, hint)
        }
    }

    /** The environment the Dart SDK picks by build mode when SENTRY_ENVIRONMENT is not defined. */
    private fun environmentFor(buildType: String) = when (buildType) {
        "release" -> "production"
        "profile" -> "profile"
        else -> "debug"
    }

    /** The build number package_info_plus reads, which the Dart side puts into the release. */
    private fun buildNumber(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        info.longVersionCode
    } else {
        @Suppress("DEPRECATION")
        info.versionCode.toLong()
    }
}
