import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppError', () {
    group('NetworkError', () {
      test('should create with message only', () {
        const error = NetworkError('No internet connection');
        expect(error.message, 'No internet connection');
        expect(error.code, isNull);
      });

      test('should create with message and code', () {
        const error = NetworkError('DNS failure', code: 'DNS_LOOKUP_FAILED');
        expect(error.message, 'DNS failure');
        expect(error.code, 'DNS_LOOKUP_FAILED');
      });

      test('should be an AppError', () {
        const error = NetworkError('test');
        expect(error, isA<AppError>());
      });

      test('toString should include type and message', () {
        const error = NetworkError('No internet');
        expect(error.toString(), 'NetworkError(No internet)');
      });

      test('toString should include code when present', () {
        const error = NetworkError('No internet', code: 'NET_ERR');
        expect(error.toString(), 'NetworkError(No internet, code: NET_ERR)');
      });
    });

    group('AuthError', () {
      test('should create with message', () {
        const error = AuthError('Unauthorized');
        expect(error.message, 'Unauthorized');
        expect(error.code, isNull);
      });

      test('should create with message and code', () {
        const error = AuthError('Token expired', code: '401');
        expect(error.message, 'Token expired');
        expect(error.code, '401');
      });

      test('should be an AppError', () {
        const error = AuthError('test');
        expect(error, isA<AppError>());
      });
    });

    group('ValidationError', () {
      test('should create with message', () {
        const error = ValidationError('Invalid email');
        expect(error.message, 'Invalid email');
      });

      test('should be an AppError', () {
        const error = ValidationError('test');
        expect(error, isA<AppError>());
      });
    });

    group('ServerError', () {
      test('should create with message', () {
        const error = ServerError('Internal server error');
        expect(error.message, 'Internal server error');
      });

      test('should create with code', () {
        const error = ServerError('Server error', code: '500');
        expect(error.code, '500');
      });

      test('should be an AppError', () {
        const error = ServerError('test');
        expect(error, isA<AppError>());
      });
    });

    group('NotFoundError', () {
      test('should create with message', () {
        const error = NotFoundError('User not found');
        expect(error.message, 'User not found');
      });

      test('should be an AppError', () {
        const error = NotFoundError('test');
        expect(error, isA<AppError>());
      });
    });

    group('TimeoutError', () {
      test('should create with message', () {
        const error = TimeoutError('Request timed out');
        expect(error.message, 'Request timed out');
      });

      test('should be an AppError', () {
        const error = TimeoutError('test');
        expect(error, isA<AppError>());
      });
    });

    group('UnknownError', () {
      test('should create with message', () {
        const error = UnknownError('Something went wrong');
        expect(error.message, 'Something went wrong');
      });

      test('should be an AppError', () {
        const error = UnknownError('test');
        expect(error, isA<AppError>());
      });
    });

    group('equality', () {
      test('same type, same message, same code should be equal', () {
        const a = NetworkError('msg', code: 'c');
        const b = NetworkError('msg', code: 'c');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('same type, same message, no code should be equal', () {
        const a = ServerError('error');
        const b = ServerError('error');
        expect(a, equals(b));
      });

      test('same type, different message should not be equal', () {
        const a = NetworkError('msg1');
        const b = NetworkError('msg2');
        expect(a, isNot(equals(b)));
      });

      test('same type, same message, different code should not be equal', () {
        const a = NetworkError('msg', code: 'c1');
        const b = NetworkError('msg', code: 'c2');
        expect(a, isNot(equals(b)));
      });

      test('different types with same message should still be equal (AppError equality)', () {
        // The == operator is defined on AppError and checks message + code only
        const a = NetworkError('msg');
        const b = ServerError('msg');
        expect(a == b, isTrue);
      });
    });

    group('pattern matching (sealed class)', () {
      test('should match NetworkError', () {
        const AppError error = NetworkError('test');
        final result = switch (error) {
          NetworkError() => 'network',
          AuthError() => 'auth',
          ValidationError() => 'validation',
          ServerError() => 'server',
          NotFoundError() => 'not_found',
          TimeoutError() => 'timeout',
          UnknownError() => 'unknown',
        };
        expect(result, 'network');
      });

      test('should match AuthError', () {
        const AppError error = AuthError('test');
        final result = switch (error) {
          NetworkError() => 'network',
          AuthError() => 'auth',
          ValidationError() => 'validation',
          ServerError() => 'server',
          NotFoundError() => 'not_found',
          TimeoutError() => 'timeout',
          UnknownError() => 'unknown',
        };
        expect(result, 'auth');
      });

      test('should match ServerError', () {
        const AppError error = ServerError('test');
        final result = switch (error) {
          NetworkError() => 'network',
          AuthError() => 'auth',
          ValidationError() => 'validation',
          ServerError() => 'server',
          NotFoundError() => 'not_found',
          TimeoutError() => 'timeout',
          UnknownError() => 'unknown',
        };
        expect(result, 'server');
      });

      test('should match all subclasses exhaustively', () {
        final errors = <AppError>[
          const NetworkError('n'),
          const AuthError('a'),
          const ValidationError('v'),
          const ServerError('s'),
          const NotFoundError('nf'),
          const TimeoutError('t'),
          const UnknownError('u'),
        ];

        final results = errors
            .map(
              (error) => switch (error) {
                NetworkError() => 'network',
                AuthError() => 'auth',
                ValidationError() => 'validation',
                ServerError() => 'server',
                NotFoundError() => 'not_found',
                TimeoutError() => 'timeout',
                UnknownError() => 'unknown',
              },
            )
            .toList();

        expect(results, ['network', 'auth', 'validation', 'server', 'not_found', 'timeout', 'unknown']);
      });
    });
  });
}
