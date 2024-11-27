import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/bloc/change_password_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/change_password_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mockito/annotations.dart';

import '../../../test_utils.dart';

final _log = AppLogger.getLogger("AccountsScreenTest");

/// Accounts Screen Test
/// claas AccountsScreen extent
@GenerateMocks([AccountRepository, ChangePasswordBloc])
void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  final blocs = [
    BlocProvider<AuthorityBloc>(
        create: (_) =>
            AuthorityBloc(repository: AuthorityRepository())),
    BlocProvider<ChangePasswordBloc>(
        create: (_) =>
            ChangePasswordBloc(repository: AccountRepository())),
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: ChangePasswordScreen(),
      ),
      supportedLocales: const [
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  // app bar
  group("ChangePasswordScreen AppBarTest", () {
    testWidgets("Validate AppBar", (tester) async {
      _log.debug("begin Validate AppBar");
      // Given
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title

      expect(find.text(S.current.change_password), findsWidgets);
      _log.debug("end Validate AppBar");
    });

    //app bar back button test
    testWidgets("Validate AppBar Back Button", (tester) async {
      _log.debug("begin Validate AppBar Back Button");

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsNothing);

      _log.debug("end Validate AppBar Back Button");
    });
  });

  //form fields
  group("ChangePasswordScreen FormFieldsTest", () {
    testWidgets("Render Screen Validate Field Type Successful", (tester) async {
      _log.debug("begin Validate Field Type");
      await TestUtils().setupAuthentication();
      _log.debug("getAccount initWidgetDependenciesWithToken");
      // Given:
      await tester.pumpWidget(getWidget());
      _log.debug("getAccount getWidget");
      //When:
      await tester.pumpAndSettle();
      _log.debug("getAccount pumpAndSettle");

      //Then:
      expect(find.byType(FormBuilderTextField), findsNWidgets(2));
      //expect(find.byType(FormBuilderSwitch), findsOneWidget);
      //expect(find.byType(ElevatedButton), findsOneWidget);
      _log.debug("end Validate Field Type");
    });
    /// validate field name with English translation
    testWidgets(skip: true, "Render Screen Validate Field Name Successful", (
        tester) async {
      //Given
      await tester.pumpWidget(getWidget());
      //When
      await tester.pumpAndSettle();
      //Then:
      // current password textField
      expect(find.text("Current Password"), findsOneWidget);
      // password textField
      expect(find.text("New Password"), findsOneWidget);
      // submit button
      expect(find.text("Change Password"), findsOneWidget);
    });
  });


  group("ChangePasswordScreen Bloc Test", () {
    testWidgets(skip: true,
        "Given valid user data with AccessToken when Change Password Button clicked then update user Successfully", (
            tester) async {
          // Given: render screen with valid user data
          await tester.pumpWidget(getWidget());
          //When: wait screen is ready
          await tester.pumpAndSettle();

          expect(find.byType(ElevatedButton), findsOneWidget);
          expect(find.text("Change Password"), findsOneWidget);
          //await tester.tap(find.text('Save'));
          // await tester.pumpAndSettle();
        });

    testWidgets(skip: true,
        "Given valid user data without AccessToken when Change Password Button clicked then update user fail (Unauthorized)",
            (tester) async {
          expect(find.byType(ElevatedButton), findsOneWidget);
          expect(find.text("Change Password"), findsOneWidget);
          // await tester.tap(find.text('Save'));
          // await tester.pumpAndSettle();
          // Given: render screen with valid user data
          await tester.pumpWidget(getWidget());
          //When: wait screen is ready
          await tester.pumpAndSettle();

          //await tester.tap(find.text('Save'));
          //await tester.pumpAndSettle();
        });

    testWidgets(skip: true,
        "Given same user data (no-changes) when Change Password Button clicked then no-action", (
            tester) async {
          // Given: render screen with valid user data
          await tester.pumpWidget(getWidget());
          //When: wait screen is ready
          await tester.pumpAndSettle();

          expect(find.byType(ElevatedButton), findsOneWidget);
          expect(find.text("Change Password"), findsOneWidget);

          await tester.tap(find.text('Change Password'));
        });
  });

  group("ChangePasswordScreen SubmitButtonTest", () {
    testWidgets(
      skip: true,
      'calls buildWhen and builder with correct state S.current.loaded',
          (tester) async {
        // Given
        await TestUtils().setupAuthentication();

        // When
        await tester.pumpWidget(getWidget());

        // Then
        await tester.pumpAndSettle();

        final currentPasswordField =
        find.byKey(const Key('currentPasswordKey'));
        final newPasswordField = find.byKey(const Key('newPasswordKey'));
        final submitButton =
        find.byKey(const Key('changeButtonSubmitButtonKey'));

        expect(currentPasswordField, findsOneWidget);
        expect(newPasswordField, findsOneWidget);
        expect(submitButton, findsOneWidget);

        await tester.enterText(currentPasswordField, 'currentPassword');
        await tester.enterText(newPasswordField, 'newPassword');

        await tester.pumpAndSettle();
        expect(find.text('currentPassword'), findsOneWidget);
        expect(find.text('newPassword'), findsOneWidget);

        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      },
    );
  });
}
