import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

part 'sidebar_event.dart';
part 'sidebar_state.dart';

class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  SidebarBloc() : super(SidebarState.initial()) {
    on<ToggleSidebarCollapse>(_onToggle);
    on<CollapseSidebar>(_onCollapse);
    on<ExpandSidebar>(_onExpand);
    on<SetActiveRoute>(_onSetActiveRoute);
    on<ToggleSubMenu>(_onToggleSubMenu);
  }

  void _onToggle(ToggleSidebarCollapse event, Emitter<SidebarState> emit) {
    final collapsed = !state.isCollapsed;
    _persistCollapsed(collapsed);
    emit(state.copyWith(isCollapsed: collapsed));
  }

  void _onCollapse(CollapseSidebar event, Emitter<SidebarState> emit) {
    _persistCollapsed(true);
    emit(state.copyWith(isCollapsed: true));
  }

  void _onExpand(ExpandSidebar event, Emitter<SidebarState> emit) {
    _persistCollapsed(false);
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
    AppLocalStorage().save('sidebarCollapsed', collapsed.toString());
  }
}
