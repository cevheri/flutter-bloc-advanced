import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/native_sentry_start.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_scrub.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The shape of [SentryFlutter.init] that [SentryStart] calls.
typedef SentryInit = Future<void> Function(FlutterOptionsConfiguration optionsConfiguration, {AppRunner? appRunner});

/// How `AppBootstrap.run` starts Sentry: whether it may start at all
/// ([gate]), and the start itself ([run]). A test passes one whose platform
/// parts, the host check and [SentryFlutter.init], are its own.
class SentryStart {
  const SentryStart({this.isNativeSdkReady = nativeSdkReady, this.sentryInit = SentryFlutter.init});

  /// Answers whether the Dart SDK may start: where the host app starts the
  /// native SDK, whether it did ([nativeSdkReady]).
  final Future<bool> Function() isNativeSdkReady;

  /// Starts the Dart SDK.
  final SentryInit sentryInit;

  /// Returns [config], or [config] without its DSN when it has one but
  /// [isNativeSdkReady] keeps Sentry off (a release build whose host app did
  /// not start the native SDK). The app then runs exactly as without a DSN:
  /// no Dart SDK, and the log-only analytics instead of a Sentry hub that
  /// never started. Debug and profile builds throw there instead.
  Future<AppConfig> gate(AppConfig config) async {
    if (config.sentryDsn == null) return config;
    return await isNativeSdkReady() ? config : config.withoutSentry();
  }

  /// Runs [appRunner] inside [SentryFlutter.init] with the options of
  /// [configureSentryOptions] when [dsn] is set, and on its own when it is
  /// null.
  Future<void> run(String? dsn, {required String release, required AppRunner appRunner}) async {
    if (dsn == null) {
      await appRunner();
      return;
    }
    _log.info('Initializing Sentry (release: {})', [release]);
    await sentryInit(
      (options) => configureSentryOptions(options, dsn: dsn, release: release),
      appRunner: appRunner,
    );
  }
}

final _log = AppLogger.getLogger('SentryStart');

/// The options `AppBootstrap.run` starts the Dart SDK with: the DSN, the
/// scrubbing hooks of [installSentryScrubbers], the native start of
/// [configureNativeSdkStart], the trace sample rate and the release.
///
/// On Android the host app starts the native SDK, so a native option set
/// here must also be set in `NativeSentry.kt` of the Android host app (under
/// `android/app/src/main/kotlin`), or it does nothing there.
void configureSentryOptions(SentryFlutterOptions options, {required String dsn, required String release}) {
  options.dsn = dsn;
  installSentryScrubbers(options);
  configureNativeSdkStart(options);
  options.tracesSampleRate = 0.2;
  options.release = release;
}
