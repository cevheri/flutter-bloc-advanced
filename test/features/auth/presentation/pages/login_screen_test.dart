@Tags(['widget'])
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/widgets/community_section_widget.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      super.createApiClient(secureStorage, onSessionExpired: onSessionExpired)..instance.httpClientAdapter = adapter;
}

const _insecureConnectionMessage =
    'The connection could not be verified as secure, so it was blocked. Try again later or on another network.';

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
}
