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
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == LoginStatus.success) {
              context.read<SessionCubit>().markAuthenticated();
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
