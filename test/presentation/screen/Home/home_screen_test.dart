import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/home/home_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

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
  const darkTheme = AdaptiveThemeMode.dark;
  const lightTheme = AdaptiveThemeMode.light;

  //endregion setup

  // main application unittest end-to-end
  group("HomeScreen Test Most critical APP UnitTest ***** ", () {
    testWidgets("Given valid AccessToken and lightTheme when open homeScreen then load AppBar successfully", (tester) async {
      TestUtils().setupAuthentication();

      // Given:
      await tester.pumpWidget(App(language: language, initialTheme: lightTheme).buildHomeApp());
      //When:
      await tester.pumpAndSettle(const Duration(seconds: 5));
      //Then:

      // appBar test
      debugPrint("AppBar Testing");
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byType(DrawerButton), findsOneWidget);
      debugPrint("AppBar Tested");
      // tester.allWidgets.forEach((e) {
      //   print(e.toString());
      // });

      debugPrint("Menu finder Testing");
      // menu finder
      final drawerButtonFinder = find.byType(DrawerButton);
      await tester.tap(drawerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("drawerButton PumpAndSettle");

      debugPrint("Menu list Testing");
      // Menu Test
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(ThemeSwitchButton), findsOneWidget);
      expect(find.byType(LanguageSwitchButton), findsOneWidget);
      expect(find.text("Logout"), findsOneWidget);
      expect(find.text("Account"), findsOneWidget);
      expect(find.text("Settings"), findsOneWidget);
      debugPrint("Menu list Tested");

      // storage and cache test
      debugPrint("storage Testing");
      String? sLang = await AppLocalStorage().read(StorageKeys.language.name);
      String? username = await AppLocalStorage().read(StorageKeys.username.name);
      List<String>? authorities = await AppLocalStorage().read(StorageKeys.roles.name);
      expect(sLang, "en");
      expect(username, "admin");
      expect(authorities, ["ROLE_ADMIN", "ROLE_USER"]);
      debugPrint("storage tested");

      // language test
      final langFinder = find.byType(LanguageSwitchButton);
      await tester.tap(langFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // open menu
      await tester.tap(drawerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("drawerButton PumpAndSettle");

      await tester.tap(langFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint("language tested");
      /////////////////////////////////////////////////////////

      // open menu
      await tester.tap(drawerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("drawerButton PumpAndSettle");

      //theme test
      final themeFinder = find.byType(ThemeSwitchButton);
      await tester.tap(themeFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("ThemeSwitchButton PumpAndSettle");

      // open menu
      await tester.tap(drawerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("drawerButton PumpAndSettle");

      // logout test alert button No
      final logoutFinder = find.byKey(drawerButtonLogout);
      await tester.tap(logoutFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final noButtonFinder = find.byKey(drawerButtonLogoutNo);
      await tester.tap(noButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Drawer), findsOneWidget);
      debugPrint("LogoutButton No PumpAndSettle");

      // logout test alert button yes
      await tester.tap(logoutFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final yesButtonFinder = find.byKey(drawerButtonLogoutYes);
      await tester.tap(yesButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint("LogoutButton YES PumpAndSettle");

      // tester.allWidgets.forEach((e) {
      //   print(e.toString());
      // });

      // clear storage test
      sLang = await AppLocalStorage().read(StorageKeys.language.name);
      username = await AppLocalStorage().read(StorageKeys.username.name);
      authorities = await AppLocalStorage().read(StorageKeys.roles.name);
      expect(sLang, null);
      expect(username, null);
      expect(authorities, null);

      // dispose test
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets("Given an invalid AccessToken when HomeScreen is opened then navigate to loginScreen", (tester) async {
      AdaptiveTheme getWidget({AdaptiveThemeMode mode = AdaptiveThemeMode.dark}) => App(language: language, initialTheme: mode).buildHomeApp();

      // Given:
      await tester.pumpWidget(getWidget(mode: darkTheme));
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(skip: true, "Given valid token when open Drawer menu then open successfully", (tester) async {});

    // Validate theme

    // home page image validation

  });
}
