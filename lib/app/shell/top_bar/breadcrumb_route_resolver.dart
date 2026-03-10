/// A single breadcrumb item with a display label and optional navigation route.
class BreadcrumbItem {
  final String label;

  /// If null, this is the current (non-navigable) page.
  final String? route;

  const BreadcrumbItem({required this.label, this.route});

  bool get isNavigable => route != null;
}

/// Resolves a URI path into a list of [BreadcrumbItem]s for breadcrumb navigation.
class BreadcrumbRouteResolver {
  static const _featureRoots = {
    'user': '/user',
    'account': '/account',
    'settings': '/settings',
    'catalog': '/catalog',
  };

  static const _actionSuffixes = {'view', 'edit', 'new'};

  /// Resolve a URI string into ordered breadcrumb items.
  ///
  /// The last item always has `route: null` (current page, not clickable).
  static List<BreadcrumbItem> resolve(String uri) {
    final cleanUri = uri.split('?').first;
    final segments = cleanUri.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      return [const BreadcrumbItem(label: 'Dashboard')];
    }

    final featureRoot = segments.first;

    // Single segment: e.g., /user, /account, /settings
    if (segments.length == 1) {
      return [BreadcrumbItem(label: _format(featureRoot))];
    }

    final items = <BreadcrumbItem>[];

    // First segment is the feature root, clickable since there are deeper segments
    items.add(BreadcrumbItem(
      label: _format(featureRoot),
      route: _featureRoots[featureRoot] ?? '/$featureRoot',
    ));

    final lastSegment = segments.last;
    final isActionLast = _actionSuffixes.contains(lastSegment);

    // Two segments: e.g., /user/new
    if (segments.length == 2) {
      items.add(BreadcrumbItem(label: _format(lastSegment)));
      return items;
    }

    // Three segments with action suffix: e.g., /user/:id/edit, /user/:id/view
    if (segments.length == 3 && isActionLast) {
      final id = segments[1];
      if (lastSegment == 'view') {
        // Collapse ID + view into single breadcrumb: User > {name}
        items.add(BreadcrumbItem(label: _format(id)));
      } else {
        // ID links to view page, action is the current page: User > {name} > Edit
        items.add(BreadcrumbItem(
          label: _format(id),
          route: '/$featureRoot/$id/view',
        ));
        items.add(BreadcrumbItem(label: _format(lastSegment)));
      }
      return items;
    }

    // Generic fallback: build cumulative paths
    for (int i = 1; i < segments.length; i++) {
      final isLast = i == segments.length - 1;
      if (isLast) {
        items.add(BreadcrumbItem(label: _format(segments[i])));
      } else {
        final cumulativePath = '/${segments.sublist(0, i + 1).join('/')}';
        items.add(BreadcrumbItem(label: _format(segments[i]), route: cumulativePath));
      }
    }
    return items;
  }

  static String _format(String segment) {
    if (segment.startsWith(':')) return segment;
    final formatted = segment.replaceAll('-', ' ').replaceAll('_', ' ');
    if (formatted.isEmpty) return formatted;
    return formatted.replaceFirst(formatted[0], formatted[0].toUpperCase());
  }
}
