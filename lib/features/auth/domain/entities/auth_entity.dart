import 'package:equatable/equatable.dart';

class AuthCredentialsEntity extends Equatable {
  const AuthCredentialsEntity({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class AuthTokenEntity extends Equatable {
  const AuthTokenEntity({this.idToken, this.refreshToken, this.expiresAt});

  final String? idToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isValid => idToken != null && idToken!.isNotEmpty;

  /// Returns true if the token has an expiration time and it has passed.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  AuthTokenEntity copyWith({String? idToken, String? refreshToken, DateTime? expiresAt}) {
    return AuthTokenEntity(
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [idToken, refreshToken, expiresAt];
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
}
