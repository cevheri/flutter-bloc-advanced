import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/register_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'register_screen_go_router_test.mocks.dart';

@GenerateMocks([RegisterBloc, AccountBloc])
void main() {
  late MockRegisterBloc mockRegisterBloc;
  late MockAccountBloc mockAccountBloc;
  late GoRouter router;

  // Test user data
  const testUser = User(firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com');

  setUp(() {
    mockRegisterBloc = MockRegisterBloc();
    mockAccountBloc = MockAccountBloc();

    // Setup router with necessary routes
    router = GoRouter(
      initialLocation: ApplicationRoutesConstants.register,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.register,
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
    when(
      mockRegisterBloc.stream,
    ).thenAnswer((_) => Stream.fromIterable([const RegisterState(status: RegisterStatus.initial)]));
    when(mockRegisterBloc.state).thenReturn(const RegisterState(status: RegisterStatus.initial));
    when(mockAccountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(mockAccountBloc.state).thenReturn(const AccountState());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
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
      when(mockRegisterBloc.state).thenReturn(const RegisterCompletedState(user: testUser));

      // Submit form
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pumpAndSettle();

      // Verify bloc interaction
      verify(mockRegisterBloc.add(const RegisterFormSubmitted(data: testUser))).called(1);
      // expect(find.text('Success'), findsOneWidget);
    });

    testWidgets('should show loading indicator during submission', (tester) async {
      // Arrange
      // final blocStates = [
      //   const RegisterState(status: RegisterStatus.initial),
      //   const RegisterState(status: RegisterStatus.loading),
      // ];

      // Setup bloc with broadcast stream to allow multiple listeners
      final controller = StreamController<RegisterState>.broadcast();
      when(mockRegisterBloc.stream).thenAnswer((_) => controller.stream);
      when(mockRegisterBloc.state).thenReturn(const RegisterState(status: RegisterStatus.initial));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), testUser.firstName!);
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), testUser.lastName!);
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), testUser.email!);

      // Change to loading state
      when(mockRegisterBloc.state).thenReturn(const RegisterState(status: RegisterStatus.loading));
      controller.add(const RegisterState(status: RegisterStatus.loading));

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
      when(mockRegisterBloc.state).thenReturn(const RegisterErrorState(message: errorMessage));

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
      when(mockRegisterBloc.stream).thenAnswer((_) => controller.stream);
      when(mockRegisterBloc.state).thenReturn(const RegisterState(status: RegisterStatus.initial));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), testUser.firstName!);
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), testUser.lastName!);
      await tester.enterText(find.byKey(const Key('userEditorEmailFieldKey')), testUser.email!);

      // Submit form and emit loading state
      when(mockRegisterBloc.state).thenReturn(const RegisterState(status: RegisterStatus.loading));
      controller.add(const RegisterState(status: RegisterStatus.loading));
      await tester.tap(find.byKey(const Key('registerSubmitButtonKey')));
      await tester.pump();

      // Verify loading state
      final loadingButton = tester.widget<ResponsiveSubmitButton>(find.byKey(const Key('registerSubmitButtonKey')));
      expect(loadingButton.isLoading, true);

      // Emit success state
      when(mockRegisterBloc.state).thenReturn(const RegisterCompletedState(user: testUser));
      controller.add(const RegisterCompletedState(user: testUser));
      await tester.pump();
      await tester.pump(); // Additional pump for state update

      // Verify success state
      //expect(find.text('Success'), findsOneWidget);
      verify(mockRegisterBloc.add(const RegisterFormSubmitted(data: testUser))).called(1);
      // Clean up
      await controller.close();
    });
  });
}
