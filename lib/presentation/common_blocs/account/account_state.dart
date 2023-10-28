part of 'account_bloc.dart';

enum AccountStatus { initial, loading, loaded, failure }

class AccountState extends Equatable {
  final User? account;
  final AccountStatus status;

  const AccountState({
    this.account,
    this.status = AccountStatus.initial,
  });

  AccountState copyWith({
    User? account,
    AccountStatus? status,
  }) {
    return AccountState(
      account: account ?? this.account,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;

}
