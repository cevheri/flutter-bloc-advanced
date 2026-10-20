import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';

/// NavigatorObserver that logs screen views to an analytics service.
///
/// Add to GoRouter's `observers` list to automatically track page navigation. go_router forwards those observers to
/// every ShellRoute navigator (`notifyRootObserver`, on by default), so do not add this observer to a ShellRoute as
/// well, or every shell screen is logged twice.
///
/// A screen view is logged whenever the screen the user sees changes. That screen is the top route of the observed
/// navigator or, when that is a ShellRoute's page, which has no name, the top route of the shell navigator. Only named
/// page routes are screens. Dialogs, menus and bottom sheets are popup routes: while one is on top no screen view is
/// logged, and closing one logs the screen under it only if that is not the screen logged last, as when the user left
/// it for a page pushed over the popup.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final IAnalyticsService _analytics;

  // The top routes of the observed navigator and of a navigator nested in it, such as a ShellRoute navigator.
  Route? _top;
  Route? _shellTop;

  // The screen logged last.
  Route? _screen;

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    if (topRoute.navigator == navigator) {
      _top = topRoute;
    } else {
      _shellTop = topRoute;
    }
    // A `go` changes the top route of the observed navigator first and of the shell navigator later in the same
    // frame, so read the screen once the frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) => _logScreenView());
  }

  void _logScreenView() {
    final top = _top;
    final shellTop = _shellTop;
    // An unnamed page route is the ShellRoute's page only while the shell is still there: once the shell is gone, its
    // last top route is no longer active and an unnamed page pushed over a root page is not a screen.
    final screen = top is PageRoute && top.settings.name == null
        ? (shellTop != null && shellTop.isActive ? shellTop : null)
        : top;
    final name = screen?.settings.name;
    if (screen is PageRoute && screen != _screen && name != null && name.isNotEmpty) {
      _screen = screen;
      _analytics.logScreenView(screenName: name, screenClass: screen.runtimeType.toString());
    }
  }
}
