import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'breadcrumb_route_resolver.dart';

/// shadcn Breadcrumb — text-sm, muted foreground, chevron separator.
/// Supports clickable segments for navigation and a home icon.
class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final items = BreadcrumbRouteResolver.resolve(uri);
    final cs = Theme.of(context).colorScheme;
    final isHome = uri == '/' || uri.isEmpty;

    return Row(
      children: [
        _HomeIcon(isActive: !isHome),
        if (items.isNotEmpty) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
        ],
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          _BreadcrumbSegment(item: items[i]),
        ],
      ],
    );
  }
}

class _HomeIcon extends StatefulWidget {
  final bool isActive;

  const _HomeIcon({required this.isActive});

  @override
  State<_HomeIcon> createState() => _HomeIconState();
}

class _HomeIconState extends State<_HomeIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!widget.isActive) {
      return Icon(Icons.home_outlined, size: 14, color: cs.onSurface);
    }

    return Semantics(
      label: 'Home',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go('/'),
          child: Icon(Icons.home_outlined, size: 14, color: _hovered ? cs.onSurface : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final BreadcrumbItem item;

  const _BreadcrumbSegment({required this.item});

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!widget.item.isNavigable) {
      return Text(
        widget.item.label,
        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
      );
    }

    return Semantics(
      label: widget.item.label,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.item.route!),
          child: Text(
            widget.item.label,
            style: tt.bodySmall?.copyWith(
              color: _hovered ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: FontWeight.normal,
              decoration: _hovered ? TextDecoration.underline : null,
              decorationColor: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
