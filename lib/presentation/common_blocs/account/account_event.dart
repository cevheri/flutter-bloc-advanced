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
  final User data;

  const AccountSubmitEvent(this.data);

  @override
  List<Object> get props => [data];
}
