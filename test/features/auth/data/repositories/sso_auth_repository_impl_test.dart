import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/sso_auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Logger, OutputEvent;

/// Answers [signIn] and [completePendingSignIn] with the configured outcomes, and records the arguments of each sign-in.
class _FakeOidcClient implements IOidcClient {
  OidcSignInOutcome signInOutcome = const OidcSignInCancelled();
  OidcSignInOutcome? pendingOutcome;
  final signIns = <({String? webReturnPath, String browserDoneMessage})>[];

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) async {
    signIns.add((webReturnPath: webReturnPath, browserDoneMessage: browserDoneMessage));
    return signInOutcome;
  }

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() async => pendingOutcome;

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => throw UnimplementedError('a sign-in never refreshes');

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) =>
      throw UnimplementedError('a sign-in never logs out');
}

class _FakeAuthSessionRepository implements IAuthSessionRepository {
  Result<void>? persistResult;
  final persisted = <AuthSession>[];

  @override
  Future<Result<void>> persist(AuthSession session) async {
    persisted.add(session);
    return persistResult ?? const Success(null);
  }

  @override
  Future<Result<void>> clear() async => const Success(null);
}

final _expiresAt = DateTime.utc(2026, 10, 21, 12);

final _tokens = OidcTokens(
  accessToken: 'access-token',
  idToken: 'id-token',
  refreshToken: 'refresh-token',
  accessTokenExpiresAt: _expiresAt,
);

final _settings = OidcSettings(
  issuer: Uri.parse('https://id.example.com/realms/demo'),
  clientId: 'app',
  roleClaim: 'roles',
  adminRoles: ['admin'],
  userRoles: ['user'],
);

Map<String, Object?> _claims({Object? roles = const ['user'], Map<String, Object?> extra = const {}}) => {
  'iss': 'https://id.example.com/realms/demo',
  'sub': 'subject-1',
  'roles': roles,
  ...extra,
};

