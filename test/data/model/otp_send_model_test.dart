import 'package:flutter_bloc_advance/data/models/send_otp_request.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendOtpRequest', () {
    test('should create SendOtpRequest instance with email', () {
      // given
      const testEmail = 'test@example.com';

      // when
      final request = SendOtpRequest(email: testEmail);

      // then
      expect(request.email, equals(testEmail));
    });

    test('should convert SendOtpRequest to JSON correctly', () {
      // given
      const testEmail = 'test@example.com';
      final request = SendOtpRequest(email: testEmail);

      // when
      final json = request.toJson();

      // then
      expect(json, {'email': 'test@example.com'});
    });

    test('should create SendOtpRequest from JSON correctly', () {
      initializeJsonMapper();
      // given
      final json = {'email': 'test@example.com'};

      // when
      final request = SendOtpRequest.fromJson(json);

      // then
      expect(request, isNotNull);
      expect(request?.email, equals('test@example.com'));
    });

    test('should return null when fromJson is called with invalid JSON', () {
      initializeJsonMapper();
      // given
      final invalidJson = {'invalid_key': 'test@example.com'};

      // when
      final request = SendOtpRequest.fromJson(invalidJson);

      // then
      expect(request, isNull);
    });
  });
}
