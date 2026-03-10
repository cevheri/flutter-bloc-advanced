class SendOtpRequest {
  final String email;

  SendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {"email": email};

  static SendOtpRequest? fromJson(Map<String, dynamic> json) {
    try {
      if (!json.containsKey('email')) return null;
      return SendOtpRequest(email: json['email']);
    } catch (e) {
      return null;
    }
  }
}
