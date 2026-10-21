import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/di/app_scope.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

final _oidcSettings = OidcSettings(issuer: Uri.parse('https://id.example.com/realms/demo'), clientId: 'app');

/// Completes a pending web sign-in with [pending], as the tab that came back from the provider would.
class _PendingSignInClient implements IOidcClient {
  _PendingSignInClient(this.pending);

  final OidcSignInOutcome? pending;

  @override
  Future<OidcSignInOutcome?> completePendingSignIn() async => pending;

  @override
  Future<OidcSignInOutcome> signIn({String? webReturnPath, required String browserDoneMessage}) =>
      throw UnimplementedError('these tests never tap the sign-in button');

  @override
  Future<TokenRotationResult> refresh({
    required String refreshToken,
    required String idToken,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) => throw UnimplementedError('these tests store no expired session');

  @override
  Future<OidcLogoutOutcome> endProviderSession({String? idTokenHint}) =>
      throw UnimplementedError('these tests never log out');
}

/// The test config in an oidc build over [client], recording the rotation its ApiClient is given.
class _OidcDependencies extends AppDependencies {
  _OidcDependencies(this.client) : super(appConfig: const AppConfig.test(), authMode: OidcAuthMode(_oidcSettings));

  final IOidcClient client;
  final apiClientRotations = <TokenRotation>[];

  @override
  IOidcClient createOidcClient(OidcSettings settings) => client;

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      throw StateError('an oidc build must create its ApiClient through createOidcApiClient');

  @override
  ApiClient createOidcApiClient(
    ISecureStorage secureStorage, {
    required OnSessionExpired onSessionExpired,
    required TokenRotation tokenRotation,
  }) {
    apiClientRotations.add(tokenRotation);
    return super.createOidcApiClient(secureStorage, onSessionExpired: onSessionExpired, tokenRotation: tokenRotation);
  }
}

/// The test config in a misconfigured oidc build, recording the rotation its ApiClient is given.
class _MisconfiguredDependencies extends AppDependencies {
  _MisconfiguredDependencies()
    : super(
        appConfig: const AppConfig.test(),
        authMode: const OidcMisconfiguredAuthMode('OIDC_SCOPE must hold openid'),
      );

  final apiClientRotations = <TokenRotation>[];

  @override
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      throw StateError('a misconfigured oidc build must never refresh through the backend refresh endpoint');

  @override
  ApiClient createOidcApiClient(
    ISecureStorage secureStorage, {
    required OnSessionExpired onSessionExpired,
    required TokenRotation tokenRotation,
  }) {
    apiClientRotations.add(tokenRotation);
    return super.createOidcApiClient(secureStorage, onSessionExpired: onSessionExpired, tokenRotation: tokenRotation);
  }
}

/// Pumps [AppScope] over [dependencies] and returns a context below it.
Future<BuildContext> _pumpScope(WidgetTester tester, AppDependencies dependencies) async {
  late BuildContext scope;
  await tester.pumpWidget(
    AppScope(
      dependencies: dependencies,
      defaultLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          scope = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return scope;
}

/// Reads [SessionCubit], which starts its restore, and waits for the first state the restore settles.
Future<SessionState> _restoredSession(WidgetTester tester, BuildContext scope) async {
  final session = scope.read<SessionCubit>();
  if (session.state is! SessionUnknown) return session.state;
  final settled = await tester.runAsync(() => session.stream.firstWhere((state) => state is! SessionUnknown));
  expect(settled, isNotNull, reason: 'the restore never settled the session');
  return settled!;
}

void main() {
  group('AppScope startup in an oidc build', () {
    testWidgets('a pending web sign-in completes while the session is restored', (tester) async {
      final expiresAt = DateTime.utc(2100);
      final scope = await _pumpScope(
        tester,
        _OidcDependencies(
          _PendingSignInClient(
            OidcSignedIn(
              tokens: OidcTokens(
                accessToken: 'sso-access-token',
                idToken: 'sso-id-token',
                refreshToken: 'sso-refresh-token',
                accessTokenExpiresAt: expiresAt,
              ),
              claims: const {'iss': 'https://id.example.com/realms/demo', 'sub': 'subject-1'},
            ),
          ),
        ),
      );

      expect(await _restoredSession(tester, scope), const SessionAuthenticated(roles: {'ROLE_USER'}));
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.jwtToken.key), 'sso-access-token');
      expect(scope.read<SsoAutoRedirectGate>().isOpen, isTrue);
    });

    testWidgets('a pending web sign-in that fails signs out with its error and closes the gate', (tester) async {
      final scope = await _pumpScope(
        tester,
        _OidcDependencies(_PendingSignInClient(const OidcSignInFailed(OidcFailure.discovery))),
      );

      expect(
        await _restoredSession(tester, scope),
        const SessionUnauthenticated(
          reason: SessionExpiredReason.signInFailed,
          signInError: AppErrorCode.authOidcDiscovery,
        ),
      );
      expect(scope.read<SsoAutoRedirectGate>().isOpen, isFalse);
    });

    testWidgets('the ApiClient refreshes through the one TokenRotation the scope provides', (tester) async {
      final dependencies = _OidcDependencies(_PendingSignInClient(null));
      final scope = await _pumpScope(tester, dependencies);

      scope.read<ApiClient>();

      expect(dependencies.apiClientRotations, hasLength(1));
      expect(dependencies.apiClientRotations.single, same(scope.read<TokenRotation>()));
    });
  });

  // A session that an earlier, correctly configured oidc build stored holds the provider's tokens.
  group('AppScope in a misconfigured oidc build, with a session an earlier oidc build stored', () {
    setUp(() async {
      final storage = FlutterSecureStorageAdapter();
      await storage.write(SecureStorageKeys.jwtToken.key, 'provider-access-token');
      await storage.write(SecureStorageKeys.refreshToken.key, 'provider-refresh-token');
      await storage.write(SecureStorageKeys.oidcIdToken.key, 'provider-id-token');
      await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN', 'ROLE_USER']);
    });

    testWidgets('restores signed out with the configuration error, and leaves the stored session alone', (
      tester,
    ) async {
      final scope = await _pumpScope(tester, _MisconfiguredDependencies());

      expect(
        await _restoredSession(tester, scope),
        const SessionUnauthenticated(
          reason: SessionExpiredReason.signInFailed,
          signInError: AppErrorCode.authOidcConfig,
        ),
      );
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), 'provider-refresh-token');
    });

    // The backend refresh endpoint must never receive the provider's refresh token.
    testWidgets('the ApiClient refreshes through a rotation that refuses every refresh', (tester) async {
      final dependencies = _MisconfiguredDependencies();
      final scope = await _pumpScope(tester, dependencies);

      scope.read<ApiClient>();

      expect(dependencies.apiClientRotations, hasLength(1));
      final rotation = dependencies.apiClientRotations.single;
      expect(rotation, isNot(isA<BackendTokenRotation>()));
      expect(await rotation.rotate('provider-refresh-token'), isA<RotationRefused>());
    });
  });

  testWidgets('a jwt build provides no automatic redirect gate', (tester) async {
    final scope = await _pumpScope(tester, const AppDependencies(appConfig: AppConfig.test()));

    expect(() => scope.read<SsoAutoRedirectGate>(), throwsA(isA<ProviderNotFoundException>()));
  });
}
