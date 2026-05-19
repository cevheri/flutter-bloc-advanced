part of 'user_editor_bloc.dart';

sealed class UserEditorState extends Equatable {
  const UserEditorState();
}

final class UserEditorInitial extends UserEditorState {
  const UserEditorInitial();

  @override
  List<Object?> get props => const [];
}

/// Loading variant carries [data] forward when a save starts from an
/// already-loaded editor state, preserving the form contents during
/// the in-flight submit (concurrent-state-access exception, see
/// `CLAUDE.md` → State Modeling).
final class UserEditorLoading extends UserEditorState {
  const UserEditorLoading({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

final class UserEditorLoaded extends UserEditorState {
  const UserEditorLoaded({required this.data});

  final UserEntity data;

  @override
  List<Object?> get props => [data];
}

final class UserEditorSaved extends UserEditorState {
  const UserEditorSaved({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

final class UserEditorViewed extends UserEditorState {
  const UserEditorViewed({this.data});

  final UserEntity? data;

  @override
  List<Object?> get props => [data];
}

final class UserEditorFailure extends UserEditorState {
  const UserEditorFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
