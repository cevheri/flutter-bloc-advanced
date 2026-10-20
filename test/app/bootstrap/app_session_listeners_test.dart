@Tags(['widget'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/bootstrap/app_session_listeners.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_nav_item.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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

/// Stores the language, theme and sidebar state a user chose on this device earlier.
Future<void> _choosePreferences() async {
  await AppLocalStorage().save(StorageKeys.language.key, 'tr');
  await AppLocalStorage().save(StorageKeys.theme.key, 'nature');
  await AppLocalStorage().save(StorageKeys.brightness.key, 'dark');
  await AppLocalStorage().save(StorageKeys.sidebarCollapsed.key, 'true');
}

/// Signs out as the user does: Logout in the sidebar, then Yes in the confirmation dialog, in whichever language the
/// app shows.
Future<void> _logOut(WidgetTester tester) async {
  await tester.tap(find.widgetWithIcon(SidebarNavItem, Icons.logout));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
  await tester.pumpAndSettle();
}

/// Leaves the app alone until the idle timeout signs the user out, and until its notice has gone.
Future<void> _idle(WidgetTester tester) async {
  await tester.pump(const Duration(minutes: 5));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// The ways a session ends while the app keeps running for the next user of the device.
const _sessionEndings = <String, Future<void> Function(WidgetTester)>{'a logout': _logOut, 'an idle timeout': _idle};

/// Signs in through the login form. The mock API accepts any username and password.
Future<void> _signIn(WidgetTester tester, String username) async {
  await tester.enterText(find.byKey(loginTextFieldUsernameKey), username);
  await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'password');
  await tester.tap(find.byKey(loginButtonSubmitKey));
  await tester.pumpAndSettle();
}

/// From now on the mock API answers GET /account with [account] instead of assets/mock/GET_account.json, as it
/// would for another user. Every other platform message still reaches the handler flutter_test registered for it.
void _answerAccountWith(WidgetTester tester, Map<String, Object> account) {
  const asset = 'assets/mock/GET_account.json';
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.allMessagesHandler = (channel, handler, message) {
    if (channel == 'flutter/assets' && utf8.decode(Uint8List.sublistView(message!)) == asset) {
      return Future.value(ByteData.sublistView(utf8.encode(jsonEncode(account))));
    }
    return handler != null ? handler(message) : messenger.delegate.send(channel, message);
  };
  addTearDown(() => messenger.allMessagesHandler = null);
  rootBundle.evict(asset);
}

/// Opens [location] as a link does, then waits for the mock API, which answers after 500 ms.
Future<void> _open(WidgetTester tester, String location) async {
  (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter).go(location);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// [text] in the top bar, which shows the first name of the signed-in account on every page.
Finder _inTopBar(String text) => find.descendant(of: find.byType(TopBarWidget), matching: find.text(text));

/// An account other than the Admin User of assets/mock/GET_account.json.
const _secondAccount = <String, Object>{
  'id': 'user-2',
  'login': 'second',
  'email': 'second@sample.tech',
  'firstName': 'Second',
  'lastName': 'Person',
  'activated': true,
  'langKey': 'en',
  'authorities': ['ROLE_USER'],
};

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
            defaultLocale: const Locale('en'),
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

    testWidgets('an idle timeout keeps the preferences and removes the cached responses', (tester) async {
      TestEnv.authenticate();
      await _choosePreferences();
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(await SharedPrefsCacheStorage().count(), isPositive, reason: 'the dashboard caches its account request');

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);

      expect(await AppLocalStorage().read(StorageKeys.language.key), 'tr');
      expect(await AppLocalStorage().read(StorageKeys.theme.key), 'nature');
      expect(await AppLocalStorage().read(StorageKeys.brightness.key), 'dark');
      expect(await AppLocalStorage().read(StorageKeys.sidebarCollapsed.key), 'true');
      expect(await SharedPrefsCacheStorage().count(), 0);
    });

    testWidgets('a logout keeps the preferences and removes the cached responses', (tester) async {
      TestEnv.authenticate();
      await _choosePreferences();
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(await SharedPrefsCacheStorage().count(), isPositive, reason: 'the dashboard caches its account request');

      await _logOut(tester);
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);

      expect(await AppLocalStorage().read(StorageKeys.language.key), 'tr');
      expect(await AppLocalStorage().read(StorageKeys.theme.key), 'nature');
      expect(await AppLocalStorage().read(StorageKeys.brightness.key), 'dark');
      expect(await AppLocalStorage().read(StorageKeys.sidebarCollapsed.key), 'true');
      expect(await SharedPrefsCacheStorage().count(), 0);

      // A relaunch mounts a new App, which loads the theme and the sidebar state from storage.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
      expect(tester.element(find.byType(MaterialApp)).read<SidebarBloc>().state.isCollapsed, isTrue);
    });

    testWidgets('a logout that cannot remove all stored data still signs out and tells the user', (tester) async {
      SharedPreferencesStorePlatform.instance = _CacheKeepingStore();
      TestEnv.authenticate();
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(await SharedPrefsCacheStorage().count(), isPositive, reason: 'the dashboard caches its account request');

      await _logOut(tester);

      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(
        find.text('You were signed out, but some stored data could not be removed from this device.').hitTestable(),
        findsOneWidget,
      );
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.jwtToken.key), isNull);
    });

    for (final MapEntry(key: ending, value: endSession) in _sessionEndings.entries) {
      for (final (page, location) in [
        ('the dashboard', ApplicationRoutesConstants.home),
        ('the account page', ApplicationRoutesConstants.account),
      ]) {
        testWidgets('after $ending on $page, the next user to sign in sees their own account', (tester) async {
          await tester.pumpWidget(_app);
          await tester.pumpAndSettle();
          await _signIn(tester, 'admin');
          await _open(tester, location);
          expect(_inTopBar('Admin'), findsOneWidget);
          final account = tester.element(find.byType(ResponsiveScaffold)).read<AccountBloc>();

          await endSession(tester);
          expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
          // Forgotten, and not requested again without a token.
          expect(account.state, const AccountState());
          _answerAccountWith(tester, _secondAccount);
          // An idle timeout returns the next user to the page where it struck.
          await _signIn(tester, 'second');
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();

          expect(_inTopBar('Second'), findsOneWidget);
          expect(find.text('Admin'), findsNothing);
        });
      }

      testWidgets('after $ending, the next user types their password hidden', (tester) async {
        await tester.pumpWidget(_app);
        await tester.pumpAndSettle();
        // The first user shows the password while typing it.
        await tester.tap(find.byKey(loginButtonPasswordVisibilityKey));
        await tester.pump();
        await _signIn(tester, 'admin');

        await endSession(tester);

        final password = find.descendant(of: find.byKey(loginTextFieldPasswordKey), matching: find.byType(TextField));
        expect(tester.widget<TextField>(password).obscureText, isTrue);
      });

      testWidgets('after $ending, the app forgets the authorities it loaded with the previous user rights', (
        tester,
      ) async {
        // A desktop window, where the user list shows its role filter.
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(_app);
        await tester.pumpAndSettle();
        await _signIn(tester, 'admin');
        // The role filter of the user list loads the authorities into the app-scoped AuthorityBloc.
        await _open(tester, ApplicationRoutesConstants.userList);
        final authorities = tester.element(find.byType(ResponsiveScaffold)).read<AuthorityBloc>();
        expect(authorities.state, isA<AuthorityLoadSuccessState>());

        await endSession(tester);

        expect(authorities.state, const AuthorityInitialState());
      });
    }
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

/// A SharedPreferences platform store that keeps the cached responses when asked to remove them, as a full or
/// read-only disk does.
class _CacheKeepingStore extends InMemorySharedPreferencesStore {
  _CacheKeepingStore() : super.empty();

  @override
  Future<bool> remove(String key) async => key.startsWith('flutter._cache_') ? false : super.remove(key);
}
