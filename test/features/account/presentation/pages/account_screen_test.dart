import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../test_utils.dart';

void main() {
  late MockAccountBloc mockAccountBloc;
  late MockUserBloc mockUserBloc;
  late TestUtils testUtils;
  late StreamController<AccountState> accountStateController;
  late StreamController<UserState> userStateController;

  // Mock user data for testing
  const mockUser = User(
    id: 'test-1',
    login: 'testuser',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    activated: true,
  );

  setUpAll(() {
    registerAllFallbackValues();
  });

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    // Initialize mock blocs and controllers
    mockAccountBloc = MockAccountBloc();
    mockUserBloc = MockUserBloc();

    accountStateController = StreamController<AccountState>.broadcast();
    userStateController = StreamController<UserState>.broadcast();

    // Setup stream responses
    when(() => mockAccountBloc.stream).thenAnswer((_) => accountStateController.stream);
    when(() => mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
    await accountStateController.close();
    await userStateController.close();
  });

  // Helper method to build the widget under test
  Widget buildTestableWidget() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => Scaffold(body: AccountScreen()),
        ),
      ],
      initialLocation: '/account',
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountBloc>.value(value: mockAccountBloc),
        BlocProvider<UserBloc>.value(value: mockUserBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
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

  group('AccountScreen Basic UI Tests', () {
    testWidgets('Should render back button and title correctly', (tester) async {
      // ARRANGE
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ASSERT - AccountScreen now uses a Row with IconButton + Text instead of AppBar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text(S.current.account), findsOneWidget);
      expect(find.byKey(const Key('accountScreenAppBarBackButtonKey')), findsOneWidget);
    });

    testWidgets('Should render form fields correctly', (tester) async {
      when(() => mockAccountBloc.state).thenReturn(const AccountState(data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byKey(const Key('userEditorFirstNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorLastNameFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorEmailFieldKey')), findsOneWidget);
      expect(find.byKey(const Key('userEditorActivatedFieldKey')), findsNothing);
    });
  });

  group('AccountScreen State Tests', () {
    testWidgets('Should display loading indicator when in loading state', (tester) async {
      // ARRANGE
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.loading));

      // Make sure the stream also emits the loading state
      accountStateController.add(const AccountState(status: AccountStatus.loading));

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // ASSERT
    });

    // Add a test to verify state transitions
    testWidgets('Should handle loading to success state transition', (tester) async {
      // ARRANGE
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.loading));

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Success durumuna geçiş
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      accountStateController.add(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpAndSettle();

      // Success durumunu kontrol et
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('AccountScreen Form Operations', () {
    testWidgets('Should show warning when save button is pressed without changes', (tester) async {
      when(() => mockAccountBloc.state).thenReturn(const AccountState(data: mockUser, status: AccountStatus.success));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(find.text(S.current.no_changes_made), findsOneWidget);
    });

    testWidgets('Should not submit when form validation fails', (tester) async {
      when(() => mockAccountBloc.state).thenReturn(const AccountState(data: mockUser, status: AccountStatus.success));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), '');
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      verifyNever(() => mockUserBloc.add(any()));
    });
  });

  group('AccountScreen Navigation Tests', () {
    testWidgets('Should exit directly when back button is pressed without changes', (tester) async {
      when(() => mockAccountBloc.state).thenReturn(const AccountState(data: mockUser, status: AccountStatus.success));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });
  });

  group('AccountScreen Form Operations', () {
    testWidgets('Given form with changes When submit button is pressed Then should handle submission successfully', (
      tester,
    ) async {
      // ARRANGE
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Modify form fields
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Updated First');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Updated Last');

      // Tap submit button
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      // Verify AccountSubmitEvent was called with correct data
      verify(() => mockAccountBloc.add(any())).called(2);
    });

    testWidgets('Given form submission When server returns error Then should display failure message', (tester) async {
      // ARRANGE - Set up initial successful state
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ACT - Make form changes
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Updated First');

      // Submit the form
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      // Trigger failure state
      accountStateController.add(const AccountState(status: AccountStatus.failure, data: mockUser));

      // Wait for SnackBar animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // ASSERT - Verify SnackBar is visible with error message
      expect(
        find.descendant(of: find.byType(SnackBar), matching: find.text(S.current.failed)),
        findsOneWidget,
        reason: 'SnackBar should be visible with failure message',
      );
    });

    // Alternative approach using ScaffoldMessenger
    testWidgets('Given form submission When server returns error Then should show error in SnackBar', (tester) async {
      // ARRANGE - Initialize widget with success state
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ACT - Simulate form changes and submission
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Updated First');

      // Trigger form submission
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      // Emit failure state
      accountStateController.add(const AccountState(status: AccountStatus.failure, data: mockUser));

      // Wait for SnackBar animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ASSERT - Verify SnackBar is visible with error message
      expect(find.byType(SnackBar), findsOneWidget, reason: 'SnackBar should be visible');

      expect(
        find.descendant(of: find.byType(SnackBar), matching: find.text(S.current.failed)),
        findsOneWidget,
        reason: 'SnackBar should display failure message',
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final snackBarText = (snackBar.content as Text).data;
      expect(snackBarText, equals(S.current.failed));
    });
  });

  group('AccountScreen Navigation Tests', () {
    testWidgets('Should show confirmation dialog when back button is pressed with changes', (tester) async {
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Changed Name');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text(S.current.warning), findsOneWidget);
    });
  });

  group('AccountScreen State Management Tests', () {
    testWidgets('Should show snackbar messages for different states', (tester) async {
      // ARRANGE - Set up initial state
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // ACT & ASSERT - Test loading state
      accountStateController.add(const AccountState(status: AccountStatus.loading));

      // Wait for state change to be processed
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify loading indicator in button using more specific finder
      expect(
        find.descendant(of: find.byType(ResponsiveSubmitButton), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'Should show loading indicator in submit button',
      );

      // Verify loading message
      expect(find.text(S.current.loading), findsOneWidget, reason: 'Should show loading message');

      // Test success state
      accountStateController.add(const AccountState(status: AccountStatus.success));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify success state
      expect(
        find.descendant(of: find.byType(ResponsiveSubmitButton), matching: find.byType(CircularProgressIndicator)),
        findsNothing,
        reason: 'Should not show loading indicator',
      );

      // Test failure state
      accountStateController.add(const AccountState(status: AccountStatus.failure));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify failure state
      expect(
        find.descendant(of: find.byType(ResponsiveSubmitButton), matching: find.byType(CircularProgressIndicator)),
        findsNothing,
        reason: 'Should not show loading indicator',
      );
    });

    testWidgets('Should show snackbar messages for different states2', (tester) async {
      // ARRANGE - Set up initial state
      when(() => mockAccountBloc.state).thenReturn(const AccountState(status: AccountStatus.success, data: mockUser));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // ACT & ASSERT - Test loading state
      accountStateController.add(const AccountState(status: AccountStatus.loading));

      // Wait for state change and animations
      await tester.pump(); // Build frame
      await tester.pump(); // Start SnackBar animation
      await tester.pump(const Duration(milliseconds: 750)); // Animation midpoint

      // Verify loading state
      expect(
        find.descendant(of: find.byType(ResponsiveSubmitButton), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'Should show loading indicator in submit button',
      );

      expect(
        find.descendant(of: find.byType(ScaffoldMessenger), matching: find.text(S.current.loading)),
        findsOneWidget,
        reason: 'Should show loading message in SnackBar',
      );

      // Test success state
      accountStateController.add(const AccountState(status: AccountStatus.success));
      await tester.pump(); // Build frame
      await tester.pump(); // Start SnackBar animation
      await tester.pump(const Duration(milliseconds: 750)); // Animation midpoint

      var snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      var snackBarText = (snackBar.content as Text).data;
      expect(snackBarText, equals(S.current.loading));

      // Test failure state
      accountStateController.add(const AccountState(status: AccountStatus.failure));
      await tester.pump(); // Build frame
      await tester.pump(); // Start SnackBar animation
      await tester.pump(const Duration(milliseconds: 750)); // Animation midpoint

      snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      snackBarText = (snackBar.content as Text).data;
      expect(snackBarText, equals(S.current.loading));
    });
  });
}
