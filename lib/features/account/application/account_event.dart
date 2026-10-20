part of 'account_bloc.dart';

class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object> get props => [];
}

class AccountFetchEvent extends AccountEvent {
  const AccountFetchEvent();

  @override
  List<Object> get props => [];
}

class AccountSubmitEvent extends AccountEvent {
  const AccountSubmitEvent(this.data);

  final UserEntity data;

  @override
  List<Object> get props => [data];
}

/// Forgets the account when the session ends, so the next user to sign in does not see it. A fetch or a save that is
/// still running then drops its result.
class AccountResetEvent extends AccountEvent {
  const AccountResetEvent();

  @override
  List<Object> get props => [];
}
