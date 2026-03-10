import 'package:flutter/material.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_durations.dart';
import 'sidebar_nav_item.dart';

/// shadcn SidebarMenuSub — border-l, mx-3.5, px-2.5, py-0.5, gap-1.
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
    final cs = Theme.of(context).colorScheme;

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
        // Parent toggle button — same style as SidebarMenuButton
        _SubMenuToggle(
          icon: icon,
          label: label,
          isExpanded: isExpanded,
          hasActiveChild: hasActiveChild,
          onTap: onToggle,
        ),
        // Collapsible children with border-left
        AnimatedCrossFade(
          duration: AppDurations.fast,
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Container(
            // shadcn: mx-3.5 (14px), px-2.5 (10px), py-0.5 (2px)
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: cs.outlineVariant, width: 1)),
            ),
            child: Column(
              // gap-1 = 4px between items
              children: _buildSubItems(context),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<Widget> _buildSubItems(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(height: 1)); // gap-1 ≈ minimal spacing
      items.add(_SubMenuItem(item: children[i]));
    }
    return items;
  }
}

/// The parent toggle for a collapsible sub-menu group.
class _SubMenuToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool hasActiveChild;
  final VoidCallback? onTap;

  const _SubMenuToggle({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.hasActiveChild,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fgColor = hasActiveChild ? cs.onSurface : cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        hoverColor: cs.onSurface.withAlpha(20),
        child: SizedBox(
          height: 32, // h-8
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8), // p-2
            child: Row(
              children: [
                Icon(icon, size: 16, color: fgColor),
                const SizedBox(width: 8), // gap-2
                Expanded(
                  child: Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: hasActiveChild ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: AppDurations.fast,
                  child: Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// shadcn SidebarMenuSubButton — h-7, px-2, text-sm, rounded-md.
class _SubMenuItem extends StatelessWidget {
  final SidebarSubMenuItem item;
  const _SubMenuItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fgColor = item.isActive ? cs.onSurface : cs.onSurfaceVariant;

    return Material(
      color: item.isActive ? cs.onSurface.withAlpha(20) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        hoverColor: cs.onSurface.withAlpha(20),
        child: SizedBox(
          height: 28, // h-7
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8), // px-2
            child: Row(
              children: [
                if (item.icon != null) ...[Icon(item.icon, size: 14, color: fgColor), const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    item.label,
                    style: tt.bodySmall?.copyWith(color: fgColor), // text-xs/text-sm
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
