import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_router_refresh_notifier.dart';
import 'package:flutter_bloc_advance/app/router/forbidden_page.dart';
import 'package:flutter_bloc_advance/app/router/route_role_requirements.dart';
// safeRedirectTarget lives in core/ so features/ guards can consume it too.
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/app_shell.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/account/navigation/account_routes.dart';
import 'package:flutter_bloc_advance/features/auth/navigation/auth_routes.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/dashboard/navigation/dashboard_routes.dart';
import 'package:flutter_bloc_advance/features/settings/navigation/settings_routes.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/features/users/navigation/users_routes.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouterFactory {
  AppRouterFactory({required this._sessionCubit, List<NavigatorObserver>? observers}) : _observers = observers ?? [];

  static final _log = AppLogger.getLogger('AppRouterFactory');

  final SessionCubit _sessionCubit;
  final List<NavigatorObserver> _observers;

  GoRouter create() {
    final refreshNotifier = AppRouterRefreshNotifier(_sessionCubit.stream);

    return GoRouter(
      initialLocation: ApplicationRoutesConstants.home,
      debugLogDiagnostics: true,
      refreshListenable: refreshNotifier,
      observers: _observers,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(state: state, child: child),
          routes: [
            ...DashboardFeatureRoutes.routes,
            ...AccountFeatureRoutes.routes,
            ...UsersFeatureRoutes.routes,
            ...SettingsFeatureRoutes.routes,
            ...DynamicFormsFeatureRoutes.routes,
            ...AuthFeatureRoutes.authenticatedRoutes,
          ],
        ),
        ...AuthFeatureRoutes.publicRoutes(
          loginBuilder: (context) =>
              LoginScreen(onToggleTheme: () => context.read<ThemeBloc>().add(const ToggleBrightness())),
        ),
        GoRoute(path: ApplicationRoutesConstants.forbidden, builder: (context, state) => const ForbiddenPage()),
      ],
      redirect: (context, state) {
        final location = state.uri.path;
        final sessionState = _sessionCubit.state;
        final isAuthenticated = sessionState is SessionAuthenticated;
        final isPublic = _isPublicRoute(location);

        _log.debug('redirect - location: {}, session: {}', [location, sessionState.runtimeType]);

        // Authenticated user landing on a public route (login / register
        // / forgot-password / OTP) should be sent to the home shell.
        // Without this, async session restore would leave a logged-in
        // user stuck on the login page after the first frame's redirect
        // raced against the cubit emission.
        if (isAuthenticated && isPublic) {
          return ApplicationRoutesConstants.home;
        }

        // SessionUnknown is treated the same as SessionUnauthenticated
        // for redirect purposes — we cannot route into protected pages
        // without proof of session. Token validity (presence + `exp`)
        // is owned by SessionCubit, which flips state to
        // SessionUnauthenticated when the JWT is missing or expired.
        if (!isAuthenticated && !isPublic) {
          // Preserve the intended destination as `returnUrl` so login
          // success can land the user where they were going. The
          // dashboard fallback handles the "user typed /login directly"
          // case where there's nothing meaningful to return to. The
          // login screen validates the value as a local path before
          // honoring it (see LoginScreen — open-redirect guard).
          final fullPath = state.uri.toString();
          if (fullPath == ApplicationRoutesConstants.home || fullPath == ApplicationRoutesConstants.login) {
            return ApplicationRoutesConstants.login;
          }
          final encoded = Uri.encodeQueryComponent(fullPath);
          return '${ApplicationRoutesConstants.login}?returnUrl=$encoded';
        }

        // Role gate. Empty required set → open access.
        if (isAuthenticated) {
          final required = requiredRolesFor(location);
          if (!hasAnyRequiredRole(sessionState.roles, required)) {
            _log.warn('redirect - role denied at {}: user roles {}, required {}', [
              location,
              sessionState.roles,
              required,
            ]);
            return ApplicationRoutesConstants.forbidden;
          }
        }

        return null;
      },
    );
  }

  bool _isPublicRoute(String path) {
    return path == ApplicationRoutesConstants.login ||
        path == ApplicationRoutesConstants.register ||
        path == ApplicationRoutesConstants.forgotPassword ||
        path == ApplicationRoutesConstants.loginOtp ||
        path.startsWith(ApplicationRoutesConstants.loginOtpVerify);
  }
}
