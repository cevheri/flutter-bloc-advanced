part of 'change_password_bloc.dart';

enum ChangePasswordStatus { initial, loading, success, failure }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;

  const ChangePasswordState({this.status = ChangePasswordStatus.initial});

  ChangePasswordState copyWith({ChangePasswordStatus? status}) {
    return ChangePasswordState(status: status ?? this.status);
  }

  @override
  List<Object> get props => [status];

  @override
  bool get stringify => true;
}
