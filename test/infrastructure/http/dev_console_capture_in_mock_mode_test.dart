import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/mock_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

/// Records whether its onResponse fired — stands in for the observability
/// interceptors (DevConsole / Logging) that must see mock-served responses.
class _ResponseRecorder extends Interceptor {
  final List<int?> seen = [];

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    seen.add(response.statusCode);
    handler.next(response);
  }
}

void main() {
  setUp(() {
    DevConsoleStore.instance.clearNetwork();
  });

  tearDown(() {
    DevConsoleStore.instance.clearNetwork();
  });

  group('MockInterceptor response propagation (#regression)', () {
    test('mock-served response reaches a preceding onResponse interceptor', () async {
      final recorder = _ResponseRecorder();
      final dio = Dio()..interceptors.addAll([recorder, MockInterceptor()]);

      await dio.delete('/anything', options: Options(headers: {'Authorization': 'Bearer t'}));

      expect(
        recorder.seen,
        isNotEmpty,
        reason: 'mock must resolve with callFollowing so onResponse handlers (DevConsole, Logging) run',
      );
    });
  });

  group('DevConsole captures requests in dev/test (mock) mode', () {
    test('a mock-served GET appears in DevConsoleStore AND is marked complete', () async {
      TestEnv.authenticate();

      await TestEnv.apiClient().get('/account');

      final entries = DevConsoleStore.instance.networkEntries;
      expect(entries, isNotEmpty, reason: 'DevConsoleInterceptor.onRequest must run before the mock short-circuits');
      expect(
        entries.first.isComplete,
        isTrue,
        reason: 'mock callFollowing must propagate the response so onResponse completes the entry',
      );
      expect(entries.first.statusCode, isNotNull);
    });

    test('a mock 401 for a request without a token is marked complete with its status', () async {
      await expectLater(TestEnv.apiClient().get('/test'), throwsA(isA<UnauthorizedException>()));

      final entry = DevConsoleStore.instance.networkEntries.single;
      expect(
        entry.isComplete,
        isTrue,
        reason: 'the mock must reject with callFollowing so onError completes the entry, as for a server 401',
      );
      expect(entry.statusCode, 401);
    });

    // Regression: the Network tab kept every request as it was sent: the Authorization header with the whole access
    // token, the sign-in password, the OTP, both passwords of a change, the password an admin sets on the extended
    // information form and the tokens of the sign-in response. Each section of the tab has a Copy button.
    test('records the requests without the credentials they carry', () async {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6NDEwMjQ0NDgwMH0.c2lnbmF0dXJlLXNpZ25hdHVyZQ';
      const secrets = [
        jwt,
        'S3cret!pw',
        '493817',
        'OldPass#1',
        'NewPass#2',
        'Adm1nSet!Pw',
        'MOCK_TOKEN',
        'MOCK_REFRESH',
      ];
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.jwtToken.key, jwt);
      final api = TestEnv.apiClient();

      await api.post('/authenticate', {'username': 'admin', 'password': 'S3cret!pw'});
      await api.post('/authenticate/verify-otp', {'email': 'otp.user@example.com', 'otp': '493817'});
      await api.post('/account/change-password', {'currentPassword': 'OldPass#1', 'newPassword': 'NewPass#2'});
      await api.get('/account');
      await api.put('/admin/users/extended', {
        'email': 'alice@example.com',
        'newPassword': 'Adm1nSet!Pw',
      }, pathParams: 'user-2');

      final entries = DevConsoleStore.instance.networkEntries;
      final recorded = [
        for (final entry in entries)
          '${entry.requestHeaders} | ${entry.requestBody} | ${entry.responseHeaders} | ${entry.responseBody}',
      ];
      expect(recorded, hasLength(5));
      expect(recorded, everyElement(allOf([for (final secret in secrets) isNot(contains(secret))])));
      // The tab still shows that a request carried a token, and which fields it sent.
      final changePassword = entries.singleWhere((entry) => entry.url.endsWith('/account/change-password'));
      expect(changePassword.requestHeaders, containsPair('Authorization', '[REDACTED]'));
      expect(changePassword.requestBody, allOf(contains('currentPassword'), contains('newPassword')));
    });

    test('a request without a mock file is marked complete with 501 and names the missing file', () async {
      TestEnv.authenticate();

      await expectLater(TestEnv.apiClient().get('/test'), throwsA(isA<FetchDataException>()));

      final entry = DevConsoleStore.instance.networkEntries.single;
      expect(entry.isComplete, isTrue);
      expect(entry.statusCode, 501);
      expect(entry.error, contains('assets/mock/GET_test.json'));
    });
  });
}
