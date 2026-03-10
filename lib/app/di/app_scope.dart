import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';

class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies, required this.child});

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAccountRepository>(create: (_) => dependencies.createAccountRepository()),
        RepositoryProvider<AuthorityRepository>(create: (_) => dependencies.createAuthorityRepository()),
        RepositoryProvider<IDashboardRepository>(create: (_) => dependencies.createDashboardRepository()),
        RepositoryProvider<IAuthRepository>(create: (_) => dependencies.createAuthRepository()),
        RepositoryProvider<MenuRepository>(create: (_) => dependencies.createMenuRepository()),
        RepositoryProvider<IUserRepository>(create: (_) => dependencies.createUserRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>(create: (_) => SessionCubit()..restore()),
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              authenticateUserUseCase: AuthenticateUserUseCase(context.read<IAuthRepository>()),
              sendOtpUseCase: SendOtpUseCase(context.read<IAuthRepository>()),
              verifyOtpUseCase: VerifyOtpUseCase(context.read<IAuthRepository>()),
              getAccountUseCase: GetAccountUseCase(context.read<IAccountRepository>()),
            ),
          ),
          BlocProvider<AuthorityBloc>(
            create: (context) => AuthorityBloc(repository: context.read<AuthorityRepository>()),
          ),
          BlocProvider<AccountBloc>(
            create: (context) => AccountBloc(
              getAccountUseCase: GetAccountUseCase(context.read<IAccountRepository>()),
              updateAccountUseCase: UpdateAccountUseCase(context.read<IAccountRepository>()),
            ),
          ),
          BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()..add(const LoadTheme())),
          BlocProvider<MenuBloc>(
            create: (context) => MenuBloc(
              loginRepository: context.read<IAuthRepository>(),
              menuRepository: context.read<MenuRepository>(),
            ),
          ),
          BlocProvider<SidebarBloc>(create: (_) => SidebarBloc()),
        ],
        child: child,
      ),
    );
  }
}
