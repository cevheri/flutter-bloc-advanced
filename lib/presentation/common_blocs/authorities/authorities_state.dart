part of 'authorities_bloc.dart';

/// Authorities status used the success or failure of the authorities loading.
enum AuthoritiesStatus { initial, loading, success, failure }

/// Authorities state that contains the current authorities and the status of the authorities.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class AuthoritiesState extends Equatable {
  final List? role;
  final AuthoritiesStatus status;

  const AuthoritiesState({
    this.role,
    this.status = AuthoritiesStatus.initial,
  });

  AuthoritiesState copyWith({
    List? authorities,
    AuthoritiesStatus? status,
  }) {
    return AuthoritiesState(
      status: status ?? this.status,
      role: authorities ?? this.role
    );
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}

class AuthoritiesInitialState extends AuthoritiesState {}
class AuthoritiesLoadInProgressState extends AuthoritiesState {}
class AuthoritiesLoadSuccessState extends AuthoritiesState {
  final List role;

  const AuthoritiesLoadSuccessState({required this.role});

  @override
  List<Object> get props => [role];
}
class AuthoritiesLoadFailureState extends AuthoritiesState {
  final String message;

  const AuthoritiesLoadFailureState({required this.message});
}

