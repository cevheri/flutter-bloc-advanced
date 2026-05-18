part of 'change_password_bloc.dart';

enum ChangePasswordStatus { initial, loading, success, failure }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;
  final String? errorMessage;

  const ChangePasswordState({this.status = ChangePasswordStatus.initial, this.errorMessage});

  ChangePasswordState copyWith({ChangePasswordStatus? status, String? errorMessage}) {
    return ChangePasswordState(status: status ?? this.status, errorMessage: errorMessage ?? this.errorMessage);
  }

  @override
  List<Object?> get props => [status, errorMessage];

  @override
  bool get stringify => true;
}
