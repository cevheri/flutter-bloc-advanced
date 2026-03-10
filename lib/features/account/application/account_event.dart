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
