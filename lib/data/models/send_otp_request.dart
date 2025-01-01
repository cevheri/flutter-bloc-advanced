import 'package:dart_json_mapper/dart_json_mapper.dart';

@JsonSerializable()
class SendOtpRequest {
  final String email;

  SendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {"email": email};

  static SendOtpRequest? fromJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('email')) return null;
      return JsonMapper.fromMap<SendOtpRequest>(json);
    } catch (e) {
      return null;
    }
  }
}
