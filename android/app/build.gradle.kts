import java.io.File
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter passes the --dart-define values as the `dart-defines` Gradle property: each entry is base64 encoded and the
// entries are separated by commas (encodeDartDefines in packages/flutter_tools/lib/src/build_info.dart).
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        .orEmpty()
        .split(",")
        .filter { it.isNotEmpty() }
        .map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        .associate { it.substringBefore("=") to it.substringAfter("=", "") }

// The host app starts sentry-android itself (NativeSentry.kt), and only when the Dart side starts Sentry: in the prod
// environment, which only lib/main/main_prod.dart selects, with a SENTRY_DSN (AppConfig.sentryDsn). On Android every
// Dart event leaves the device through the native SDK, so the two gates must agree; a fork that renames the prod
// entry point changes it here too (test/architecture/sentry_native_scrub_patterns_test.dart checks it, and
// nativeSdkReady fails at start when the gates disagree).
val isProdTarget = File(project.findProperty("target") as String? ?: "").name == "main_prod.dart"

fun buildConfigString(value: String) = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

android {
    namespace = "com.cevheri.flutter.flutter_bloc_advance"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cevheri.flutter.flutter_bloc_advance"
        // sentry_flutter 10 requires Android API 26 or higher.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The oidc_android redirect activity listens on this scheme; it must match OidcSettings.defaultRedirectScheme.
        manifestPlaceholders["oidcRedirectScheme"] = "com.example.flutterblocadvance"
        // The DSN is the public key that --dart-define already compiles into the Dart snapshot.
        val nativeSentryDsn = if (isProdTarget) dartDefines["SENTRY_DSN"].orEmpty() else ""
        buildConfigField("String", "SENTRY_DSN", buildConfigString(nativeSentryDsn))
        buildConfigField("String", "SENTRY_ENVIRONMENT", buildConfigString(dartDefines["SENTRY_ENVIRONMENT"].orEmpty()))
        buildConfigField("String", "SENTRY_DIST", buildConfigString(dartDefines["SENTRY_DIST"].orEmpty()))
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    // Reads test/fixtures/native_scrub_cases.json, which the Dart scrubber test runs too.
    testImplementation("com.google.code.gson:gson:2.13.2")
}
