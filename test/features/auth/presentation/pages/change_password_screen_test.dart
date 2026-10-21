@Tags(['widget'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart'
    show HttpClientAdapter, Interceptor, RequestInterceptorHandler, RequestOptions, ResponseBody;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/change_password_page.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/test_env.dart';
import '../../../../support/unsaved_changes_host.dart';

final _log = AppLogger.getLogger("AccountsScreenTest");

/// Change Password Screen Test
void main() {
  //region setup
  late MockAuthorityBloc authorityBloc;
  late MockChangePasswordBloc changePasswordBloc;
  late StreamController<ChangePasswordState> stateController;

  tearDown(() async {
    await stateController.close();
  });

  setUp(() {
    authorityBloc = MockAuthorityBloc();
    changePasswordBloc = MockChangePasswordBloc();
    stateController = StreamController<ChangePasswordState>.broadcast();

    when(() => changePasswordBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => changePasswordBloc.state).thenReturn(const ChangePasswordInitialState());

    when(() => authorityBloc.stream).thenAnswer((_) => Stream.fromIterable([const AuthorityInitialState()]));
    when(() => authorityBloc.state).thenReturn(const AuthorityInitialState());
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

  Widget getWidget() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: buildBlocProviders(child: ChangePasswordScreen())),
        ),
      ],
    );
    return withUnsavedChangesRegistry(
      MaterialApp.router(
        localizationsDelegates: locales,
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
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
          onExit: confirmLeavingUnsavedChanges,
          builder: (_, _) => Scaffold(body: buildBlocProviders(child: ChangePasswordScreen())),
        ),
      ],
    );
    return withUnsavedChangesRegistry(
      MaterialApp.router(
        localizationsDelegates: locales,
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
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

    testWidgets("fits the title on a 320 px wide phone", (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(S.current.change_password), findsWidgets);
    });
  });

  //form fields
  group("ChangePasswordScreen FormFieldsTest", () {
    testWidgets("Render Screen Validate Field Type Successful", (tester) async {
      _log.debug("begin Validate Field Type");
      TestEnv.authenticate();
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
    testWidgets("names the back button and the password visibility toggles for screen readers", (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      Matcher announcedAs(String tooltip) => isSemantics(tooltip: tooltip, isButton: true);
      final toggles = find.widgetWithIcon(IconButton, Icons.visibility);
      expect(
        tester.getSemantics(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey'))),
        announcedAs('Back'),
      );
      expect(tester.getSemantics(toggles.first), announcedAs('Show password'));
      expect(tester.getSemantics(toggles.last), announcedAs('Show password'));

      await tester.tap(toggles.first);
      await tester.pump();

      expect(tester.getSemantics(find.widgetWithIcon(IconButton, Icons.visibility_off)), announcedAs('Hide password'));
      semantics.dispose();
    });

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
      stateController.add(const ChangePasswordLoadingState());
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
      stateController.add(const ChangePasswordSuccessState());
      await tester.pump();
      await tester.pump();
      // Then
      expect(find.text(S.current.success), findsOneWidget);
    });

    testWidgets("Validate failure state shows why it failed in a snackbar", (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();
      // When: emit failure state
      stateController.add(const ChangePasswordFailureState(errorCode: AppErrorCode.accountPasswordRequired));
      await tester.pump();
      await tester.pump();
      // Then
      expect(find.text(S.current.error_account_password_required), findsOneWidget);
      expect(find.text(S.current.failed), findsNothing);
      // The reason is a sentence, so it stays for the default 4 s instead of the 1 s of the other notices.
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).duration, const Duration(seconds: 4));
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
      await tester.pumpAndSettle();
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
    testWidgets("Back button after a successful change leaves without asking", (tester) async {
      await tester.pumpWidget(getRouterWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'oldPass');
      await tester.pumpAndSettle();

      // The page resets the form when the change succeeds.
      stateController.add(const ChangePasswordSuccessState());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('changePasswordScreenAppBarBackButtonKey')));
      await tester.pumpAndSettle();

      expect(find.text(S.current.unsaved_changes), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

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

  group("ChangePasswordScreen in the app", () {
    late List<RequestOptions> requests;

    setUp(() {
      requests = [];
      TestEnv.authenticate();
    });

    testWidgets("shows why the new password was refused in the app language", (tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(App(language: 'tr', dependencies: _RecordingDependencies(requests)));
      await tester.pumpAndSettle();
      final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
      router.go(ApplicationRoutesConstants.changePassword);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'samePassword');
      await tester.enterText(find.byKey(changePasswordTextFieldNewPasswordKey), 'samePassword');
      await tester.tap(find.byKey(changePasswordButtonSubmitKey));
      await tester.pumpAndSettle();
      // The page first shows for a second that it is saving; the failure follows.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Yeni şifre mevcut şifreden farklı olmalıdır'), findsOneWidget);
      expect(find.text('Başarısız'), findsNothing);
      expect(requests.where((request) => request.path == '/account/change-password'), isEmpty);
    });
  });

  group("ChangePasswordScreen new password length", () {
    // Validates the new password field alone, so a valid password does not submit.
    Future<String?> newPasswordError(WidgetTester tester, String password) async {
      await tester.enterText(find.byKey(changePasswordTextFieldNewPasswordKey), password);
      final field = tester.state<FormFieldState<dynamic>>(find.byKey(changePasswordTextFieldNewPasswordKey));
      field.validate();
      return field.errorText;
    }

    const messages = {
      'en': ('Password must be at least 4 characters long', 'Password cannot be more than 20 characters long'),
      'tr': ('Şifre en az 4 karakter uzunluğunda olmalıdır', 'Şifre en fazla 20 karakter uzunluğunda olmalıdır'),
    };

    for (final MapEntry(key: language, value: (tooShort, tooLong)) in messages.entries) {
      testWidgets("accepts 4 to 20 characters and says so in $language", (tester) async {
        await tester.pumpWidget(
          withUnsavedChangesRegistry(
            MaterialApp.router(
              locale: Locale(language),
              localizationsDelegates: locales,
              supportedLocales: S.delegate.supportedLocales,
              routerConfig: singlePageRouter(Scaffold(body: buildBlocProviders(child: ChangePasswordScreen()))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(await newPasswordError(tester, 'a' * 3), tooShort);
        expect(await newPasswordError(tester, 'a' * 4), isNull);
        expect(await newPasswordError(tester, 'a' * 20), isNull);
        expect(await newPasswordError(tester, 'a' * 21), tooLong);
      });
    }
  });

  // Regression: changing the password on a network whose certificate matches no pin said "Failed", as if the current
  // password were wrong.
  testWidgets('tells the user the connection was blocked when the certificate matches no pin', (tester) async {
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, _unexpiredJwt());
    await AppLocalStorage().save(StorageKeys.roles.key, ['ROLE_USER']);
    final adapter = _PinMismatchAdapter();
    await tester.pumpWidget(App(language: 'en', dependencies: _PinnedDependencies(adapter)));
    await tester.pumpAndSettle();
    final router = tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;
    router.go(ApplicationRoutesConstants.changePassword);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(changePasswordTextFieldCurrentPasswordKey), 'current-password');
    await tester.enterText(find.byKey(changePasswordTextFieldNewPasswordKey), 'new-password');
    await tester.tap(find.byKey(changePasswordButtonSubmitKey));

    // The reason is a sentence, so it stays for the default 4 s, while the loading notice keeps its second.
    expect(await _snackBars(tester), {
      S.current.loading: const Duration(seconds: 1),
      S.current.error_network_cert_invalid: const Duration(seconds: 4),
    });
    expect(adapter.requests, contains('POST /account/change-password'));
  });
}

/// A JWT whose `exp` lies far in the future, so a production session restores it as signed in.
String _unexpiredJwt() {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': 'admin', 'exp': 4102444800})}.signature';
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
  ApiClient createApiClient(
    ISecureStorage secureStorage, {
    required OnSessionExpired onSessionExpired,
    required ITokenRefreshLock? tokenRefreshLock,
    required RotatedTokensTakeBack? rotatedTokensTakeBack,
  }) => super.createApiClient(
    secureStorage,
    onSessionExpired: onSessionExpired,
    tokenRefreshLock: tokenRefreshLock,
    rotatedTokensTakeBack: rotatedTokensTakeBack,
  )..instance.httpClientAdapter = adapter;
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

/// Test-mode app dependencies whose API client records each request the mock API answers in [requests].
class _RecordingDependencies extends AppDependencies {
  const _RecordingDependencies(this.requests) : super(appConfig: const AppConfig.test());

  final List<RequestOptions> requests;

  @override
  ApiClient createApiClient(
    ISecureStorage secureStorage, {
    required OnSessionExpired onSessionExpired,
    required ITokenRefreshLock? tokenRefreshLock,
    required RotatedTokensTakeBack? rotatedTokensTakeBack,
  }) {
    final apiClient = super.createApiClient(
      secureStorage,
      onSessionExpired: onSessionExpired,
      tokenRefreshLock: tokenRefreshLock,
      rotatedTokensTakeBack: rotatedTokensTakeBack,
    );
    // MockInterceptor comes last and answers in place of the server, so the recorder goes right before it.
    final interceptors = apiClient.instance.interceptors;
    interceptors.insert(interceptors.length - 1, _RequestRecorder(requests));
    return apiClient;
  }
}

class _RequestRecorder extends Interceptor {
  _RequestRecorder(this.requests);

  final List<RequestOptions> requests;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.next(options);
  }
}
