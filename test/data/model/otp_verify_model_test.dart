import 'package:flutter_bloc_advance/data/models/verify_otp_request.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerifyOtpRequest', () {
    test('should create VerifyOtpRequest instance with email and otp', () {
      // given
      const testEmail = 'test@example.com';
      const testOtp = '123456';

      // when
      final request = VerifyOtpRequest(email: testEmail, otp: testOtp);

      // then
      expect(request.email, equals(testEmail));
      expect(request.otp, equals(testOtp));
    });

    test('should convert VerifyOtpRequest to JSON correctly', () {
      // given
      const testEmail = 'test@example.com';
      const testOtp = '123456';
      final request = VerifyOtpRequest(email: testEmail, otp: testOtp);

      // when
      final json = request.toJson();

      // then
      expect(json, {'email': 'test@example.com', 'otp': '123456'});
    });

    test('should create VerifyOtpRequest from JSON correctly', () {
      initializeJsonMapper();
      // given
      final json = {'email': 'test@example.com', 'otp': '123456'};

      // when
      final request = VerifyOtpRequest.fromJson(json);

      // then
      expect(request, isNotNull);
      expect(request?.email, equals('test@example.com'));
      expect(request?.otp, equals('123456'));
    });

    test('should return null when fromJson is called with invalid JSON', () {
      // given
      final invalidJson = {'invalid_key': 'test@example.com'};

      // when
      final request = VerifyOtpRequest.fromJson(invalidJson);

      // then
      expect(request, isNull);
    });

    test('should return null when fromJson is called with missing otp', () {
      // given
      final invalidJson = {'email': 'test@example.com'};

      // when
      final request = VerifyOtpRequest.fromJson(invalidJson);

      // then
      expect(request, isNull);
    });

    test('should return null when fromJson is called with missing email', () {
      // given
      final invalidJson = {'otp': '123456'};

      // when
      final request = VerifyOtpRequest.fromJson(invalidJson);

      // then
      expect(request, isNull);
    });
  });
}
