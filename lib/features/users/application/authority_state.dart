part of 'authority_bloc.dart';

enum AuthorityStatus { initial, loading, success, failure }

class AuthorityState extends Equatable {
  const AuthorityState({this.authorities = const [], this.status = AuthorityStatus.initial});

  final List<String?> authorities;
  final AuthorityStatus status;

  AuthorityState copyWith({List<String?>? authorities, AuthorityStatus? status}) {
    return AuthorityState(status: status ?? this.status, authorities: authorities ?? this.authorities);
  }

  @override
  List<Object> get props => [status, authorities];

  @override
  bool get stringify => true;
}

class AuthorityInitialState extends AuthorityState {
  const AuthorityInitialState() : super(status: AuthorityStatus.initial);
}

class AuthorityLoadingState extends AuthorityState {
  const AuthorityLoadingState() : super(status: AuthorityStatus.loading);
}

class AuthorityLoadSuccessState extends AuthorityState {
  const AuthorityLoadSuccessState({required super.authorities}) : super(status: AuthorityStatus.success);
}

class AuthorityLoadFailureState extends AuthorityState {
  const AuthorityLoadFailureState({required this.message}) : super(status: AuthorityStatus.failure);

  final String message;

  @override
  List<Object> get props => [status, message];
}
