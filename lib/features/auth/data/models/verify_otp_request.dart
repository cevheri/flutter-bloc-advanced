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
}
