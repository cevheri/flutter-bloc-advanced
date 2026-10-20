@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';

/// The browser's session history, as the Flutter engine keeps it on the web. It records the entries the router reports
/// through `SystemNavigator.routeInformationUpdated`, and the back and forward buttons replay an entry the way the
/// engine does on a popstate event: as a `pushRouteInformation` message on the `flutter/navigation` channel.
class _FakeBrowserHistory {
  _FakeBrowserHistory(this._tester) {
    _messenger.setMockMethodCallHandler(SystemChannels.navigation, _onNavigationCall);
    addTearDown(() => _messenger.setMockMethodCallHandler(SystemChannels.navigation, null));
  }

  final WidgetTester _tester;
  final _entries = <Map<String, Object?>>[];
  int _current = -1;

  TestDefaultBinaryMessenger get _messenger => _tester.binding.defaultBinaryMessenger;

  /// The URLs in the history, oldest first.
  List<String> get locations => [for (final entry in _entries) entry['location']! as String];

  /// The URL in the address bar.
  String get location => locations[_current];

  Future<Object?> _onNavigationCall(MethodCall call) async {
    if (call.method != 'routeInformationUpdated') return null;
    final arguments = call.arguments as Map<Object?, Object?>;
    final entry = <String, Object?>{'location': arguments['uri'], 'state': arguments['state']};
    if (arguments['replace'] == true && _current >= 0) {
      _entries[_current] = entry;
    } else {
      _entries
        ..removeRange(_current + 1, _entries.length)
        ..add(entry);
      _current = _entries.length - 1;
    }
    return null;
  }

  Future<void> back() => _goTo(_current - 1);

  Future<void> forward() => _goTo(_current + 1);

  Future<void> _goTo(int index) async {
    _current = index;
    final message = const JSONMethodCodec().encodeMethodCall(MethodCall('pushRouteInformation', _entries[index]));
    await _messenger.handlePlatformMessage(SystemChannels.navigation.name, message, (_) {});
    await _tester.pumpAndSettle();
  }
}

