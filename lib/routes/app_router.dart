// Navigator wrapper for navigator and go_router in Application (with strategy pattern)

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:go_router/go_router.dart' as go_router;

enum RouterType { navigator, goRouter }

/// Application Navigator base class for navigation
abstract class RouterStrategy {
  Future<void> pop(BuildContext context);
  Future<void> push(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});
  Future<void> pushRemoveUntil(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});
  Future<void> pushReplacement(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});
}

/// Flutter Navigator implementation of RouteStrategy
class NavigatorStrategy implements RouterStrategy {
  @override
  Future<void> pop(BuildContext context) async {
    Navigator.of(context).pop();
  }

  @override
  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    Navigator.of(context).pushNamed(routeName, arguments: args);
  }

  @override
  Future<void> pushRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false, arguments: args);
  }

  @override
  Future<void> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: args);
  }
}

/// GoRouter implementation of RouteStrategy
class GoRouterStrategy implements RouterStrategy {
  @override
  Future<void> pop(BuildContext context) async {
    go_router.GoRouter.of(context).pop();
  }

  @override
  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (args != null && kwargs.isNotEmpty) {
      Map<String, String> pathParameters = args as Map<String, String>;
      go_router.GoRouter.of(context).goNamed(routeName, pathParameters: pathParameters, queryParameters: kwargs);
    } else if (args != null) {
      go_router.GoRouter.of(context).go(routeName, extra: args);
    } else {
      go_router.GoRouter.of(context).go(routeName);
    }
  }

  @override
  Future<void> pushRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (args != null && kwargs.isNotEmpty) {
      Map<String, String> pathParameters = args as Map<String, String>;
      go_router.GoRouter.of(context).goNamed(routeName, pathParameters: pathParameters, queryParameters: kwargs);
    } else if (args != null) {
      go_router.GoRouter.of(context).go(routeName, extra: args);
    } else {
      go_router.GoRouter.of(context).go(routeName);
    }
  }

  @override
  Future<void> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (args != null && kwargs.isNotEmpty) {
      Map<String, String> pathParameters = args as Map<String, String>;
      go_router.GoRouter.of(context).goNamed(routeName, pathParameters: pathParameters, queryParameters: kwargs);
    } else if (args != null) {
      go_router.GoRouter.of(context).go(routeName, extra: args);
    } else {
      go_router.GoRouter.of(context).go(routeName);
    }
  }
}

/// Application Navigator class for navigation
///
/// Default RouteStrategy is GoRouterStrategy.
class AppRouter {
  static final _log = AppLogger.getLogger("AppRouter");
  static final AppRouter _instance = AppRouter._internal();
  late RouterStrategy _routeStrategy;

  AppRouter._internal() {
    _log.trace("Creating AppRouter instance");
    _routeStrategy = GoRouterStrategy();
  }

  factory AppRouter() {
    _log.trace("Creating AppRouter instance");
    return _instance;
  }

  @visibleForTesting
  RouterStrategy get routeStrategy => _routeStrategy;

  void setRouter(RouterType routerType) {
    _log.trace("Setting AppRouter with routerType: {}", [routerType]);
    switch (routerType) {
      case RouterType.navigator:
        _routeStrategy = NavigatorStrategy();
        break;
      case RouterType.goRouter:
        _routeStrategy = GoRouterStrategy();
        break;
    }
  }

  Future<void> pop(BuildContext context) async {
    await _routeStrategy.pop(context);
  }

  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.push(context, routeName, args: args, kwargs: kwargs);
  }

  Future<void> pushRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.pushRemoveUntil(context, routeName, args: args, kwargs: kwargs);
  }

  Future<void> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.pushReplacement(context, routeName, args: args, kwargs: kwargs);
  }
}
