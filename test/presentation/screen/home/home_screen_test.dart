import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/main/app.dart';
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

  //endregion setup

  // main application unittest end-to-end
  group("HomeScreen Test Most critical APP UnitTest ***** ", () {
    testWidgets("Given valid AccessToken and lightTheme when open homeScreen then load AppBar successfully", (
      tester,
    ) async {
      TestUtils().setupAuthentication();

      // Given:
      await tester.pumpWidget(const App(language: language).buildHomeApp());
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
      expect(find.byKey(const Key("drawer-switch-theme")), findsOneWidget);
      expect(find.byKey(const Key("drawer-switch-language")), findsOneWidget);
      expect(find.text("Logout"), findsOneWidget);
      //expect(find.text("Account"), findsOneWidget);
      //expect(find.text("Settings"), findsOneWidget);
      debugPrint("Menu list Tested");

      // storage and cache test
      // debugPrint("storage Testing");
      // String? sLang = await AppLocalStorage().read(StorageKeys.language.name);
      // String? username = await AppLocalStorage().read(StorageKeys.username.name);
      // List<String>? authorities = await AppLocalStorage().read(StorageKeys.roles.name);
      // expect(sLang, "en");
      // expect(username, "admin");
      // expect(authorities, ["ROLE_ADMIN", "ROLE_USER"]);
      // debugPrint("storage tested");

      // language test
      // debugPrint("language Testing");
      // final langFinder = find.byKey(const Key("drawer-switch-language"));
      // debugPrint("language Testing - langFinder");
      // await tester.tap(langFinder);
      // debugPrint("language Testing - tap");
      // await tester.pumpAndSettle(const Duration(seconds: 5));
      // debugPrint("language Testing - pumpAndSettle");
      // open menu

      // await tester.tap(drawerButtonFinder);
      // debugPrint("language Testing - drawerButtonFinder");
      // await tester.pumpAndSettle(const Duration(seconds: 5));
      // debugPrint("language Testing -drawerButton PumpAndSettle");

      // await tester.tap(langFinder);
      // debugPrint("language Testing - tap");
      // await tester.pumpAndSettle(const Duration(seconds: 5));
      // debugPrint("language tested");
      /////////////////////////////////////////////////////////

      // open menu

      // debugPrint("drawerButton finding");
      // await tester.tap(drawerButtonFinder);
      // await tester.pumpAndSettle(const Duration(seconds: 5));
      // debugPrint("drawerButton PumpAndSettle");

      //theme test
      final themeFinder = find.byKey(const Key("drawer-switch-theme"));
      await tester.tap(themeFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("ThemeSwitchButton PumpAndSettle");

      // open menu
      await tester.tap(drawerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      debugPrint("drawerButton PumpAndSettle 5");

      // logout test alert button No
      debugPrint("LogoutButton No Testing");
      final logoutFinder = find.byKey(drawerButtonLogoutKey);
      debugPrint("LogoutButton drawerButtonLogoutKey Finder");
      await tester.tap(logoutFinder);
      debugPrint("LogoutButton No Tap");
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // final noButtonFinder = find.byKey(drawerButtonLogoutNoKey);
      debugPrint("LogoutButton No Finder");
      //await tester.tap(noButtonFinder);
      debugPrint("LogoutButton No Tap");
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Drawer), findsOneWidget);
      debugPrint("LogoutButton No PumpAndSettle");

      // logout test alert button yes
      // await tester.tap(logoutFinder);
      // await tester.pumpAndSettle(const Duration(seconds: 5));
      // final yesButtonFinder = find.byKey(drawerButtonLogoutYesKey);
      // await tester.tap(yesButtonFinder);
      // await tester.pumpAndSettle(const Duration(seconds: 5));

      debugPrint("LogoutButton YES PumpAndSettle");

      // tester.allWidgets.forEach((e) {
      //   print(e.toString());
      // });

      // clear storage test
      // sLang = await AppLocalStorage().read(StorageKeys.language.name);
      // username = await AppLocalStorage().read(StorageKeys.username.name);
      // authorities = await AppLocalStorage().read(StorageKeys.roles.name);
      // expect(sLang, "en");
      // expect(username, "admin");
      // expect(authorities, ['ROLE_ADMIN', 'ROLE_USER']);

      // dispose test
      // expect(find.byType(HomeScreen), findsNothing);
      // expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets("Given an invalid AccessToken when HomeScreen is opened then navigate to loginScreen", (tester) async {
      Widget getWidget() => const App(language: "en").buildHomeApp();

      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