void main() {
  void setDesktopViewport(WidgetTester tester) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  GoRouter routerFromApp(WidgetTester tester) {
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    return materialApp.routerConfig! as GoRouter;
  }

  // A deep link, a bookmarked URL or a browser refresh starts the app on this location: GoRouter prefers the
  // platform's default route over its initialLocation.
  void startOn(WidgetTester tester, String location) {
    tester.platformDispatcher.defaultRouteNameTestValue = location;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
  }

  // The platform pushes a route the way iOS delivers a universal link or a custom scheme link: after the first frame,
  // also for the link that opened the app.
  Future<void> pushRouteFromPlatform(WidgetTester tester, String location) async {
    final message = SystemChannels.navigation.codec.encodeMethodCall(
      MethodCall('pushRouteInformation', <String, Object?>{'location': location, 'state': null}),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(SystemChannels.navigation.name, message, (_) {});
  }

  // Secure storage that answers the stored session read only when the returned completer completes.
  Completer<String?> storedTokenPending(MockISecureStorage secureStorage) {
    final storedToken = Completer<String?>();
    when(() => secureStorage.read(any())).thenAnswer((_) => storedToken.future);
    return storedToken;
  }

  // Pumps the authenticated shell frame by frame and returns the frames that built the login page, offstage ones
  // included. A fixed number of frames, instead of pumpAndSettle, so every frame is inspected.
  Future<List<int>> pumpShellRecordingLogin(WidgetTester tester) async {
    final loginFrames = <int>[];
    for (var frame = 0; frame < 30; frame++) {
      if (find.byType(LoginScreen, skipOffstage: false).evaluate().isNotEmpty) loginFrames.add(frame);
      await tester.pump(const Duration(milliseconds: 100));
    }
    return loginFrames;
  }

  group('AppRouterFactory', () {
    testWidgets('redirects unauthenticated users to login', (tester) async {
      setDesktopViewport(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final router = routerFromApp(tester);
      router.go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('allows authenticated users to open settings', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final router = routerFromApp(tester);
      router.go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('sends an authenticated user on the login page home when its returnUrl leaves the app', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      final returnUrl = Uri.encodeQueryComponent('https://evil.example/settings');
      routerFromApp(tester).go('${ApplicationRoutesConstants.login}?returnUrl=$returnUrl');
      await tester.pumpAndSettle();

      expect(routerFromApp(tester).state.uri.toString(), ApplicationRoutesConstants.home);
    });

    testWidgets('never builds the login page on an authenticated cold start', (tester) async {
      setDesktopViewport(tester);
      TestEnv.authenticate();
      final analytics = MockAnalyticsService();
      await tester.pumpWidget(App(language: 'en', analytics: analytics));
      final loginFrames = await pumpShellRecordingLogin(tester);

      expect(loginFrames, isEmpty, reason: 'frames that built the login page');
      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(find.byType(DashboardHomePage), findsOneWidget);
      verifyNever(
        () => analytics.logScreenView(
          screenName: any(named: 'screenName', that: equals('login')),
          screenClass: any(named: 'screenClass'),
        ),
      );
    });

    testWidgets('opens a deep link on an authenticated cold start', (tester) async {
      setDesktopViewport(tester);
      startOn(tester, ApplicationRoutesConstants.settings);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      final loginFrames = await pumpShellRecordingLogin(tester);

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(loginFrames, isEmpty, reason: 'frames that built the login page');
    });

    testWidgets('keeps a deep link as the login returnUrl on an unauthenticated cold start', (tester) async {
      setDesktopViewport(tester);
      startOn(tester, ApplicationRoutesConstants.settings);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(routerFromApp(tester).state.uri.queryParameters['returnUrl'], ApplicationRoutesConstants.settings);
    });

    testWidgets('opens a route the platform pushes while the stored session is restored', (tester) async {
      setDesktopViewport(tester);
      final secureStorage = MockISecureStorage();
      final storedToken = storedTokenPending(secureStorage);
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump();

      await pushRouteFromPlatform(tester, ApplicationRoutesConstants.settings);
      storedToken.complete('MOCK_TOKEN');
      await tester.pumpAndSettle();

      expect(routerFromApp(tester).state.uri.toString(), ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('keeps a route the platform pushes while the stored session is restored as the login returnUrl', (
      tester,
    ) async {
      setDesktopViewport(tester);
      final secureStorage = MockISecureStorage();
      final storedToken = storedTokenPending(secureStorage);
      await tester.pumpWidget(App(language: 'en', secureStorage: secureStorage));
      await tester.pump();

      await pushRouteFromPlatform(tester, ApplicationRoutesConstants.settings);
      storedToken.complete(null);
      await tester.pumpAndSettle();

      expect(routerFromApp(tester).state.uri.toString(), '/login?returnUrl=%2Fsettings');
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // On the web each navigation adds an entry to the browser's history, and the back and forward buttons bring one back.
  // These guard what the router and its redirect do with such an entry. They cannot see a script in web/index.html
  // that blocks the buttons, because flutter test never loads that file: test/architecture/web_history_test.dart does.
  group('AppRouterFactory - browser back and forward', () {
    testWidgets('back after going from / to /settings shows the dashboard, and forward shows settings again', (
      tester,
    ) async {
      setDesktopViewport(tester);
      final browser = _FakeBrowserHistory(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();
      routerFromApp(tester).go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();
      expect(browser.locations, [ApplicationRoutesConstants.home, ApplicationRoutesConstants.settings]);

      await browser.back();

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(find.byType(DashboardHomePage), findsOneWidget);
      expect(browser.location, ApplicationRoutesConstants.home);

      await browser.forward();

      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(browser.location, ApplicationRoutesConstants.settings);
    });

    testWidgets('back after logout to the page the user signed out from opens the login page instead', (tester) async {
      setDesktopViewport(tester);
      final browser = _FakeBrowserHistory(tester);
      TestEnv.authenticate();
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();
      routerFromApp(tester).go(ApplicationRoutesConstants.settings);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(SidebarWidget), matching: find.text('Logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Yes'));
      await tester.pumpAndSettle();
      expect(browser.locations, [
        ApplicationRoutesConstants.home,
        ApplicationRoutesConstants.settings,
        ApplicationRoutesConstants.login,
      ]);

      await browser.back();

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.login);
      expect(Uri.parse(browser.location).path, ApplicationRoutesConstants.login);
    });

    testWidgets('back after signing in does not show the login page again', (tester) async {
      setDesktopViewport(tester);
      final browser = _FakeBrowserHistory(tester);
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'admin');
      await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'admin');
      await tester.tap(find.byKey(loginButtonSubmitKey));
      await tester.pumpAndSettle();
      expect(browser.locations, [ApplicationRoutesConstants.login, ApplicationRoutesConstants.home]);

      await browser.back();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(DashboardHomePage), findsOneWidget);
      expect(routerFromApp(tester).state.uri.path, ApplicationRoutesConstants.home);
      expect(browser.location, ApplicationRoutesConstants.home);
    });
  });
}
