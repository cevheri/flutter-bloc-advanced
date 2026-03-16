import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_widget.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils.dart';

void main() {
  //region setup
  setUp(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
    TestWidgetsFlutterBinding.instance.reset();
  });

  const language = "en";

  //endregion setup

  // main application unittest end-to-end
  group("HomeScreen Test Most critical APP UnitTest ***** ", () {
    testWidgets("Given valid AccessToken when open home then load ResponsiveScaffold successfully", (tester) async {
      // Use a wider surface to avoid overflow on the new dashboard header.
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TestUtils().setupAuthentication();

      // Given:
      await tester.pumpWidget(const App(language: language).buildHomeApp());
      //When:
      await tester.pumpAndSettle(const Duration(seconds: 5));
      //Then:

      // ResponsiveScaffold and shell layout test
      debugPrint("Shell layout Testing");
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
      expect(find.byType(TopBarWidget), findsOneWidget);
      expect(find.byType(SidebarWidget), findsOneWidget);
      debugPrint("Shell layout Tested");

      // Dashboard content should be rendered
      debugPrint("Dashboard content Testing");
      expect(find.text('Dashboard'), findsWidgets);
      debugPrint("Dashboard content Tested");

      // Sidebar has logout icon (collapsed sidebar hides labels)
      debugPrint("Sidebar Logout Icon Testing");
      expect(find.byIcon(Icons.logout), findsWidgets);
      debugPrint("Sidebar Logout Icon Tested");
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
}
