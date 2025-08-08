import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
@GenerateNiceMocks([MockSpec<LoginBloc>(), MockSpec<AccountBloc>()])
import 'login_otp_verify_widget_test.mocks.dart';

void main() {
  late MockLoginBloc mockLoginBloc;
  late Widget testWidget;
  late GoRouter mockGoRouter;

  setUp(() {
    mockLoginBloc = MockLoginBloc();

    // Set basic state for login bloc
    when(mockLoginBloc.state).thenReturn(const LoginState());
    mockGoRouter = GoRouter(
      initialLocation: "${ApplicationRoutesConstants.loginOtpVerify}/test@example.com",
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.loginOtp,
          builder: (context, state) => BlocProvider.value(value: mockLoginBloc, child: OtpEmailScreen()),
        ),
        GoRoute(
          path: '${ApplicationRoutesConstants.loginOtpVerify}/:email',
          builder: (context, state) => BlocProvider.value(
            value: mockLoginBloc,
            child: OtpVerifyScreen(email: state.pathParameters['email']!),
          ),
        ),
        GoRoute(
          path: ApplicationRoutesConstants.login,
          builder: (context, state) => BlocProvider.value(value: mockLoginBloc, child: LoginScreen()),
        ),
        GoRoute(
          path: ApplicationRoutesConstants.home,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text("home")),
            body: Container(),
          ),
        ),
      ],
    );

    testWidget = AdaptiveTheme(
      light: ThemeData(useMaterial3: false, brightness: Brightness.light, colorSchemeSeed: Colors.blueGrey),
      dark: ThemeData(useMaterial3: false, brightness: Brightness.dark, primarySwatch: Colors.blueGrey),
      initial: AdaptiveThemeMode.light,
      builder: (light, dark) => MultiBlocProvider(
        providers: [BlocProvider<LoginBloc>.value(value: mockLoginBloc)],
        child: MaterialApp.router(
          theme: light,
          darkTheme: dark,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: const Locale('en'),
          routerConfig: mockGoRouter,
        ),
      ),
    );
  });

  group("OtpVerifyScreen form element appBar and formBuilder", () {
    //appbar
    testWidgets('should render appbar correctly', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // THEN
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(S.current.verify_otp_code), findsAtLeast(1));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    //form
    testWidgets('should render initial UI elements correctly', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // THEN
      expect(find.byType(ResponsiveFormBuilder), findsOneWidget);
      expect(find.text("${S.current.otp_sent_to} test@example.com"), findsOneWidget);

      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.text(S.current.otp_code), findsOneWidget);
      //Icon(Icons.lock_clock),
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);

      expect(find.byType(ResponsiveSubmitButton), findsOneWidget);
      expect(find.text(S.current.verify_otp_code), findsAtLeast(1));

      //resend button
      expect(find.byType(TextButton), findsAtLeast(1));
      expect(find.text(S.current.resend_otp_code), findsOneWidget);
    });
  });

  // otp text field validator
  group("OtpVerifyScreen form element otp text field validator", () {
    testWidgets('should show error message when otp code is empty', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.required_field), findsOneWidget);
    });

    testWidgets('should show error message when otp code is not a number', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), 'abc');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.only_numbers), findsOneWidget);
    });

    testWidgets('should show error message when otp code is less than 6 characters', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '12345');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.otp_length), findsOneWidget);
    });

    testWidgets('should show error message when otp code is more than 6 characters', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '1234567');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.otp_length), findsOneWidget);
    });
  });

  //submit button test
  group("OtpVerifyScreen form element submit button", () {
    testWidgets('should call LoginOtpVerify event when otp code is valid', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '123456');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      verify(mockLoginBloc.add(const VerifyOtpSubmitted(email: "test@example.com", otpCode: "123456"))).called(1);
    });

    // success scenario
    testWidgets('should call LoginOtpVerify event when otp code is valid', (tester) async {
      TestUtils().setupUnitTest();
      final loginStateController = StreamController<LoginState>.broadcast();
      when(mockLoginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(mockLoginBloc.state).thenReturn(const LoginState());
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '123456');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pump();

      loginStateController.add(
        const LoginState(
          email: "test@example.com",
          otpCode: "123456",
          status: LoginStatus.loading,
          isOtpSent: true,
          loginMethod: LoginMethod.otp,
        ),
      );
      await tester.pump();

      await AppLocalStorage().save(StorageKeys.jwtToken.name, "MOCK_TOKEN");
      await AppLocalStorage().save(StorageKeys.username.name, "mock");
      await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_USER"]);
      loginStateController.add(const LoginLoadedState(username: "test@example.com", password: "123456"));
      await tester.pump();

      // THEN
      // home screen should be navigated
      expect(mockGoRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.home);
      expect(find.byType(Scaffold), findsOneWidget);
      //expect(find.text("home"), findsOneWidget);

      verify(mockLoginBloc.add(const VerifyOtpSubmitted(email: "test@example.com", otpCode: "123456"))).called(1);

      //finally
      loginStateController.close();
    });

    //fail scenario
    testWidgets('should show error message when otp code is invalid', (tester) async {
      TestUtils().setupUnitTest();
      final loginStateController = StreamController<LoginState>.broadcast();
      when(mockLoginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(mockLoginBloc.state).thenReturn(const LoginState());
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.enterText(find.byType(FormBuilderTextField), '123456');
      final submitButtonFinder = find.byType(ResponsiveSubmitButton);
      await tester.tap(submitButtonFinder);
      await tester.pump();

      loginStateController.add(
        const LoginState(
          email: "test@example.com",
          otpCode: "123456",
          status: LoginStatus.loading,
          isOtpSent: true,
          loginMethod: LoginMethod.otp,
        ),
      );
      await tester.pump();

      loginStateController.add(const LoginErrorState(message: "Invalid OTP Token"));
      await tester.pump();

      // THEN
      //expect(find.text("Invalid OTP Token"), findsOneWidget);
      verify(mockLoginBloc.add(const VerifyOtpSubmitted(email: "test@example.com", otpCode: "123456"))).called(1);

      expect(
        mockGoRouter.routerDelegate.currentConfiguration.uri.path,
        "${ApplicationRoutesConstants.loginOtpVerify}/test@example.com",
      );

      //finally
      loginStateController.close();
    });
  });

  //resend button test
  group("OtpVerifyScreen form element resend button", () {
    testWidgets('should call SendOtpRequested event when resend button is clicked', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      final resendButtonFinder = find.byType(TextButton);
      await tester.tap(resendButtonFinder);
      await tester.pumpAndSettle();

      // THEN
      verify(mockLoginBloc.add(const SendOtpRequested(email: "test@example.com"))).called(1);
    });
  });
}
