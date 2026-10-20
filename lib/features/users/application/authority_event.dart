part of 'authority_bloc.dart';

class AuthorityEvent extends Equatable {
  const AuthorityEvent();

  @override
  List<Object> get props => [];
}

class AuthorityLoad extends AuthorityEvent {
  const AuthorityLoad();

  @override
  List<Object> get props => [];
}

/// Forgets the authorities when the session ends: they were loaded with the signed-out user's rights. A load that is
/// still running then drops its result.
class AuthorityReset extends AuthorityEvent {
  const AuthorityReset();

  @override
  List<Object> get props => [];
}
