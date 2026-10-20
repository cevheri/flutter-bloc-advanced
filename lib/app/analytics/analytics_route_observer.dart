import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';

/// NavigatorObserver that logs screen views to an analytics service.
///
/// Add to GoRouter's `observers` list to automatically track page navigation. go_router forwards those observers to
/// every ShellRoute navigator (`notifyRootObserver`, on by default), so do not add this observer to a ShellRoute as
/// well, or every shell screen is logged twice.
///
/// Only named page routes are screens. Dialogs, menus and bottom sheets are popup routes: opening one is not a screen
/// view, and closing one reveals a screen the user never left.
///
/// A ShellRoute's page on the root navigator has no name: the screen it shows is the top page of the shell navigator.
/// So when a root page pops off the shell, the revealed screen is the one the shell navigator logged last.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final IAnalyticsService _analytics;

  // The screen last logged from a navigator nested in the observed one, such as a ShellRoute navigator.
  Route? _shellScreen;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _logScreenView(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is! PageRoute || previousRoute == null) return;
    if (previousRoute is PageRoute && previousRoute.settings.name == null) {
      _logRevealedShellScreen(previousRoute);
    } else {
      _logScreenView(previousRoute);
    }
  }

  // A `go` that leaves the root page pops it here first and updates the shell navigator later in the same frame, and
  // that navigator logs its new screen itself. So log the revealed screen once the frame is done, and only if the
  // shell still shows it.
  void _logRevealedShellScreen(Route shell) {
    final screen = _shellScreen;
    if (screen == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shell.isCurrent && screen.isCurrent) _logScreenView(screen);
    });
  }

  void _logScreenView(Route route) {
    final name = route.settings.name;
    if (route is PageRoute && name != null && name.isNotEmpty) {
      _analytics.logScreenView(screenName: name, screenClass: route.runtimeType.toString());
      if (route.navigator != navigator) _shellScreen = route;
    }
  }
}
