import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Auto-generates breadcrumb trail from the current route path.
class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final segments = uri.split('/').where((s) => s.isNotEmpty).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (segments.isEmpty) {
      return Text('Dashboard', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
    }

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0) Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Text(
            _formatSegment(segments[i]),
            style: textTheme.bodyMedium?.copyWith(
              color: i == segments.length - 1 ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              fontWeight: i == segments.length - 1 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (i < segments.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }

  String _formatSegment(String segment) {
    // Skip path parameters like :id
    if (segment.startsWith(':')) return segment;
    return segment.replaceAll('-', ' ').replaceFirst(segment[0], segment[0].toUpperCase());
  }
}
