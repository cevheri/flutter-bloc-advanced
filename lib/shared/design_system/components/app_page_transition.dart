import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tokens/app_durations.dart';

/// Page transition types for go_router.
enum AppPageTransitionType { fade, slideRight, slideUp }

/// Creates a platform-adaptive [MaterialPage], built the way go_router 17 built pages for `builder:` routes.
///
/// go_router 18 only detects material_ui's MaterialApp. Under the SDK MaterialApp it turns `builder:` routes into
/// `NoTransitionPage`s, so every route must return an explicit page.
///
/// Unlike go_router 17, path and query parameters are not copied into the page arguments: nothing reads them, and
/// navigator observers such as Sentry's would otherwise record values like the email in `/login-otp-verify/:email`.
MaterialPage<void> appPlatformPage({required Widget child, required GoRouterState state}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    restorationId: state.pageKey.value,
    child: child,
  );
}

/// Creates a CustomTransitionPage with consistent animations.
CustomTransitionPage<T> appTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  AppPageTransitionType type = AppPageTransitionType.fade,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Respect reduced motion preferences
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return child;
      }

      final curve = CurvedAnimation(parent: animation, curve: AppDurations.easeInOut);

      switch (type) {
        case AppPageTransitionType.fade:
          return FadeTransition(opacity: curve, child: child);

        case AppPageTransitionType.slideRight:
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curve),
            child: FadeTransition(opacity: curve, child: child),
          );

        case AppPageTransitionType.slideUp:
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(curve),
            child: FadeTransition(opacity: curve, child: child),
          );
      }
    },
  );
}
