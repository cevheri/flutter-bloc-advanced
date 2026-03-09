import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_durations.dart';
import 'sidebar_nav_item.dart';

/// An expandable sub-menu group in the sidebar.
class SidebarSubMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool isCollapsed;
  final bool hasActiveChild;
  final VoidCallback? onToggle;
  final List<SidebarSubMenuItem> children;

  const SidebarSubMenu({
    super.key,
    required this.icon,
    required this.label,
    this.isExpanded = false,
    this.isCollapsed = false,
    this.hasActiveChild = false,
    this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isCollapsed) {
      return PopupMenuButton<String>(
        tooltip: label,
        offset: const Offset(56, 0),
        child: SidebarNavItem(icon: icon, label: label, isCollapsed: true, isActive: hasActiveChild),
        itemBuilder: (context) => children
            .map((item) => PopupMenuItem<String>(value: item.route, onTap: item.onTap, child: Text(item.label)))
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: hasActiveChild ? colorScheme.primary : colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: hasActiveChild ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        fontWeight: hasActiveChild ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: AppDurations.fast,
                    child: Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppDurations.fast,
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: Column(
              children: children.map((item) {
                return SidebarNavItem(
                  icon: item.icon ?? Icons.circle,
                  label: item.label,
                  isActive: item.isActive,
                  onTap: item.onTap,
                );
              }).toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Data class for sub-menu items.
class SidebarSubMenuItem {
  final String label;
  final String route;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;

  const SidebarSubMenuItem({required this.label, required this.route, this.icon, this.isActive = false, this.onTap});
}
