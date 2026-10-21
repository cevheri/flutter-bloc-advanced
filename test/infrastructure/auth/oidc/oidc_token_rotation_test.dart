import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/auth_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';

class _MockOidcClient extends Mock implements IOidcClient {}

void main() {
  final expiresAt = DateTime.utc(2026, 10, 21, 12);
  late _MockOidcClient client;
  late MockISecureStorage storage;
  late OidcTokenRotation rotation;

  setUp(() {
    client = _MockOidcClient();
    storage = MockISecureStorage();
    rotation = OidcTokenRotation(client: client, secureStorage: storage);
    when(() => storage.read(SecureStorageKeys.refreshToken.key)).thenAnswer((_) async => 'refresh-value');
    when(() => storage.read(SecureStorageKeys.jwtToken.key)).thenAnswer((_) async => 'access-value');
    when(() => storage.read(SecureStorageKeys.oidcIdToken.key)).thenAnswer((_) async => 'id-token-value');
    when(() => storage.read(SecureStorageKeys.accessTokenExpiresAt.key))
        .thenAnswer((_) async => encodeAccessTokenExpiry(expiresAt));
  });

  void stubRefresh(TokenRotationResult result) {
    when(
      () => client.refresh(
        refreshToken: any(named: 'refreshToken'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
        accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('reads the stored tokens and refreshes with them', () async {
    const rotated = TokensRotated(accessToken: 'access-new-value');
    stubRefresh(rotated);

    final result = await rotation.rotate('refresh-value');

    expect(result, same(rotated));
    verify(
      () => client.refresh(
        refreshToken: 'refresh-value',
        idToken: 'id-token-value',
        accessToken: 'access-value',
        accessTokenExpiresAt: expiresAt,
      ),
    ).called(1);
  });

  test('passes the client answer on, refused or unavailable', () async {
    stubRefresh(const RotationUnavailable());

    expect(await rotation.rotate('refresh-value'), isA<RotationUnavailable>());
  });

  for (final (name, key) in [
    ('ID token', SecureStorageKeys.oidcIdToken),
    ('expiry', SecureStorageKeys.accessTokenExpiresAt),
    ('access token', SecureStorageKeys.jwtToken),
  ]) {
    test('a missing stored $name is RotationRefused with no request', () async {
      when(() => storage.read(key.key)).thenAnswer((_) async => null);

      expect(await rotation.rotate('refresh-value'), isA<RotationRefused>());
      verifyZeroInteractions(client);
    });
  }

  test('an empty stored ID token is RotationRefused with no request', () async {
    when(() => storage.read(SecureStorageKeys.oidcIdToken.key)).thenAnswer((_) async => '');

    expect(await rotation.rotate('refresh-value'), isA<RotationRefused>());
    verifyZeroInteractions(client);
  });

  group('one refresh token is sent once', () {
    void stubSlowRefresh(Completer<TokenRotationResult> answer) {
      when(
        () => client.refresh(
          refreshToken: any(named: 'refreshToken'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
          accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
        ),
      ).thenAnswer((_) => answer.future);
    }

    int grants() => verify(
      () => client.refresh(
        refreshToken: any(named: 'refreshToken'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
        accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
      ),
    ).callCount;

    test('two concurrent rotations with the same refresh token make one grant and get its answer', () async {
      final answer = Completer<TokenRotationResult>();
      stubSlowRefresh(answer);
      const rotated = TokensRotated(accessToken: 'access-new-value', refreshToken: 'refresh-new-value');

      final first = rotation.rotate('refresh-value');
      final second = rotation.rotate('refresh-value');
      await pumpEventQueue();
      answer.complete(rotated);

      expect(await first, same(rotated));
      expect(await second, same(rotated));
      expect(grants(), 1);
    });

    test('a refused refresh token is not sent again', () async {
      stubRefresh(const RotationRefused());

      expect(await rotation.rotate('refresh-value'), isA<RotationRefused>());
      expect(await rotation.rotate('refresh-value'), isA<RotationRefused>());
      expect(grants(), 1);
    });

    test('a refresh token the provider could not be reached for is sent again', () async {
      stubRefresh(const RotationUnavailable());

      await rotation.rotate('refresh-value');
      await rotation.rotate('refresh-value');
      expect(grants(), 2);
    });

    test('a refresh token that storage no longer holds makes no grant, and keeps the stored session', () async {
      when(() => storage.read(SecureStorageKeys.refreshToken.key)).thenAnswer((_) async => 'refresh-other-value');

      expect(await rotation.rotate('refresh-value'), isA<RotationUnavailable>());
      verifyZeroInteractions(client);
    });

    test('a request sent during a slow startup refresh is retried with the access token the startup stored', () async {
      final memory = _MemorySecureStorage()
        ..values[SecureStorageKeys.jwtToken.key] = 'access-value'
        ..values[SecureStorageKeys.refreshToken.key] = 'refresh-value'
        ..values[SecureStorageKeys.oidcIdToken.key] = 'id-token-value'
        ..values[SecureStorageKeys.accessTokenExpiresAt.key] = encodeAccessTokenExpiry(expiresAt);
      final answer = Completer<TokenRotationResult>();
      stubSlowRefresh(answer);
      final shared = OidcTokenRotation(client: client, secureStorage: memory);
      final dio = Dio(BaseOptions(baseUrl: 'https://test.api'));
      addTearDown(dio.close);
      final server = _ServerStub();
      dio.interceptors
        ..add(TokenRefreshInterceptor(dio: dio, secureStorage: memory, rotation: shared))
        ..add(server);

      // The startup step: rotates, then stores what it got, bearer first.
      final startup = shared.rotate('refresh-value').then((result) async {
        final rotated = result as TokensRotated;
        await memory.write(SecureStorageKeys.jwtToken.key, rotated.accessToken);
        await memory.write(SecureStorageKeys.refreshToken.key, rotated.refreshToken!);
      });
      await pumpEventQueue();
      final request = dio.get<String>(
        '/api/users',
        options: Options(
          headers: {'Authorization': 'Bearer access-value'},
          // What AuthInterceptor records on every request it sends.
          extra: {AuthInterceptor.sessionGenerationKey: SessionGeneration.current},
        ),
      );
      await pumpEventQueue();
      answer.complete(const TokensRotated(accessToken: 'access-new-value', refreshToken: 'refresh-new-value'));
      await startup;

      expect((await request).statusCode, 200);
      expect(server.authorizations, ['Bearer access-value', 'Bearer access-new-value']);
      expect(grants(), 1);
      expect(memory.values[SecureStorageKeys.refreshToken.key], 'refresh-new-value');
    });
  });
}

class _MemorySecureStorage implements ISecureStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> deleteAll() async => values.clear();
}

/// Answers 401 to a request with the old bearer, which runs the error interceptors as a server response does, and 200
/// to any other. Records each Authorization header.
class _ServerStub extends Interceptor {
  final authorizations = <String?>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final authorization = options.headers['Authorization'] as String?;
    authorizations.add(authorization);
    if (authorization == 'Bearer access-value') {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 401),
        ),
        true,
      );
      return;
    }
    handler.resolve(Response(requestOptions: options, statusCode: 200, data: 'ok'));
  }
}
