import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/bloc/change_password_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/change_password_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'change_password_screen_test.mocks.dart';

final _log = AppLogger.getLogger("AccountsScreenTest");

/// Accounts Screen Test
/// claas AccountsScreen extent
@GenerateMocks([AuthorityBloc, ChangePasswordBloc])
void main() {
  //region setup
  late MockAuthorityBloc authorityBloc;
  late MockChangePasswordBloc changePasswordBloc;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  setUp(() {
    authorityBloc = MockAuthorityBloc();
    changePasswordBloc = MockChangePasswordBloc();

    when(changePasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ChangePasswordInitialState()]));
    when(changePasswordBloc.state).thenReturn(const ChangePasswordInitialState());

    when(authorityBloc.stream).thenAnswer((_) => Stream.fromIterable([const AuthorityState()]));
    when(authorityBloc.state).thenReturn(const AuthorityState());
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
          BlocProvider<AuthorityBloc>(create: (context) => authorityBloc),
          BlocProvider<ChangePasswordBloc>(create: (context) => changePasswordBloc),
        ],
        child: ChangePasswordScreen(),
      ),
    );
  }
  //endregion setup

  // app bar
  group("ChangePasswordScreen AppBarTest", () {
    testWidgets("Validate AppBar", (tester) async {
      _log.debug("begin Validate AppBar");
      // Given
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title

      expect(find.text(S.current.change_password), findsWidgets);
      _log.debug("end Validate AppBar");
    });
  });

  //form fields
  group("ChangePasswordScreen FormFieldsTest", () {
    testWidgets("Render Screen Validate Field Type Successful", (tester) async {
      _log.debug("begin Validate Field Type");
      await TestUtils().setupAuthentication();
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();

      //Then:
      expect(find.byType(FormBuilderTextField), findsNWidgets(2));
      _log.debug("end Validate Field Type");
    });

    /// validate field name with English translation
    testWidgets(skip: true, "Render Screen Validate Field Name Successful", (tester) async {
      //Given
      await tester.pumpWidget(getWidget());
      //When
      await tester.pumpAndSettle();
      //Then:
      expect(find.text("Current Password"), findsOneWidget);
      expect(find.text("New Password"), findsOneWidget);
      expect(find.text("Change Password"), findsOneWidget);
    });
  });

  group("ChangePasswordScreen Bloc Test", () {
    testWidgets("Validate initial state", (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets("Validate loading state", (WidgetTester tester) async {
      // Given
      when(
        changePasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ChangePasswordState(status: ChangePasswordStatus.loading)]));
      when(changePasswordBloc.state).thenReturn(const ChangePasswordState(status: ChangePasswordStatus.loading));
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pump();
      //Then:
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets("Validate success state", (WidgetTester tester) async {
      // Given
      when(
        changePasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ChangePasswordState(status: ChangePasswordStatus.success)]));
      when(changePasswordBloc.state).thenReturn(const ChangePasswordState(status: ChangePasswordStatus.success));
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pump();
      //Then:
      //expect(find.byType(ChangePasswordScreen), findsNothing);
    });

    testWidgets("Validate failure state", (WidgetTester tester) async {
      // Given
      when(
        changePasswordBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable([const ChangePasswordErrorState(message: "Failed")]));
      when(changePasswordBloc.state).thenReturn(const ChangePasswordErrorState(message: "Failed"));
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle(const Duration(seconds: 3));
      //Then:
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets("Validate submit button", (tester) async {
      // Given:
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      final submitButtonFinder = find.byKey(changePasswordButtonSubmitKey);
      await tester.tap(submitButtonFinder);
      await tester.pump();
      //Then:
      expect(find.text('Required Field'), findsAtLeastNWidgets(1));
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });
  });

  group("ChangePasswordScreen SubmitButtonTest", () {
    testWidgets('given valid password when submit button clicked then change password', (tester) async {
      when(
        changePasswordBloc.add(
          const ChangePasswordChanged(currentPassword: "currentPassword", newPassword: "newPassword"),
        ),
      ).thenAnswer((_) async => const ChangePasswordCompletedState());
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      // When
      await tester.pumpAndSettle();

      // Then

      final currentPasswordField = find.byKey(changePasswordTextFieldCurrentPasswordKey);
      expect(currentPasswordField, findsOneWidget);
      //debugPrint("currentPasswordField: $currentPasswordField");

      final newPasswordField = find.byKey(changePasswordTextFieldNewPasswordKey);
      expect(newPasswordField, findsOneWidget);
      //debugPrint("newPasswordField: $newPasswordField");

      final submitButton = find.byKey(changePasswordButtonSubmitKey);
      expect(submitButton, findsOneWidget);
      //debugPrint("submitButton: $submitButton");

      await tester.enterText(currentPasswordField, 'currentPassword');
      await tester.enterText(newPasswordField, 'newPassword');
      await tester.pumpAndSettle();
      expect(find.text('currentPassword'), findsOneWidget);
      expect(find.text('newPassword'), findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      //verify(changePasswordBloc.add(any)).called(1);
    });
    testWidgets('given same password when submit button clicked then change password', (tester) async {
      // Given
      // when(changePasswordBloc.stream).thenAnswer((_) => Stream.fromIterable([const ChangePasswordState(status: ChangePasswordStatus.failure)]));
      // when(changePasswordBloc.state).thenReturn(const ChangePasswordState(status: ChangePasswordStatus.failure));

      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // When
      final currentPasswordField = find.byKey(changePasswordTextFieldCurrentPasswordKey);
      final newPasswordField = find.byKey(changePasswordTextFieldNewPasswordKey);
      final submitButton = find.byKey(changePasswordButtonSubmitKey);

      expect(currentPasswordField, findsOneWidget);
      expect(newPasswordField, findsOneWidget);
      expect(submitButton, findsOneWidget);

      // Aynı şifreyi gir
      await tester.enterText(currentPasswordField, 'samePassword');
      await tester.enterText(newPasswordField, 'samePassword');
      await tester.pump();

      // Buton tıklaması
      await tester.tap(submitButton);
      await tester.pump();

      // Then
      //
      //verifyNever(changePasswordBloc.add(const ChangePasswordChanged(currentPassword: 'samePassword', newPassword: 'samePassword')));

      //
      //expect(find.text(S.current.failed), findsOneWidget);

      //Then
      //When enter same password then bloc should emit failure state
      verify(
        changePasswordBloc.add(
          const ChangePasswordChanged(currentPassword: 'samePassword', newPassword: 'samePassword'),
        ),
      );
      // expect(changePasswordBloc.state, const ChangePasswordState(status: ChangePasswordStatus.failure));
    });
  });
}
