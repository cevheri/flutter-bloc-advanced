@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/widgets/community_section_widget.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
