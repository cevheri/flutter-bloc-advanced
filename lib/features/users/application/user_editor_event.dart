part of 'user_editor_bloc.dart';

sealed class UserEditorEvent extends Equatable {
  const UserEditorEvent();

  @override
  List<Object?> get props => const [];
}

/// Resets the editor back to its initial state. Used when navigating
/// into a "create" flow.
final class UserEditorReset extends UserEditorEvent {
  const UserEditorReset();
}

final class UserEditorFetch extends UserEditorEvent {
  const UserEditorFetch(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class UserEditorSubmit extends UserEditorEvent {
  const UserEditorSubmit(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// Flips state to [UserEditorSaved] without re-submitting. Carried-user
/// is preserved.
final class UserEditorSaveComplete extends UserEditorEvent {
  const UserEditorSaveComplete();
}

/// Flips state to [UserEditorViewed]. Used by the view-mode screen.
final class UserEditorViewComplete extends UserEditorEvent {
  const UserEditorViewComplete();
}
