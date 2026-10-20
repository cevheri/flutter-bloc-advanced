@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/test_env.dart';
import '../../../support/url_launcher_stub.dart';

const _docs = 'https://docs.acme.example';

void main() {
  // The real app, signed in, on settings: the sidebar is the same on every shell page and settings has no loading
  // animation. The shell shows the account name in the top bar once the mock API answers after its 500 ms delay, so
  // let that land before the screen is compared. The build gives the documentation website [docs].
  Future<void> pumpAppOnSettings(WidgetTester tester, {Size size = const Size(1600, 1600), String docs = _docs}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
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

  group('SidebarWidget - website link that does not open', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tapping Website shows a message when ${failure.description}', (tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpAppOnSettings(tester);

        await expectTapShowsMessage(tester, find.byKey(sidebarWebsiteButtonKey));
        expect(calls.requestedUrls, contains(_docs));
      });
    }
  });

  // On a phone the sidebar sits in the shell's drawer, which covers the snack bar that reports the failure.
  group('SidebarWidget - website link in the phone drawer', () {
    testWidgets('closes the drawer so the user sees that the link did not open', (tester) async {
      stubFailingUrlLauncher(UrlLauncherFailure.values.first);
      await pumpAppOnSettings(tester, size: const Size(390, 844));
      tester.state<ScaffoldState>(find.byWidgetPredicate((w) => w is Scaffold && w.drawer != null)).openDrawer();
      await tester.pumpAndSettle();

      await expectTapShowsMessage(tester, find.byKey(sidebarWebsiteButtonKey));
    });
  });

  group('SidebarWidget - website link that opens', () {
    for (final canLaunch in [true, false]) {
      testWidgets('tapping Website opens it and shows no message when canLaunchUrl answers $canLaunch', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpAppOnSettings(tester);

        await expectTapShowsNoMessage(tester, find.byKey(sidebarWebsiteButtonKey));
        expect(calls.launchedUrls, [_docs]);
      });
    }
  });

  group('SidebarWidget - project without a documentation website', () {
    // A made-up key: replacing the template's real placeholders across a project leaves this test as it is.
    testWidgets('shows no Website link while the docs URL is a placeholder', (tester) async {
      await pumpAppOnSettings(tester, docs: '__DOCS__');

      expect(find.byKey(sidebarWebsiteButtonKey), findsNothing);
      expect(find.text('Website'), findsNothing);
    });
  });
}
