import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../test_utils.dart';

void main() {
  late MockLoginBloc mockLoginBloc;
  late Widget testWidget;
  late GoRouter mockGoRouter;

  setUpAll(() {
    registerAllFallbackValues();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    mockLoginBloc = MockLoginBloc();

    // Set basic state for login bloc
    when(() => mockLoginBloc.state).thenReturn(const LoginState());
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

    testWidget = MultiBlocProvider(
      providers: [BlocProvider<LoginBloc>.value(value: mockLoginBloc)],
      child: MaterialApp.router(
        theme: ThemeData(useMaterial3: false, brightness: Brightness.light, colorSchemeSeed: Colors.blueGrey),
        darkTheme: ThemeData(useMaterial3: false, brightness: Brightness.dark, primarySwatch: Colors.blueGrey),
        themeMode: ThemeMode.light,
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
    );
  });

  group('OtpEmailScreen Widget Tests', () {
    testWidgets('should render initial UI elements correctly', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(find.text(S.current.login_with_email), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(ResponsiveSubmitButton), findsOneWidget);
    });

    testWidgets('should validate email field correctly', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final emailField = find.byType(FormBuilderTextField);

      // WHEN - Submit with empty email
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text(S.current.required_field), findsOneWidget);

      // WHEN - Submit with invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text(S.current.invalid_email), findsOneWidget);

      // WHEN - Submit with valid email
      await tester.enterText(emailField, 'test@example.com');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pumpAndSettle();

      verify(() => mockLoginBloc.add(const SendOtpRequested(email: 'test@example.com'))).called(1);
    });

    testWidgets('should show loading state when sending OTP', (tester) async {
      when(() => mockLoginBloc.state).thenReturn(const LoginState(status: LoginStatus.loading));
      await tester.pumpWidget(testWidget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(S.current.send_otp_code), findsOneWidget);
    });

    testWidgets('should navigate to verify screen when OTP sent successfully', (tester) async {
      TestUtils().setupUnitTest();

      final loginStateController = StreamController<LoginState>.broadcast();
      when(() => mockLoginBloc.stream).thenAnswer((_) => loginStateController.stream);
      when(() => mockLoginBloc.state).thenReturn(const LoginState());

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(FormBuilderTextField), 'test@example.com');
      await tester.tap(find.byType(ResponsiveSubmitButton));
      await tester.pump();

      loginStateController.add(
        const LoginState(status: LoginStatus.loading, email: 'test@example.com', loginMethod: LoginMethod.otp),
      );
      await tester.pump();

      loginStateController.add(const LoginOtpSentState(email: 'test@example.com'));
      await tester.pumpAndSettle();

      verify(() => mockLoginBloc.add(const SendOtpRequested(email: 'test@example.com'))).called(1);
      expect(
        mockGoRouter.routerDelegate.currentConfiguration.uri.path,
        '${ApplicationRoutesConstants.loginOtpVerify}/test@example.com',
      );

      await loginStateController.close();
    });

    testWidgets('should handle back button press', (tester) async {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      SharedPreferences.setMockInitialValues({});
      await AppLocalStorage().save(StorageKeys.language.name, "en");

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(mockGoRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.login);
    });

    testWidgets('should show error state', (tester) async {
      when(() => mockLoginBloc.state).thenReturn(const LoginState(status: LoginStatus.failure));
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(mockGoRouter.routerDelegate.currentConfiguration.uri.path, ApplicationRoutesConstants.loginOtp);
    });

    group('Localization Tests', () {
      testWidgets('should display texts in English', (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.pumpAndSettle();

        expect(find.text(S.current.login_with_email), findsOneWidget);
        expect(find.text(S.current.email), findsOneWidget);
        expect(find.text(S.current.send_otp_code), findsOneWidget);
      });
    });
  });
}
