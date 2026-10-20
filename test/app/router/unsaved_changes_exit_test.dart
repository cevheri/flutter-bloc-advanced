@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_nav_item.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_env.dart';

/// The app on the mock-backed development config, with the idle timeout production has.
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

/// Boots the app on a desktop window, signed in when [signedIn], and records what the router reports to the
/// browser history.
Future<List<MethodCall>> _pumpApp(WidgetTester tester, {bool signedIn = true}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1600, 1600);
  tester.view.devicePixelRatio = 1.0;
  final history = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, (call) async {
    history.add(call);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.navigation, null));
  if (signedIn) {
    TestEnv.authenticate();
    await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
  }
  await tester.pumpWidget(_app);
  await tester.pumpAndSettle();
  return history;
}

GoRouter _router(WidgetTester tester) => tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

/// The URL the router last wrote to the browser history.
String _lastReportedUrl(List<MethodCall> history) =>
    (history.lastWhere((call) => call.method == 'routeInformationUpdated').arguments as Map)['uri'] as String;

/// What a browser back or forward button does: the engine reports the location and state of the history entry the
/// browser moved to.
Future<void> _browserMovesTo(WidgetTester tester, List<MethodCall> history, String location) async {
  final entry = history.lastWhere(
    (call) => call.method == 'routeInformationUpdated' && (call.arguments as Map)['uri'] == location,
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      MethodCall('pushRouteInformation', <String, Object?>{
        'location': location,
        'state': (entry.arguments as Map)['state'],
      }),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// What the Android back button does: the engine asks the framework to pop a route.
Future<void> _androidBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// The page in [page] holds the system back and the iOS back swipe, so they reach the route's onExit.
void _expectBackHeld(WidgetTester tester, Finder page) {
  expect(ModalRoute.of(tester.element(page))!.popDisposition, RoutePopDisposition.doNotPop);
}

Finder get _unsavedChangesDialog => find.text(S.current.unsaved_changes);

Future<void> _answer(WidgetTester tester, {required bool leave}) async {
  await tester.tap(find.text(leave ? S.current.yes : S.current.no));
  await tester.pumpAndSettle();
}

Future<void> _openDirtyAccountForm(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(SidebarNavItem, 'Account'));
  await tester.pumpAndSettle();
  expect(find.byType(AccountScreen), findsOneWidget);
  await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Changed');
  await tester.pumpAndSettle();
}

void main() {
  group('A dirty account form', () {
    testWidgets('asks before the browser back button leaves it', (tester) async {
      final history = await _pumpApp(tester);
      await _openDirtyAccountForm(tester);

      await _browserMovesTo(tester, history, ApplicationRoutesConstants.home);
      expect(_unsavedChangesDialog, findsOneWidget);

      await _answer(tester, leave: false);
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Changed'), findsOneWidget);
      expect(_lastReportedUrl(history), ApplicationRoutesConstants.account);

      await _browserMovesTo(tester, history, ApplicationRoutesConstants.home);
      await _answer(tester, leave: true);
      expect(find.byType(AccountScreen), findsNothing);
      expect(_router(tester).state.uri.path, ApplicationRoutesConstants.home);
    });

    testWidgets('asks before the sidebar leaves it, and keeps the sidebar on the page when the user stays', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _openDirtyAccountForm(tester);

      await tester.tap(find.widgetWithText(SidebarNavItem, 'Settings'));
      await tester.pumpAndSettle();
      expect(_unsavedChangesDialog, findsOneWidget);

      await _answer(tester, leave: false);
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(tester.element(find.byType(AccountScreen)).read<SidebarBloc>().state.activeRoute, '/account');

      await tester.tap(find.widgetWithText(SidebarNavItem, 'Settings'));
      await tester.pumpAndSettle();
      await _answer(tester, leave: true);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('asks before the Android back button leaves it', (tester) async {
      await _pumpApp(tester);
      await _openDirtyAccountForm(tester);
      _expectBackHeld(tester, find.byType(AccountScreen));

      await _androidBack(tester);
      expect(_unsavedChangesDialog, findsOneWidget);

      await _answer(tester, leave: false);
      expect(find.byType(AccountScreen), findsOneWidget);

      // Leaving goes where the page's own back button goes: the dashboard, as the page is the shell's only page.
      await _androidBack(tester);
      await _answer(tester, leave: true);
      expect(find.byType(AccountScreen), findsNothing);
      expect(_router(tester).state.uri.path, ApplicationRoutesConstants.home);
    });

    testWidgets('asks once when its own back button leaves it', (tester) async {
      await _pumpApp(tester);
      await _openDirtyAccountForm(tester);

      await tester.tap(find.byKey(const Key('accountScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();
      expect(_unsavedChangesDialog, findsOneWidget);

      await _answer(tester, leave: true);
      expect(_unsavedChangesDialog, findsNothing);
      expect(find.byType(AccountScreen), findsNothing);
    });

    testWidgets('does not hold up signing out', (tester) async {
      await _pumpApp(tester);
      await _openDirtyAccountForm(tester);

      await tester.tap(find.widgetWithText(SidebarNavItem, S.current.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.yes));
      await tester.pumpAndSettle();

      expect(_unsavedChangesDialog, findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('does not hold up a session the server ends', (tester) async {
      await _pumpApp(tester);
      await _openDirtyAccountForm(tester);

      await tester
          .element(find.byType(AccountScreen))
          .read<SessionCubit>()
          .endSession(reason: SessionExpiredReason.expired);
      await tester.pumpAndSettle();

      expect(_unsavedChangesDialog, findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('gives way to an idle timeout while the unsaved-changes dialog is open', (tester) async {
      final history = await _pumpApp(tester);
      await _openDirtyAccountForm(tester);
      await _browserMovesTo(tester, history, ApplicationRoutesConstants.home);
      expect(_unsavedChangesDialog, findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();

      expect(_unsavedChangesDialog, findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ResponsiveScaffold), findsNothing);
    });
  });

  group('A clean account form', () {
    testWidgets('leaves through the sidebar without asking', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.widgetWithText(SidebarNavItem, 'Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SidebarNavItem, 'Settings'));
      await tester.pumpAndSettle();

      expect(_unsavedChangesDialog, findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  testWidgets('every route of a page with an unsaved-changes scope asks before it is left', (tester) async {
    await _pumpApp(tester);
    final routes = <String, GoRoute>{};
    void collect(List<RouteBase> list) {
      for (final route in list) {
        if (route is GoRoute) routes[route.path] = route;
        collect(route.routes);
      }
    }

    collect(_router(tester).configuration.routes);
    for (final path in [ApplicationRoutesConstants.account]) {
      expect(routes[path]?.onExit, confirmLeavingUnsavedChanges, reason: path);
    }
  });
}
