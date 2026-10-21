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
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_nav_item.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/widgets/community_section_widget.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';

/// Production chain (no MockInterceptor) with certificate pinning configured.
const _pinnedProdConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: ['test-pin'],
  idleTimeout: null,
);

/// Sits in the slot of the certificate-pinning adapter and fails every request the way it fails a server whose
/// certificate matches no configured pin, as on a network that intercepts the connection.
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

/// The production dependencies, with [adapter] in the slot of the certificate-pinning adapter.
class _PinnedDependencies extends AppDependencies {
  _PinnedDependencies(this.adapter) : super(appConfig: _pinnedProdConfig);

  final _PinMismatchAdapter adapter;

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

const _insecureConnectionMessage =
    'The connection could not be verified as secure, so it was blocked. Try again later or on another network.';

/// A sign-in that the provider accepts for an account with the admin role.
final _signedIn = OidcSignedIn(
  tokens: OidcTokens(
    accessToken: 'sso-access-token',
    idToken: 'sso-id-token',
    refreshToken: 'sso-refresh-token',
    accessTokenExpiresAt: DateTime.utc(2100),
  ),
  claims: const {
    'iss': 'https://id.example.com/realms/demo',
    'sub': 'subject-1',
    'roles': ['admin'],
  },
);

/// The identity provider of an oidc build. Each sign-in answers with the next of [outcomes], and with [_signedIn] once
/// they have run out; the startup completion answers with [pending].
class _ScriptedOidcClient implements IOidcClient {
  _ScriptedOidcClient({List<FutureOr<OidcSignInOutcome>>? outcomes, this.pending}) : outcomes = outcomes ?? [];

  final List<FutureOr<OidcSignInOutcome>> outcomes;
  final OidcSignInOutcome? pending;

  /// The `webReturnPath` of every sign-in, in order.
  final webReturnPaths = <String?>[];

  int get signIns => webReturnPaths.length;

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) async {
    webReturnPaths.add(webReturnPath);
    return outcomes.isEmpty ? _signedIn : await outcomes.removeAt(0);
  }

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() async => pending;

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => throw UnimplementedError('these tests store no expired session');

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) async => const ProviderSessionEnded();
}

/// The test config in an oidc build over [client], for a project that gives all its links. Only the `admin` and
/// `user` roles of the `roles` claim are allowed.
class _OidcDependencies extends AppDependencies {
  _OidcDependencies(this.client, {bool autoRedirect = false})
    : super(
        appConfig: const AppConfig.test(),
        projectLinks: const ProjectLinks(
          repository: 'https://github.com/acme/dashboard',
          docs: 'https://docs.acme.example',
          sponsor: 'https://github.com/sponsors/acme',
        ),
        authMode: OidcAuthMode(
          OidcSettings(
            issuer: Uri.parse('https://id.example.com/realms/demo'),
            clientId: 'app',
            roleClaim: 'roles',
            userRoles: const ['user'],
            autoRedirect: autoRedirect,
          ),
        ),
      );

  final IOidcClient client;

  @override
  IOidcClient createOidcClient(OidcSettings settings) => client;
}

const _discoveryMessage =
    'The identity provider could not be reached. Try again later, or contact your administrator if this continues.';
const _failedMessage = 'Sign-in failed. Please try again.';
const _noRoleMessage = 'Your account has no role that allows access to this app. Ask your administrator.';
const _configMessage = 'Single sign-on is not configured correctly in this app. Contact your administrator.';

