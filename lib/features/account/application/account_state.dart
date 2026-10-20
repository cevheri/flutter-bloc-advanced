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
  const AccountState({this.data, this.status = AccountStatus.initial, this.errorCode});

  final UserEntity? data;
  final AccountStatus status;

  /// Set with [AccountStatus.failure] when the failure has a translated message, which the UI shows via
  /// `errorCode.resolve(context)` instead of its generic one.
  final AppErrorCode? errorCode;

  /// [errorCode] belongs to the failure that set it, so a copy keeps it only when it is passed again.
  AccountState copyWith({UserEntity? data, AccountStatus? status, AppErrorCode? errorCode}) {
    return AccountState(status: status ?? this.status, data: data ?? this.data, errorCode: errorCode);
  }

  @override
  List<Object?> get props => [status, data, errorCode];

  @override
  bool get stringify => true;
}
