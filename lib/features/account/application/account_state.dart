part of 'account_bloc.dart';

enum AccountStatus { initial, loading, success, failure }

/// Single-state + status enum is intentional here under the project's
/// state-modeling rule (CLAUDE.md → State Modeling, exception #1:
/// **concurrent state access**).
///
/// `AccountBloc` emits `state.copyWith(status: loading)` and
/// `state.copyWith(status: failure)` to preserve the previously loaded
/// `data` across transitions, and the account form (`account_page.dart`)
/// reads `state.data?.firstName/lastName/email` regardless of the current
/// status so the user keeps seeing their profile during a refresh or
/// after a save failure. Splitting into sealed variants would either
/// force `data` onto every variant (redundant) or blank the form during
/// any non-success state (UX regression).
///
/// When this BLoC is touched in the future, prefer the existing shape
/// unless the concurrent-access requirement is removed.
class AccountState extends Equatable {
  const AccountState({this.data, this.status = AccountStatus.initial});

  final UserEntity? data;
  final AccountStatus status;

  AccountState copyWith({UserEntity? data, AccountStatus? status}) {
    return AccountState(status: status ?? this.status, data: data ?? this.data);
  }

  @override
  List<Object?> get props => [status, data];

  @override
  bool get stringify => true;
}
