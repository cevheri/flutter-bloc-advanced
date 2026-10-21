import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/mock_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/printed_lines.dart';

/// Builds a JWT signed nowhere: three base64url parts with the given `exp`, or with no `exp` claim when it is null.
String _jwt(DateTime? exp) {
  String part(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final payload = {'sub': 'admin', 'exp': ?(exp == null ? null : exp.millisecondsSinceEpoch ~/ 1000)};
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.${part(payload)}.c2lnbmF0dXJl';
}

/// The 401 the mock answers to a protected path it does not let through.
final _unauthorized = isA<DioException>()
    .having((e) => e.type, 'type', DioExceptionType.badResponse)
    .having((e) => e.response?.statusCode, 'statusCode', 401)
    .having((e) => e.response?.data, 'data', 'Unauthorized Access');

void main() {
  Dio mockDio() => Dio()..interceptors.add(MockInterceptor(appConfig: const AppConfig.test()));

  Future<Response<dynamic>> getAccount({String? authorization}) =>
      mockDio().get('/account', options: Options(headers: {'Authorization': ?authorization}));

  group('MockInterceptor bearer check', () {
    test('an expired JWT bearer gets a 401', () async {
      final expired = _jwt(DateTime.now().subtract(const Duration(minutes: 1)));

      await expectLater(getAccount(authorization: 'Bearer $expired'), throwsA(_unauthorized));
    });

    test('an unexpired JWT bearer reaches the mock file', () async {
      final valid = _jwt(DateTime.now().add(const Duration(minutes: 5)));

      final response = await getAccount(authorization: 'Bearer $valid');

      expect(response.statusCode, 200);
      expect(response.data, contains('"login": "admin"'));
    });

    test('a 3-part bearer without an exp claim still reaches the mock file', () async {
      final noExp = _jwt(null);
      late Response<dynamic> response;

      final lines = await printedLines(() async => response = await getAccount(authorization: 'Bearer $noExp'));

      expect(response.statusCode, 200);
      expect(response.data, contains('"login": "admin"'));
      expect(lines.where((line) => line.contains('[E]')), isEmpty);
    });

    test('the opaque MOCK_TOKEN still reaches the mock file', () async {
      final response = await getAccount(authorization: 'Bearer MOCK_TOKEN');

      expect(response.statusCode, 200);
      expect(response.data, contains('"login": "admin"'));
    });

    test('a request with no Authorization header still gets a 401', () async {
      await expectLater(getAccount(), throwsA(_unauthorized));
    });
  });
}