void main() {
  void setViewport(WidgetTester tester, Size size) {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  // The real app starts unauthenticated after the global reset, so it lands on /login. The project gives all its
  // links, so the page shows its community section.
  Future<void> pumpLogin(WidgetTester tester, {String language = 'en'}) async {
    await tester.pumpWidget(
      App(
        language: language,
        dependencies: const AppDependencies(
          projectLinks: ProjectLinks(
            repository: 'https://github.com/acme/dashboard',
            docs: 'https://docs.acme.example',
            sponsor: 'https://github.com/sponsors/acme',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  group('LoginScreen community section', () {
    testWidgets('renders once, as the brand panel cards, on a wide surface', (tester) async {
      setViewport(tester, const Size(1600, 1600));
      await pumpLogin(tester);

      expect(find.byType(CommunitySectionWidget), findsOneWidget);
      expect(find.byKey(communityDocsKey), findsOneWidget);
      expect(tester.widget<CommunitySectionWidget>(find.byType(CommunitySectionWidget)).isDesktop, isTrue);
    });

    testWidgets('renders once, as the chips below the form, on a narrow surface', (tester) async {
      setViewport(tester, const Size(390, 844));
      await pumpLogin(tester);

      expect(find.byType(CommunitySectionWidget), findsOneWidget);
      expect(find.byKey(communityDocsKey), findsOneWidget);
      expect(tester.widget<CommunitySectionWidget>(find.byType(CommunitySectionWidget)).isDesktop, isFalse);
    });
  });

  group('LoginScreen brand panel', () {
    // 1024 px is the narrowest width that shows the brand panel. The test font is wider than the real one, which
    // stands in for a larger text scale.
    testWidgets('lays out without overflow at the desktop breakpoint', (tester) async {
      setViewport(tester, const Size(1024, 1600));
      await pumpLogin(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('LoginScreen password length', () {
    // Validates the password field alone, so a valid password does not sign in.
    Future<String?> passwordError(WidgetTester tester, String password) async {
      await tester.enterText(find.byKey(loginTextFieldPasswordKey), password);
      final field = tester.state<FormFieldState<dynamic>>(find.byKey(loginTextFieldPasswordKey));
      field.validate();
      return field.errorText;
    }

    const messages = {
      'en': ('Password must be at least 4 characters long', 'Password cannot be more than 20 characters long'),
      'tr': ('Şifre en az 4 karakter uzunluğunda olmalıdır', 'Şifre en fazla 20 karakter uzunluğunda olmalıdır'),
    };

    for (final MapEntry(key: language, value: (tooShort, tooLong)) in messages.entries) {
      testWidgets('accepts 4 to 20 characters and says so in $language', (tester) async {
        setViewport(tester, const Size(1600, 1600));
        await pumpLogin(tester, language: language);

        expect(await passwordError(tester, 'a' * 3), tooShort);
        expect(await passwordError(tester, 'a' * 4), isNull);
        expect(await passwordError(tester, 'a' * 20), isNull);
        expect(await passwordError(tester, 'a' * 21), tooLong);
      });
    }
  });

  // An icon-only button is announced by its tooltip, which is all a screen reader can say about it.
  Matcher announcedAs(String tooltip) => isSemantics(tooltip: tooltip, isButton: true);
  final passwordToggle = find.byKey(loginButtonPasswordVisibilityKey);

  group('LoginScreen screen reader labels', () {
    testWidgets('names the password visibility toggle by what it does', (tester) async {
      final semantics = tester.ensureSemantics();
      setViewport(tester, const Size(1600, 1600));
      await pumpLogin(tester);

      expect(tester.getSemantics(passwordToggle), announcedAs('Show password'));

      await tester.tap(passwordToggle);
      await tester.pumpAndSettle();

      expect(tester.getSemantics(passwordToggle), announcedAs('Hide password'));
      semantics.dispose();
    });

    testWidgets('names the password visibility toggle and the OTP back button in Turkish', (tester) async {
      final semantics = tester.ensureSemantics();
      setViewport(tester, const Size(390, 844));
      await pumpLogin(tester, language: 'tr');

      expect(tester.getSemantics(passwordToggle), announcedAs('Şifreyi göster'));

      await tester.tap(find.byKey(const Key('loginButtonOtpKey')));
      await tester.pumpAndSettle();

      expect(tester.getSemantics(find.widgetWithIcon(IconButton, Icons.arrow_back)), announcedAs('Geri'));
      semantics.dispose();
    });
  });

  group('LoginScreen - Turkish', () {
    testWidgets('shows the form and the brand panel in Turkish', (tester) async {
      setViewport(tester, const Size(1440, 900));
      await pumpLogin(tester, language: 'tr');

      for (final text in [
        'Tekrar hoş geldiniz',
        'Hesabınıza erişmek için bilgilerinizi girin',
        'veya',
        'Hesabınız yok mu? ',
        'Prototipten\nüretime ölçeklenin.',
        'Platform',
        'Temel Katman',
        '%100',
        'BLoC Hazır',
        'Kimlik Doğrulama ve Erişim Kontrolü',
        'Temiz Mimari',
        "Sahte Veriden Gerçek API'ye",
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byTooltip('Koyu temaya geç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the OTP email instructions in Turkish', (tester) async {
      setViewport(tester, const Size(390, 844));
      await pumpLogin(tester, language: 'tr');

      await tester.tap(find.byKey(const Key('loginButtonOtpKey')));
      await tester.pumpAndSettle();

      expect(find.text('OTP kodunu almak için e-posta adresinizi girin'), findsOneWidget);
    });
  });

  // A network that intercepts the connection presents a certificate that matches no pin. Signing in there used to
  // show "Login failed" and an inline "Failed", as if the credentials were wrong.
  group('over a connection whose certificate matches no pin', () {
    Future<_PinMismatchAdapter> pumpPinnedLogin(WidgetTester tester) async {
      setViewport(tester, const Size(1600, 1600));
      final adapter = _PinMismatchAdapter();
      await tester.pumpWidget(App(language: 'en', dependencies: _PinnedDependencies(adapter)));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      // The lifecycle check reads the app config when the app starts. It fails open, so the login screen shows.
      expect(adapter.requests, ['GET /app/config']);
      adapter.requests.clear();
      return adapter;
    }

    GoRouter routerFromApp(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

    void expectInsecureConnectionMessageOnly(WidgetTester tester) {
      expect(find.text(_insecureConnectionMessage), findsWidgets);
      expect(find.textContaining('api.example.test'), findsNothing);
      expect(find.textContaining('443'), findsNothing);
    }

    testWidgets('signing in tells the user the connection was blocked, not that the sign-in failed', (tester) async {
      final adapter = await pumpPinnedLogin(tester);

      await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'admin');
      await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'admin');
      await tester.tap(find.byKey(loginButtonSubmitKey));
      await tester.pumpAndSettle();

      expect(adapter.requests, ['POST /authenticate']);
      // The snack bar and the line under the password field.
      expect(find.text(_insecureConnectionMessage), findsNWidgets(2));
      expect(find.text('Login failed'), findsNothing);
      expect(find.text('Failed'), findsNothing);
      expectInsecureConnectionMessageOnly(tester);
    });

    testWidgets('sending the sign-in code tells the user the connection was blocked', (tester) async {
      final adapter = await pumpPinnedLogin(tester);

      await tester.tap(find.byKey(const Key('loginButtonOtpKey')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(FormBuilderTextField), 'jane.doe@example.com');
      await tester.tap(find.text('Send OTP Code'));
      await tester.pumpAndSettle();

      expect(adapter.requests, ['POST /authenticate/send-otp']);
      expect(find.text('Could not send the OTP code'), findsNothing);
      expectInsecureConnectionMessageOnly(tester);
    });

    testWidgets('verifying the sign-in code tells the user the connection was blocked', (tester) async {
      final adapter = await pumpPinnedLogin(tester);

      routerFromApp(tester).go('${ApplicationRoutesConstants.loginOtpVerify}/jane.doe@example.com');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(FormBuilderTextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP Code'));
      await tester.pumpAndSettle();

      expect(adapter.requests, ['POST /authenticate/verify-otp']);
      expect(find.text('OTP validation failed'), findsNothing);
      expectInsecureConnectionMessageOnly(tester);
    });
  });

  group('in oidc mode', () {
    final ssoButton = find.byKey(loginButtonSsoKey);

    Future<void> pumpOidcApp(WidgetTester tester, AppDependencies dependencies, {String language = 'en'}) async {
      setViewport(tester, const Size(1600, 1600));
      await tester.pumpWidget(App(language: language, dependencies: dependencies));
      await tester.pumpAndSettle();
    }

    GoRouter routerFromApp(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter;

    String location(WidgetTester tester) => routerFromApp(tester).state.uri.toString();

    SsoAutoRedirectGate gate(WidgetTester tester) =>
        tester.element(find.byType(MaterialApp)).read<SsoAutoRedirectGate>();

    // Signs out as the user does: Logout in the sidebar, then Yes in the confirmation dialog.
    Future<void> logOut(WidgetTester tester) async {
      await tester.tap(find.widgetWithIcon(SidebarNavItem, Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();
    }

    // Waits until the snack bar that repeats the error has gone, so only the line on the page is left.
    Future<void> waitForSnackBarToGo(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    testWidgets('shows only the single sign-on button', (tester) async {
      await pumpOidcApp(tester, _OidcDependencies(_ScriptedOidcClient()));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in with SSO'), findsOneWidget);
      expect(find.text('Sign in with your organization account.'), findsOneWidget);
      expect(find.text('Enter your credentials to access your account'), findsNothing);
      for (final key in [
        loginTextFieldUsernameKey,
        loginTextFieldPasswordKey,
        loginButtonSubmitKey,
        loginButtonPasswordVisibilityKey,
        loginButtonForgotPasswordKey,
        loginButtonRegisterKey,
        const Key('loginButtonOtpKey'),
      ]) {
        expect(find.byKey(key), findsNothing, reason: '$key');
      }
      expect(find.byType(CommunitySectionWidget), findsOneWidget);
    });

    for (final (rejection, outcome, message) in [
      ('an unreachable provider', const OidcSignInFailed(OidcFailure.discovery), _discoveryMessage),
      ('an error answer', const OidcSignInFailed(OidcFailure.failed), _failedMessage),
      (
        'an account with no allowed role',
        OidcSignedIn(
          tokens: _signedIn.tokens,
          claims: const {
            'iss': 'https://id.example.com/realms/demo',
            'sub': 's',
            'roles': ['guest'],
          },
        ),
        _noRoleMessage,
      ),
      (
        'an ID token with no subject',
        OidcSignedIn(tokens: _signedIn.tokens, claims: const {'iss': 'https://id.example.com/realms/demo'}),
        _failedMessage,
      ),
    ]) {
      testWidgets('says why for $rejection and keeps the button', (tester) async {
        final client = _ScriptedOidcClient(outcomes: [outcome]);
        await pumpOidcApp(tester, _OidcDependencies(client));

        await tester.tap(ssoButton);
        await tester.pumpAndSettle();
        await waitForSnackBarToGo(tester);

        expect(client.signIns, 1);
        expect(find.text(message), findsOneWidget);
        expect(tester.widget<FilledButton>(ssoButton).onPressed, isNotNull);
        expect(location(tester), ApplicationRoutesConstants.login);
      });
    }

    testWidgets('shows a startup sign-in error until the first tap, and nothing while the sign-in runs', (
      tester,
    ) async {
      final answer = Completer<OidcSignInOutcome>();
      final client = _ScriptedOidcClient(
        pending: const OidcSignInFailed(OidcFailure.discovery),
        outcomes: [answer.future],
      );
      await pumpOidcApp(tester, _OidcDependencies(client));
      expect(find.text(_discoveryMessage), findsOneWidget);

      await tester.tap(ssoButton);
      // The spinner runs until the provider answers, so the frames are pumped one by one.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.descendant(of: ssoButton, matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(tester.widget<FilledButton>(ssoButton).onPressed, isNull);
      expect(find.text(_discoveryMessage), findsNothing);

      answer.complete(const OidcSignInCancelled());
      await tester.pumpAndSettle();

      expect(find.text(_discoveryMessage), findsNothing);
      expect(tester.widget<FilledButton>(ssoButton).onPressed, isNotNull);
    });

    testWidgets('a misconfigured build says so and shows no button', (tester) async {
      await pumpOidcApp(
        tester,
        const AppDependencies(
          appConfig: AppConfig.test(),
          authMode: OidcMisconfiguredAuthMode('OIDC_ISSUER is required in oidc mode'),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(_configMessage), findsOneWidget);
      expect(ssoButton, findsNothing);
      expect(find.byKey(loginTextFieldUsernameKey), findsNothing);
      expect(find.byKey(loginButtonSubmitKey), findsNothing);
    });

    testWidgets('shows the button in Turkish', (tester) async {
      await pumpOidcApp(tester, _OidcDependencies(_ScriptedOidcClient()), language: 'tr');

      expect(find.widgetWithText(FilledButton, 'SSO ile giriş yap'), findsOneWidget);
      expect(find.text('Kurumsal hesabınızla giriş yapın.'), findsOneWidget);
    });

    testWidgets('a tap signs in and opens the dashboard, with no web return path off the web', (tester) async {
      final client = _ScriptedOidcClient();
      await pumpOidcApp(tester, _OidcDependencies(client));

      await tester.tap(ssoButton);
      await tester.pumpAndSettle();

      expect(client.webReturnPaths, [null]);
      expect(find.byType(ResponsiveScaffold), findsOneWidget);
      expect(location(tester), ApplicationRoutesConstants.home);
    });

    testWidgets('a safe returnUrl is where the sign-in lands', (tester) async {
      await pumpOidcApp(tester, _OidcDependencies(_ScriptedOidcClient()));
      routerFromApp(tester).go('${ApplicationRoutesConstants.login}?returnUrl=%2Fsettings');
      await tester.pumpAndSettle();

      await tester.tap(ssoButton);
      await tester.pumpAndSettle();

      expect(location(tester), ApplicationRoutesConstants.settings);
    });

    testWidgets('a returnUrl of /login or with a control character lands on /', (tester) async {
      await pumpOidcApp(tester, _OidcDependencies(_ScriptedOidcClient()));

      for (final returnUrl in ['%2Flogin', '%2Fsettings%07']) {
        routerFromApp(tester).go('${ApplicationRoutesConstants.login}?returnUrl=$returnUrl');
        await tester.pumpAndSettle();
        await tester.tap(ssoButton);
        await tester.pumpAndSettle();

        expect(location(tester), ApplicationRoutesConstants.home, reason: returnUrl);
        await logOut(tester);
      }
    });

    group('automatic redirect', () {
      testWidgets('signs in once on a cold start', (tester) async {
        final client = _ScriptedOidcClient();
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));

        expect(client.signIns, 1);
        expect(find.byType(ResponsiveScaffold), findsOneWidget);
        expect(gate(tester).isOpen, isFalse);
      });

      testWidgets('does not run when it is turned off', (tester) async {
        final client = _ScriptedOidcClient();
        await pumpOidcApp(tester, _OidcDependencies(client));

        expect(client.signIns, 0);
        expect(ssoButton, findsOneWidget);
      });

      testWidgets('does not run after a startup sign-in error', (tester) async {
        final client = _ScriptedOidcClient(pending: const OidcSignInFailed(OidcFailure.failed));
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));

        expect(client.signIns, 0);
        expect(find.text(_failedMessage), findsOneWidget);
      });

      // Back from the provider's page brings a web tab back with no answer, which the startup completion reports as a
      // cancel.
      testWidgets('does not run after the user came back from the provider without signing in', (tester) async {
        final client = _ScriptedOidcClient(pending: const OidcSignInCancelled());
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));

        expect(client.signIns, 0);
        expect(ssoButton, findsOneWidget);
      });

      testWidgets('does not run when the login page shows again after a logout', (tester) async {
        final client = _ScriptedOidcClient();
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));
        expect(find.byType(ResponsiveScaffold), findsOneWidget);

        await logOut(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(client.signIns, 1);
      });

      testWidgets('after a cancel, keeps the gate closed and the button signs in again', (tester) async {
        final client = _ScriptedOidcClient(outcomes: [const OidcSignInCancelled()]);
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));
        expect(client.signIns, 1);
        expect(gate(tester).isOpen, isFalse);
        expect(tester.widget<FilledButton>(ssoButton).onPressed, isNotNull);

        await tester.tap(ssoButton);
        await tester.pumpAndSettle();

        expect(client.signIns, 2);
        expect(find.byType(ResponsiveScaffold), findsOneWidget);
      });

      testWidgets('after an error, keeps the gate closed and the error on the page', (tester) async {
        final client = _ScriptedOidcClient(outcomes: [const OidcSignInFailed(OidcFailure.discovery)]);
        await pumpOidcApp(tester, _OidcDependencies(client, autoRedirect: true));
        await waitForSnackBarToGo(tester);

        expect(client.signIns, 1);
        expect(gate(tester).isOpen, isFalse);
        expect(find.text(_discoveryMessage), findsOneWidget);
      });
    });
  });
}
