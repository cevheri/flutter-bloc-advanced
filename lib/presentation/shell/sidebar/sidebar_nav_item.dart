import 'package:flutter/material.dart';
import '../../design_system/tokens/app_radius.dart';

/// shadcn SidebarMenuButton — h-8, p-2, gap-2, rounded-md, text-sm.
///
/// Active & hover share the same accent background (bg-sidebar-accent).
/// No left border indicator — just a subtle background shift.
class SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isCollapsed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // shadcn: active & hover use sidebar-accent bg + sidebar-accent-foreground
    final fgColor = isActive ? cs.onSurface : cs.onSurfaceVariant;

    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: isActive ? cs.onSurface.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: cs.onSurface.withAlpha(20),
          splashColor: cs.onSurface.withAlpha(30),
          child: SizedBox(
            height: 32, // h-8
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8), // p-2
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: fgColor), // size-4
                  if (!isCollapsed) ...[
                    const SizedBox(width: 8), // gap-2
                    Expanded(
                      child: Text(
                        label,
                        style: tt.bodyMedium?.copyWith(
                          color: fgColor,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal, // font-medium when active
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
