import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/repositories/lifecycle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/printed_lines.dart';
import '../../../../support/test_env.dart';

// Regression: every AppException logged itself at error level when it was built, and the repository logged the
// failure it handled at error level again, so a 401, a validation error or a 404 that the user is shown printed two
// error lines. The repository now logs a handled failure once, as a warning, or as info for a validation error.
void main() {
  final calls = <String, Future<Object?> Function(LifecycleRepository)>{
    'fetchAppConfig': (repository) => repository.fetchAppConfig(),
  };
  const failures = [
    (status: 401, kind: 'auth error', label: '[W]'),
    (status: 404, kind: 'network error', label: '[W]'),
  ];

  group('LifecycleRepository logs a failed request once', () {
    for (final MapEntry(key: method, value: call) in calls.entries) {
      for (final (:status, :kind, :label) in failures) {
        test('$method logs a $status response as $kind at $label', () async {
          final apiClient = TestEnv.apiClient();
          apiClient.instance.interceptors.insert(0, _StatusInterceptor(status));

          final lines = await printedLines(() => call(LifecycleRepository(apiClient)));

          expect(lines.where((line) => line.contains('LifecycleRepository : $method $kind: ')), [contains(label)]);
          expect(lines.where((line) => line.contains('[E]')), isEmpty);
        });
      }
    }

    // The app config sends no data, so a 400 is an unexpected failure, and it was reported without a line of its own.
    test('fetchAppConfig logs a 400 response as unknown error at [E]', () async {
      final apiClient = TestEnv.apiClient();
      apiClient.instance.interceptors.insert(0, _StatusInterceptor(400));

      final lines = await printedLines(() => LifecycleRepository(apiClient).fetchAppConfig());

      expect(lines.where((line) => line.contains('[E]')), [
        allOf(contains('LifecycleRepository : fetchAppConfig unknown error: '), contains('Invalid Request: ')),
      ]);
    });
  });
}

/// Fails every request with an error response of [statusCode] before the rest of the chain runs, so ApiClient turns it
/// into the AppException that the repository catches.
class _StatusInterceptor extends Interceptor {
  _StatusInterceptor(this.statusCode);

  final int statusCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: statusCode, data: '{"title":"refused"}'),
      ),
    );
  }
}
