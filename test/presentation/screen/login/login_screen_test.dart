import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
  late GoRouter goRouter;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
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
    when(appLocalStorage.save(StorageKeys.jwtToken.name, any)).thenAnswer((_) => Future.value(true));
    when(appLocalStorage.save(StorageKeys.username.name, any)).thenAnswer((_) => Future.value(true));

    // GoRouter setup
    goRouter = GoRouter(
      initialLocation: ApplicationRoutesConstants.login,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.login,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<LoginBloc>.value(value: loginBloc),
              BlocProvider<AccountBloc>.value(value: accountBloc),
              BlocProvider<RegisterBloc>.value(value: registerBloc),
              BlocProvider<ForgotPasswordBloc>.value(value: forgotPasswordBloc),
            ],
            child: LoginScreen(),
          ),
        ),
        GoRoute(path: ApplicationRoutesConstants.register, builder: (context, state) => const SizedBox()),
        GoRoute(path: ApplicationRoutesConstants.forgotPassword, builder: (context, state) => const SizedBox()),
        GoRoute(path: ApplicationRoutesConstants.home, builder: (context, state) => const SizedBox()),
      ],
      redirect: (context, state) {
        // Disable redirect for tests
        return null;
      },
    );
  });

  tearDownAll(() async {
    await TestUtils().tearDownUnitTest();
  });

  Widget getWidget() {
    return MaterialApp.router(
      routerConfig: goRouter,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }

  group('LoginScreen Tests', skip: true, () {
    testWidgets('Successful login scenario', (tester) async {
      // Arrange
      final loginStateController = StreamController<LoginState>.broadcast();

      when(loginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(loginBloc.state).thenReturn(const LoginInitialState());

      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byKey(loginTextFieldUsernameKey), findsOneWidget);
      expect(find.byKey(loginTextFieldPasswordKey), findsOneWidget);

      // Act - Fill form
      await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'test123');
      await tester.pump();

      await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'test123');
      await tester.pump();

      // Submit form using ElevatedButton
      final submitButton = find.byType(FilledButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Simulate state changes
      loginStateController.add(const LoginLoadingState(username: 'test123', password: 'test123'));
      await tester.pump();

      loginStateController.add(const LoginLoadedState(username: 'test123', password: 'test123'));
      await tester.pumpAndSettle();

      // Submit form
      //await tester.tap(submitButton);
      //await tester.pumpAndSettle();

      // Assert
      verify(loginBloc.add(const LoginFormSubmitted(username: 'test123', password: 'test123'))).called(1);

      // Cleanup
      await loginStateController.close();
    });

    testWidgets('Forgot password navigation test', (tester) async {
      // Arrange
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(loginButtonForgotPasswordKey));
      await tester.pumpAndSettle();

      // Assert
      expect(goRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.forgotPassword);
    });

    testWidgets('Register navigation test', (tester) async {
      // Arrange
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(loginButtonRegisterKey));
      await tester.pumpAndSettle();

      // Assert
      expect(goRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.register);
    });

    testWidgets('Login error scenario', (tester) async {
      // Arrange
      when(loginBloc.state).thenReturn(const LoginState());
      when(loginBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const LoginLoadingState(username: 'test', password: 'test'),
          const LoginErrorState(message: 'Error message'),
        ]),
      );

      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'test');
      await tester.pump();
      await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'test');
      await tester.pump();

      await tester.tap(find.byKey(loginButtonSubmitKey));
      await tester.pumpAndSettle();

      // Assert
      verify(loginBloc.add(const LoginFormSubmitted(username: 'test', password: 'test'))).called(1);

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Password visibility toggle test', (tester) async {
      // Arrange
      final loginStateController = StreamController<LoginState>.broadcast();

      when(loginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(loginBloc.state).thenReturn(const LoginState(passwordVisible: false));

      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Initial state - password should be obscured
      final initialPasswordField = find.byKey(loginTextFieldPasswordKey);
      expect(tester.widget<FormBuilderTextField>(initialPasswordField).obscureText, true);

      // Act - toggle visibility
      await tester.tap(find.byKey(loginButtonPasswordVisibilityKey));
      await tester.pump();

      // Simulate state change
      loginStateController.add(const LoginState(passwordVisible: true));
      await tester.pumpAndSettle();

      // Assert - password should be visible
      expect(tester.widget<FormBuilderTextField>(initialPasswordField).obscureText, false);

      // Cleanup
      await loginStateController.close();
    });
  });
}
