import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// shadcn Breadcrumb — text-sm, muted foreground, chevron separator.
class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final segments = uri.split('/').where((s) => s.isNotEmpty).toList();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (segments.isEmpty) {
      return Text(
        'Dashboard',
        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            _formatSegment(segments[i]),
            style: tt.bodySmall?.copyWith(
              color: i == segments.length - 1 ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: i == segments.length - 1 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  String _formatSegment(String segment) {
    if (segment.startsWith(':')) return segment;
    return segment.replaceAll('-', ' ').replaceFirst(segment[0], segment[0].toUpperCase());
  }
}
