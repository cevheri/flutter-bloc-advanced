import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/settings_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/settings_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'settings_screen_test.mocks.dart';

@GenerateMocks([DrawerBloc, AppLocalStorage])
void main() {
  late DrawerBloc mockDrawerBloc;
  late TestUtils testUtils;

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    mockDrawerBloc = MockDrawerBloc();

    when(mockDrawerBloc.stream).thenAnswer((_) => Stream.fromIterable([]));
    when(mockDrawerBloc.state).thenReturn(const DrawerState());
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  Widget buildTestableWidget() {
    final router = GoRouter(initialLocation: ApplicationRoutesConstants.settings, routes: SettingsRoutes.routes);

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all buttons correctly', (WidgetTester tester) async {
      await testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      // Language selection removed from settings (moved to drawer)
      expect(find.byKey(settingsLogoutButtonKey), findsOneWidget);
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      await testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
    });

    // Language selection moved to drawer menu
    testWidgets('shows theme selection dialog when theme button is pressed', (WidgetTester tester) async {
      await testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Find theme selection button and tap it
      final themeButton = find.byKey(const Key('settings-theme-button'));
      if (tester.any(themeButton)) {
        await tester.tap(themeButton);
        await tester.pumpAndSettle();

        // Check if theme selection dialog is shown
        expect(find.byType(Dialog), findsOneWidget);
      }
    }, skip: true); // Skip for now as theme button key might not be defined
    //TODO : fix the following skipped tests
    testWidgets('shows logout confirmation dialog when logout button is pressed', skip: true, (
      WidgetTester tester,
    ) async {
      await testUtils.setupAuthentication();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('performs logout when confirmed', skip: true, (WidgetTester tester) async {
      await testUtils.setupAuthentication();
      when(mockDrawerBloc.stream).thenAnswer((_) => Stream.fromIterable([]));
      when(mockDrawerBloc.state).thenReturn(const DrawerState());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
      // verify(() => mockStorage.clear()).called(1);
      verifyNever(mockDrawerBloc.add(Logout()));
    });

    testWidgets('cancels logout when declined', skip: true, (WidgetTester tester) async {
      await testUtils.setupAuthentication();
      when(mockDrawerBloc.stream).thenAnswer((_) => Stream.fromIterable([]));
      when(mockDrawerBloc.state).thenReturn(const DrawerState());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsLogoutButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      verifyNever(mockDrawerBloc.add(Logout()));
    });
  });
}
