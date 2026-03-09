import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../tokens/app_durations.dart';

/// Page transition types for go_router.
enum AppPageTransitionType { fade, slideRight, slideUp }

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
