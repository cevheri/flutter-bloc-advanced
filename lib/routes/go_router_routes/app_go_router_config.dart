import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/allowed_paths.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/account_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/auth_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/home_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/settings_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/routes/user_routes.dart';
import 'package:flutter_bloc_advance/utils/security_utils.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends StatelessWidget {
  final GoException? error;

  const ErrorScreen(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error?.message}'),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}

class AppGoRouterConfig {
  static final _log = AppLogger.getLogger("AppGoRouterConfig");
  static final GoRouter router = GoRouter(
    initialLocation: ApplicationRoutesConstants.home,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => ErrorScreen(state.error),
    routes: [
      ...HomeRoutes.routes,
      ...AccountRoutes.routes,
      ...UserRoutes.routes,
      ...AuthRoutes.routes,
      ...SettingsRoutes.routes,
    ],
    redirect: (context, state) async {
      _log.debug("BEGIN: redirect");
      _log.debug("redirect - uri: ${state.uri}");
      _log.debug("authPaths: $authPaths");
      // Skip redirect for login page
      if (authPaths.any((p) => state.uri.path.startsWith(p))) {
        _log.debug("END: redirect null - with authPaths");
        return null;
      }

      // check : when redirect the new page then load the account data
      if (state.uri.toString() == ApplicationRoutesConstants.home) {
        var accountBloc = context.read<AccountBloc>();
        await Future.delayed(const Duration(microseconds: 500));
        accountBloc.add(const AccountFetchEvent());
        _log.debug("redirect - load event : accountBloc.add(AccountLoad())");
      }
      // check : when jwtToken is null then redirect to login page
      if (!SecurityUtils.isUserLoggedIn() && !SecurityUtils.isAllowedPath(state.uri.toString())) {
        _log.debug("END: isUserLoggedIn is false and isAllowedPath is false");
        if (state.uri.toString() != ApplicationRoutesConstants.login) {
          return ApplicationRoutesConstants.login;
        } else {
          return null;
        }
      }
      // check : when running in production mode and jwtToken is expired then redirect to login page
      if (ProfileConstants.isProduction &&
          SecurityUtils.isTokenExpired() &&
          state.uri.toString() != ApplicationRoutesConstants.login) {
        _log.debug("END: redirect - jwtToken is expired");
        return ApplicationRoutesConstants.login;
      }

      _log.debug("END: redirect return null");
      return null;
    },
  );

  static MaterialApp routeBuilder(ThemeData theme, ThemeData darkTheme, String language, ThemeMode themeMode) {
    return MaterialApp.router(
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: true,
      debugShowMaterialGrid: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: Locale(language),
      routerConfig: AppGoRouterConfig.router,
    );
  }
}
