part of 'sidebar_bloc.dart';

abstract class SidebarEvent extends Equatable {
  const SidebarEvent();

  @override
  List<Object?> get props => [];
}

/// Restores the collapsed or expanded state that the user last chose with [ToggleSidebarCollapse], the only event that
/// stores it. [CollapseSidebar] and [ExpandSidebar] store nothing, because the tablet layout collapses the sidebar on
/// its own. A value that an earlier release stored is restored as well, although those releases also stored the
/// tablet layout's collapse.
class RestoreSidebarCollapse extends SidebarEvent {
  const RestoreSidebarCollapse();
}

class ToggleSidebarCollapse extends SidebarEvent {
  const ToggleSidebarCollapse();
}

class CollapseSidebar extends SidebarEvent {
  const CollapseSidebar();
}

class ExpandSidebar extends SidebarEvent {
  const ExpandSidebar();
}

class SetActiveRoute extends SidebarEvent {
  const SetActiveRoute(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class ToggleSubMenu extends SidebarEvent {
  const ToggleSubMenu(this.menuId);

  final String menuId;

  @override
  List<Object?> get props => [menuId];
}
