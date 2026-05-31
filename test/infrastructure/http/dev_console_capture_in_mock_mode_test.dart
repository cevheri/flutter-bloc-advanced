import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/mock_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

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
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    ProfileConstants.setEnvironment(Environment.test);
    ApiClient.reset();
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
      TestUtils().setupAuthentication();

      await ApiClient.get('/test');

      final entries = DevConsoleStore.instance.networkEntries;
      expect(entries, isNotEmpty, reason: 'DevConsoleInterceptor.onRequest must run before the mock short-circuits');
      expect(
        entries.first.isComplete,
        isTrue,
        reason: 'mock callFollowing must propagate the response so onResponse completes the entry',
      );
      expect(entries.first.statusCode, isNotNull);
    });
  });
}
