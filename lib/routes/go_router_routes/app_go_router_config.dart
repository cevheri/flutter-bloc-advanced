import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/account_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/auth_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/home_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/settings_routes.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/user_routes.dart';
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
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go back'),
            ),
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
      final accountBloc = context.read<AccountBloc>();
      _log.debug("redirect - accountBloc.state: ${accountBloc.state.status}");
      // check if the account is loaded
      if (accountBloc.state.status == AccountStatus.initial) {
        //
        _log.debug("redirect with account load from initial");
        accountBloc.add(const AccountLoad());
        _log.debug("redirect with account load from initial - after add");
        //
        _log.debug("redirect with account load from initial - before delay");
        await Future.delayed(const Duration(seconds: 1));
        _log.debug("redirect with account load from initial - after delay");
        //
        if (accountBloc.state.status == AccountStatus.failure) {
          _log.debug("END: redirect - ${accountBloc.state.status}  with login - initial>failure");
          return ApplicationRoutesConstants.login;
        }
      }

      _log.debug("END: redirect return null");
      return null;
    },
  );

  static MaterialApp routeBuilder(ThemeData light, ThemeData dark, String language) {
    return MaterialApp.router(
      theme: light,
      darkTheme: dark,
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
