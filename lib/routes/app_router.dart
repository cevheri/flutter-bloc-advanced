// Navigator wrapper for navigator, go_router and auto_route in Application (with strategy pattern)
// This file contains the implementation of the app_router for the application.
// It uses navigator, go_router and auto_route to navigate between screens.

import 'package:auto_route/auto_route.dart' as auto_route;
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:get/get.dart' as get_router;
import 'package:go_router/go_router.dart' as go_router;

enum RouterType { navigator, goRouter, autoRoute, getRouter }

/// Application Navigator base class for navigation
///
/// This class is used to navigate between screens with the help of navigator.
/// It contains common navigation methods like push, pushNamed, pushReplacementNamed, pushNamedAndRemoveUntil, popAndPushNamed, popUntil, pop, etc.
abstract class RouterStrategy {
  /// Pop the top-most route off the navigator that most tightly encloses the given context.
  ///
  /// @param context The context to use to look up the navigator.
  ///
  /// Example:
  /// ```dart
  /// await navigator.pop(context);
  /// ```
  Future<void> pop(BuildContext context);

  /// Push the given route onto the navigator that most tightly encloses the given context.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The route to add to the navigator.
  /// @param arguments The arguments to pass to the route.
  ///
  /// Example:
  /// ```dart
  /// await navigator.push(context, MaterialPageRoute(builder: (context) => const MyScreen()));
  /// ```
  Future<void> push(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});

  /// Push the route with the given name onto the navigator that most tightly encloses the given context, and then remove all the previous routes until the predicate returns true.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The name of the route to push onto the navigator.
  /// @param arguments The arguments to pass to the route.
  ///
  /// Example:
  /// ```dart
  /// await navigator.pushNamedAndRemoveUntil(context, "/myScreen", ModalRoute.withName("/home"));
  ///
  /// await navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
  /// ```
  Future<void> pushRemoveUntil(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});

  /// Replace the current route of the navigator that most tightly encloses the given context by pushing the route named routeName and then disposing the previous route once the new route has finished animating in.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The name of the route to push onto the navigator.
  /// @param arguments The arguments to pass to the route.
  ///
  /// Example:
  /// ```dart
  /// await navigator.pushReplacementNamed(context, "/myScreen", arguments: {"id": 1});
  /// ```
  Future<void> pushReplacement(BuildContext context, String routeName, {Object? args, Map<String, dynamic> kwargs});
}

/// Flutter Navigator implementation of RouteStrategy
/// @link [Navigation](https://docs.flutter.dev/ui/navigation)
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
/// @link [GoRouter](https://pub.dev/packages/go_router)
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

/// AutoRoute implementation of RouteStrategy
/// @link [AutoRoute](https://pub.dev/packages/auto_route)
/// Not Tested!!!
class AutoRouteStrategy implements RouterStrategy {
  @override
  Future<void> pop(BuildContext context) async {
    auto_route.AutoRouter.of(context).pop();
    // auto_route.AutoRouter.of(context).maybePop();
    // auto_route.AutoRouter.of(context).back();
  }

  @override
  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (args != null && kwargs.isNotEmpty) {
      Navigator.of(context).pushNamed(routeName, arguments: args);
    } else if (args != null) {
      Navigator.of(context).pushNamed(routeName, arguments: args);
    } else {
      Navigator.of(context).pushNamed(routeName);
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
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false, arguments: args);
    } else if (args != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false, arguments: args);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
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
      Navigator.of(context).pushReplacementNamed(routeName, arguments: args);
    } else if (args != null) {
      Navigator.of(context).pushReplacementNamed(routeName, arguments: args);
    } else {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }
}

/// Get route strategy implementation of RouteStrategy
/// @link [RouteStrategy](https://pub.dev/packages/get)
/// Not Tested!!!
class GetRouteStrategy implements RouterStrategy {
  @override
  Future<void> pop(BuildContext context) async {
    get_router.Get.back();
  }

