@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

void main() {
  //region setup
  tearDown(() async {
    TestWidgetsFlutterBinding.instance.reset();
  });

  const language = "en";

  //endregion setup

  // main application unittest end-to-end
  group("HomeScreen Test Most critical APP UnitTest ***** ", () {
    testWidgets("Given valid AccessToken when open home then load ResponsiveScaffold successfully", (tester) async {
      // A desktop surface, where the shell shows the sidebar next to the content.
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TestEnv.authenticate();

      // Given:
      await tester.pumpWidget(const App(language: language).buildHomeApp());
      //When:
      await tester.pumpAndSettle();
      //Then:

      // ResponsiveScaffold and shell layout test
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
      expect(find.byType(TopBarWidget), findsOneWidget);
      expect(find.byType(SidebarWidget), findsOneWidget);

      // Dashboard content should be rendered
      expect(find.text('Dashboard'), findsWidgets);

      // Sidebar has logout icon (collapsed sidebar hides labels)
      expect(find.byIcon(Icons.logout), findsWidgets);
    });

    testWidgets("Given an invalid AccessToken when HomeScreen is opened then navigate to loginScreen", (tester) async {
      Widget getWidget() => const App(language: "en").buildHomeApp();

      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(ResponsiveScaffold), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('HomeScreen dashboard layout', () {
    // Surfaces where the dashboard overflowed right after login: four KPI columns on a wide screen, and the section
    // titles on a phone. The test font is wider than the real one, which stands in for a larger text scale.
    for (final size in const [
      Size(1366, 768),
      Size(1400, 900),
      Size(1440, 900),
      Size(1366, 1024),
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
    ]) {
      testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        TestEnv.authenticate();

        await tester.pumpWidget(const App(language: language).buildHomeApp());
        await tester.pumpAndSettle();

        expect(find.text('Circuit Breaker'), findsOneWidget, reason: 'the loaded dashboard shows its KPI cards');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
