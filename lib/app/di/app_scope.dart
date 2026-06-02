import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_cubit.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies, this.secureStorage, required this.child});

  final AppDependencies dependencies;

  /// Pre-constructed ISecureStorage from bootstrap. When provided, it is
  /// shared via `.value` so migration and runtime consumers use the same
  /// instance. When null, AppScope falls back to `dependencies.createSecureStorage()`
  /// (useful for tests that don't go through bootstrap).
  final ISecureStorage? secureStorage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final secure = secureStorage;
    return MultiRepositoryProvider(
      providers: [
        if (secure != null)
          RepositoryProvider<ISecureStorage>.value(value: secure)
        else
          RepositoryProvider<ISecureStorage>(create: (_) => dependencies.createSecureStorage()),
        RepositoryProvider<AppConfig>.value(value: dependencies.appConfig),
        RepositoryProvider<ApiClient>(
          create: (context) => dependencies.createApiClient(context.read<ISecureStorage>()),
        ),
        RepositoryProvider<IAccountRepository>(
          create: (context) => dependencies.createAccountRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthorityRepository>(
          create: (context) => dependencies.createAuthorityRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthRepository>(
          create: (context) =>
              dependencies.createAuthRepository(context.read<ISecureStorage>(), context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthSessionRepository>(
          create: (context) => dependencies.createAuthSessionRepository(context.read<ISecureStorage>()),
        ),
        RepositoryProvider<IDynamicFormRepository>(
          create: (context) => dependencies.createDynamicFormRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<MenuRepository>(create: (_) => dependencies.createMenuRepository()),
        RepositoryProvider<IUserRepository>(
          create: (context) => dependencies.createUserRepository(context.read<ApiClient>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()..monitor()),
          BlocProvider<SessionCubit>(
            create: (context) =>
                SessionCubit(secureStorage: context.read<ISecureStorage>(), appConfig: context.read<AppConfig>())
                  ..restore(),
          ),
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              authenticateUserUseCase: AuthenticateUserUseCase(context.read<IAuthRepository>()),
              sendOtpUseCase: SendOtpUseCase(context.read<IAuthRepository>()),
              verifyOtpUseCase: VerifyOtpUseCase(context.read<IAuthRepository>()),
              getAccountUseCase: GetAccountUseCase(context.read<IAccountRepository>()),
              persistAuthSessionUseCase: PersistAuthSessionUseCase(context.read<IAuthSessionRepository>()),
            ),
          ),
          BlocProvider<AuthorityBloc>(
            create: (context) =>
                AuthorityBloc(listAuthoritiesUseCase: ListAuthoritiesUseCase(context.read<IAuthorityRepository>())),
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
          BlocProvider<SystemDashboardCubit>(
            create: (context) => SystemDashboardCubit(
              connectivityService: ConnectivityService.instance,
              featureFlagService: FeatureFlagService.instance,
              resilienceInterceptor: ResilienceInterceptor.instance,
              cacheStorage: SharedPrefsCacheStorage.instance,
              apiClient: context.read<ApiClient>(),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}
