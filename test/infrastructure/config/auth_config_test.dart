import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// The issuer and client id of a valid `oidc` build, which a row changes one field of.
const _issuer = 'https://id.example.com/realms/demo';
const _clientId = 'demo-app';

/// The settings an `oidc` build with [defines] parses to; fails the test when the build is misconfigured.
OidcSettings _settings(AuthDefines defines) {
  final mode = AuthMode.fromDefines(defines);
  if (mode is! OidcAuthMode) fail('expected OidcAuthMode, got $mode');
  return mode.settings;
}

void main() {
  group('AuthMode.fromDefines', () {
    test('uses jwt when nothing is set', () {
      expect(AuthMode.fromDefines(const AuthDefines()), isA<JwtAuthMode>());
    });

    test('uses jwt for a padded upper-case JWT', () {
      expect(AuthMode.fromDefines(const AuthDefines(authProvider: ' JWT ')), isA<JwtAuthMode>());
    });

    test('throws an error that names AUTH_PROVIDER and the value for an unknown provider', () {
      expect(
        () => AuthMode.fromDefines(const AuthDefines(authProvider: 'saml')),
        throwsA(
          isA<AuthProviderConfigError>()
              .having((error) => error.value, 'value', 'saml')
              .having((error) => error.toString(), 'toString', allOf(contains('AUTH_PROVIDER'), contains('saml'))),
        ),
      );
    });

    test('is misconfigured in oidc mode without an issuer', () {
      final mode = AuthMode.fromDefines(const AuthDefines(authProvider: 'oidc', oidcClientId: _clientId));

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_ISSUER')));
    });

    test('is misconfigured in oidc mode without a client id', () {
      final mode = AuthMode.fromDefines(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer));

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_CLIENT_ID')));
    });

    test('is misconfigured for an http issuer on a host that is not loopback', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: 'http://keycloak.example.com/realms/x',
          oidcClientId: _clientId,
        ),
      );

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_ISSUER')));
    });

    for (final issuer in ['http://localhost:8080/realms/x', 'http://127.0.0.1:8080/r', 'http://[::1]:8080/r']) {
      test('accepts the loopback http issuer $issuer', () {
        final mode = AuthMode.fromDefines(
          AuthDefines(authProvider: 'oidc', oidcIssuer: issuer, oidcClientId: _clientId),
        );

        expect(mode, isA<OidcAuthMode>().having((m) => m.settings.issuer, 'issuer', Uri.parse(issuer)));
      });
    }

    test('accepts an https issuer whose scheme is upper-case', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: 'HTTPS://id.example.com', oidcClientId: _clientId),
      );

      expect(mode, isA<OidcAuthMode>());
    });

    test('is misconfigured for an issuer without a scheme', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: 'id.example.com', oidcClientId: _clientId),
      );

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_ISSUER')));
    });

    test('is misconfigured for a scope without openid', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcScope: 'profile email',
        ),
      );

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_SCOPE')));
    });

    test('asks for openid, profile and email when the scope is unset', () {
      final settings = _settings(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId));

      expect(settings.scopes, ['openid', 'profile', 'email']);
    });

    test('splits the scope on white space', () {
      final settings = _settings(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcScope: ' openid  offline_access ',
        ),
      );

      expect(settings.scopes, ['openid', 'offline_access']);
    });

    test('prompts for login when the prompt is unset', () {
      final settings = _settings(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId));

      expect(settings.prompt, OidcPrompt.login);
    });

    test('reads a padded mixed-case select_account prompt', () {
      final settings = _settings(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcPrompt: ' Select_Account ',
        ),
      );

      expect(settings.prompt, OidcPrompt.selectAccount);
    });

    test('reads the omit prompt', () {
      final settings = _settings(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcPrompt: 'omit'),
      );

      expect(settings.prompt, OidcPrompt.omit);
    });

    for (final prompt in ['none', 'always']) {
      test('is misconfigured for the prompt $prompt', () {
        final mode = AuthMode.fromDefines(
          AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcPrompt: prompt),
        );

        expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_PROMPT')));
      });
    }

    for (final value in ['true', '1', 'on', 'YES']) {
      test('turns the automatic redirect on for $value', () {
        final settings = _settings(
          AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcAutoRedirect: value),
        );

        expect(settings.autoRedirect, isTrue);
      });
    }

    for (final value in ['false', '0', 'off', 'no', '']) {
      test('leaves the automatic redirect off for "$value"', () {
        final settings = _settings(
          AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcAutoRedirect: value),
        );

        expect(settings.autoRedirect, isFalse);
      });
    }

    test('is misconfigured for an automatic redirect of maybe', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcAutoRedirect: 'maybe',
        ),
      );

      expect(mode, isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_AUTO_REDIRECT')));
    });

    test('sends the logout hint when it is unset', () {
      final settings = _settings(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId));

      expect(settings.logoutHint, isTrue);
    });

    test('leaves the logout hint out when it is off', () {
      final settings = _settings(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcLogoutHint: 'off'),
      );

      expect(settings.logoutHint, isFalse);
    });

    test('is misconfigured for user roles without a role claim', () {
      final mode = AuthMode.fromDefines(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcUserRoles: 'user'),
      );

      expect(
        mode,
        isA<OidcMisconfiguredAuthMode>().having(
          (m) => m.reason,
          'reason',
          allOf(contains('OIDC_USER_ROLES'), contains('OIDC_ROLE_CLAIM')),
        ),
      );
    });

    test('reads the role claim and the user roles together', () {
      final settings = _settings(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcRoleClaim: ' realm_access.roles ',
          oidcUserRoles: 'user',
        ),
      );

      expect(settings.roleClaim, 'realm_access.roles');
      expect(settings.userRoles, ['user']);
    });

    test('uses the admin role when the admin roles are only commas', () {
      final settings = _settings(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcAdminRoles: ' , ,'),
      );

      expect(settings.adminRoles, ['admin']);
    });

    test('has no user roles when the user roles are only commas', () {
      final settings = _settings(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcUserRoles: ' , ,'),
      );

      expect(settings.userRoles, isEmpty);
    });

    test('trims each admin role and keeps its case', () {
      final settings = _settings(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcAdminRoles: 'Admin, superadmin',
        ),
      );

      expect(settings.adminRoles, ['Admin', 'superadmin']);
    });

    test('uses the template redirect scheme and any free loopback port when they are unset', () {
      final settings = _settings(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId));

      expect(settings.redirectScheme, OidcSettings.defaultRedirectScheme);
      expect(settings.redirectScheme, 'com.example.flutterblocadvance');
      expect(settings.loopbackPort, 0);
    });

    for (final scheme in ['com.example_app', '9app']) {
      test('is misconfigured for the redirect scheme $scheme', () {
        final mode = AuthMode.fromDefines(
          AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcRedirectScheme: scheme),
        );

        expect(
          mode,
          isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_REDIRECT_SCHEME')),
        );
      });
    }

    test('reads the loopback port 53682', () {
      final settings = _settings(
        const AuthDefines(
          authProvider: 'oidc',
          oidcIssuer: _issuer,
          oidcClientId: _clientId,
          oidcLoopbackPort: '53682',
        ),
      );

      expect(settings.loopbackPort, 53682);
    });

    for (final port in ['abc', '-1', '70000']) {
      test('is misconfigured for the loopback port $port', () {
        final mode = AuthMode.fromDefines(
          AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcLoopbackPort: port),
        );

        expect(
          mode,
          isA<OidcMisconfiguredAuthMode>().having((m) => m.reason, 'reason', contains('OIDC_LOOPBACK_PORT')),
        );
      });
    }

    test('reads the audience, and leaves an unset audience and role claim out', () {
      final withAudience = _settings(
        const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId, oidcAudience: ' api '),
      );
      final without = _settings(const AuthDefines(authProvider: 'oidc', oidcIssuer: _issuer, oidcClientId: _clientId));

      expect(withAudience.audience, 'api');
      expect(without.audience, isNull);
      expect(without.roleClaim, isNull);
    });
  });

  group('AuthMode.usesOidc', () {
    test('is false for jwt and true for both oidc modes', () {
      expect(const JwtAuthMode().usesOidc, isFalse);
      expect(OidcAuthMode(OidcSettings(issuer: Uri.parse(_issuer), clientId: _clientId)).usesOidc, isTrue);
      expect(const OidcMisconfiguredAuthMode('OIDC_ISSUER is required').usesOidc, isTrue);
    });
  });

  group('OidcPrompt.parameter', () {
    test('is the prompt value sent to the provider, and none for omit', () {
      expect(OidcPrompt.login.parameter, 'login');
      expect(OidcPrompt.consent.parameter, 'consent');
      expect(OidcPrompt.selectAccount.parameter, 'select_account');
      expect(OidcPrompt.omit.parameter, isNull);
    });
  });
}
