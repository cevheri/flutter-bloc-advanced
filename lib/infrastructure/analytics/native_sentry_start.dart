import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The channel on which `MainActivity.kt` answers whether the host app
/// started the native Sentry SDK.
const String nativeSentryChannelName = 'flutter_bloc_advance/native_sentry';

final _log = AppLogger.getLogger('NativeSentryStart');

/// Whether the host app, not sentry_flutter, starts the native Sentry SDK on
/// the platform of [options]: on Android `MainApplication.kt` starts
/// sentry-android with the scrubbing hooks of `NativeSentryScrubber.kt`, so
/// what the native SDK records itself leaves the device masked too.
///
/// It reads `options.platform`, by which sentry_flutter picks its Java
/// binding, and not the Flutter target platform, which a test or a debug
/// session can override. iOS and macOS keep the start by sentry_flutter, and
/// their native events and breadcrumbs are not scrubbed yet.
bool hostStartsNativeSdk(SentryOptions options) =>
    hostStartsNativeSdkOn(isWeb: options.platform.isWeb, isAndroid: options.platform.isAndroid);

/// The rule of [hostStartsNativeSdk]. On web the options report the
/// operating system of the browser, which is Android in a phone browser, and
/// sentry_flutter starts the JavaScript SDK there.
@visibleForTesting
bool hostStartsNativeSdkOn({required bool isWeb, required bool isAndroid}) => isAndroid && !isWeb;

/// Turns [SentryFlutterOptions.autoInitializeNativeSdk] off where
/// [hostStartsNativeSdk], or where [hostStarts] says so, and leaves it on
/// everywhere else.
///
/// sentry_flutter then no longer passes the Dart options to the native SDK
/// on Android. Any native option set on the Dart side, such as
/// `enableAutoNativeBreadcrumbs`, `enableNativeCrashHandling`,
/// `maxBreadcrumbs`, `sendDefaultPii` or the replay options, must be set in
/// `NativeSentry.kt` of the Android host app (under
/// `android/app/src/main/kotlin`) as well, or it does nothing there.
void configureNativeSdkStart(SentryFlutterOptions options, {bool? hostStarts}) {
  options.autoInitializeNativeSdk = !(hostStarts ?? hostStartsNativeSdk(options));
}

/// Whether the Dart SDK may start. Where the host app starts the native SDK
/// ([hostStarts], by default [hostStartsNativeSdk] of the options
/// sentry_flutter builds), it asks the host whether it did.
///
/// On Android every Dart event leaves the device through the native SDK, so
/// a Dart SDK that starts while the host did not start the native one drops
/// every event while it looks configured. The host starts it only for a
/// `lib/main/main_prod.dart` build with a `SENTRY_DSN` (the gate in
/// `android/app/build.gradle.kts`), the Dart side for the prod environment
/// with one (`AppConfig.sentryDsn`), and the two gates disagree when a fork
/// changes one of them. A debug or profile build then throws a [StateError]
/// that names the mismatch; a release build logs it and returns false, so the
/// app runs without Sentry.
Future<bool> nativeSdkReady({
  bool? hostStarts,
  MethodChannel channel = const MethodChannel(nativeSentryChannelName),
  bool releaseMode = kReleaseMode,
}) async {
  if (!(hostStarts ?? hostStartsNativeSdk(SentryFlutterOptions()))) return true;
  final enabled = await channel.invokeMethod<bool>('isEnabled');
  if (enabled == true) return true;
  final error = StateError(
    'Sentry has a DSN on the Dart side, but the host app did not start the native Sentry SDK (it answered $enabled), '
    'so every Dart event would be dropped. The host starts it only for a lib/main/main_prod.dart build with a '
    'SENTRY_DSN define: see android/app/build.gradle.kts.',
  );
  if (!releaseMode) throw error;
  _log.error('Sentry stays off: {}', [error.message]);
  return false;
}
