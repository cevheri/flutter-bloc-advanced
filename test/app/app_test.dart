@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/force_update_screen.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/maintenance_screen.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/startup_storage_time_limit.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';

import '../mocks/mock_classes.dart';
import '../support/url_launcher_stub.dart';

/// Device preferences whose stored language arrives only when [language] completes, like a slow device.
class _HeldLanguageStorage implements AppLocalStorage {
  _HeldLanguageStorage(this.language);

  final Future<Object?> language;

  @override
  Future<dynamic> read(String key) => key == StorageKeys.language.key ? language : AppLocalStorage().read(key);
  @override
  Future<bool> save(String key, dynamic value) => AppLocalStorage().save(key, value);
  @override
  Future<bool> remove(String key) => AppLocalStorage().remove(key);
  @override
  Future<void> clear() => AppLocalStorage().clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => AppLocalStorage().setPreferencesInstance(prefs);
}

/// The default dependencies, recording the session end signals and refresh locks they create and where they go.
class _TabResourceDependencies extends AppDependencies {
  _TabResourceDependencies();

  final signals = <ISessionEndSignal>[];
  final locks = <ITokenRefreshLock>[];
  final repositorySignals = <ISessionEndSignal?>[];
  final apiClientLocks = <ITokenRefreshLock?>[];
  final apiClientTakeBacks = <RotatedTokensTakeBack?>[];

  @override
  ISessionEndSignal? createSessionEndSignal() {
    final signal = _SilentSessionEndSignal();
    signals.add(signal);
    return signal;
  }

  @override
  ITokenRefreshLock createTokenRefreshLock() {
    final lock = _PassThroughLock();
    locks.add(lock);
    return lock;
  }

  @override
  IAuthSessionRepository createAuthSessionRepository(
    ISecureStorage secureStorage, {
    required ISessionEndSignal? sessionEndSignal,
  }) {
    repositorySignals.add(sessionEndSignal);
    return super.createAuthSessionRepository(secureStorage, sessionEndSignal: sessionEndSignal);
  }

  @override
  ApiClient createApiClient(
    ISecureStorage secureStorage, {
    required OnSessionExpired onSessionExpired,
    required ITokenRefreshLock? tokenRefreshLock,
    required RotatedTokensTakeBack? rotatedTokensTakeBack,
  }) {
    apiClientLocks.add(tokenRefreshLock);
    apiClientTakeBacks.add(rotatedTokensTakeBack);
    return super.createApiClient(
      secureStorage,
      onSessionExpired: onSessionExpired,
      tokenRefreshLock: tokenRefreshLock,
      rotatedTokensTakeBack: rotatedTokensTakeBack,
    );
  }
}

/// A session end signal that no other tab uses.
class _SilentSessionEndSignal implements ISessionEndSignal {
  bool disposed = false;

  @override
  void dispose() => disposed = true;

  @override
  void notifyEnded() {}

  @override
  Stream<DateTime> get endedElsewhere => const Stream.empty();

  @override
  Stream<void> get storeChanges => const Stream.empty();
}

/// A refresh lock of its own, which runs each refresh at once.
class _PassThroughLock implements ITokenRefreshLock {
  bool disposed = false;

  @override
  void dispose() => disposed = true;

  @override
  Future<T> hold<T>(Future<T> Function() body) => body();
}

class _LocalStorageDependencies extends AppDependencies {
  const _LocalStorageDependencies(this.localStorage);

  final AppLocalStorage localStorage;

  @override
  AppLocalStorage createLocalStorage() => localStorage;
}

