import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';

class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {"email": email, "otp": otp};

  static VerifyOtpRequest? fromJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('email') || !json.containsKey('otp')) return null;
      return VerifyOtpRequest(email: json['email'], otp: json['otp']);
    } catch (e) {
      return null;
    }
  }

  /// The code is masked, so the request is safe to print in a log line or the dev console.
  @override
  String toString() => 'VerifyOtpRequest(email: $email, otp: $secretMask)';
}
