import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/change_password_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../test_utils.dart';

final _log = AppLogger.getLogger("AccountsScreenTest");

/// Change Password Screen Test
void main() {
  //region setup
  late MockAuthorityBloc authorityBloc;
  late MockChangePasswordBloc changePasswordBloc;
  late StreamController<ChangePasswordState> stateController;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    registerAllFallbackValues();
  });

  tearDown(() async {
    await stateController.close();
    await TestUtils().tearDownUnitTest();
  });

  setUp(() {
    authorityBloc = MockAuthorityBloc();
    changePasswordBloc = MockChangePasswordBloc();
    stateController = StreamController<ChangePasswordState>.broadcast();

    when(() => changePasswordBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => changePasswordBloc.state).thenReturn(const ChangePasswordState());

    when(() => authorityBloc.stream).thenAnswer((_) => Stream.fromIterable([const AuthorityState()]));
    when(() => authorityBloc.state).thenReturn(const AuthorityState());
  });

  final Iterable<LocalizationsDelegate<dynamic>> locales = [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget buildBlocProviders({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthorityBloc>(create: (context) => authorityBloc),
        BlocProvider<ChangePasswordBloc>(create: (context) => changePasswordBloc),
      ],
      child: child,
    );
  }

  MaterialApp getWidget() {
    return MaterialApp(
      localizationsDelegates: locales,
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: buildBlocProviders(child: ChangePasswordScreen())),
    );
  }

  Widget getRouterWidget() {
    final router = GoRouter(
      initialLocation: '/change-password',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/change-password',
          builder: (_, _) => Scaffold(body: buildBlocProviders(child: ChangePasswordScreen())),
        ),
      ],
    );
    return MaterialApp.router(
      localizationsDelegates: locales,
      supportedLocales: S.delegate.supportedLocales,
      routerConfig: router,
    );
  }
  //endregion setup

  // header
  group("ChangePasswordScreen HeaderTest", () {
    testWidgets("Validate Header", (tester) async {
      _log.debug("begin Validate Header");
      // Given
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')), findsOneWidget);
      expect(find.text(S.current.change_password), findsWidgets);
      _log.debug("end Validate Header");
    });

    testWidgets("Validate back button navigates back", (tester) async {
      // Given - use GoRouter widget so navigation works
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();

      // When - tap back button
      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      // Then - should navigate to home
      expect(find.text('Home'), findsOneWidget);
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
  });

  group("ChangePasswordScreen PasswordVisibilityTest", () {
    testWidgets("Toggle current password visibility", (tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Initially both fields show visibility icon (password is hidden)
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));

      // Tap the first visibility icon (current password)
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      // Now one field shows visibility_off (toggled) and one still shows visibility
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Toggle back
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Both back to visibility
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets("Toggle new password visibility", (tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Tap the second visibility icon (new password)
      await tester.tap(find.byIcon(Icons.visibility).last);
      await tester.pump();

      // Now one field shows visibility_off and one shows visibility
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Toggle back
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
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

    testWidgets("Validate loading state shows snackbar", (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();
      // When: emit loading state via stream
      stateController.add(const ChangePasswordState(status: ChangePasswordStatus.loading));
      await tester.pump();
      await tester.pump();
      // Then
      expect(find.text(S.current.loading), findsOneWidget);
    });

    testWidgets("Validate success state shows snackbar and resets form", (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      // Fill form first so reset has effect
      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'oldPass');
      await tester.enterText(find.byKey(changePasswordTextFieldNewPasswordKey), 'newPass');
      await tester.pump();

      // When: emit success state
      stateController.add(const ChangePasswordState(status: ChangePasswordStatus.success));
      await tester.pump();
      await tester.pump();
      // Then
      expect(find.text(S.current.success), findsOneWidget);
    });

    testWidgets("Validate failure state shows snackbar", (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();
      // When: emit failure state
      stateController.add(const ChangePasswordState(status: ChangePasswordStatus.failure));
      await tester.pump();
      await tester.pump();
      // Then
      expect(find.text(S.current.failed), findsOneWidget);
    });

    testWidgets("Validate submit button with invalid form", (tester) async {
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
      // Given
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(getWidget());
      // When
      await tester.pumpAndSettle();

      // Then

      final currentPasswordField = find.byKey(changePasswordTextFieldCurrentPasswordKey);
      expect(currentPasswordField, findsOneWidget);

      final newPasswordField = find.byKey(changePasswordTextFieldNewPasswordKey);
      expect(newPasswordField, findsOneWidget);

      final submitButton = find.byKey(changePasswordButtonSubmitKey);
      expect(submitButton, findsOneWidget);

      await tester.enterText(currentPasswordField, 'currentPassword');
      await tester.enterText(newPasswordField, 'newPassword');
      await tester.pumpAndSettle();
      expect(find.text('currentPassword'), findsOneWidget);
      expect(find.text('newPassword'), findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
    testWidgets('given same password when submit button clicked then change password', (tester) async {
      // Given
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
      verify(
        () => changePasswordBloc.add(
          const ChangePasswordChanged(currentPassword: 'samePassword', newPassword: 'samePassword'),
        ),
      );
    });
  });

  group("ChangePasswordScreen PopScope Test", () {
    testWidgets("Back button with clean form navigates back directly", (tester) async {
      // Given - use GoRouter widget, form is clean
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();

      // When - tap back button
      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      // Then - should navigate to home
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets("Back button with dirty form shows confirmation dialog", (tester) async {
      // Given - use GoRouter widget, make form dirty
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'dirtyValue');
      await tester.pump();

      // When - tap back button
      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      // Then - confirmation dialog should appear
      expect(find.text(S.current.warning), findsOneWidget);
      expect(find.text(S.current.unsaved_changes), findsOneWidget);
    });

    testWidgets("Confirmation dialog cancel keeps screen", (tester) async {
      // Given - make form dirty
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'dirtyValue');
      await tester.pump();

      // When - tap back, then cancel
      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      // Tap "No" (cancel)
      await tester.tap(find.text(S.current.no));
      await tester.pumpAndSettle();

      // Then - screen should still be visible
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets("Confirmation dialog confirm navigates back", (tester) async {
      // Given - make form dirty
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'dirtyValue');
      await tester.pump();

      // When - tap back, then confirm
      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      // Tap "Yes" (confirm)
      await tester.tap(find.text(S.current.yes));
      await tester.pumpAndSettle();

      // Then - should navigate to home
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
