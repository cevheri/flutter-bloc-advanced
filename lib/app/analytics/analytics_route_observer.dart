import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';

/// NavigatorObserver that logs screen views to an analytics service.
///
/// Add to GoRouter's `observers` list to automatically track page navigation.
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
    if (previousRoute != null) _logScreenView(previousRoute);
  }

  void _logScreenView(Route route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _analytics.logScreenView(screenName: name, screenClass: route.runtimeType.toString());
    }
  }
}
