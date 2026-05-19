part of 'authority_bloc.dart';

sealed class AuthorityState extends Equatable {
  const AuthorityState();
}

final class AuthorityInitialState extends AuthorityState {
  const AuthorityInitialState();

  @override
  List<Object?> get props => const [];
}

final class AuthorityLoadingState extends AuthorityState {
  const AuthorityLoadingState();

  @override
  List<Object?> get props => const [];
}

final class AuthorityLoadSuccessState extends AuthorityState {
  const AuthorityLoadSuccessState({required this.authorities});

  final List<String?> authorities;

  @override
  List<Object?> get props => [authorities];
}

final class AuthorityLoadFailureState extends AuthorityState {
  const AuthorityLoadFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
