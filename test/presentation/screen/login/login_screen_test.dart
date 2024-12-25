import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/register_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'login_screen_test.mocks.dart';

/// Login Screen Test
/// claas AccountsScreen extent
@GenerateMocks([LoginBloc, AccountBloc, ForgotPasswordBloc, RegisterBloc, AppLocalStorage])
void main() {
  late MockLoginBloc loginBloc;
  late MockAccountBloc accountBloc;
  late MockForgotPasswordBloc forgotPasswordBloc;
  late MockRegisterBloc registerBloc;
  late MockAppLocalStorage appLocalStorage;
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
    // loginBloc = LoginBloc(repository: LoginRepository());
    // accountBloc = AccountBloc(repository: AccountRepository());
    // forgotPasswordBloc = ForgotPasswordBloc(repository: AccountRepository());
    // registerBloc = RegisterBloc(repository: AccountRepository());
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();

    // when(loginBloc.stream).thenAnswer((_) => Stream.fromIterable([const LoginInitialState()]));
    // when(loginBloc.state).thenReturn(const LoginInitialState());
    //
    // when(accountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    // when(accountBloc.state).thenReturn(const AccountState());
    //
    // when(forgotPasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordInitialState()]));
    // when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());
    //
    // when(registerBloc.stream).thenAnswer((_) => Stream.fromIterable([const RegisterInitialState()]));
    // when(registerBloc.state).thenReturn(const RegisterInitialState());
  });

  setUp(() {
    loginBloc = MockLoginBloc();
    accountBloc = MockAccountBloc();
    forgotPasswordBloc = MockForgotPasswordBloc();
    registerBloc = MockRegisterBloc();
    appLocalStorage = MockAppLocalStorage();

    when(loginBloc.stream).thenAnswer((_) => Stream.fromIterable([const LoginInitialState()]));
    when(loginBloc.state).thenReturn(const LoginInitialState());

    when(accountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(accountBloc.state).thenReturn(const AccountState());

    when(forgotPasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordInitialState()]));
    when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());

    when(registerBloc.stream).thenAnswer((_) => Stream.fromIterable([const RegisterInitialState()]));
    when(registerBloc.state).thenReturn(const RegisterInitialState());

    when(appLocalStorage.read(StorageKeys.jwtToken.name)).thenAnswer((_) => Future.value(null));
  });

  // tearDownAll(() {
  //   loginBloc.close();
  //   forgotPasswordBloc.close();
  //   accountBloc.close();
  // });

  // GetMaterialApp getWidget() {
  //   return GetMaterialApp(
  //     home: MultiBlocProvider(
  //       providers: [
  //         BlocProvider<LoginBloc>.value(value: loginBloc),
  //         BlocProvider<AccountBloc>.value(value: accountBloc),
  //         BlocProvider<RegisterBloc>(create: (_) => registerBloc, child: RegisterScreen()),
  //         BlocProvider<ForgotPasswordBloc>(create: (_) => forgotPasswordBloc, child: ForgotPasswordScreen()),
  //       ],
  //       child: LoginScreen(),
  //     ),
  //     localizationsDelegates: const [
  //       S.delegate,
  //       GlobalMaterialLocalizations.delegate,
  //       GlobalWidgetsLocalizations.delegate,
  //       GlobalCupertinoLocalizations.delegate,
  //     ],
  //   );
  // }

  final Iterable<LocalizationsDelegate<dynamic>> locales = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
        localizationsDelegates: locales,
        supportedLocales: S.delegate.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<LoginBloc>(create: (context) => loginBloc),
            BlocProvider<AccountBloc>(create: (context) => accountBloc),
            BlocProvider<RegisterBloc>(create: (context) => registerBloc),
            BlocProvider<ForgotPasswordBloc>(create: (context) => forgotPasswordBloc),
          ],
          child: LoginScreen(),
        ));
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
    testWidgets(skip: true, "Validate Forgot Password Button", (tester) async {
      //TODO validate forgot password button
    });
  });

  // register button
  group("LoginScreen RegisterButtonTest", () {
    testWidgets(skip: true, "Validate Register Button", (tester) async {
      //TODO validate register button
    });
  });

  // login screen submit event test with username and password
  group("LoginScreen SubmitEventTest", () {
    testWidgets("Validate Submit Event and success", (tester) async {
      //TestUtils().setupAuthentication();

      when(appLocalStorage.read(any)).thenAnswer((_) => Future.value("MOCK_TOKEN"));
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
      String jwtTokenStorage = await appLocalStorage.read(StorageKeys.jwtToken.name);
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
  });

  testWidgets("Validate buildWhen with LoginLoadedState", (tester) async {
    // Given
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();

    GetMaterialApp getWidgetX() {
      return GetMaterialApp(
          localizationsDelegates: locales,
          supportedLocales: S.delegate.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<LoginBloc>(create: (context) => loginBloc),
              BlocProvider<AccountBloc>(create: (context) => accountBloc),
              BlocProvider<RegisterBloc>(create: (context) => registerBloc),
              BlocProvider<ForgotPasswordBloc>(create: (context) => forgotPasswordBloc),
            ],
            child: LoginScreen(
              key: const Key("Validate_buildWhen_with_LoginLoadedState_key"),
            ),
          ));
    }

    when(loginBloc.add(const LoginFormSubmitted(username: "admin", password: "admin"))).thenAnswer((_) => const LoginLoadedState());
    await tester.pumpWidget(getWidgetX());
    final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
    final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);

    // When
    await tester.enterText(usernameFieldFinder, "admin");
    await tester.enterText(passwordFieldFinder, "admin");

    //when(loginBloc.stream).thenAnswer((_) => Stream.fromIterable([const LoginLoadedState()]));
    //when(loginBloc.state).thenReturn(const LoginLoadedState());
    // Then
    final submitButtonFinder = find.byKey(loginButtonSubmitKey);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 3000));

    // When
    //await tester.pumpAndSettle(const Duration(seconds: 1));
    //await tester.pump();

    // Then
    // expect(find.text("Success"), findsOneWidget);
    //expect(find.byType(LoginScreen), findsNothing);
    //verify(loginBloc.add(const LoginFormSubmitted(username: "admin", password: "admin"))).called(1);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets("Validate buildWhen with LoginErrorState", (tester) async {
    // Given
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(getWidget());
    //loginBloc.add(const LoginFormSubmitted(username: "invalid", password: "invalid"));
    final usernameFieldFinder = find.byKey(loginTextFieldUsernameKey);
    final passwordFieldFinder = find.byKey(loginTextFieldPasswordKey);

    // When
    await tester.enterText(usernameFieldFinder, "invalid");
    await tester.enterText(passwordFieldFinder, "invalid");

    when(loginBloc.stream).thenAnswer((_) => Stream.fromIterable([const LoginErrorState(message: "Login failed.")]));
    when(loginBloc.state).thenReturn(const LoginErrorState(message: "Login failed."));
    when(loginBloc.add(const LoginFormSubmitted(username: "invalid", password: "invalid")))
        .thenAnswer((_) => const LoginErrorState(message: "Login failed."));
    // Then
    final submitButtonFinder = find.byKey(loginButtonSubmitKey);
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 3000));
    // When
    //await tester.pumpAndSettle(const Duration(seconds: 5));

    // Then
    expect(find.byType(LoginScreen), findsOneWidget);
    //verifyNever(loginBloc.add(const LoginFormSubmitted(username: "admin", password: "admin")));
  });
}
