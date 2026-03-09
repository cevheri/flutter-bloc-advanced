import 'package:flutter/material.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_durations.dart';

/// A single navigation item in the sidebar.
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    final activeBg = colorScheme.primaryContainer;

    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppDurations.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppSpacing.md : AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isActive ? Border(left: BorderSide(color: activeColor, width: 2)) : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isActive ? activeColor : inactiveColor),
                if (!isCollapsed) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: AppDurations.fast,
                      opacity: isCollapsed ? 0 : 1,
                      child: Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isActive ? activeColor : inactiveColor,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
