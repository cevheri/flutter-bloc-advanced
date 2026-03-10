import 'package:equatable/equatable.dart';

class AuthCredentialsEntity extends Equatable {
  const AuthCredentialsEntity({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class AuthTokenEntity extends Equatable {
  const AuthTokenEntity({this.idToken});

  final String? idToken;

  bool get isValid => idToken != null && idToken!.isNotEmpty;

  @override
  List<Object?> get props => [idToken];
}

class SendOtpEntity extends Equatable {
  const SendOtpEntity({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class VerifyOtpEntity extends Equatable {
  const VerifyOtpEntity({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}
