import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/routes.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/home/home_screen.dart';
import 'package:flutter_bloc_advance/route/account_routes.dart';
import 'package:flutter_bloc_advance/route/auth_routes.dart';
import 'package:flutter_bloc_advance/route/settings_routes.dart';
import 'package:flutter_bloc_advance/route/user_routes.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: ApplicationRoutes.home,
    routes: [
      GoRoute(name: "home", path: ApplicationRoutes.home, builder: (context, state) => HomeScreen()),
      ...AccountRoutes.routes,
      ...UserRoutes.routes,
      ...AuthRoutes.routes,
      ...SettingsRoutes.routes,
    ],
    redirect: (context, state) async {
      print("Redirecting to ${state.uri.toString()}");
      print(" state = ${state.toString()}");
      print(" context = $context");
      final accountBloc = context.read<AccountBloc>();

      print("accountBloc = $accountBloc");
      print("accountBloc.state = ${accountBloc.state}");
      print("accountBloc.state.status = ${accountBloc.state.status}");

      // check if the account is loaded
      if (accountBloc.state.status == AccountStatus.initial) {
        print("accountBloc.state.status == AccountStatus.initial");
        accountBloc.add(const AccountLoad());
        await Future.delayed(const Duration(seconds: 1));
        if (accountBloc.state.status == AccountStatus.failure) {
          return ApplicationRoutes.login;
        }
      }

      // check if the token is valid
      if (accountBloc.state.status == AccountStatus.failure) {
        print("accountBloc.state.status == AccountStatus.failure");
        return ApplicationRoutes.login;
      }

      return null; // No redirection needed
    },
  );
}
