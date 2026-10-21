import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/router/app_root_page.dart';
import 'package:flutter_bloc_advance/app/router/app_router_refresh_notifier.dart';
import 'package:flutter_bloc_advance/app/router/forbidden_page.dart';
import 'package:flutter_bloc_advance/app/router/not_found_page.dart';
import 'package:flutter_bloc_advance/app/router/route_role_requirements.dart';
// safeRedirectTarget lives in core/ so features/ guards can consume it too.
import 'package:flutter_bloc_advance/core/security/safe_redirect.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/app_shell.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/account/navigation/account_routes.dart';
import 'package:flutter_bloc_advance/features/auth/navigation/auth_routes.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/dashboard/navigation/dashboard_routes.dart';
import 'package:flutter_bloc_advance/features/settings/navigation/settings_routes.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/features/users/navigation/users_routes.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouterFactory {
  AppRouterFactory({
    required this._sessionCubit,
    this._authMode = const JwtAuthMode(),
    List<NavigatorObserver>? observers,
  }) : _observers = observers ?? [];

  static final _log = AppLogger.getLogger('AppRouterFactory');

  /// The paths the identity provider sends its answer to: the native sign-in redirect and the desktop logout
  /// redirect (see OidcRedirectUris). Their query carries the authorization code and state.
  static const _appRedirectPaths = {'/oauth2redirect', '/logout'};

  final SessionCubit _sessionCubit;

  /// An `oidc` build leaves out the password routes: the identity provider owns the password.
  final AuthMode _authMode;
  final List<NavigatorObserver> _observers;

  GoRouter create() {
    final refreshNotifier = AppRouterRefreshNotifier(_sessionCubit.stream);

    return GoRouter(
      initialLocation: ApplicationRoutesConstants.home,
      debugLogDiagnostics: true,
      refreshListenable: refreshNotifier,
      observers: _observers,
      errorPageBuilder: (context, state) {
        // The page tells the user in the app language; the router's own error, in English, goes to the log.
        _log.warn('No page for location {}: {}', [state.uri, state.error]);
        return appRootPage(
          state: state,
          // An error state has no route name or path, and an unnamed page is invisible to analytics.
          name: ApplicationRoutesConstants.notFound,
          child: const NotFoundPage(),
        );
      },
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => appPlatformPage(
            state: state,
            child: AppShell(state: state, child: child),
          ),
          routes: [
            ...DashboardFeatureRoutes.routes,
            ...AccountFeatureRoutes.routes,
            ...UsersFeatureRoutes.routes,
            ...SettingsFeatureRoutes.routes,
            ...DynamicFormsFeatureRoutes.routes,
            if (!_authMode.usesOidc) ...AuthFeatureRoutes.authenticatedRoutes,
          ],
        ),
        ...AuthFeatureRoutes.publicRoutes(
          loginBuilder: (context) => LoginScreen(
            onToggleTheme: () => context.read<ThemeBloc>().add(const ToggleBrightness()),
            startupSignInError: switch (_sessionCubit.state) {
              SessionUnauthenticated(:final signInError) => signInError,
              SessionUnknown() || SessionAuthenticated() => null,
            },
          ),
          ssoOnly: _authMode.usesOidc,
        ),
        GoRoute(
          path: ApplicationRoutesConstants.forbidden,
          pageBuilder: (context, state) => appRootPage(state: state, child: const ForbiddenPage()),
        ),
      ],
      redirect: (context, state) {
        final location = state.uri.path;
        final sessionState = _sessionCubit.state;
        final isAuthenticated = sessionState is SessionAuthenticated;
        final isPublic = _isPublicRoute(location);

        _log.debug('redirect - location: {}, session: {}', [location, sessionState.runtimeType]);

        // In an oidc build, a callback URL reaching the router, such as a custom scheme link the platform pushes, must
        // never become a router location or a returnUrl: its query holds the authorization code and state. A jwt build
        // has no such paths and keeps its usual handling of them.
        if (_authMode.usesOidc && _appRedirectPaths.contains(location)) return ApplicationRoutesConstants.login;

        // Authenticated user landing on a public route (login / register
        // / forgot-password / OTP), for example by opening /login while
        // signed in, should be sent to the home shell, or to the returnUrl
        // that the redirect below gives the login page, as the sign-in on
        // that page does: SessionCubit signs the user in on that page when
        // the stored session answers only after its restore time limit.
        // Like the login screen, it honors only a local path.
        if (isAuthenticated && isPublic) {
          return safeRedirectTarget(state.uri.queryParameters['returnUrl'], fallback: ApplicationRoutesConstants.home);
        }

        // The router never sees SessionUnknown at startup: App mounts it
        // only once SessionCubit.restore() has settled the session. Should
        // a later SessionUnknown reach this redirect, it still counts as
        // unauthenticated, the safe default, since we cannot route into
        // protected pages without proof of session. Token validity
        // (presence + `exp`) is owned by SessionCubit, which flips state
        // to SessionUnauthenticated when the JWT is missing or expired.
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

  /// Whether [leaving] must close without asking about unsaved changes: a page that needs a session cannot stay once
  /// the session has ended, so logout, an idle timeout or a 401 always reach the login page.
  bool isExitForced(GoRouterState leaving) =>
      _sessionCubit.state is! SessionAuthenticated && !_isPublicRoute(leaving.matchedLocation);

  bool _isPublicRoute(String path) {
    return path == ApplicationRoutesConstants.login ||
        path == ApplicationRoutesConstants.register ||
        path == ApplicationRoutesConstants.forgotPassword ||
        path == ApplicationRoutesConstants.loginOtp ||
        path.startsWith(ApplicationRoutesConstants.loginOtpVerify);
  }
}
