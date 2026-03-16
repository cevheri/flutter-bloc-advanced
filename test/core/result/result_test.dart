import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create with data', () {
        const result = Success(42);
        expect(result.data, 42);
      });

      test('should create with string data', () {
        const result = Success('hello');
        expect(result.data, 'hello');
      });

      test('should create with complex data', () {
        final result = Success({'key': 'value'});
        expect(result.data, {'key': 'value'});
      });

      test('isSuccess should return true', () {
        const Result<int> result = Success(42);
        expect(result.isSuccess, isTrue);
      });

      test('isFailure should return false', () {
        const Result<int> result = Success(42);
        expect(result.isFailure, isFalse);
      });

      test('dataOrNull should return data', () {
        const Result<int> result = Success(42);
        expect(result.dataOrNull, 42);
      });

      test('toString should include data', () {
        const result = Success(42);
        expect(result.toString(), 'Success(42)');
      });

      test('equality should compare data', () {
        const a = Success(42);
        const b = Success(42);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('inequality when data differs', () {
        const a = Success(42);
        const b = Success(99);
        expect(a, isNot(equals(b)));
      });
    });

    group('Failure', () {
      test('should create with AppError', () {
        const result = Failure<int>(NetworkError('No internet'));
        expect(result.error, isA<NetworkError>());
        expect(result.error.message, 'No internet');
      });

      test('should create with stackTrace', () {
        final trace = StackTrace.current;
        final result = Failure<int>(const ServerError('fail'), stackTrace: trace);
        expect(result.stackTrace, isNotNull);
        expect(result.stackTrace, trace);
      });

      test('stackTrace should default to null', () {
        const result = Failure<int>(ServerError('fail'));
        expect(result.stackTrace, isNull);
      });

      test('isSuccess should return false', () {
        const Result<int> result = Failure(NetworkError('err'));
        expect(result.isSuccess, isFalse);
      });

      test('isFailure should return true', () {
        const Result<int> result = Failure(NetworkError('err'));
        expect(result.isFailure, isTrue);
      });

      test('dataOrNull should return null', () {
        const Result<int> result = Failure(NetworkError('err'));
        expect(result.dataOrNull, isNull);
      });

      test('toString should include error', () {
        const result = Failure<int>(NetworkError('No internet'));
        expect(result.toString(), 'Failure(NetworkError(No internet))');
      });

      test('equality should compare error', () {
        const a = Failure<int>(NetworkError('err'));
        const b = Failure<int>(NetworkError('err'));
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('inequality when error differs', () {
        const a = Failure<int>(NetworkError('err1'));
        const b = Failure<int>(NetworkError('err2'));
        expect(a, isNot(equals(b)));
      });
    });

    group('pattern matching', () {
      test('should match Success case', () {
        const Result<int> result = Success(42);
        final value = switch (result) {
          Success(:final data) => 'data: $data',
          Failure(:final error) => 'error: ${error.message}',
        };
        expect(value, 'data: 42');
      });

      test('should match Failure case', () {
        const Result<int> result = Failure(NetworkError('failed'));
        final value = switch (result) {
          Success(:final data) => 'data: $data',
          Failure(:final error) => 'error: ${error.message}',
        };
        expect(value, 'error: failed');
      });

      test('should destructure Success data', () {
        const Result<String> result = Success('hello');
        if (result case Success(:final data)) {
          expect(data, 'hello');
        } else {
          fail('Expected Success');
        }
      });

      test('should destructure Failure error', () {
        const Result<String> result = Failure(AuthError('unauthorized', code: '401'));
        if (result case Failure(:final error)) {
          expect(error.message, 'unauthorized');
          expect(error.code, '401');
        } else {
          fail('Expected Failure');
        }
      });
    });

    group('type safety', () {
      test('Success should maintain generic type', () {
        const Result<String> result = Success('typed');
        expect(result, isA<Result<String>>());
        expect(result, isA<Success<String>>());
      });

      test('Failure should maintain generic type', () {
        const Result<String> result = Failure(UnknownError('err'));
        expect(result, isA<Result<String>>());
        expect(result, isA<Failure<String>>());
      });
    });
  });
}
