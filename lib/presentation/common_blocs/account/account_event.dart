part of 'account_bloc.dart';

class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object> get props => [];
}

class AccountLoad extends AccountEvent {
  const AccountLoad();

  @override
  List<Object> get props => [];
}

class AccountUpdate extends AccountEvent {
  final User account;

  const AccountUpdate(this.account);

  @override
  List<Object> get props => [account];
}

class AccountDelete extends AccountEvent {
  const AccountDelete();

  @override
  List<Object> get props => [];
}

