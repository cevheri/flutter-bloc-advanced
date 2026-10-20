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
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final IAnalyticsService _analytics;

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
    if (route is PageRoute && previousRoute != null) _logScreenView(previousRoute);
  }

  void _logScreenView(Route route) {
    final name = route.settings.name;
    if (route is PageRoute && name != null && name.isNotEmpty) {
      _analytics.logScreenView(screenName: name, screenClass: route.runtimeType.toString());
    }
  }
}
