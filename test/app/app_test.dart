@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_migration.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/startup_storage_time_limit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_classes.dart';

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
  });
}
