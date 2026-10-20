@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/test_env.dart';
import '../../../../support/url_launcher_stub.dart';

const _docs = 'https://docs.acme.example';

void main() {
  // The build gives the documentation website [docs].
  Widget buildTestableWidget({String docs = _docs}) {
    final router = GoRouter(
      initialLocation: ApplicationRoutesConstants.settings,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.settings,
          builder: (context, state) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: ApplicationRoutesConstants.changePassword,
          builder: (context, state) => const Scaffold(body: Placeholder()),
        ),
      ],
    );

    return RepositoryProvider<ProjectLinks>.value(
      value: ProjectLinks(docs: docs),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }

  // The real app, signed in, on settings. The shell shows the account name in the top bar once the mock API answers
  // after its 500 ms delay, so let that land before the screen is compared. The build gives the documentation website
  // [docs].
  Future<void> pumpAppOnSettings(WidgetTester tester, {String docs = _docs}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();

    await tester.pumpWidget(
      App(
        language: 'en',
        dependencies: AppDependencies(projectLinks: ProjectLinks(docs: docs)),
      ),
    );
    await tester.pump();
    (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter).go(
      ApplicationRoutesConstants.settings,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all settings tiles', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Assert via Keys only — text-based asserts would couple the
      // test to the active locale (some titles use S.of(context) /
      // generated strings, others are still literals pending i18n).
      // Key presence is enough to guard the screen layout against
      // accidental tile removal.
      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsOneWidget);
      // Logout intentionally lives only in the sidebar / topbar shell —
      // settings does not own auth-session lifecycle (cross-feature).
    });

    // A made-up key: replacing the template's real placeholders across a project leaves this test as it is.
    testWidgets('shows no Help & Resources section while the docs URL is a placeholder', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget(docs: '__DOCS__'));
      await tester.pumpAndSettle();

      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsNothing);
      expect(find.text('Help & Resources'), findsNothing);
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      // Assert we navigated TO the change-password route (its content renders),
      // not merely that the settings screen disappeared.
      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });
  });

  group('SettingsScreen - website link that does not open', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tapping Website shows a message when ${failure.description}', (WidgetTester tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpAppOnSettings(tester);

        await expectTapShowsMessage(tester, find.byKey(settingsWebsiteButtonKey));
        expect(calls.requestedUrls, contains(_docs));
      });
    }
  });

  group('SettingsScreen - website link that opens', () {
    for (final canLaunch in [true, false]) {
      testWidgets('tapping Website opens it and shows no message when canLaunchUrl answers $canLaunch', (
        WidgetTester tester,
      ) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpAppOnSettings(tester);

        await expectTapShowsNoMessage(tester, find.byKey(settingsWebsiteButtonKey));
        expect(calls.launchedUrls, [_docs]);
      });
    }
  });
}
