import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/login_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/register_screen.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../test_utils.dart';

/// Login Screen Test
/// claas AccountsScreen extent
void main() {
  late LoginBloc loginBloc;
  late AccountBloc accountBloc;
  late ForgotPasswordBloc forgotPasswordBloc;
  late RegisterBloc registerBloc;
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
    loginBloc = LoginBloc(loginRepository: LoginRepository());
    accountBloc = AccountBloc(accountRepository: AccountRepository());
    forgotPasswordBloc = ForgotPasswordBloc(accountRepository: AccountRepository());
    registerBloc = RegisterBloc(accountRepository: AccountRepository());
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  tearDownAll(() {
    loginBloc.close();
    forgotPasswordBloc.close();
    accountBloc.close();
  });

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>.value(value: loginBloc),
          BlocProvider<AccountBloc>.value(value: accountBloc),
          BlocProvider<RegisterBloc>(create: (_) => registerBloc, child: RegisterScreen()),
          BlocProvider<ForgotPasswordBloc>(create: (_) => forgotPasswordBloc, child: ForgotPasswordScreen()),
        ],
        child: LoginScreen(),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
  //endregion setup

  // app bar
  group("LoginScreen AppBarTest", () {
    testWidgets("Validate AppBar", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final appBarFinder = find.byType(AppBar);
      final titleFinder = find.text(AppConstants.appName);

      //Then:
      expect(appBarFinder, findsOneWidget);
      expect(titleFinder, findsOneWidget);
    });
  });

  // logo
  group("LoginScreen LogoTest", () {
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

  // username field
  group("LoginScreen UsernameFieldTest", () {
    testWidgets("Validate Username Field", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);

      //Then:
      expect(usernameFieldFinder, findsOneWidget);
    });
  });

  // password field
  group("LoginScreen PasswordFieldTest", () {
    testWidgets("Validate Password Field", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);

      //Then:
      expect(passwordFieldFinder, findsOneWidget);

      // enter password text
      await tester.enterText(passwordFieldFinder, "admin");
      await tester.pumpAndSettle();
    });
  });

  // password visibility
  group("LoginScreen PasswordVisibilityTest", () {
    testWidgets("Validate Password Visibility", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final passwordVisibilityFinder = find.byKey(loginButtonPasswordVisibilityKey);

      //Then:
      expect(passwordVisibilityFinder, findsOneWidget);
      await tester.tap(passwordVisibilityFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // check loginTextFieldPassword password is visible or not
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);
      final textField = tester.widget<FormBuilderTextField>(passwordFieldFinder);
      expect(textField.obscureText, true);

    });
  });

  // submit button
  group("LoginScreen SubmitButtonTest", () {
    testWidgets("Validate Submit Button", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final submitButtonFinder = find.byKey(loginButtonSubmitKey);

      //Then:
      expect(submitButtonFinder, findsOneWidget);
    });
  });

  // forgot password button
  group("LoginScreen ForgotPasswordButtonTest", () {
    testWidgets("Validate Forgot Password Button", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final forgotPasswordButtonFinder = find.byKey(loginButtonForgotPasswordKey);

      //Then:
      expect(forgotPasswordButtonFinder, findsOneWidget);
      await tester.tap(forgotPasswordButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  // register button
  group("LoginScreen RegisterButtonTest", () {
    testWidgets("Validate Register Button", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final registerButtonFinder = find.byKey(loginButtonRegisterKey);

      //Then:
      expect(registerButtonFinder, findsOneWidget);
      await tester.tap(registerButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  // login screen submit event test with username and password
  group("LoginScreen SubmitEventTest", () {
    testWidgets("Validate Submit Event and success", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);
      final submitButtonFinder = find.byKey(loginButtonSubmitKey);
      //When:
      await tester.enterText(usernameFieldFinder, "admin");
      await tester.enterText(passwordFieldFinder, "admin");
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      //Then:
      // Success
      String jwtTokenStorage = await AppLocalStorage().read(StorageKeys.jwtToken.name);
      expect(jwtTokenStorage, "MOCK_TOKEN");
    });

    testWidgets("Validate Submit Event without AccessToken and fail", (tester) async {
      TestUtils().tearDownUnitTest();
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);
      final submitButtonFinder = find.byKey(loginButtonSubmitKey);
      //When:
      await tester.enterText(usernameFieldFinder, "admin");
      await tester.enterText(passwordFieldFinder, "admin");
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      //Then:
      // Fail
      expect(find.byType(LoginScreen), findsOneWidget);

      //final loginErrorFinder = find.text("Login Error");
      //expect(loginErrorFinder, findsOneWidget);
      final visibilityFinder = find.byType(Visibility);
      expect(visibilityFinder, findsOneWidget);
    });

    testWidgets("Validate Submit Event with null values and fail", (tester) async {
      TestUtils().tearDownUnitTest();
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);
      final submitButtonFinder = find.byKey(loginButtonSubmitKey);
      //When:
      await tester.enterText(usernameFieldFinder, "");
      await tester.enterText(passwordFieldFinder, "");
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      //Then:
      // Fail
      expect(find.byType(LoginScreen), findsOneWidget);

      //final loginErrorFinder = find.text("Login Error");
      //expect(loginErrorFinder, findsOneWidget);
      final visibilityFinder = find.byType(Visibility);
      expect(visibilityFinder, findsOneWidget);
    });

  });

  // password field onSubmitted event
  group("LoginScreen PasswordFieldOnSubmittedTest", () {
    testWidgets("Validate Password Field onSubmitted Event with valid data", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);

      // When
      await tester.enterText(usernameFieldFinder, "admin");
      await tester.enterText(passwordFieldFinder, "admin");

      // Then
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Success
     // String jwtTokenStorage = await AppLocalStorage().read(StorageKeys.jwtToken.name);
      //expect(jwtTokenStorage, "MOCK_TOKEN");
    });

    testWidgets("Validate Password Field onSubmitted Event with invalid data", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
      final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);

      // When
      await tester.enterText(usernameFieldFinder, "");
      await tester.enterText(passwordFieldFinder, "");

      // Then
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Fail
      expect(find.byType(LoginScreen), findsOneWidget);
      final visibilityFinder = find.byType(Visibility);
      expect(visibilityFinder, findsOneWidget);
    });
  });


  // bloc buildWhen tests
  group("LoginScreen BlocBuildWhenTest", () {
    testWidgets("Validate buildWhen with LoginLoadingState", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      loginBloc.add(const LoginFormSubmitted(username: "admin", password: "admin"));

      // When
      await tester.pumpAndSettle();

      // Then
      //expect(find.text("Logging in..."), findsOneWidget);
    });

    testWidgets("Validate buildWhen with LoginLoadedState", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      loginBloc.add(const LoginFormSubmitted(username: "admin", password: "admin"));

      // When
      await tester.pumpAndSettle();

      // Then
      //expect(find.text("Success"), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets("Validate buildWhen with LoginErrorState", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      loginBloc.add(const LoginFormSubmitted(username: "invalid", password: "sdfsdfasf"));

      // When
      await tester.pumpAndSettle();

      // Then
      //expect(find.text("Login failed."), findsOneWidget);
    });
  });

}
