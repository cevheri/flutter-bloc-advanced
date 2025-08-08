part of 'account_bloc.dart';

/// Account status used the success or failure of the account loading.
enum AccountStatus { initial, loading, success, failure }

/// Account state that contains the current account and the status of the account.
/// The status is used to display the loading indicator.
///
/// The state is immutable and copyWith is used to update the state.
class AccountState extends Equatable {
  final User? data;
  final AccountStatus status;

  const AccountState({this.data, this.status = AccountStatus.initial});

  AccountState copyWith({User? data, AccountStatus? status}) {
    return AccountState(status: status ?? this.status, data: data ?? this.data);
  }

  @override
  List<Object> get props => [status, data ?? ''];

  @override
  bool get stringify => true;
}
