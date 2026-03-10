import 'package:flutter_bloc_advance/app/router/app_router_refresh_notifier.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/app_shell.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/account/navigation/account_routes.dart';
import 'package:flutter_bloc_advance/features/auth/navigation/auth_routes.dart';
import 'package:flutter_bloc_advance/features/catalog/navigation/catalog_routes.dart';
import 'package:flutter_bloc_advance/features/dashboard/navigation/dashboard_routes.dart';
import 'package:flutter_bloc_advance/features/settings/navigation/settings_routes.dart';
import 'package:flutter_bloc_advance/features/users/navigation/users_routes.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:go_router/go_router.dart';

class AppRouterFactory {
  AppRouterFactory({required SessionCubit sessionCubit}) : _sessionCubit = sessionCubit;

  static final _log = AppLogger.getLogger('AppRouterFactory');

  final SessionCubit _sessionCubit;

  GoRouter create() {
    final refreshNotifier = AppRouterRefreshNotifier(_sessionCubit.stream);

    return GoRouter(
      initialLocation: ApplicationRoutesConstants.home,
      debugLogDiagnostics: true,
      refreshListenable: refreshNotifier,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(state: state, child: child),
          routes: [
            ...DashboardFeatureRoutes.routes,
            ...AccountFeatureRoutes.routes,
            ...UsersFeatureRoutes.routes,
            ...SettingsFeatureRoutes.routes,
            ...CatalogFeatureRoutes.routes,
          ],
        ),
        ...AuthFeatureRoutes.routes,
      ],
      redirect: (context, state) {
        final location = state.uri.path;
        final isAuthenticated = _sessionCubit.state.isAuthenticated;

        _log.debug('redirect - location: {}, isAuthenticated: {}', [location, isAuthenticated]);

        if (_isPublicRoute(location)) {
          return null;
        }

        if (!isAuthenticated && !_isPublicRoute(location)) {
          return ApplicationRoutesConstants.login;
        }

        if (ProfileConstants.isProduction &&
            SecurityUtils.isTokenExpired() &&
            location != ApplicationRoutesConstants.login) {
          return ApplicationRoutesConstants.login;
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
