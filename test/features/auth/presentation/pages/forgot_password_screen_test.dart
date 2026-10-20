@Tags(['widget'])
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/unsaved_changes_host.dart';

///Forgot Password Screen Test
///class ForgotPasswordScreen extends
void main() {
  late MockForgotPasswordBloc forgotPasswordBloc;
  late MockAccountBloc accountBloc;

  //region setup
  setUp(() {
    forgotPasswordBloc = MockForgotPasswordBloc();
    accountBloc = MockAccountBloc();

    when(() => forgotPasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordInitialState()]));
    when(() => forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());

    when(() => accountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(() => accountBloc.state).thenReturn(const AccountState());
  });

  final Iterable<LocalizationsDelegate<dynamic>> locales = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget getWidget({Locale locale = const Locale('en')}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AccountBloc>(create: (context) => accountBloc),
              BlocProvider<ForgotPasswordBloc>(create: (context) => forgotPasswordBloc),
            ],
            child: ForgotPasswordScreen(),
          ),
        ),
      ],
    );
    return withUnsavedChangesRegistry(
      MaterialApp.router(
        locale: locale,
        localizationsDelegates: locales,
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
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
      // appBar title
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Forgot Password')), findsOneWidget);
    });
  });
  //email text
  group("ForgotPasswordScreen TextFields Test", () {
    testWidgets("Validate FormBuilderTextField ", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.text('Email'), findsOneWidget);
    });
  });

  // logo Test - REMOVED (logo no longer exists in forgot password screen)
  group("ForgotPasswordScreen LogoTest", () {
    testWidgets("Validate Logo", (tester) async {
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      final logoFinder = find.byType(Image);

      //Then: Logo removed from screen, so no image should be found
      expect(logoFinder, findsNothing);
    });
  });

  group("Bloc State changes Test", () {
    // ForgotPasswordInitialState
    testWidgets("Validate initial state", (WidgetTester tester) async {
      // Given
      when(() => forgotPasswordBloc.stream)
          .thenAnswer((_) => Stream.fromIterable([const ForgotPasswordInitialState()]));
      when(() => forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();

      //Then:
      expect(find.text('Forgot Password'), findsNWidgets(2));
    });

    // ForgotPasswordLoadingState
    testWidgets("Validate loading state", (WidgetTester tester) async {
      // Given
      when(() => forgotPasswordBloc.stream)
          .thenAnswer((_) => Stream.fromIterable([const ForgotPasswordLoadingState()]));
      when(() => forgotPasswordBloc.state).thenReturn(const ForgotPasswordLoadingState());
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pump(); //AndSettle(const Duration(milliseconds: 1000));

      //Then:
      // expect(find.text("Loading..."), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    // ForgotPasswordSuccessState
    testWidgets("Validate success state", (WidgetTester tester) async {
      // Given
      when(() => forgotPasswordBloc.stream)
          .thenAnswer((_) => Stream.fromIterable([const ForgotPasswordCompletedState(email: 'test@example.com')]));
      when(() => forgotPasswordBloc.state).thenReturn(const ForgotPasswordCompletedState(email: 'test@example.com'));
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pump(); //AndSettle(const Duration(milliseconds: 1000));

      //Then:
      verifyNever(() => forgotPasswordBloc.add(any()));
    });

    // ForgotPasswordFailureState
    testWidgets("Validate failure state", (WidgetTester tester) async {
      // Given
      when(() => forgotPasswordBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([const ForgotPasswordErrorState(email: 'test@example.com', errorMessage: 'Failed')]),
      );
      when(() => forgotPasswordBloc.state)
          .thenReturn(const ForgotPasswordErrorState(email: 'test@example.com', errorMessage: 'Failed'));
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();

      //Then:
      //expect(find.text("Failed"), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
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
      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmitKey);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();
      //Then:
      expect(find.text(S.current.required_field), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    // Send Email  Button Test Success
    testWidgets("Validate send email button Successful", (WidgetTester tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();

      final emailFinder = find.byKey(forgotPasswordTextFieldEmailKey);
      await tester.enterText(emailFinder, "test@test.com");

      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmitKey);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      //Then:
      verify(() => forgotPasswordBloc.add(any(that: isA<ForgotPasswordEmailChanged>()))).called(1);
    });

    // Send Email  Button Test Success
    testWidgets("Validate send email button invalid email fail", (tester) async {
      // Given:

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();

      final emailFinder = find.byKey(forgotPasswordTextFieldEmailKey);
      await tester.enterText(emailFinder, "invalid-email");

      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmitKey);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      //Then:
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      verifyNever(() => forgotPasswordBloc.add(any()));
    });

    // Send Email  Button Test Success
    testWidgets("Validate send email button empty email fail", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();

      final emailFinder = find.byKey(forgotPasswordTextFieldEmailKey);
      await tester.enterText(emailFinder, "");

      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmitKey);
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      //Then:
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      verifyNever(() => forgotPasswordBloc.add(any()));
    });
  });
  group('ForgotPasswordScreen - Turkish', () {
    testWidgets('shows the description in Turkish', (tester) async {
      await tester.pumpWidget(getWidget(locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(
        find.text('E-posta adresinizi girin, şifrenizi sıfırlamanız için size bir bağlantı gönderelim.'),
        findsOneWidget,
      );
    });
  });

  // Regression: asking for a password reset on a network whose certificate matches no pin said "Failed", as if the
  // email were wrong.
  testWidgets('tells the user the connection was blocked when the certificate matches no pin', (tester) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final adapter = _PinMismatchAdapter();
    await tester.pumpWidget(App(language: 'en', dependencies: _PinnedDependencies(adapter)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(loginButtonForgotPasswordKey));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(forgotPasswordTextFieldEmailKey), 'jane.doe@example.com');
    await tester.tap(find.byKey(forgotPasswordButtonSubmitKey));

    // The reason is a sentence, so it stays for the default 4 s, while the loading notice keeps its second.
    expect(await _snackBars(tester), {
      S.current.loading: const Duration(seconds: 1),
      S.current.error_network_cert_invalid: const Duration(seconds: 4),
    });
    // The lifecycle check reads the app config when the app starts.
    expect(adapter.requests, ['GET /app/config', 'POST /account/reset-password/init']);
  });
}

/// Sits in the slot of the certificate-pinning adapter and fails every request the way it fails a server whose
/// certificate matches no configured pin.
class _PinMismatchAdapter implements HttpClientAdapter {
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    throw const CertificatePinningException('api.example.test', 443);
  }

  @override
  void close({bool force = false}) {}
}

/// Production dependencies with certificate pinning configured and [adapter] in the slot of the pinning adapter.
class _PinnedDependencies extends AppDependencies {
  _PinnedDependencies(this.adapter)
    : super(
        appConfig: const AppConfig(
          environment: Environment.prod,
          apiBaseUrl: 'https://api.example.test',
          certificatePins: ['test-pin'],
          idleTimeout: null,
        ),
      );

  final HttpClientAdapter adapter;

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      super.createApiClient(secureStorage, onSessionExpired: onSessionExpired)..instance.httpClientAdapter = adapter;
}

/// Pumps for [duration] and collects the text and the display duration of every snack bar shown meanwhile. The page
/// queues its snack bars, so one only shows once the one before it has gone.
Future<Map<String, Duration>> _snackBars(WidgetTester tester, {Duration duration = const Duration(seconds: 5)}) async {
  final snackBars = <String, Duration>{};
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
    for (final snackBar in tester.widgetList<SnackBar>(find.byType(SnackBar))) {
      snackBars[(snackBar.content as Text).data!] = snackBar.duration;
    }
  }
  return snackBars;
}
