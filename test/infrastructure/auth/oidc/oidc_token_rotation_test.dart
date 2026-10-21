import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
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
}