  @override
  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    final queryParams = kwargs as Map<String, String>;
    if (args != null && kwargs.isNotEmpty) {
      get_router.Get.toNamed(routeName, arguments: args, parameters: queryParams);
    } else if (args != null) {
      get_router.Get.toNamed(routeName, parameters: queryParams);
    } else {
      get_router.Get.toNamed(routeName);
    }
  }

  @override
  Future<void> pushRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    final queryParams = kwargs as Map<String, String>;
    if (args != null && kwargs.isNotEmpty) {
      get_router.Get.offNamedUntil(routeName, (route) => false, arguments: args, parameters: queryParams);
    } else if (args != null) {
      get_router.Get.offNamedUntil(routeName, (route) => false, parameters: queryParams);
    } else {
      get_router.Get.offNamedUntil(routeName, (route) => false);
    }
  }

  @override
  Future<void> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    final queryParams = kwargs as Map<String, String>;
    if (args != null && kwargs.isNotEmpty) {
      get_router.Get.offNamed(routeName, arguments: args, parameters: queryParams);
    } else if (args != null) {
      get_router.Get.offNamed(routeName, parameters: queryParams);
    } else {
      get_router.Get.offNamed(routeName);
    }
  }
}

/// Application Navigator class for navigation
///
/// This class is used to navigate between screens with the help of navigator.
/// It contains common navigation methods like push, pushNamed, pushReplacementNamed, pushNamedAndRemoveUntil, popAndPushNamed, popUntil, pop, etc.
/// It uses the RouteStrategy to navigate between screens.
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

  /// Set the route strategy for the application
  /// @param routeStrategy The route strategy to use for the application
  void setRouter(RouterType routerType) {
    _log.trace("Setting AppRouter with routerType: {}", [routerType]);
    switch (routerType) {
      case RouterType.navigator:
        _routeStrategy = NavigatorStrategy();
        break;
      case RouterType.goRouter:
        _routeStrategy = GoRouterStrategy();
        break;
      case RouterType.autoRoute:
        _routeStrategy = AutoRouteStrategy();
        break;
      case RouterType.getRouter:
        _routeStrategy = GetRouteStrategy();
        break;
    }
  }

  /// Get the route strategy for the application

  /// Pop the top-most route off the navigator that most tightly encloses the given context.
  ///
  /// @param context The context to use to look up the navigator.
  ///
  /// Example:
  /// ```dart
  /// await AppRouter.pop(context);
  /// ```
  Future<void> pop(BuildContext context) async {
    await _routeStrategy.pop(context);
  }

  /// Push the given route onto the navigator that most tightly encloses the given context.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The route to add to the navigator.
  /// @param arguments The arguments to pass to the route.
  ///
  /// Example:
  /// ```dart
  /// await AppRouter.push(context, "/myScreen", arguments: {"id": 1});
  /// ```
  Future<void> push(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.push(context, routeName, args: args, kwargs: kwargs);
  }

  /// Push the route with the given name onto the navigator that most tightly encloses the given context, and then remove all the previous routes until the predicate returns true.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The name of the route to push onto the navigator.
  /// @param arguments The arguments to pass to the route.
  ///
  /// Example:
  /// ```dart
  /// await AppRouter.pushNamedAndRemoveUntil(context, "/myScreen", ModalRoute.withName("/home"));
  ///
  /// await AppRouter.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
  /// ```
  Future<void> pushRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.pushRemoveUntil(context, routeName, args: args, kwargs: kwargs);
  }

  /// Replace the current route of the navigator that most tightly encloses the given context by pushing the route named routeName and then disposing the previous route once the new route has finished animating in.
  ///
  /// @param context The context to use to look up the navigator.
  /// @param routeName The name of the route to push onto the navigator.
  /// @param arguments The arguments to pass to the route.
  /// @param kwargs The query parameters to pass to the route.
  Future<void> pushReplacement(
    BuildContext context,
    String routeName, {
    Object? args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    await _routeStrategy.pushReplacement(context, routeName, args: args, kwargs: kwargs);
  }
}
