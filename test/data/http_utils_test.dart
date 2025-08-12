import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/http_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../test_utils.dart';
import 'http_utils_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    mockClient = MockClient();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('Api Exceptions', () {
    //FetchDataException
    test('given FetchDataException when created then should return message', () {
      final exception = FetchDataException('Test Fetch Data Exception');
      expect(exception.toString(), equals('Error During Communication: Test Fetch Data Exception'));
    });
    //BadRequestException
    test('given BadRequestException when created then should return message', () {
      final exception = BadRequestException('Test Bad Request');
      expect(exception.toString(), equals('Invalid Request: Test Bad Request'));
    });
    //UnauthorizedException
    test('given UnauthorizedException when created then should return message', () {
      final exception = UnauthorizedException('Test access denied');
      expect(exception.toString(), equals('Unauthorized: Test access denied'));
    });
    //InvalidInputException
    test('given InvalidInputException when created then should return message', () {
      final exception = InvalidInputException('Test invalid data');
      expect(exception.toString(), equals('Invalid Input: Test invalid data'));
    });
    //ApiBusinessException
    test('given ApiBusinessException when created then should return message', () {
      final exception = ApiBusinessException('Test Business Exception');
      expect(exception.toString(), equals('Api Business Exception: Test Business Exception'));
    });
  });

  group('HttpUtils Tests', () {
    tearDown(() {
      HttpUtils.resetHttpClient();
    });

    test('http client set should be default', () {
      HttpUtils.setHttpClient(http.Client());
      expect(HttpUtils.client, isA<http.Client>());
    });
    test('http client should be default', () {
      expect(HttpUtils.client, isA<http.Client>());
    });
    test('http mock client should be mock', () {
      HttpUtils.setHttpClient(mockClient);
      expect(HttpUtils.client, isA<MockClient>());
    });

    test('should return default client after reset', () {
      HttpUtils.setHttpClient(mockClient);
      HttpUtils.resetHttpClient();
      expect(HttpUtils.client, isA<http.Client>());
    });

    test('given a new custom header when added then it should be in headers', () async {
      HttpUtils.addCustomHttpHeader('test-key', 'test-value');
      HttpUtils.addCustomHttpHeader('test-key', 'test-value');
      expect(HttpUtils.headers(), completion(contains('test-key')));
    });

    test('given a UTF8 string when decoded then it should match original string', () {
      const testString = 'Test String üğişçöIİÜĞŞÇÖ';
      final decoded = HttpUtils.decodeUTF8(testString);
      expect(decoded, equals(testString));
    });

    group('HTTP Requests', () {
      test('given valid data when post request is made then should return success response', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.post(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response('{"success": true}', 200));

        final response = await HttpUtils.postRequest('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given valid data when post request is made then should return SocketException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.post(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenThrow(const SocketException('No Internet Connection'));

        expect(HttpUtils.postRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
        await expectLater(
          HttpUtils.postRequest('/test', {'data': 'test'}),
          throwsA(
            allOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
            ]),
          ),
        );
      });

      test('given valid data when post request is made then should return TimeoutException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.post(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenThrow(TimeoutException('Timeout Exception'));

        expect(HttpUtils.postRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));
        await expectLater(
          HttpUtils.postRequest('/test', {'data': 'test'}),
          throwsA(
            anyOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
              predicate((e) => e.toString().contains('Timeout Exception')),
              predicate((e) => e.toString().contains('Timeout')),
            ]),
          ),
        );
      });

      test('given valid data when get request is made then should return success 200', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.get(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{"success": true}', 200));

        final response = await HttpUtils.getRequest('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given no internet connection when get request is made then should throw FetchDataException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);

        when(
          mockClient.get(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(const SocketException('No Internet Connection'));

        await expectLater(HttpUtils.getRequest('/test'), throwsA(isA<FetchDataException>()));

        await expectLater(
          HttpUtils.getRequest('/test'),
          throwsA(
            allOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
            ]),
          ),
        );
      });

      test('given no AccessToken when get request is made then should throw UnauthorizedException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);

        when(
          mockClient.get(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(UnauthorizedException('Unauthorized'));

        await expectLater(HttpUtils.getRequest('/test'), throwsA(isA<UnauthorizedException>()));

        await expectLater(
          HttpUtils.getRequest('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given no internet connection when get request is made then should throw SocketException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);

        when(
          mockClient.get(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(const SocketException('No Internet Connection'));

        await expectLater(HttpUtils.getRequest('/test'), throwsA(isA<FetchDataException>()));

        await expectLater(
          HttpUtils.getRequest('/test'),
          throwsA(
            allOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
            ]),
          ),
        );
      });

      test('given no internet connection when get request is made then should throw TimeoutException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        await TestUtils().setupAuthentication();

        when(
          mockClient.get(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(TimeoutException('Timeout'));

        await expectLater(HttpUtils.getRequest('/test'), throwsA(isA<FetchDataException>()));

        await expectLater(
          HttpUtils.getRequest('/test'),
          throwsA(
            anyOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
              predicate((e) => e.toString().contains('TimeoutException')),
              predicate((e) => e.toString().contains('Timeout')),
            ]),
          ),
        );
      });

      test('given valid data when put request is made then should return success 200', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.put(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenAnswer((_) async => http.Response('{"success": true}', 200));

        final response = await HttpUtils.putRequest('/test', {'data': 'test'});
        expect(response.statusCode, lessThan(300));
      });

      test('given network timeout when put request is made then should throw SocketException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.put(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenThrow(const SocketException('No Internet connection'));

        await expectLater(HttpUtils.putRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));

        await expectLater(
          HttpUtils.putRequest('/test', {'data': 'test'}),
          throwsA(
            anyOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
              predicate((e) => e.toString().contains('Request timeout')),
              predicate((e) => e.toString().contains('TimeoutException')),
              predicate((e) => e.toString().contains('Timeout')),
            ]),
          ),
        );
      });
      test('given network timeout when put request is made then should throw TimeoutException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.put(
            Uri.parse('https://dhw-api.onrender.com/api/test'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding'),
          ),
        ).thenThrow(TimeoutException('Timeout'));

        await expectLater(HttpUtils.putRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));

        await expectLater(
          HttpUtils.putRequest('/test', {'data': 'test'}),
          throwsA(
            anyOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('Request timeout')),
              predicate((e) => e.toString().contains('TimeoutException')),
              predicate((e) => e.toString().contains('Timeout')),
            ]),
          ),
        );
      });

      group('PATCH', () {
        test('given valid data when patch request is made then should return success 200', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.prod);
          HttpUtils.setHttpClient(mockClient);
          when(
            mockClient.patch(
              Uri.parse('https://dhw-api.onrender.com/api/test'),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenAnswer((_) async => http.Response('{"success": true}', 200));

          final response = await HttpUtils.patchRequest('/test', {'data': 'test'});
          expect(response.statusCode, lessThan(300));
        });

        test('given network timeout when patch request is made then should throw SocketException', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.prod);
          HttpUtils.setHttpClient(mockClient);
          when(
            mockClient.patch(
              Uri.parse('https://dhw-api.onrender.com/api/test'),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenThrow(const SocketException('No Internet connection'));

          await expectLater(HttpUtils.patchRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));

          await expectLater(
            HttpUtils.patchRequest('/test', {'data': 'test'}),
            throwsA(
              anyOf([
                isA<FetchDataException>(),
                predicate((e) => e.toString().contains('Error During Communication')),
                predicate((e) => e.toString().contains('No Internet connection')),
                predicate((e) => e.toString().contains('Request timeout')),
                predicate((e) => e.toString().contains('TimeoutException')),
                predicate((e) => e.toString().contains('Timeout')),
              ]),
            ),
          );
        });
        test('given network timeout when patch request is made then should throw TimeoutException', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.prod);
          HttpUtils.setHttpClient(mockClient);
          when(
            mockClient.patch(
              Uri.parse('https://dhw-api.onrender.com/api/test'),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding'),
            ),
          ).thenThrow(TimeoutException('Timeout'));

          await expectLater(HttpUtils.patchRequest('/test', {'data': 'test'}), throwsA(isA<FetchDataException>()));

          await expectLater(
            HttpUtils.patchRequest('/test', {'data': 'test'}),
            throwsA(
              anyOf([
                isA<FetchDataException>(),
                predicate((e) => e.toString().contains('Error During Communication')),
                predicate((e) => e.toString().contains('Request timeout')),
                predicate((e) => e.toString().contains('TimeoutException')),
                predicate((e) => e.toString().contains('Timeout')),
              ]),
            ),
          );
        });
      });

      test('given valid data when delete request is made then should return success 204', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.delete(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{"success": true}', 204));

        final response = await HttpUtils.deleteRequest('/test');
        expect(response.statusCode, lessThan(300));
      });

      test('given unauthorized user when delete request is made then should throw UnauthorizedException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.delete(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{"error": "Unauthorized"}', 401));

        await expectLater(HttpUtils.deleteRequest('/test'), throwsA(isA<UnauthorizedException>()));

        await expectLater(
          HttpUtils.deleteRequest('/test'),
          throwsA(allOf([isA<UnauthorizedException>(), predicate((e) => e.toString().contains('Unauthorized'))])),
        );
      });

      test('given unauthorized user when delete request is made then should throw SocketException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.delete(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(const SocketException('No Internet connection'));

        expect(HttpUtils.deleteRequest('/test'), throwsA(isA<FetchDataException>()));
        await expectLater(
          HttpUtils.deleteRequest('/test'),
          throwsA(
            allOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('No Internet connection')),
            ]),
          ),
        );
      });

      test('given unauthorized user when delete request is made then should throw TimeoutException', () async {
        // ProfileConstants.isProduction = true;
        ProfileConstants.setEnvironment(Environment.prod);
        HttpUtils.setHttpClient(mockClient);
        when(
          mockClient.delete(Uri.parse('https://dhw-api.onrender.com/api/test'), headers: anyNamed('headers')),
        ).thenThrow(TimeoutException('TimeoutException'));

        expect(HttpUtils.deleteRequest('/test'), throwsA(isA<FetchDataException>()));
        await expectLater(
          HttpUtils.deleteRequest('/test'),
          throwsA(
            anyOf([
              isA<FetchDataException>(),
              predicate((e) => e.toString().contains('Error During Communication')),
              predicate((e) => e.toString().contains('Request timeout')),
              predicate((e) => e.toString().contains('TimeoutException')),
            ]),
          ),
        );
      });

      group('Mock Requests', () {
        test('given development environment when GET request is made then should return 200 status code', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.dev);
          await TestUtils().setupAuthentication();
          final response = await HttpUtils.mockRequest('GET', '/test');
          expect(response.statusCode, lessThan(300));
        });
        test(
          'given development environment without AccessToken when GET request is made then should return 401 error',
          () async {
            // ProfileConstants.isProduction = true;
            ProfileConstants.setEnvironment(Environment.dev);
            expect(() => HttpUtils.mockRequest('GET', '/test'), throwsA(isA<UnauthorizedException>()));
            await expectLater(
              HttpUtils.mockRequest('GET', '/test'),
              throwsA(
                allOf([
                  isA<UnauthorizedException>(),
                  predicate((e) => e.toString().contains('Unauthorized')),
                  predicate((e) => e.toString().contains('Unauthorized Access')),
                ]),
              ),
            );
          },
        );

        test('given development environment when POST request is made then should return 200 status code', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.dev);
          await TestUtils().setupAuthentication();
          final response = await HttpUtils.mockRequest('POST', '/test');
          expect(response.statusCode, lessThan(300));
        });

        test(
          'given development environment without AccessToken when POST request is made then should return 401 error',
          () async {
            // ProfileConstants.isProduction = true;
            ProfileConstants.setEnvironment(Environment.dev);
            expect(() => HttpUtils.mockRequest('POST', '/test'), throwsA(isA<UnauthorizedException>()));
            await expectLater(
              HttpUtils.mockRequest('POST', '/test'),
              throwsA(
                allOf([
                  isA<UnauthorizedException>(),
                  predicate((e) => e.toString().contains('Unauthorized')),
                  predicate((e) => e.toString().contains('Unauthorized Access')),
                ]),
              ),
            );
          },
        );

        test('given development environment when PUT request is made then should return 200 status code', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.dev);
          await TestUtils().setupAuthentication();
          final response = await HttpUtils.mockRequest('PUT', '/test');
          expect(response.statusCode, lessThan(300));
        });

        test(
          'given development environment without AccessToken when PUT request is made then should return 401 error',
          () async {
            // ProfileConstants.isProduction = true;
            ProfileConstants.setEnvironment(Environment.dev);
            expect(() => HttpUtils.mockRequest('PUT', '/test'), throwsA(isA<UnauthorizedException>()));
            await expectLater(
              HttpUtils.mockRequest('PUT', '/test'),
              throwsA(
                allOf([
                  isA<UnauthorizedException>(),
                  predicate((e) => e.toString().contains('Unauthorized')),
                  predicate((e) => e.toString().contains('Unauthorized Access')),
                ]),
              ),
            );
          },
        );

        test('given development environment when DELETE request is made then should return 200 status code', () async {
          // ProfileConstants.isProduction = true;
          ProfileConstants.setEnvironment(Environment.dev);
          await TestUtils().setupAuthentication();
          final response = await HttpUtils.mockRequest('DELETE', '/test');
          expect(response.statusCode, lessThan(300));
        });

        test(
          'given development environment without AccessToken when DELETE request is made then should return 401 error',
          () async {
            // ProfileConstants.isProduction = true;
            ProfileConstants.setEnvironment(Environment.dev);
            expect(() => HttpUtils.mockRequest('DELETE', '/test'), throwsA(isA<UnauthorizedException>()));
            await expectLater(
              HttpUtils.mockRequest('DELETE', '/test'),
              throwsA(
                allOf([
                  isA<UnauthorizedException>(),
                  predicate((e) => e.toString().contains('Unauthorized')),
                  predicate((e) => e.toString().contains('Unauthorized Access')),
                ]),
              ),
            );
          },
        );
      });
    });
  });
}
