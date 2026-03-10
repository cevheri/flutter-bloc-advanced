part of 'sidebar_bloc.dart';

class SidebarState extends Equatable {
  const SidebarState({required this.isCollapsed, required this.activeRoute, required this.expandedMenuIds});

  final bool isCollapsed;
  final String activeRoute;
  final Set<String> expandedMenuIds;

  factory SidebarState.initial() {
    return const SidebarState(isCollapsed: false, activeRoute: '/', expandedMenuIds: {});
  }

  SidebarState copyWith({bool? isCollapsed, String? activeRoute, Set<String>? expandedMenuIds}) {
    return SidebarState(
      isCollapsed: isCollapsed ?? this.isCollapsed,
      activeRoute: activeRoute ?? this.activeRoute,
      expandedMenuIds: expandedMenuIds ?? this.expandedMenuIds,
    );
  }

  @override
  List<Object?> get props => [isCollapsed, activeRoute, expandedMenuIds];
}
