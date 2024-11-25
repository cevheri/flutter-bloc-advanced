import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/register_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils.dart';

class MockBuildContext extends Mock implements BuildContext {}

// class MockRegisterBloc extends Mock implements RegisterBloc {}

class MockNavigator extends Mock implements NavigatorObserver {}

class MockAccountBloc extends Mock implements AccountBloc {
  @override
  Stream<AccountState> get stream => Stream.fromIterable([const AccountState(status: AccountStatus.initial)]);

  @override
  AccountState get state => const AccountState(status: AccountStatus.initial);
}

// class MockRegisterBloc extends Mock implements RegisterBloc {
//   @override
//   Stream<RegisterState> get stream => Stream.fromIterable([RegisterInitialState()]);

//   @override
//   RegisterState get state => RegisterInitialState();
// }

class MockRegisterBloc extends Mock implements RegisterBloc {
  final _controller = StreamController<RegisterState>.broadcast();

  @override
  Stream<RegisterState> get stream => _controller.stream;

  void emitState(RegisterState state) {
    _controller.add(state);
  }

  void dispose() {
    _controller.close();
  }
}

///Register User Screen Test
///class RegisterScreen extends StatelessWidget
void main() {
  //region setup

  late RegisterBloc mockRegisterBloc;
  late AccountBloc mockAccountBloc;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    registerFallbackValue(MockBuildContext());
    registerFallbackValue(MockRegisterBloc());
    registerFallbackValue(const RegisterFormSubmitted(createUser: User()));
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  setUp(() {
    mockRegisterBloc = MockRegisterBloc();
    Get.testMode = true;
    mockAccountBloc = MockAccountBloc();
  });

  final blocs = [
    BlocProvider<AccountBloc>(create: (_) => AccountBloc(accountRepository: AccountRepository())),
    BlocProvider<RegisterBloc>(create: (_) => RegisterBloc(accountRepository: AccountRepository())),
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: RegisterScreen(),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      expect(find.byType(ElevatedButton), findsOneWidget);
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
      await tester.tap(find.byType(ElevatedButton));
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
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(Get.currentRoute, "/");
    });

    //validate app-bar back button
    /// Tests the back button functionality in the app bar
    ///
    /// Verifies that:
    /// - Back button icon is clickable
    /// - When clicked, navigates to login route ("/login")
    /// - Navigation occurs successfully
    testWidgets("Validate AppBar Back Button", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      //Then:
      expect(Get.currentRoute, "/");
    });
  });

  // testWidgets('should rebuild when state changes from loading to initial', (WidgetTester tester) async {
  //   // Arrange
  //   final previousState = RegisterState();
  //   final currentState = RegisterInitialState();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: BlocProvider<RegisterBloc>.value(
  //         value: mockRegisterBloc,
  //         child: BlocBuilder<RegisterBloc, RegisterState>(
  //           buildWhen: (previous, current) =>
  //             previous is RegisterState && current is RegisterInitialState,
  //           builder: (context, state) => const SizedBox(),
  //         ),
  //       ),
  //     ),
  //   );

  //   // Act & Assert
  //   final bool shouldRebuild = tester
  //       .widget<BlocBuilder<RegisterBloc, RegisterState>>(
  //         find.byType(BlocBuilder<RegisterBloc, RegisterState>)
  //       )
  //       .buildWhen!(previousState, currentState);

  //   expect(shouldRebuild, true);
  // });

  // testWidget("RegisterCompletedState", (tester) async {
  //   TestUtils().setupAuthentication();
  //   await tester.pumpWidget(getWidget());
  //   await tester.pumpAndSettle();
  // });

  //email validation test
  testWidgets('Email validation test', (WidgetTester tester) async {
    TestUtils().setupAuthentication();
    // Arrange
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: MultiBlocProvider(
          providers: blocs,
          child: RegisterScreen(),
        ),
      ),
    );
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
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: MultiBlocProvider(
          providers: blocs,
          child: RegisterScreen(),
        ),
      ),
    );
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
    await tester.pumpWidget(
      GetMaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: MultiBlocProvider(
          providers: blocs,
          child: RegisterScreen(),
        ),
      ),
    );
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
    //await TestUtils().setupAuthentication();
    await tester.pumpWidget(
      GetMaterialApp(
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

    const User user = User(firstName: "test", lastName: "test", email: "test@test.com");
    when(() => mockRegisterBloc.add(const RegisterFormSubmitted(createUser: user))).thenReturn(null);
    //verify(() => mockRegisterBloc.add(any())).called(1);

    //when submitButton clicked then expect an error
    await tester.tap(find.byKey(registerSubmitButtonKey));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, "/");

    // final saveButton = find.byKey(registerSubmitButtonKey);
    // await tester.tap(saveButton);
    // await tester.pump();

    //expect(find.text('required_field'), findsNWidgets(3));

    //
    // await tester.tap(saveButton);
    // await tester.pump();
    //
    // when(() => mockRegisterBloc.add(any())).thenReturn(null);
    // verify(() => mockRegisterBloc.add(any())).called(1);

    // when(() => mockRegisterBloc.state).thenReturn(RegisterInitialState());
    // await tester.pump();
    // expect(find.text('Loading'), findsOneWidget);

    //when(() => mockRegisterBloc.state).thenReturn(RegisterCompletedState());
    //await tester.pump();
    //expect(find.text('Success'), findsOneWidget);

    // when(() => mockRegisterBloc.state).thenReturn(RegisterErrorState(message: 'Error'));
    // await tester.pump();
    // expect(find.text('Error'), findsOneWidget);
  });
}
