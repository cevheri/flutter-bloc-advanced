import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/printed_lines.dart';
import '../../../../support/test_env.dart';

// Regression: every AppException logged itself at error level when it was built, and the repository logged the
// failure it handled at error level again, so a 401, a validation error or a 404 that the user is shown printed two
// error lines. The repository now logs a handled failure once, as a warning, or as info for a validation error.
void main() {
  final calls = <String, Future<Object?> Function(LoginRepository)>{
    'authenticate': (repository) =>
        repository.authenticate(const AuthCredentialsEntity(username: 'jane', password: 'Secret#1')),
    'sendOtp': (repository) => repository.sendOtp(const SendOtpEntity(email: 'jane@example.test')),
    'verifyOtp': (repository) => repository.verifyOtp(const VerifyOtpEntity(email: 'jane@example.test', otp: '123456')),
  };
  const failures = [
    (status: 401, kind: 'auth error', label: '[W]'),
    (status: 400, kind: 'validation error', label: '[I]'),
    (status: 404, kind: 'network error', label: '[W]'),
  ];

  group('LoginRepository logs a failed request once', () {
    for (final MapEntry(key: method, value: call) in calls.entries) {
      for (final (:status, :kind, :label) in failures) {
        test('$method logs a $status response as $kind at $label', () async {
          final apiClient = TestEnv.apiClient();
          apiClient.instance.interceptors.insert(0, _StatusInterceptor(status));

          final lines = await printedLines(() => call(LoginRepository(apiClient: apiClient)));

          expect(lines.where((line) => line.contains('LoginRepository : END:$method $kind: ')), [contains(label)]);
          expect(lines.where((line) => line.contains('[E]')), isEmpty);
        });
      }
    }
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
