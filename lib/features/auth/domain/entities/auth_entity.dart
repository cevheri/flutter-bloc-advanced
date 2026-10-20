import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/core/logging/log_sanitizer.dart';
import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';

class AuthCredentialsEntity extends Equatable {
  const AuthCredentialsEntity({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];

  /// The password is masked, so the entity is safe to print in a log line or the dev console.
  @override
  String toString() => 'AuthCredentialsEntity(username: $username, password: $secretMask)';
}

class AuthTokenEntity extends Equatable {
  const AuthTokenEntity({this.idToken, this.refreshToken, this.expiresAt});

  final String? idToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isValid => idToken != null && idToken!.isNotEmpty;

  @override
  List<Object?> get props => [idToken, refreshToken, expiresAt];

  /// The tokens are masked, so the entity is safe to print in a log line or the dev console.
  @override
  String toString() =>
      'AuthTokenEntity(idToken: ${maskToken(idToken)}, refreshToken: ${maskToken(refreshToken)}, expiresAt: $expiresAt)';
}

class SendOtpEntity extends Equatable {
  const SendOtpEntity({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class VerifyOtpEntity extends Equatable {
  const VerifyOtpEntity({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];

  /// The code is masked, so the entity is safe to print in a log line or the dev console.
  @override
  String toString() => 'VerifyOtpEntity(email: $email, otp: $secretMask)';
}
