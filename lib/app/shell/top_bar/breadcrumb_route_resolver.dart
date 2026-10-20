import 'package:flutter_bloc_advance/generated/l10n.dart';

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
  static const _featureRoots = {'user': '/user', 'account': '/account', 'settings': '/settings'};

  static const _actionSuffixes = {'view', 'edit', 'new'};

  /// Feature roots whose second segment is a path parameter, such as the form id in `/dynamic-forms/:formId`.
  static const _parameterChildRoots = {'dynamic-forms'};

  /// Resolve a URI string into ordered breadcrumb items, with the page names in the language of [l10n].
  ///
  /// The last item always has `route: null` (current page, not clickable).
  static List<BreadcrumbItem> resolve(String uri, S l10n) {
    final cleanUri = uri.split('?').first;
    final segments = cleanUri.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      return [BreadcrumbItem(label: l10n.dashboard)];
    }

    final featureRoot = segments.first;
    String label(String segment) => segmentLabel(segment, l10n) ?? _format(segment);

    // Single segment: e.g., /user, /account, /settings
    if (segments.length == 1) {
      return [BreadcrumbItem(label: label(featureRoot))];
    }

    final items = <BreadcrumbItem>[];

    // First segment is the feature root, clickable since there are deeper segments
    items.add(BreadcrumbItem(label: label(featureRoot), route: _featureRoots[featureRoot] ?? '/$featureRoot'));

    final lastSegment = segments.last;
    final isActionLast = _actionSuffixes.contains(lastSegment);

    // Two segments: e.g., /user/new, /dynamic-forms/:formId
    if (segments.length == 2) {
      items.add(
        BreadcrumbItem(label: _parameterChildRoots.contains(featureRoot) ? _format(lastSegment) : label(lastSegment)),
      );
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
        items.add(BreadcrumbItem(label: _format(id), route: '/$featureRoot/$id/view'));
        items.add(BreadcrumbItem(label: label(lastSegment)));
      }
      return items;
    }

    // Generic fallback: build cumulative paths. The inner segments are path parameters such as the login in
    // /user/:id/extended-info, so only the last segment is a route word.
    for (int i = 1; i < segments.length; i++) {
      final isLast = i == segments.length - 1;
      if (isLast) {
        items.add(BreadcrumbItem(label: label(segments[i])));
      } else {
        final cumulativePath = '/${segments.sublist(0, i + 1).join('/')}';
        items.add(BreadcrumbItem(label: _format(segments[i]), route: cumulativePath));
      }
    }
    return items;
  }

  /// The label of a route segment that names a page, such as `user` or `edit`, or null for a segment that is data,
  /// such as a login or a form id, which is shown as it is.
  static String? segmentLabel(String segment, S l10n) => switch (segment) {
    'user' => l10n.users,
    'account' => l10n.account,
    'settings' => l10n.settings,
    'change-password' => l10n.change_password,
    'dynamic-forms' => l10n.dynamic_forms,
    'extended-info' => l10n.user_extended_info_title,
    'new' => l10n.new_item,
    'edit' => l10n.edit,
    _ => null,
  };

  static String _format(String segment) {
    if (segment.startsWith(':')) return segment;
    final formatted = segment.replaceAll('-', ' ').replaceAll('_', ' ');
    if (formatted.isEmpty) return formatted;
    return formatted.replaceFirst(formatted[0], formatted[0].toUpperCase());
  }
}