void main() {
  late _FakeOidcClient client;
  late _FakeAuthSessionRepository sessions;
  late SsoAuthRepository repository;

  setUp(() {
    client = _FakeOidcClient();
    sessions = _FakeAuthSessionRepository();
    repository = SsoAuthRepository(client: client, sessionRepository: sessions, settings: _settings);
  });

  Future<SsoSignInResult> signInWith(Map<String, Object?> claims) {
    client.signInOutcome = OidcSignedIn(tokens: _tokens, claims: claims);
    return repository.signIn(browserDoneMessage: 'done');
  }

  group('SsoAuthRepository.signIn', () {
    test('persists the session the tokens and the mapped role make, and answers the username and roles', () async {
      final result = await signInWith(_claims(extra: {'email': 'user@example.com'}));

      expect(
        result,
        isA<SsoSignInSucceeded>().having((r) => r.username, 'username', 'user@example.com').having(
          (r) => r.roles,
          'roles',
          ['ROLE_USER'],
        ),
      );
      expect(sessions.persisted, hasLength(1));
      final session = sessions.persisted.single;
      expect(session.idToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.username, 'user@example.com');
      expect(session.roles, ['ROLE_USER']);
      expect(session.oidcIdToken, 'id-token');
      expect(session.accessTokenExpiresAt, _expiresAt);
    });

    test('persists no refresh token when the provider issued none', () async {
      client.signInOutcome = OidcSignedIn(
        tokens: OidcTokens(accessToken: 'access-token', idToken: 'id-token', accessTokenExpiresAt: _expiresAt),
        claims: _claims(),
      );

      expect(await repository.signIn(browserDoneMessage: 'done'), isA<SsoSignInSucceeded>());

      expect(sessions.persisted.single.refreshToken, isNull);
    });

    test('hands the return path and the browser message to the client', () async {
      await repository.signIn(webReturnPath: '/users', browserDoneMessage: 'You can close this window.');

      expect(client.signIns, [(webReturnPath: '/users', browserDoneMessage: 'You can close this window.')]);
    });

    test('an admin claim persists the admin and user roles', () async {
      final result = await signInWith(_claims(roles: ['admin']));

      expect(result, isA<SsoSignInSucceeded>().having((r) => r.roles, 'roles', ['ROLE_ADMIN', 'ROLE_USER']));
      expect(sessions.persisted.single.roles, ['ROLE_ADMIN', 'ROLE_USER']);
    });

    group('the username', () {
      test('is the email when there is one', () async {
        final result = await signInWith(_claims(extra: {'email': 'user@example.com', 'preferred_username': 'jdoe'}));

        expect((result as SsoSignInSucceeded).username, 'user@example.com');
      });

      test('is the preferred username when there is no email', () async {
        final result = await signInWith(_claims(extra: {'preferred_username': 'jdoe'}));

        expect((result as SsoSignInSucceeded).username, 'jdoe');
        expect(sessions.persisted.single.username, 'jdoe');
      });

      test('is the preferred username when the email is empty or not a string', () async {
        expect(
          (await signInWith(
            _claims(extra: {'email': '', 'preferred_username': 'jdoe'}),
          ) as SsoSignInSucceeded).username,
          'jdoe',
        );
        expect(
          (await signInWith(
            _claims(extra: {'email': 42, 'preferred_username': 'jdoe'}),
          ) as SsoSignInSucceeded).username,
          'jdoe',
        );
      });

      test('is the subject when there is neither an email nor a preferred username', () async {
        final result = await signInWith(_claims(extra: {'preferred_username': ''}));

        expect((result as SsoSignInSucceeded).username, 'subject-1');
        expect(sessions.persisted.single.username, 'subject-1');
      });
    });

    test('an account with no allowed role is rejected and nothing is persisted', () async {
      final result = await signInWith(_claims(roles: ['guest']));

      expect(result, isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcNoRole));
      expect(sessions.persisted, isEmpty);
    });

    for (final (name, claims) in [
      (
        'no sub',
        {
          'iss': 'https://id.example.com/realms/demo',
          'roles': const ['user'],
        },
      ),
      (
        'an empty sub',
        {
          'iss': 'https://id.example.com/realms/demo',
          'sub': '',
          'roles': const ['user'],
        },
      ),
      (
        'a sub that is not a string',
        {
          'iss': 'https://id.example.com/realms/demo',
          'sub': 7,
          'roles': const ['user'],
        },
      ),
      (
        'no iss',
        {
          'sub': 'subject-1',
          'roles': const ['user'],
        },
      ),
      (
        'an empty iss',
        {
          'iss': '',
          'sub': 'subject-1',
          'roles': const ['user'],
        },
      ),
      (
        'an iss that is not a string',
        {
          'iss': true,
          'sub': 'subject-1',
          'roles': const ['user'],
        },
      ),
    ]) {
      test('an ID token with $name is rejected and nothing is persisted', () async {
        final result = await signInWith(claims);

        expect(result, isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcNoClaims));
        expect(sessions.persisted, isEmpty);
      });
    }

    test('a provider that could not be reached is rejected with the discovery code', () async {
      client.signInOutcome = const OidcSignInFailed(OidcFailure.discovery);

      final result = await repository.signIn(browserDoneMessage: 'done');

      expect(result, isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcDiscovery));
      expect(sessions.persisted, isEmpty);
    });

    test('a failed sign-in is rejected with the failed code', () async {
      client.signInOutcome = const OidcSignInFailed(OidcFailure.failed);

      final result = await repository.signIn(browserDoneMessage: 'done');

      expect(result, isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcFailed));
      expect(sessions.persisted, isEmpty);
    });

    test('a cancel passes through', () async {
      client.signInOutcome = const OidcSignInCancelled();

      expect(await repository.signIn(browserDoneMessage: 'done'), isA<SsoSignInCancelled>());
      expect(sessions.persisted, isEmpty);
    });

    test('a web tab on its way to the provider passes through', () async {
      client.signInOutcome = const OidcSignInNavigatedAway();

      expect(await repository.signIn(browserDoneMessage: 'done'), isA<SsoSignInNavigatedAway>());
      expect(sessions.persisted, isEmpty);
    });

    test('a session that cannot be persisted is rejected with the persist code', () async {
      sessions.persistResult = const Failure(UnknownError('disk full'));

      final result = await signInWith(_claims());

      expect(
        result,
        isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authSessionPersistFailed),
      );
    });
  });

  group('SsoAuthRepository.completePendingSignIn', () {
    test('answers null when no sign-in is pending', () async {
      client.pendingOutcome = null;

      expect(await repository.completePendingSignIn(), isNull);
      expect(sessions.persisted, isEmpty);
    });

    test('persists a pending sign-in and answers its username and roles', () async {
      client.pendingOutcome = OidcSignedIn(
        tokens: _tokens,
        claims: _claims(extra: {'preferred_username': 'jdoe'}),
      );

      final result = await repository.completePendingSignIn();

      expect(
        result,
        isA<SsoSignInSucceeded>().having((r) => r.username, 'username', 'jdoe').having((r) => r.roles, 'roles', [
          'ROLE_USER',
        ]),
      );
      expect(sessions.persisted.single.oidcIdToken, 'id-token');
      expect(client.signIns, isEmpty);
    });

    test('maps a pending failure and a pending cancel like a sign-in', () async {
      client.pendingOutcome = const OidcSignInFailed(OidcFailure.discovery);
      expect(
        await repository.completePendingSignIn(),
        isA<SsoSignInRejected>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcDiscovery),
      );

      client.pendingOutcome = const OidcSignInCancelled();
      expect(await repository.completePendingSignIn(), isA<SsoSignInCancelled>());
    });
  });

  // A production build prints the info level, and the email mask does not cover a preferred username or a subject.
  group('SsoAuthRepository log output in production', () {
    late List<String> lines;

    setUp(() {
      AppLogger.configure(isProduction: true);
      lines = [];
      void collect(OutputEvent event) => lines.addAll(event.lines);
      Logger.addOutputListener(collect);
      addTearDown(() => Logger.removeOutputListener(collect));
    });

    tearDown(() => AppLogger.configure(isProduction: false));

    for (final (name, extra, username) in <(String, Map<String, Object?>, String)>[
      ('the preferred username', {'preferred_username': 'jdoe-identifier'}, 'jdoe-identifier'),
      ('the subject', {}, 'subject-1'),
    ]) {
      test('a sign-in whose username is $name logs the role but not the username', () async {
        final result = await signInWith(_claims(extra: extra));

        expect(result, isA<SsoSignInSucceeded>().having((r) => r.username, 'username', username));
        expect(lines.join('\n'), contains('with role user'));
        expect(lines.join('\n'), isNot(contains(username)));
      });
    }
  });
}
