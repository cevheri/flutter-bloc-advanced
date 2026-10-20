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

/// Fetching the user to edit or view failed, so there is no user to show. The UI shows [errorCode]
/// translated via `errorCode.resolve(context)`; the raw error message only goes to the log.
final class UserEditorFetchFailure extends UserEditorState {
  const UserEditorFetchFailure({required this.errorCode});

  final AppErrorCode errorCode;

  @override
  List<Object?> get props => [errorCode];
}

/// Saving the user failed. [data] is the user the editor held before the save (null when creating), so
/// the form stays on that user and saving again updates it.
final class UserEditorSaveFailure extends UserEditorState {
  const UserEditorSaveFailure({this.data, this.errorCode});

  final UserEntity? data;

  /// Set when the failure has a translated message, which the UI shows via `errorCode.resolve(context)`
  /// instead of its generic one.
  final AppErrorCode? errorCode;

  @override
  List<Object?> get props => [data, errorCode];
}
