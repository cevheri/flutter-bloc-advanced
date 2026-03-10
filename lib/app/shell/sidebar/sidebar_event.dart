part of 'sidebar_bloc.dart';

abstract class SidebarEvent extends Equatable {
  const SidebarEvent();

  @override
  List<Object?> get props => [];
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
