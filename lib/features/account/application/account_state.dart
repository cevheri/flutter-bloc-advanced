part of 'account_bloc.dart';

enum AccountStatus { initial, loading, success, failure }

class AccountState extends Equatable {
  const AccountState({this.data, this.status = AccountStatus.initial});

  final UserEntity? data;
  final AccountStatus status;

  AccountState copyWith({UserEntity? data, AccountStatus? status}) {
    return AccountState(status: status ?? this.status, data: data ?? this.data);
  }

  @override
  List<Object> get props => [status, data ?? ''];

  @override
  bool get stringify => true;
}
