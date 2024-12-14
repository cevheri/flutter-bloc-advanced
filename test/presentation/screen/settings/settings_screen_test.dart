import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/settings_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../test_utils.dart';
import 'settings_screen_test.mocks.dart';

@GenerateMocks([DrawerBloc, AppLocalStorage])
void main() {
  late DrawerBloc bloc;
  late AppLocalStorage storage;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    bloc = MockDrawerBloc();
    storage = MockAppLocalStorage();

  });

  Widget createWidgetUnderTest() {
    return GetMaterialApp(
      initialRoute: ApplicationRoutesConstants.settings,
      routes: {
        ApplicationRoutesConstants.settings: (context) => BlocProvider<DrawerBloc>(
              create: (context) => bloc,
              child: SettingsScreen(),
            ),
        ApplicationRoutesConstants.changePassword: (context) => const Scaffold(),
        ApplicationRoutesConstants.login: (context) => const Scaffold(),
        ApplicationRoutesConstants.home: (context) => const Scaffold(),
      },
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  group("AppBar Test", () {
    testWidgets("AppBar is built correctly", (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
    testWidgets("AppBar back button navigates back", (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
      //TODO check with go_router expect(Get.currentRoute, "/");
    });
  });

  group('SettingsScreen Tests', () {
    testWidgets('renders all buttons correctly', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsChangeLanguageButtonKey), findsOneWidget);
      expect(find.byKey(settingsLogoutButtonKey), findsOneWidget);
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      // Verify navigation
      expect(Get.currentRoute, ApplicationRoutesConstants.changePassword);
    });

    testWidgets('shows language selection dialog when button is pressed', (WidgetTester tester) async {

      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(settingsChangeLanguageButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Turkish'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog when logout button is pressed', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('performs logout when confirmed', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      when(bloc.stream).thenAnswer((_) => Stream.fromIterable([]));
      when(bloc.state).thenReturn(const DrawerState());
      when(bloc.add(Logout())).thenReturn(null);

      TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, ApplicationRoutesConstants.login);
    });
    testWidgets('performs logout when confirmed', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      when(bloc.stream).thenAnswer((_) => Stream.fromIterable([]));
      when(bloc.state).thenReturn(const DrawerState());
      when(bloc.add(Logout())).thenReturn(null);

      TestUtils().setupAuthentication();
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, ApplicationRoutesConstants.settings);
    });
  });

  group('LanguageConfirmationDialog Tests', () {

    testWidgets('changes language to Turkish when selected', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(const GetMaterialApp(
        home: LanguageConfirmationDialog(),
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ));

      when(storage.save(StorageKeys.language.name, 'tr')).thenAnswer((_) async => Future.value(true));
      await tester.tap(find.text('Turkish'));
      await tester.pumpAndSettle();

      //verify(storage.save(StorageKeys.language.name, 'tr')).called(1);
    });

    testWidgets('changes language to English when selected', (WidgetTester tester) async {
      await TestUtils().setupAuthentication();
      await tester.pumpWidget(
        const GetMaterialApp(
          home: LanguageConfirmationDialog(),
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      );

      when(storage.save(StorageKeys.language.name, 'en')).thenAnswer((_) async => Future.value(true));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      //verify(storage.save(StorageKeys.language.name, 'en')).called(1);
    });
  });
/*
*/
}
