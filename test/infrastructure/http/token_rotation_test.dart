import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [BackendTokenRotation] whose refresh request [stub] answers instead of the network, and the requests it sent.
({BackendTokenRotation rotation, List<RequestOptions> sent}) _rotationAnsweredBy(_StubInterceptor stub) {
  final sent = <RequestOptions>[];
  final rotation = BackendTokenRotation(
    dio: Dio(BaseOptions(baseUrl: 'https://test.api')),
    refreshDioFactory: (source) =>
        Dio(BaseOptions(baseUrl: source.options.baseUrl))..interceptors.addAll([_RecordingInterceptor(sent), stub]),
  );
  return (rotation: rotation, sent: sent);
}

void main() {
  // A misconfigured oidc build may hold a refresh token of the identity provider, which no backend may receive.
  group('RefusingTokenRotation', () {
    test('refuses every refresh', () async {
      expect(await const RefusingTokenRotation().rotate('provider-refresh-token'), isA<RotationRefused>());
    });
  });

  group('BackendTokenRotation', () {
    test('posts the refresh token to the refresh endpoint', () async {
      final (:rotation, :sent) = _rotationAnsweredBy(_StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}'));

      await rotation.rotate('valid-refresh');

      expect(sent.map((options) => '${options.method} ${options.path} ${options.data}'), [
        'POST /api/token/refresh {"refresh_token":"valid-refresh"}',
      ]);
    });

    test('a 200 with id_token and refresh_token gives TokensRotated with both', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(
        _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt","refresh_token":"new-refresh"}'),
      );

      final result = await rotation.rotate('valid-refresh');

      expect(
        result,
        isA<TokensRotated>()
            .having((r) => r.accessToken, 'accessToken', 'new-jwt')
            .having((r) => r.refreshToken, 'refreshToken', 'new-refresh')
            .having((r) => r.oidcIdToken, 'oidcIdToken', isNull)
            .having((r) => r.accessTokenExpiresAt, 'accessTokenExpiresAt', isNull),
      );
    });

    test('a 200 with only id_token gives TokensRotated without a refresh token', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(_StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}'));

      final result = await rotation.rotate('valid-refresh');

      expect(result, isA<TokensRotated>().having((r) => r.refreshToken, 'refreshToken', isNull));
    });

    test('a 201 is a success too', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(
        _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}', statusCode: 201),
      );

      expect(await rotation.rotate('valid-refresh'), isA<TokensRotated>());
    });

    test('a 2xx other than 200 and 201 gives RotationRefused', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(
        _StubInterceptor()..stubSuccess(data: '{"id_token":"new-jwt"}', statusCode: 204),
      );

      expect(await rotation.rotate('valid-refresh'), isA<RotationRefused>());
    });

    test('a 401 gives RotationRefused', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(_StubInterceptor()..stubError(statusCode: 401));

      expect(await rotation.rotate('valid-refresh'), isA<RotationRefused>());
    });

    test('a 500 gives RotationRefused', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(_StubInterceptor()..stubError(statusCode: 500));

      expect(await rotation.rotate('valid-refresh'), isA<RotationRefused>());
    });

    test('a transport error gives RotationRefused, as every refresh failure in jwt mode', () async {
      final (:rotation, sent: _) = _rotationAnsweredBy(_StubInterceptor()..stubTransportError());

      expect(await rotation.rotate('valid-refresh'), isA<RotationRefused>());
    });

    for (final (name, body) in [
      ('a malformed body', '{"id_token":"new-jwt","refresh_token":"new-ref'),
      ('a body without id_token', '{}'),
      ('an empty id_token', '{"id_token":""}'),
      ('a JSON array', '["not", "a", "map"]'),
    ]) {
      test('$name gives RotationRefused', () async {
        final (:rotation, sent: _) = _rotationAnsweredBy(_StubInterceptor()..stubSuccess(data: body));

        expect(await rotation.rotate('valid-refresh'), isA<RotationRefused>());
      });
    }
  });

  group('defaultRefreshDio', () {
    test('shares the adapter of the source Dio and takes the body as text', () {
      final source = Dio(BaseOptions(baseUrl: 'https://test.api'));

      final refreshDio = defaultRefreshDio(source);

      expect(refreshDio.httpClientAdapter, same(source.httpClientAdapter));
      expect(refreshDio.options.baseUrl, 'https://test.api');
      expect(refreshDio.options.responseType, ResponseType.plain);
    });
  });

  group('TokensRotated', () {
    test('masks every token in toString', () {
      final text = TokensRotated(
        accessToken: 'access-token-123456',
        refreshToken: 'refresh-token-654321',
        oidcIdToken: 'id-token-abcdef',
        accessTokenExpiresAt: DateTime.utc(2026, 10, 21, 12),
      ).toString();

      expect(text, allOf(isNot(contains('access-token-123456')), isNot(contains('refresh-token-654321'))));
      expect(text, isNot(contains('id-token-abcdef')));
      expect(text, contains('2026-10-21'));
    });
  });

  group('isUnauthorized', () {
    DioException errorWith(int? statusCode) {
      final options = RequestOptions(path: '/api/users');
      return DioException(
        requestOptions: options,
        response: statusCode == null ? null : Response(requestOptions: options, statusCode: statusCode),
      );
    }

    test('accepts a 401', () => expect(isUnauthorized(errorWith(401)), isTrue));

    test('refuses a 403', () => expect(isUnauthorized(errorWith(403)), isFalse));

    test('refuses an error without a response', () => expect(isUnauthorized(errorWith(null)), isFalse));
  });
}

/// Records every request that reaches it, then passes it on.
class _RecordingInterceptor extends Interceptor {
  _RecordingInterceptor(this.sent);

  final List<RequestOptions> sent;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    sent.add(options);
    handler.next(options);
  }
}

/// Answers the refresh request with a stubbed response or error before any real HTTP call.
class _StubInterceptor extends Interceptor {
  int? _errorStatusCode;
  bool _transportError = false;
  String? _successData;
  int _successStatusCode = 200;

  void stubError({required int statusCode}) => _errorStatusCode = statusCode;

  void stubTransportError() => _transportError = true;

  void stubSuccess({required String data, int statusCode = 200}) {
    _successData = data;
    _successStatusCode = statusCode;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_transportError) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError), true);
      return;
    }
    if (_errorStatusCode != null) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: _errorStatusCode!, data: ''),
        ),
        true,
      );
      return;
    }
    handler.resolve(Response(requestOptions: options, data: _successData!, statusCode: _successStatusCode));
  }
}
