import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';
@GenerateNiceMocks([MockSpec<LoginBloc>(), MockSpec<AccountBloc>()])
import 'login_otp_email_widget_test.mocks.dart';

void main() {
  late MockLoginBloc mockLoginBloc;
  late Widget testWidget;
  late GoRouter mockGoRouter;

  setUp(() {
    mockLoginBloc = MockLoginBloc();

    // Set basic state for login bloc
    when(mockLoginBloc.state).thenReturn(const LoginState());
    mockGoRouter = GoRouter(
      initialLocation: ApplicationRoutesConstants.loginOtp,
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

  group('OtpEmailScreen Widget Tests', () {
    testWidgets('should render initial UI elements correctly', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.login_with_email), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(ResponsiveSubmitButton), findsOneWidget);
    });

    testWidgets('should validate email field correctly', (tester) async {
      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final emailField = find.byType(FormBuilderTextField);

      // WHEN - Submit with empty email
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.required_field), findsOneWidget);

      // WHEN - Submit with invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      // THEN
      expect(find.text(S.current.invalid_email), findsOneWidget);

      // WHEN - Submit with valid email
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      // THEN
      verify(mockLoginBloc.add(const SendOtpRequested(email: 'test@example.com'))).called(1);
    });

    testWidgets('should show loading state when sending OTP', (tester) async {
      // GIVEN
      when(mockLoginBloc.state).thenReturn(const LoginState(status: LoginStatus.loading));
      await tester.pumpWidget(testWidget);
      await tester.pump();

      // THEN
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(S.current.send_otp_code), findsOneWidget);
    });

    testWidgets('should navigate to verify screen when OTP sent successfully', (tester) async {
      TestUtils().setupUnitTest();

      // Generate stream controller for login state
      final loginStateController = StreamController<LoginState>.broadcast();
      when(mockLoginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(mockLoginBloc.state).thenReturn(const LoginState());

      // generate test widget
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // enter email and submit form
      await tester.enterText(find.byType(FormBuilderTextField), 'test@example.com');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pump();

      // emit loading state
      loginStateController.add(
        const LoginState(status: LoginStatus.loading, email: 'test@example.com', loginMethod: LoginMethod.otp),
      );
      await tester.pump();

      // emit success state
      loginStateController.add(const LoginOtpSentState(email: 'test@example.com'));
      await tester.pumpAndSettle();

      // verify
      verify(mockLoginBloc.add(const SendOtpRequested(email: 'test@example.com'))).called(1);
      expect(
        mockGoRouter.routerDelegate.currentConfiguration.uri.path,
        '${ApplicationRoutesConstants.loginOtpVerify}/test@example.com',
      );

      // clean up
      await loginStateController.close();
    });

    testWidgets('should handle back button press', (tester) async {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      SharedPreferences.setMockInitialValues({});
      await AppLocalStorage().save(StorageKeys.language.name, "en");

      // GIVEN
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // WHEN
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // THEN
      expect(mockGoRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.login);
    });

    testWidgets('should show error state', (tester) async {
      // GIVEN
      when(mockLoginBloc.state).thenReturn(const LoginState(status: LoginStatus.failure));
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // THEN
      expect(mockGoRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.loginOtp);
    });

    group('Localization Tests', () {
      testWidgets('should display texts in English', (tester) async {
        // GIVEN
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        // THEN
        expect(find.text(S.current.login_with_email), findsOneWidget);
        expect(find.text(S.current.email), findsOneWidget);
        expect(find.text(S.current.send_otp_code), findsOneWidget);
      });

      testWidgets(skip: true, 'should display texts in Turkish', (tester) async {
        // GIVEN
        AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
        SharedPreferences.setMockInitialValues({});
        await AppLocalStorage().save(StorageKeys.language.name, "tr");

        // Before loading the app, load the Turkish locale
        await S.load(const Locale('tr'));

        final turkishWidget = AdaptiveTheme(
          light: ThemeData(useMaterial3: false, brightness: Brightness.light, colorSchemeSeed: Colors.blueGrey),
          dark: ThemeData(useMaterial3: false, brightness: Brightness.dark, primarySwatch: Colors.blueGrey),
          initial: AdaptiveThemeMode.light,
          builder: (light, dark) => MultiBlocProvider(
            providers: [BlocProvider<LoginBloc>.value(value: mockLoginBloc)],
            child: MaterialApp(
              theme: light,
              darkTheme: dark,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              locale: const Locale('tr'),
              home: OtpEmailScreen(),
            ),
          ),
        );

        await tester.pumpWidget(turkishWidget);
        await tester.pumpAndSettle();

        // THEN
        expect(find.text('E-posta ile Giriş'), findsOneWidget);
        expect(find.text('E-posta'), findsOneWidget);
        expect(find.text('OTP Kodu Gönder'), findsOneWidget);
      });
    });
  });
}
