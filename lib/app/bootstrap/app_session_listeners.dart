import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';

class AppSessionListeners extends StatelessWidget {
  const AppSessionListeners({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            if (state is LoginLoadedState) {
              // Mark the session authenticated SYNCHRONOUSLY using the roles
              // carried on LoginLoadedState. As an ancestor of the login page
              // this listener fires before the page's success listener, so the
              // session is already authenticated (with roles) when that listener
              // navigates to the `returnUrl` deep link. The previous version
              // awaited a storage read here, which let navigation win the race
              // and bounce the deep link back to /login → home.
              context.read<SessionCubit>().markAuthenticated(roles: state.roles.toSet());
            }
          },
        ),
        BlocListener<MenuBloc, MenuState>(
          listenWhen: (previous, current) => previous.isLogout != current.isLogout,
          listener: (context, state) {
            if (state.isLogout) {
              context.read<SessionCubit>().markLoggedOut();
            }
          },
        ),
      ],
      child: child,
    );
  }
}
