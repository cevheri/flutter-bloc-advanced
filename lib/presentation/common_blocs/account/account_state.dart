part of 'account_bloc.dart';

/// Account status used the success or failure of the account loading.
enum AccountStatus { initial, loading, success, failure }

/// Account state that contains the current account and the status of the account.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
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
        status: status ?? this.status, account: account ?? this.account);
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}
