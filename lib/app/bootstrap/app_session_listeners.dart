import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

class AppSessionListeners extends StatelessWidget {
  const AppSessionListeners({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: (context, state) async {
            if (state is LoginLoadedState) {
              // AuthSessionRepository.persist has already written roles to
              // AppLocalStorage by the time LoginLoadedState is emitted.
              // Read them here so SessionAuthenticated carries the role set
              // that route guards consult on the next router refresh.
              final raw = await AppLocalStorage().read(StorageKeys.roles.key);
              final roles = raw is List ? raw.whereType<String>().toSet() : const <String>{};
              if (context.mounted) {
                context.read<SessionCubit>().markAuthenticated(roles: roles);
              }
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
