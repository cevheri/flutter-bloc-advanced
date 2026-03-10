import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/app/router/app_router_strategy.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/utils/icon_utils.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_durations.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'sidebar_nav_item.dart';
import 'sidebar_sub_menu.dart';

/// shadcn Sidebar — bg-sidebar, w-256, flex-col.
///
/// Structure: SidebarHeader (p-2) → SidebarContent (flex-1, scroll) → SidebarSeparator → SidebarFooter (p-2).
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarBloc, SidebarState>(
      builder: (context, sidebarState) {
        return BlocBuilder<MenuBloc, MenuState>(
          builder: (context, drawerState) {
            final isCollapsed = sidebarState.isCollapsed;
            final width = isCollapsed ? AppBreakpoints.sidebarCollapsed : AppBreakpoints.sidebarExpanded;

            return AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppDurations.easeInOut,
              width: width,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    _SidebarHeader(isCollapsed: isCollapsed),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _SidebarContent(drawerState: drawerState, sidebarState: sidebarState),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    _SidebarFooter(isCollapsed: isCollapsed),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// shadcn SidebarHeader — p-2, flex-col, gap-2.
class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  const _SidebarHeader({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8), // p-2
      child: SizedBox(
        height: 32, // consistent with nav item height
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(Icons.grid_view_rounded, color: cs.onPrimary, size: 14),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 8), // gap-2
              Expanded(
                child: Text(
                  'BLoC Advance',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// shadcn SidebarContent — flex-1, overflow-auto, gap-0.
class _SidebarContent extends StatelessWidget {
  final MenuState drawerState;
  final SidebarState sidebarState;
  const _SidebarContent({required this.drawerState, required this.sidebarState});

  @override
  Widget build(BuildContext context) {
    final currentUserRoles = AppLocalStorageCached.roles;
    final menuNodes = drawerState.menus.where((e) => e.level == 1 && e.active).toList()
      ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

    return SingleChildScrollView(
      // shadcn SidebarGroup: p-2
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: menuNodes.map((node) {
          if (!_hasAccess(node, currentUserRoles)) return const SizedBox.shrink();

          final childMenus =
              drawerState.menus
                  .where((e) => e.parent?.id == node.id && e.active && _hasAccess(e, currentUserRoles))
                  .toList()
                ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          if (childMenus.isEmpty) {
            return SidebarNavItem(
              icon: getIconFromString(node.icon),
              label: S.of(context).translate_menu_title(node.name),
              isActive: sidebarState.activeRoute == node.url,
              isCollapsed: sidebarState.isCollapsed,
              onTap: () {
                if ((node.leaf ?? false) && node.url.isNotEmpty) {
                  context.read<SidebarBloc>().add(SetActiveRoute(node.url));
                  AppRouter().push(context, node.url);
                }
              },
            );
          }

          final hasActiveChild = childMenus.any((c) => sidebarState.activeRoute == c.url);
          return SidebarSubMenu(
            icon: getIconFromString(node.icon),
            label: S.of(context).translate_menu_title(node.name),
            isExpanded: sidebarState.expandedMenuIds.contains(node.id),
            isCollapsed: sidebarState.isCollapsed,
            hasActiveChild: hasActiveChild,
            onToggle: () => context.read<SidebarBloc>().add(ToggleSubMenu(node.id)),
            children: childMenus.map((child) {
              return SidebarSubMenuItem(
                label: S.of(context).translate_menu_title(child.name),
                route: child.url,
                icon: getIconFromString(child.icon),
                isActive: sidebarState.activeRoute == child.url,
                onTap: () {
                  if ((child.leaf ?? false) && child.url.isNotEmpty) {
                    context.read<SidebarBloc>().add(SetActiveRoute(child.url));
                    AppRouter().push(context, child.url);
                  }
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  bool _hasAccess(Menu menu, List<String>? userRoles) {
    if (userRoles == null) return false;
    final menuAuthorities = menu.authorities ?? [];
    return menuAuthorities.any((authority) => userRoles.contains(authority));
  }
}

/// shadcn SidebarFooter — p-2, flex-col, gap-2.
class _SidebarFooter extends StatelessWidget {
  final bool isCollapsed;
  const _SidebarFooter({required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8), // p-2
      child: Column(
        children: [
          // Theme toggle
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return SidebarNavItem(
                icon: themeState.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                label: themeState.isDarkMode ? 'Dark' : 'Light',
                isCollapsed: isCollapsed,
                onTap: () => context.read<ThemeBloc>().add(const ToggleBrightness()),
              );
            },
          ),
          // Collapse toggle
          SidebarNavItem(
            icon: isCollapsed ? Icons.chevron_right : Icons.chevron_left,
            label: isCollapsed ? 'Expand' : 'Collapse',
            isCollapsed: isCollapsed,
            onTap: () => context.read<SidebarBloc>().add(const ToggleSidebarCollapse()),
          ),
          // Logout
          SidebarNavItem(
            icon: Icons.logout,
            label: S.of(context).logout,
            isCollapsed: isCollapsed,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;
    if (shouldLogout && context.mounted) {
      BlocProvider.of<MenuBloc>(context).add(Logout());
      AppRouter().push(context, ApplicationRoutesConstants.login);
    }
  }
}
