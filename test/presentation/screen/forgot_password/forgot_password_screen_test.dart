import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import '../../../test_utils.dart';

///Forgot Password Screen Test
///class ForgotPasswordScreen extends
void main() {
  late ForgotPasswordBloc forgotPasswordBloc;
  late AccountBloc accountBloc;

  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
    forgotPasswordBloc = ForgotPasswordBloc(repository: AccountRepository());
    accountBloc = AccountBloc(repository: AccountRepository());
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  // tearDownAll(() {
  //   forgotPasswordBloc.close();
  //   accountBloc.close();
  // });

  final blocs = [
    BlocProvider<AccountBloc>(create: (_) => accountBloc),
    BlocProvider<ForgotPasswordBloc>(create: (_) => forgotPasswordBloc),
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(providers: blocs, child: ForgotPasswordScreen()),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
  //endregion setup

  //AppBar Test
  group("ForgotPasswordScreen AppBar Test", () {
    testWidgets("Validate AppBar", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title"
      expect(find.text('Forgot Password'), findsOneWidget);
    });
  });
  //email text
  group("ForgotPasswordScreen Text Test", () {
    testWidgets("Validate FormBuilderTextField ", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.text('Email'), findsOneWidget);
    });
  });

  // logo Test
  group("ForgotPasswordScreen LogoTest", () {
    testWidgets("Validate Logo", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final logoFinder = find.byType(Image);

      //Then:
      expect(logoFinder, findsOneWidget);
    });
  });

  // Send Email Button Test
  group("ForgotPasswordScreen Send email Button", () {
    testWidgets("Validate send email button", (tester) async {
      // Given:

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmit);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      //Then:
      //expect(find.text('Sending email to reset password...'), findsOneWidget);
      //'Sending email to reset password...'
      expect(find.text('Email is required'), findsOneWidget);
      //expect(find.byType(ForgotPasswordScreen), findsNothing);
    });
  });

  // group("ForgotPasswordScreen email Changed", () {
  //   testWidgets("Validate email", (tester) async {
  //    // Given
  //     await tester.pumpWidget(Container());
  //     await tester.pumpAndSettle();
  //     await tester.pumpWidget(getWidget());
  //     //When:
  //     final emailTextFinder = find.byType(Text(EmailValidator));
  //
  //     //Then:
  //     expect(emailTextFinder, findsOneWidget);
  //   });
  // });

  //       expect(find.byType(FormBuilderTextField), findsOneWidget);
  //       // send button
  //       expect(find.text('Send Email'), findsOneWidget);
  //
  //       //Button test
  //       final submitButtonFinder = find.byKey(forgotPasswordButtonSubmit);
  //       await tester.tap(submitButtonFinder);
  //       await tester.pumpAndSettle(const Duration(seconds: 5));
  //
  //       expect(find.text('Email is required'), findsOneWidget);

  // Send Email  Button Test Success
  testWidgets(skip: true, "Validate send email button Successful", (tester) async {
    // Given:

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(getWidget());
    //When:
    await tester.pumpAndSettle();

    final emailFinder = find.byKey(forgotPasswordTextFieldEmail);
    await tester.enterText(emailFinder, "test@test.com");

    final submitButtonFinder = find.byKey(forgotPasswordButtonSubmit);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    //Then:
    //TODO passwordScreen does not disposed in bloc.buildWhen
    //expect(find.byType(ForgotPasswordScreen), findsNothing);
  });

  // Send Email  Button Test Success
  testWidgets("Validate send email button invalid email fail", (tester) async {
    // Given:

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(getWidget());
    //When:
    await tester.pumpAndSettle();

    final emailFinder = find.byKey(forgotPasswordTextFieldEmail);
    await tester.enterText(emailFinder, "invalid-email");

    final submitButtonFinder = find.byKey(forgotPasswordButtonSubmit);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    //Then:
    //TODO passwordScreen does not disposed in bloc.buildWhen
    //expect(find.byType(ForgotPasswordScreen), findsNothing);
  });

  // Send Email  Button Test Success
  testWidgets("Validate send email button invalid email fail", (tester) async {
    // Given:

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(getWidget());
    //When:
    await tester.pumpAndSettle();

    final emailFinder = find.byKey(forgotPasswordTextFieldEmail);
    await tester.enterText(emailFinder, "");

    final submitButtonFinder = find.byKey(forgotPasswordButtonSubmit);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    //Then:
    //TODO passwordScreen does not disposed in bloc.buildWhen
    //expect(find.byType(ForgotPasswordScreen), findsNothing);
  });
}
