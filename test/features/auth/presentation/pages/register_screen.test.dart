import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../test_utils.dart';

///Register User Screen Test
///class RegisterScreen extends StatelessWidget
void main() {
  //region setup

  late MockRegisterBloc mockRegisterBloc;
  late MockAccountBloc mockAccountBloc;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    registerAllFallbackValues();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  setUp(() {
    mockRegisterBloc = MockRegisterBloc();
    mockAccountBloc = MockAccountBloc();

    when(() => mockRegisterBloc.stream).thenAnswer((_) => Stream.fromIterable([const RegisterInitialState()]));
    when(() => mockRegisterBloc.state).thenReturn(const RegisterInitialState());

    when(() => mockAccountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(() => mockAccountBloc.state).thenReturn(const AccountState());
  });

  final Iterable<LocalizationsDelegate<dynamic>> locales = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  MaterialApp getWidget() {
    return MaterialApp(
      localizationsDelegates: locales,
      supportedLocales: S.delegate.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AccountBloc>.value(value: mockAccountBloc),
          BlocProvider<RegisterBloc>.value(value: mockRegisterBloc),
        ],
        child: RegisterScreen(),
      ),
    );
  }
  //endregion setup

  //validate AppBar and back button
  group("RegisterScreen Test", () {
    testWidgets("Validate AppBar", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title
      expect(find.text("Register"), findsNWidgets(1));
      expect(find.text("Save"), findsNWidgets(1));
      // back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    //validate form fields
    testWidgets("Validate Form Fields", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsNWidgets(3));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    //validate form fields enter text
    testWidgets("Validate Form Fields Enter Text", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.enterText(find.byType(FormBuilderTextField).first, "test");
      await tester.enterText(find.byType(FormBuilderTextField).at(1), "test");
      await tester.enterText(find.byType(FormBuilderTextField).last, "test@test.com");
    });

    //validate submit button
    testWidgets("Validate Submit Button", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    });

    //validate form fields enter text
    testWidgets("Validate Form Fields Enter Text and submit", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.enterText(find.byKey(registerFirstNameTextFieldKey), "test");
      await tester.enterText(find.byKey(registerLastNameTextFieldKey), "test");
      await tester.enterText(find.byKey(registerEmailTextFieldKey), "test@test.com");

      //when submitButton clicked then expect an error
      await tester.tap(find.byKey(registerSubmitButtonKey));
      await tester.pump(); //AndSettle(const Duration(seconds: 3));

      //TODO check with go_router expect(Get.currentRoute, "/");
    });

    //validate app-bar back button
    testWidgets("Validate AppBar Back Button", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      //Then:
      //TODO check with go_router expect(Get.currentRoute, "/");
    });
  });

  //email validation test
  testWidgets('Email validation test', (WidgetTester tester) async {
    TestUtils().setupAuthentication();
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final emailFieldFinder = find.byKey(registerEmailTextFieldKey);

    // Test empty email
    await tester.enterText(emailFieldFinder, '');
    await tester.pump();

    FormBuilderTextField emailField = tester.widget(emailFieldFinder);
    String? emptyResult = emailField.validator?.call('');
    expect(emptyResult, isNotNull);
    expect(emptyResult, 'Required Field');

    // Test invalid email
    await tester.enterText(emailFieldFinder, 'invalid-email');
    await tester.pump();

    String? invalidResult = emailField.validator?.call('invalid-email');
    expect(invalidResult, isNotNull);
    expect(invalidResult, 'Email must be a valid email address');

    // Test valid email
    await tester.enterText(emailFieldFinder, 'test@example.com');
    await tester.pump();

    String? validResult = emailField.validator?.call('test@example.com');
    expect(validResult, isNull);
  });

  //first name validation test
  testWidgets('First Name validation test', (WidgetTester tester) async {
    TestUtils().setupAuthentication();
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final firstNameFieldFinder = find.byKey(registerFirstNameTextFieldKey);

    // Test empty first name
    await tester.enterText(firstNameFieldFinder, '');
    await tester.pump();

    FormBuilderTextField firstNameField = tester.widget(firstNameFieldFinder);
    String? emptyResult = firstNameField.validator?.call('');
    expect(emptyResult, isNotNull);
    expect(emptyResult, 'Required Field');

    // Test valid first name
    await tester.enterText(firstNameFieldFinder, 'test');
    await tester.pump();

    String? validResult = firstNameField.validator?.call('test');
    expect(validResult, isNull);
  });

  //last name validation test
  testWidgets('Last Name validation test', (WidgetTester tester) async {
    TestUtils().setupAuthentication();
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final lastNameFieldFinder = find.byKey(registerLastNameTextFieldKey);

    // Test empty last name
    await tester.enterText(lastNameFieldFinder, '');
    await tester.pump();

    FormBuilderTextField lastNameField = tester.widget(lastNameFieldFinder);
    String? emptyResult = lastNameField.validator?.call('');
    expect(emptyResult, isNotNull);
    expect(emptyResult, 'Required Field');

    // Test valid last name
    await tester.enterText(lastNameFieldFinder, 'test');
    await tester.pump();

    String? validResult = lastNameField.validator?.call('test');
    expect(validResult, isNull);
  });

  testWidgets('Register form validation and submission test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<RegisterBloc>.value(value: mockRegisterBloc),
            BlocProvider<AccountBloc>.value(value: mockAccountBloc),
          ],
          child: RegisterScreen(),
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(registerFirstNameTextFieldKey), "test");
    await tester.enterText(find.byKey(registerLastNameTextFieldKey), "test");
    await tester.enterText(find.byKey(registerEmailTextFieldKey), "test@test.com");

    //when submitButton clicked then expect an error
    await tester.tap(find.byKey(registerSubmitButtonKey));
    await tester.pumpAndSettle();
  });

  // loading state test
  testWidgets('Register loading state test', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final firstNameFieldFinder = find.byKey(registerFirstNameTextFieldKey);
    final lastNameFieldFinder = find.byKey(registerLastNameTextFieldKey);
    final emailFieldFinder = find.byKey(registerEmailTextFieldKey);

    await tester.enterText(firstNameFieldFinder, 'test');
    await tester.enterText(lastNameFieldFinder, 'test');
    await tester.enterText(emailFieldFinder, 'test@test.com');

    when(() => mockRegisterBloc.state).thenReturn(const RegisterLoadingState());
    await tester.pump();

    final saveButton = find.byKey(registerSubmitButtonKey);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  //loaded state test
  testWidgets('Register loaded state test', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final firstNameFieldFinder = find.byKey(registerFirstNameTextFieldKey);
    final lastNameFieldFinder = find.byKey(registerLastNameTextFieldKey);
    final emailFieldFinder = find.byKey(registerEmailTextFieldKey);

    await tester.enterText(firstNameFieldFinder, 'test');
    await tester.enterText(lastNameFieldFinder, 'test');
    await tester.enterText(emailFieldFinder, 'test@test.com');

    when(() => mockRegisterBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const RegisterCompletedState(
          user: User(firstName: 'test', lastName: 'test', email: 'test@test.com'),
        ),
      ]),
    );
    when(() => mockRegisterBloc.state).thenReturn(
      const RegisterCompletedState(
        user: User(firstName: 'test', lastName: 'test', email: 'test@test.com'),
      ),
    );

    final saveButton = find.byKey(registerSubmitButtonKey);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 3000));

    verify(
      () => mockRegisterBloc.add(
        const RegisterFormSubmitted(
          data: User(firstName: 'test', lastName: 'test', email: 'test@test.com'),
        ),
      ),
    ).called(1);
  });

  //error state test
  testWidgets('Register error state test', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final firstNameFieldFinder = find.byKey(registerFirstNameTextFieldKey);
    final lastNameFieldFinder = find.byKey(registerLastNameTextFieldKey);
    final emailFieldFinder = find.byKey(registerEmailTextFieldKey);

    await tester.enterText(firstNameFieldFinder, '');
    await tester.enterText(lastNameFieldFinder, '');
    await tester.enterText(emailFieldFinder, 'test@test.com');

    when(
      () => mockRegisterBloc.stream,
    ).thenAnswer((_) => Stream.fromIterable([const RegisterErrorState(message: 'Error')]));
    when(() => mockRegisterBloc.state).thenReturn(const RegisterErrorState(message: 'Error'));

    final saveButton = find.byKey(registerSubmitButtonKey);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 3000));

    expect(find.byType(RegisterScreen), findsOneWidget);
    verifyNever(
      () => mockRegisterBloc.add(
        const RegisterFormSubmitted(
          data: User(firstName: 'test', lastName: 'test', email: 'test@test.com'),
        ),
      ),
    );
  });
}
