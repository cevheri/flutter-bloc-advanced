import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/bloc/forgot_password.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'forgot_password_screen_test.mocks.dart';

///Forgot Password Screen Test
///class ForgotPasswordScreen extends
@GenerateMocks([ForgotPasswordBloc, AccountBloc])
void main() {
  late MockForgotPasswordBloc forgotPasswordBloc;
  late MockAccountBloc accountBloc;

  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  setUp(() {
    forgotPasswordBloc = MockForgotPasswordBloc();
    accountBloc = MockAccountBloc();

    when(
      forgotPasswordBloc.stream,
    ).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordState(status: ForgotPasswordStatus.initial)]));
    when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordState(status: ForgotPasswordStatus.initial));

    when(accountBloc.stream).thenAnswer((_) => Stream.fromIterable([const AccountState()]));
    when(accountBloc.state).thenReturn(const AccountState());
  });

  final Iterable<LocalizationsDelegate<dynamic>> locales = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      localizationsDelegates: locales,
      supportedLocales: S.delegate.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AccountBloc>(create: (context) => accountBloc),
          BlocProvider<ForgotPasswordBloc>(create: (context) => forgotPasswordBloc),
        ],
        child: ForgotPasswordScreen(),
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
      // appBar title"
      expect(find.text('Forgot Password'), findsOneWidget);
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
      when(forgotPasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordInitialState()]));
      when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordInitialState());
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();

      //Then:
      expect(find.text('Forgot Password'), findsOneWidget);
    });

    // ForgotPasswordLoadingState
    testWidgets("Validate loading state", (WidgetTester tester) async {
      // Given
      when(
        forgotPasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordState(status: ForgotPasswordStatus.loading)]));
      when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordState(status: ForgotPasswordStatus.loading));
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
      when(
        forgotPasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordState(status: ForgotPasswordStatus.success)]));
      when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordState(status: ForgotPasswordStatus.success));
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pump(); //AndSettle(const Duration(milliseconds: 1000));

      //Then:
      //expect(find.text("Success"), findsOneWidget);
      //expect(find.byType(ForgotPasswordScreen), findsNothing);
      verifyNever(forgotPasswordBloc.add(any));
    });

    // ForgotPasswordFailureState
    testWidgets("Validate failure state", (WidgetTester tester) async {
      // Given
      when(
        forgotPasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordErrorState(message: "Failed")]));
      when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordErrorState(message: "Failed"));
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

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
      await tester.pumpAndSettle(const Duration(seconds: 5));
      //Then:
      expect(find.text(S.current.required_field), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    // Send Email  Button Test Success
    testWidgets("Validate send email button Successful", (WidgetTester tester) async {
      when(
        forgotPasswordBloc.add(const ForgotPasswordEmailChanged(email: "test@test.com")),
      ).thenAnswer((_) => const ForgotPasswordCompletedState());

      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();

      final screenFinder = find.byType(ForgotPasswordScreen);
      debugPrint("screenFinder: $screenFinder");

      final emailFinder = find.byKey(forgotPasswordTextFieldEmailKey);
      debugPrint("emailFinder: $emailFinder");
      await tester.enterText(emailFinder, "test@test.com");

      // // when call ForgotPasswordEmailChanged then return success
      // when(forgotPasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ForgotPasswordCompletedState()]));
      // when(forgotPasswordBloc.state).thenReturn(const ForgotPasswordCompletedState());

      final submitButtonFinder = find.byKey(forgotPasswordButtonSubmitKey);
      debugPrint("submitButtonFinder: $submitButtonFinder");
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      //Then:
      verify(forgotPasswordBloc.add(any)).called(1);
      // expect(find.byType(ForgotPasswordScreen), findsNothing); screen should pop after success
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
      await tester.pumpAndSettle(const Duration(seconds: 1));

      //Then:
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      verifyNever(forgotPasswordBloc.add(any));
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
      await tester.pumpAndSettle(const Duration(seconds: 1));

      //Then:
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      verifyNever(forgotPasswordBloc.add(any));
    });
  });
}
