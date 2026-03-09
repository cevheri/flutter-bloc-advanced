import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/utils/icon_utils.dart';
import '../../design_system/tokens/app_breakpoints.dart';
import '../../design_system/tokens/app_durations.dart';
import '../../design_system/tokens/app_spacing.dart';
import 'sidebar_nav_item.dart';
import 'sidebar_sub_menu.dart';

/// The full sidebar widget with logo, nav items, and footer controls.
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarBloc, SidebarState>(
      builder: (context, sidebarState) {
        return BlocBuilder<DrawerBloc, DrawerState>(
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
                    _buildHeader(context, isCollapsed),
                    const Divider(height: 1),
                    Expanded(child: _buildNavItems(context, drawerState, sidebarState)),
                    const Divider(height: 1),
                    _buildFooter(context, isCollapsed),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isCollapsed) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? AppSpacing.md : AppSpacing.lg, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.dashboard, color: colorScheme.primary, size: 28),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'BLoC Advance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, DrawerState drawerState, SidebarState sidebarState) {
    final currentUserRoles = AppLocalStorageCached.roles;
    final menuNodes = drawerState.menus.where((e) => e.level == 1 && e.active).toList()
      ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      child: Column(
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

  Widget _buildFooter(BuildContext context, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // Theme toggle
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return SidebarNavItem(
                icon: themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
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
      BlocProvider.of<DrawerBloc>(context).add(Logout());
      AppRouter().push(context, ApplicationRoutesConstants.login);
    }
  }

  bool _hasAccess(Menu menu, List<String>? userRoles) {
    if (userRoles == null) return false;
    final menuAuthorities = menu.authorities ?? [];
    return menuAuthorities.any((authority) => userRoles.contains(authority));
  }
}
