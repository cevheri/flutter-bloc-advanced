import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

part 'sidebar_event.dart';
part 'sidebar_state.dart';

class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  SidebarBloc() : super(SidebarState.initial()) {
    on<RestoreSidebarCollapse>(_onRestoreCollapse);
    on<ToggleSidebarCollapse>(_onToggle);
    on<CollapseSidebar>(_onCollapse);
    on<ExpandSidebar>(_onExpand);
    on<SetActiveRoute>(_onSetActiveRoute);
    on<ToggleSubMenu>(_onToggleSubMenu);
  }

  Future<void> _onRestoreCollapse(RestoreSidebarCollapse event, Emitter<SidebarState> emit) async {
    final stored = await AppLocalStorage().read(StorageKeys.sidebarCollapsed.key);
    switch (stored) {
      case null:
        // The user has never toggled the sidebar, so it keeps its expanded initial state.
        return;
      case 'true':
        emit(state.copyWith(isCollapsed: true));
      case 'false':
        emit(state.copyWith(isCollapsed: false));
      default:
        throw FormatException('The stored sidebar collapse state is neither "true" nor "false"', stored);
    }
  }

  void _onToggle(ToggleSidebarCollapse event, Emitter<SidebarState> emit) {
    final collapsed = !state.isCollapsed;
    _persistCollapsed(collapsed);
    emit(state.copyWith(isCollapsed: collapsed));
  }

  // Stores nothing: the tablet layout collapses the sidebar on its own, and only the user's own choice is restored.
  void _onCollapse(CollapseSidebar event, Emitter<SidebarState> emit) {
    emit(state.copyWith(isCollapsed: true));
  }

  void _onExpand(ExpandSidebar event, Emitter<SidebarState> emit) {
    emit(state.copyWith(isCollapsed: false));
  }

  void _onSetActiveRoute(SetActiveRoute event, Emitter<SidebarState> emit) {
    emit(state.copyWith(activeRoute: event.path));
  }

  void _onToggleSubMenu(ToggleSubMenu event, Emitter<SidebarState> emit) {
    final expanded = Set<String>.from(state.expandedMenuIds);
    if (expanded.contains(event.menuId)) {
      expanded.remove(event.menuId);
    } else {
      expanded.add(event.menuId);
    }
    emit(state.copyWith(expandedMenuIds: expanded));
  }

  void _persistCollapsed(bool collapsed) {
    AppLocalStorage().save(StorageKeys.sidebarCollapsed.key, collapsed.toString());
  }
}
