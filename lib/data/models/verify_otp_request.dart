import 'package:dart_json_mapper/dart_json_mapper.dart';

@JsonSerializable()
class VerifyOtpRequest {
  final String email;
  final String otp;

  VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {"email": email, "otp": otp};

  static VerifyOtpRequest? fromJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('email') || !json.containsKey('otp')) return null;
      return JsonMapper.fromMap<VerifyOtpRequest>(json);
    } catch (e) {
      return null;
    }
  }
}
