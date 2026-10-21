import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_redirect_uris.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_test/flutter_test.dart';

final _settings = OidcSettings(issuer: Uri.parse('https://id.example.com/realms/demo'), clientId: 'demo-app');
const _loginPath = '/login';

void main() {
  group('OidcRedirectUris.forPlatform', () {
    for (final platform in [OidcPlatformKind.android, OidcPlatformKind.ios, OidcPlatformKind.macos]) {
      test('${platform.name} uses the custom scheme for both URIs', () {
        final uris = OidcRedirectUris.forPlatform(_settings, platform: platform);

        expect(uris.signIn.toString(), 'com.example.flutterblocadvance:/oauth2redirect');
        expect(uris.postLogout.toString(), 'com.example.flutterblocadvance:/oauth2redirect');
      });
    }

    test('native uses the configured redirect scheme', () {
      final settings = OidcSettings(issuer: _settings.issuer, clientId: 'demo-app', redirectScheme: 'org.acme.app');

      final uris = OidcRedirectUris.forPlatform(settings, platform: OidcPlatformKind.android);

      expect(uris.signIn.toString(), 'org.acme.app:/oauth2redirect');
    });

    test('web uses redirect.html and the app root of the page origin', () {
      final uris = OidcRedirectUris.forPlatform(
        _settings,
        platform: OidcPlatformKind.web,
        pageUri: Uri.parse('http://localhost:8081/#/login?returnUrl=%2Fuser'),
      );

      expect(uris.signIn.toString(), 'http://localhost:8081/redirect.html');
      expect(uris.postLogout.toString(), 'http://localhost:8081/');
    });

    test('web keeps the base path the app is served under', () {
      final uris = OidcRedirectUris.forPlatform(
        _settings,
        platform: OidcPlatformKind.web,
        pageUri: Uri.parse('https://h.example/flutter-bloc-advanced/#/login'),
      );

      expect(uris.signIn.toString(), 'https://h.example/flutter-bloc-advanced/redirect.html');
      expect(uris.postLogout.toString(), 'https://h.example/flutter-bloc-advanced/');
    });

    test('web drops a page file name and treats an empty path as the root', () {
      final named = OidcRedirectUris.forPlatform(
        _settings,
        platform: OidcPlatformKind.web,
        pageUri: Uri.parse('https://h.example/app/index.html#/login'),
      );
      final bare = OidcRedirectUris.forPlatform(
        _settings,
        platform: OidcPlatformKind.web,
        pageUri: Uri.parse('http://localhost:8081#/login'),
      );

      expect(named.signIn.toString(), 'https://h.example/app/redirect.html');
      expect(bare.signIn.toString(), 'http://localhost:8081/redirect.html');
      expect(bare.postLogout.toString(), 'http://localhost:8081/');
    });

    test('web without a page URI is an error', () {
      expect(() => OidcRedirectUris.forPlatform(_settings, platform: OidcPlatformKind.web), throwsArgumentError);
    });

    for (final platform in [OidcPlatformKind.linux, OidcPlatformKind.windows]) {
      test('${platform.name} with port 0 uses the loopback listener on any free port', () {
        final uris = OidcRedirectUris.forPlatform(_settings, platform: platform);

        expect(uris.signIn.toString(), 'http://127.0.0.1:0/oauth2redirect');
        expect(uris.postLogout.toString(), 'http://127.0.0.1:0/logout');
      });
    }

    test('desktop uses the configured loopback port', () {
      final settings = OidcSettings(issuer: _settings.issuer, clientId: 'demo-app', loopbackPort: 8765);

      final uris = OidcRedirectUris.forPlatform(settings, platform: OidcPlatformKind.linux);

      expect(uris.signIn.toString(), 'http://127.0.0.1:8765/oauth2redirect');
      expect(uris.postLogout.toString(), 'http://127.0.0.1:8765/logout');
    });
  });

  group('webAppEntryUri', () {
    final page = Uri.parse('https://h.example/flutter-bloc-advanced/#/login?returnUrl=%2Fuser');

    test('keeps a safe return path as the fragment', () {
      final uri = webAppEntryUri(page, returnPath: '/user?tab=2', loginPath: _loginPath);

      expect(uri.toString(), 'https://h.example/flutter-bloc-advanced/#/user?tab=2');
    });

    test('uses / without a return path', () {
      expect(webAppEntryUri(page, loginPath: _loginPath).toString(), 'https://h.example/flutter-bloc-advanced/#/');
    });

    for (final (name, path) in [
      ('a protocol-relative path', '//evil.example'),
      ('a backslash path', r'/\evil.example'),
      ('an absolute URL', 'https://evil.example/'),
      ('the login route', '/login'),
      ('a control character', '/user\n'),
      ('a 1025-byte path', '/${'a' * 1024}'),
    ]) {
      test('turns $name into #/', () {
        expect(
          webAppEntryUri(page, returnPath: path, loginPath: _loginPath).toString(),
          'https://h.example/flutter-bloc-advanced/#/',
        );
      });
    }

    test('a path with dot segments stays inside the fragment', () {
      final uri = webAppEntryUri(page, returnPath: '/..//evil.example', loginPath: _loginPath);

      expect(uri.origin, 'https://h.example');
      expect(uri.path, '/flutter-bloc-advanced/');
      expect(uri.fragment, '/..//evil.example');
      expect(uri.toString(), 'https://h.example/flutter-bloc-advanced/#/..//evil.example');
    });

    test('never carries the code or state of the page query', () {
      final withCallback = Uri.parse('http://localhost:8081/?code=code-1&state=state-1#/login');

      final uri = webAppEntryUri(withCallback, returnPath: '/user', loginPath: _loginPath);

      expect(uri.toString(), 'http://localhost:8081/#/user');
      expect(uri.toString(), isNot(contains('code=')));
      expect(uri.toString(), isNot(contains('state=')));
    });
  });

  group('OidcPlatformKind.current', () {
    for (final (target, kind) in [
      (TargetPlatform.android, OidcPlatformKind.android),
      (TargetPlatform.iOS, OidcPlatformKind.ios),
      (TargetPlatform.macOS, OidcPlatformKind.macos),
      (TargetPlatform.linux, OidcPlatformKind.linux),
      (TargetPlatform.windows, OidcPlatformKind.windows),
    ]) {
      test('maps ${target.name} to ${kind.name}', () {
        debugDefaultTargetPlatformOverride = target;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        expect(OidcPlatformKind.current(), kind);
      });
    }

    test('refuses Fuchsia, which the package does not support', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(OidcPlatformKind.current, throwsUnsupportedError);
    });
  });
}
