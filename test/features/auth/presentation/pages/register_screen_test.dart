@Tags(['widget'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/unsaved_changes_host.dart';

void main() {
  late MockRegisterBloc mockRegisterBloc;
  late MockAccountBloc mockAccountBloc;
  late GoRouter router;

  // Test user data
  const testUser = UserEntity(firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com');

  setUp(() {
    mockRegisterBloc = MockRegisterBloc();
    mockAccountBloc = MockAccountBloc();

    // Setup router with necessary routes
    router = GoRouter(
      initialLocation: ApplicationRoutesConstants.register,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.register,
          onExit: confirmLeavingUnsavedChanges,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<RegisterBloc>.value(value: mockRegisterBloc),
              BlocProvider<AccountBloc>.value(value: mockAccountBloc),
            ],
            child: RegisterScreen(),
          ),
        ),
        GoRoute(path: ApplicationRoutesConstants.home, builder: (context, state) => const SizedBox()),
      ],
    );

    // Setup default bloc behaviors
    when(() => mockRegisterBloc.stream).thenAnswer((_) => Stream.fromIterable([const RegisterInitialState()]));
    when(() => mockRegisterBloc.state).thenReturn(const RegisterInitialState());
    when(() => mockAccountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(() => mockAccountBloc.state).thenReturn(const AccountState());
  });

  Widget createWidgetUnderTest({Locale locale = const Locale('en')}) {
    return withUnsavedChangesRegistry(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }

  group('RegisterScreen Initial UI Tests', () {
    testWidgets('should display all required form fields and buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify AppBar elements
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Verify form fields
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('registerSubmitButtonKey')), findsOneWidget);
    });
  });

  group('Form Validation Tests', () {
    testWidgets('should show validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Submit empty form
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text('Required Field'), findsNWidgets(3));
    });

    testWidgets('should validate email format correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - Enter invalid email
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'invalid-email');
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pump();

      // Assert - Should show validation error
      expect(find.text('Required Field'), findsAtLeast(1));

      // Act - Enter valid email, first name and last name
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'valid@email.com');
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'John');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Doe');
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pump();

      // Assert - Error should be gone
      expect(find.text('Required Field'), findsNothing);
    });
  });

  group('Form Submission Tests', () {
    testWidgets('should handle successful registration', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), testUser.firstName!);
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), testUser.lastName!);
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), testUser.email!);

      // Setup success state
      when(() => mockRegisterBloc.state).thenReturn(const RegisterCompletedState(user: testUser));

      // Submit form
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pumpAndSettle();

      // Verify bloc interaction
      verify(() => mockRegisterBloc.add(const RegisterFormSubmitted(data: testUser))).called(1);
    });

    testWidgets('should show loading indicator during submission', (tester) async {
      // Setup bloc with broadcast stream to allow multiple listeners
      final controller = StreamController<RegisterState>.broadcast();
      when(() => mockRegisterBloc.stream).thenAnswer((_) => controller.stream);
      when(() => mockRegisterBloc.state).thenReturn(const RegisterInitialState());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), testUser.firstName!);
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), testUser.lastName!);
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), testUser.email!);

      // Change to loading state
      when(() => mockRegisterBloc.state).thenReturn(const RegisterLoadingState());
      controller.add(const RegisterLoadingState());

      // Submit form
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pump(); // For form submission
      await tester.pump(); // For state change

      // Verify loading state
      final submitButton = tester.widget<ResponsiveSubmitButton>(find.byKey(const Key('registerSubmitButtonKey')));
      expect(submitButton.isLoading, true);

      // Clean up
      await controller.close();
    });

    testWidgets('should handle registration error', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Setup error state
      const errorMessage = 'Registration failed';
      when(() => mockRegisterBloc.state).thenReturn(const RegisterErrorState(message: errorMessage));

      // Submit form
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pumpAndSettle();

      expect(find.text('Failed'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('should handle back navigation with clean form', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should navigate to home without showing dialog
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should show confirmation dialog when form is dirty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Make form dirty
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'John');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('You have unsaved changes. Are you sure you want to leave?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });
  });

  group('State Management Integration Tests', () {
    testWidgets('should handle complete registration flow', (tester) async {
      // Arrange
      final controller = StreamController<RegisterState>.broadcast();
      when(() => mockRegisterBloc.stream).thenAnswer((_) => controller.stream);
      when(() => mockRegisterBloc.state).thenReturn(const RegisterInitialState());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), testUser.firstName!);
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), testUser.lastName!);
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), testUser.email!);

      // Submit form and emit loading state
      when(() => mockRegisterBloc.state).thenReturn(const RegisterLoadingState());
      controller.add(const RegisterLoadingState());
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pump();

      // Verify loading state
      final loadingButton = tester.widget<ResponsiveSubmitButton>(find.byKey(const Key('registerSubmitButtonKey')));
      expect(loadingButton.isLoading, true);

      // Emit success state
      when(() => mockRegisterBloc.state).thenReturn(const RegisterCompletedState(user: testUser));
      controller.add(const RegisterCompletedState(user: testUser));
      await tester.pump();
      await tester.pump(); // Additional pump for state update

      // Verify success state
      verify(() => mockRegisterBloc.add(const RegisterFormSubmitted(data: testUser))).called(1);
      // Clean up
      await controller.close();
    });
  });
  group('RegisterScreen - Turkish', () {
    testWidgets('shows the subtitle and the save button in Turkish', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text('Hesabınızı oluşturun'), findsOneWidget);
      expect(find.descendant(of: find.byType(ResponsiveSubmitButton), matching: find.text('Kaydet')), findsOneWidget);
    });
  });

  // Regression: registering on a network whose certificate matches no pin said "Failed", as if the form were wrong.
  testWidgets('tells the user the connection was blocked when the certificate matches no pin', (tester) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final adapter = _PinMismatchAdapter();
    await tester.pumpWidget(App(language: 'en', dependencies: _PinnedDependencies(adapter)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(loginButtonRegisterKey));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Jane');
    await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Doe');
    await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), 'jane.doe@example.com');
    await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));

    // The reason is a sentence, so it stays for the default 4 s, while the loading notice keeps its second.
    expect(await _snackBars(tester), {
      S.current.loading: const Duration(seconds: 1),
      S.current.error_network_cert_invalid: const Duration(seconds: 4),
    });
    // The lifecycle check reads the app config when the app starts.
    expect(adapter.requests, ['GET /app/config', 'POST /register']);
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