void main() {
  group('App', () {
    testWidgets('shows a loading indicator in place of the router until the stored session is restored', (
      tester,
    ) async {
      final storedToken = Completer<String?>();
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
      final analytics = MockAnalyticsService();
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage, analytics: analytics));
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      verifyNever(
        () => analytics.logScreenView(
          screenName: any(named: 'screenName'),
          screenClass: any(named: 'screenClass'),
        ),
      );

      storedToken.complete(null);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading...'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows the login page once secure storage has not answered within the restore time limit', (
      tester,
    ) async {
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => Completer<String?>().future);
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump(SessionCubit.defaultRestoreTimeLimit - const Duration(milliseconds: 1));

      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading...'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows the login page when secure storage never answers, from the session migration at startup on', (
      tester,
    ) async {
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => Completer<String?>().future);

      // AppBootstrap.run awaits the session migration, which reads secure storage first, and only then runs App.
      var migrated = false;
      unawaited(
        runSessionMigration(secureStorage: secureStorage, localStorage: AppLocalStorage()).then((_) => migrated = true),
      );
      await tester.pump(StartupStorageTimeLimit.defaultDuration);
      expect(migrated, isTrue, reason: 'the launch screen stays up until the migration is done');

      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump(SessionCubit.defaultRestoreTimeLimit);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // On macOS a read waits while the login keychain asks for its password, which the user may enter after the limit.
    testWidgets('opens the app when secure storage answers with a stored session after the restore time limit', (
      tester,
    ) async {
      final storedToken = Completer<String?>();
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump(SessionCubit.defaultRestoreTimeLimit);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      storedToken.complete('MOCK_TOKEN');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
    });

    // A deep link, a bookmark or a browser refresh starts the app on a page, which the restore time limit replaces with
    // the login page that keeps the page as its returnUrl.
    testWidgets('opens the page the app started on when a stored session answers after the restore time limit', (
      tester,
    ) async {
      tester.platformDispatcher.defaultRouteNameTestValue = ApplicationRoutesConstants.settings;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final storedToken = Completer<String?>();
      final secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump(SessionCubit.defaultRestoreTimeLimit);
      await tester.pumpAndSettle();
      GoRouter router() => tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      expect(router().state.uri.toString(), '/login?returnUrl=%2Fsettings');

      storedToken.complete('MOCK_TOKEN');
      await tester.pumpAndSettle();

      expect(router().state.uri.toString(), ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('shows a loading indicator in place of the router until the stored language is read', (tester) async {
      final storedLanguage = Completer<Object?>();
      await tester.pumpWidget(
        App(language: 'en', dependencies: _LocalStorageDependencies(_HeldLanguageStorage(storedLanguage.future))),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      storedLanguage.complete('tr');
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Loading...'), findsNothing);
      expect(find.text('Şifremi unuttum'), findsOneWidget);
    });

    testWidgets('starts in the language that an earlier run stored', (tester) async {
      await AppLocalStorage().save(StorageKeys.language.key, 'tr');

      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('Şifremi unuttum'), findsOneWidget);
      expect(find.text('Forgot Password'), findsNothing);
    });

    // A guard rather than a reproduction: it passed before the stored language was read. It keeps the router mounting
    // when restore ends in the language the app already shows.
    testWidgets('starts in the configured language when no language is stored', (tester) async {
      await AppLocalStorage().remove(StorageKeys.language.key);

      await tester.pumpWidget(const App(language: 'tr'));
      await tester.pumpAndSettle();

      expect(find.text('Şifremi unuttum'), findsOneWidget);
      expect(find.text('Forgot Password'), findsNothing);
    });

    // The task switcher and the browser tab show this title.
    for (final (language, title) in [('en', 'Flutter BLoC Advance Template'), ('tr', 'Flutter BLoC Advance Şablonu')]) {
      testWidgets('names the app in the task switcher in the app language ($language)', (tester) async {
        await tester.pumpWidget(App(language: language));
        await tester.pumpAndSettle();

        expect(tester.widget<Title>(find.byType(Title)).title, title);
      });
    }

    // On web a second BroadcastChannel in the same tab would hear the tab's own ends, and a second lock object would
    // still share the lock, but the take-back and the refreshes of one tab must hear and use the same ones.
    testWidgets('creates one session end signal and one refresh lock per tab and hands them to the session and the '
        'HTTP client', (tester) async {
      final dependencies = _TabResourceDependencies();

      await tester.pumpWidget(App(language: 'en', dependencies: dependencies));
      await tester.pumpAndSettle();
      await tester.pumpWidget(App(language: 'en', dependencies: dependencies));
      await tester.pumpAndSettle();

      expect(dependencies.signals, hasLength(1));
      expect(dependencies.locks, hasLength(1));
      expect(dependencies.repositorySignals, [same(dependencies.signals.single)]);
      expect(dependencies.apiClientLocks, [same(dependencies.locks.single)]);
      expect(dependencies.apiClientTakeBacks.single, isNotNull);
    });

    testWidgets('releases the tab\'s session end signal and refresh lock when it is unmounted', (tester) async {
      final dependencies = _TabResourceDependencies();
      await tester.pumpWidget(App(language: 'en', dependencies: dependencies));
      await tester.pumpAndSettle();
      final signal = dependencies.signals.single as _SilentSessionEndSignal;
      final lock = dependencies.locks.single as _PassThroughLock;
      expect(signal.disposed, isFalse);

      await tester.pumpWidget(const SizedBox());

      expect(signal.disposed, isTrue, reason: 'an App mounted again would otherwise run a second wipe for one end');
      expect(lock.disposed, isTrue);
    });
  });

  // The gate sits in the MaterialApp builder, around the session restore and the router. These tests replace the
  // lifecycle repository; the last one reads the config the mock serves.
  group('App lifecycle gate', () {
    const maintenance = AppConfigEntity(maintenanceMode: true);
    const ready = AppConfigEntity(minimumVersion: '0.1.0');
    late MockILifecycleRepository repository;
    late MockISecureStorage secureStorage;

    setUp(() {
      repository = MockILifecycleRepository();
      secureStorage = MockISecureStorage();
      when(() => secureStorage.read(any())).thenAnswer((_) async => null);
    });

    Future<void> pumpApp(WidgetTester tester, {String language = 'en'}) async {
      await tester.pumpWidget(
        App(language: language, secureStorage: secureStorage, dependencies: _LifecycleDependencies(repository)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the maintenance screen in place of the app when the app config turns maintenance on', (
      tester,
    ) async {
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));

      await pumpApp(tester);

      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('shows the maintenance screen in place of the restore view while the stored session is read', (
      tester,
    ) async {
      final storedToken = Completer<String?>();
      when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));

      await tester.pumpWidget(
        App(language: 'en', secureStorage: secureStorage, dependencies: _LifecycleDependencies(repository)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Loading...'), findsNothing);

      storedToken.complete(null);
      await tester.pumpAndSettle();

      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('keeps the maintenance screen while the user retries, and opens the app once maintenance has ended', (
      tester,
    ) async {
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));
      await pumpApp(tester);
      final answer = Completer<Result<AppConfigEntity>>();
      when(() => repository.fetchAppConfig()).thenAnswer((_) => answer.future);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(tester.widget<AppButton>(find.byType(AppButton)).isLoading, isTrue);

      answer.complete(const Success(ready));
      await tester.pumpAndSettle();

      expect(find.byType(MaintenanceScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows the update screen in place of the app when the app is older than the app config allows', (
      tester,
    ) async {
      when(() => repository.fetchAppConfig()).thenAnswer(
        (_) async => const Success(AppConfigEntity(minimumVersion: '999.0.0', storeUrl: 'https://store.example/app')),
      );

      await pumpApp(tester);

      expect(find.byType(ForceUpdateScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // The gate screens sit above the router's Navigator, so the update button must work without one.
    testWidgets('tells the user when the store link on the update screen does not open', (tester) async {
      final calls = stubFailingUrlLauncher(UrlLauncherFailure.values.first);
      when(() => repository.fetchAppConfig()).thenAnswer(
        (_) async => const Success(AppConfigEntity(minimumVersion: '999.0.0', storeUrl: 'https://store.example/app')),
      );
      await pumpApp(tester);

      await expectTapShowsMessage(tester, find.byType(AppButton));
      expect(calls.requestedUrls, contains('https://store.example/app'));
    });

    testWidgets('opens the app and logs an error when the app config cannot be read', (tester) async {
      final errors = <String>[];
      void record(OutputEvent event) {
        if (event.level == Level.error) errors.addAll(event.lines);
      }

      Logger.addOutputListener(record);
      addTearDown(() => Logger.removeOutputListener(record));
      when(() => repository.fetchAppConfig())
          .thenAnswer((_) async => const Failure(NetworkError('Not found: no /app/config on this server')));

      await pumpApp(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(errors, contains(allOf(contains('LifecycleBloc : '), contains('no /app/config on this server'))));
    });

    testWidgets('checks the app config again when the app resumes after the recheck interval, and not before', (
      tester,
    ) async {
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(ready));
      await pumpApp(tester);
      verify(() => repository.fetchAppConfig()).called(1);

      await _sendToBackgroundAndBack(tester);

      verifyNever(() => repository.fetchAppConfig());
      expect(find.byType(LoginScreen), findsOneWidget);

      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));
      await tester.pump(LifecycleBloc.defaultRecheckInterval);
      await _sendToBackgroundAndBack(tester);

      verify(() => repository.fetchAppConfig()).called(1);
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // The gate replaces the router while the maintenance screen shows, so the router is mounted again afterwards.
    testWidgets('returns to the page the user was on when maintenance ends', (tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = ApplicationRoutesConstants.settings;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      when(() => secureStorage.read(any())).thenAnswer((_) async => 'MOCK_TOKEN');
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(ready));
      await pumpApp(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);

      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));
      await tester.pump(LifecycleBloc.defaultRecheckInterval);
      await _sendToBackgroundAndBack(tester);
      expect(find.byType(MaintenanceScreen), findsOneWidget);

      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(ready));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      GoRouter router() => tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(router().state.uri.toString(), ApplicationRoutesConstants.settings);
    });

    // The language change stores the user's language, which wins over App.language, so the test sets both.
    testWidgets('shows the maintenance screen in the app language', (tester) async {
      await AppLocalStorage().save(StorageKeys.language.key, 'tr');
      when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(maintenance));

      await pumpApp(tester, language: 'tr');

      expect(find.text('Bakım Yapılıyor'), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    // GET /app/config is a public endpoint, so the mock answers it before sign-in.
    testWidgets('reads the app config from the mock before sign-in', (tester) async {
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final lifecycle = tester.element(find.byType(LoginScreen)).read<LifecycleBloc>();
      expect(lifecycle.state, isA<LifecycleReady>().having((s) => s.config?.minimumVersion, 'minimumVersion', '0.1.0'));
    });
  });
}

/// The app's dependencies with [repository] in place of the lifecycle repository that AppDependencies creates.
class _LifecycleDependencies extends AppDependencies {
  const _LifecycleDependencies(this.repository);

  final ILifecycleRepository repository;

  @override
  ILifecycleRepository createLifecycleRepository(ApiClient apiClient) => repository;
}

/// Sends the app to the background and back, through every state Flutter reports on the way.
Future<void> _sendToBackgroundAndBack(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}
