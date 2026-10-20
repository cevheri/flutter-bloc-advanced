@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_session_listeners.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

/// The app on the mock-backed development config, with the idle timeout turned on as production has it.
const _app = App(
  language: 'en',
  dependencies: AppDependencies(
    appConfig: AppConfig(
      environment: Environment.dev,
      apiBaseUrl: null,
      certificatePins: <String>[],
      idleTimeout: Duration(minutes: 5),
    ),
  ),
);

void main() {
  group('AppSessionListeners', () {
    testWidgets('an idle timeout clears the stored session, so a relaunch opens the login screen', (tester) async {
      TestEnv.authenticate();
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'MOCK_REFRESH_TOKEN');
      await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(find.byType(ResponsiveScaffold), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);

      // A relaunch mounts a new App, which restores the session from storage.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(find.byType(ResponsiveScaffold), findsNothing);
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await AppLocalStorage().read(StorageKeys.roles.key), isNull);
    });

    testWidgets('an idle timeout tells the user on the login screen why they were signed out', (tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(find.byType(ResponsiveScaffold), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();

      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(find.text('You were signed out due to inactivity.').hitTestable(), findsOneWidget);
    });

    testWidgets('raises an error instead of dropping the idle timeout notice when no ScaffoldMessenger is mounted', (
      tester,
    ) async {
      TestEnv.authenticate();
      // The notice is shown from a stream listener, so its error is uncaught in the zone that built the listener.
      final errors = <Object>[];
      await runZonedGuarded(
        () => tester.pumpWidget(
          AppScope(
            dependencies: _app.dependencies,
            child: AppSessionListeners(
              scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
              sharedActivity: null,
              child: const SizedBox(),
            ),
          ),
        ),
        (error, _) => errors.add(error),
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();

      expect(errors, [isA<StateError>()]);
    });

    // On web every browser tab shares the session, and AppDependencies gives the idle timeout the activity of all tabs.
    testWidgets('an idle timeout records and checks the activity of every tab in the store from AppDependencies', (
      tester,
    ) async {
      final store = _MemoryActivityStore();
      TestEnv.authenticate();
      await tester.pumpWidget(App(language: 'en', dependencies: _SharedActivityDependencies(store)));
      await tester.pumpAndSettle();
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
      expect(store.writes, hasLength(1));

      // IdleTimeoutObserver reads the wall clock, which the fake time of the test does not move, so the record is set
      // back by the threshold: no tab has seen activity for that long.
      store.lastActivity = DateTime.now().subtract(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();

      expect(store.reads, 1);
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
    });
  });
}

/// The dependencies of [_app], with [store] as the activity that the browser tabs share, as on web.
class _SharedActivityDependencies extends AppDependencies {
  _SharedActivityDependencies(this.store) : super(appConfig: _app.dependencies.appConfig);

  final ISharedActivityStore store;

  @override
  ISharedActivityStore? createSharedActivityStore() => store;
}

/// One activity record in memory, as window.localStorage holds it for every tab on web, that keeps the writes and
/// counts the reads.
class _MemoryActivityStore implements ISharedActivityStore {
  DateTime? lastActivity;
  final writes = <DateTime>[];
  var reads = 0;

  @override
  Future<DateTime?> readLastActivity() async {
    reads++;
    return lastActivity;
  }

  @override
  Future<void> writeLastActivity(DateTime time) async {
    writes.add(time);
    lastActivity = time;
  }
}
