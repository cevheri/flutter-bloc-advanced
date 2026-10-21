import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

/// Creates a [MaterialPage] for a root page outside the shell that appears without an entering transition and leaves
/// with the Material one, keeping the iOS back swipe. Its key, name and restoration id come from [appPlatformPage],
/// so navigator observers such as analytics name it the same way.
///
/// While a root page that replaces the shell is still entering, the root navigator keeps the exiting shell page
/// mounted. A shell page that comes back in that window builds the shell Navigator a second time with the same
/// GlobalKey, "Duplicate GlobalKey detected in widget tree" (flutter/flutter#148768, #179). Without an entering
/// transition the exiting shell page is dropped in the next frame. Once a go_router or Flutter release fixes that
/// issue, these pages can go back to [appPlatformPage].
///
/// [name] replaces the route-derived name for a page that has no route of its own, such as the error page.
MaterialPage<void> appRootPage({required Widget child, required GoRouterState state, String? name}) {
  return _RootMaterialPage.from(appPlatformPage(child: child, state: state, name: name));
}

class _RootMaterialPage extends MaterialPage<void> {
  _RootMaterialPage.from(MaterialPage<void> page)
    : super(
        key: page.key,
        name: page.name,
        arguments: page.arguments,
        restorationId: page.restorationId,
        maintainState: page.maintainState,
        fullscreenDialog: page.fullscreenDialog,
        allowSnapshotting: page.allowSnapshotting,
        child: page.child,
      );

  @override
  Route<void> createRoute(BuildContext context) => _RootMaterialPageRoute(page: this);
}

class _RootMaterialPageRoute extends PageRoute<void> with MaterialRouteTransitionMixin<void> {
  _RootMaterialPageRoute({required MaterialPage<void> page})
    : super(settings: page, allowSnapshotting: page.allowSnapshotting);

  MaterialPage<void> get _page => settings as MaterialPage<void>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  // Only the entering transition is removed; the reverse duration still comes from the Material transition.
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
