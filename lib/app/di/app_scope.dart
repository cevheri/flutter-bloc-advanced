import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_cubit.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/localization/locale_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/logout_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/usecases/fetch_app_config_usecase.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
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
  const AppScope({
    super.key,
    required this.dependencies,
    this.secureStorage,
    required this.defaultLocale,
    required this.child,
  });

  final AppDependencies dependencies;

  /// Pre-constructed ISecureStorage from bootstrap. When provided, it is
  /// shared via `.value` so migration and runtime consumers use the same
  /// instance. When null, AppScope falls back to `dependencies.createSecureStorage()`
  /// (useful for tests that don't go through bootstrap).
  final ISecureStorage? secureStorage;

  /// The language [LocaleCubit] shows when no language is stored on the device.
  final Locale defaultLocale;
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
        RepositoryProvider<ProjectLinks>.value(value: dependencies.projectLinks),
        RepositoryProvider<AuthMode>.value(value: dependencies.authMode),
        // Provided above SessionCubit and IAuthRepository, which clear the stored session when they end one.
        RepositoryProvider<IAuthSessionRepository>(
          create: (context) => dependencies.createAuthSessionRepository(context.read<ISecureStorage>()),
        ),
        // Provided above ApiClient so a failed token refresh can end the session.
        BlocProvider<SessionCubit>(
          create: (context) => SessionCubit(
            secureStorage: context.read<ISecureStorage>(),
            sessionRepository: context.read<IAuthSessionRepository>(),
            appConfig: context.read<AppConfig>(),
          )..restore(),
        ),
        RepositoryProvider<ApiClient>(
          create: (context) {
            final session = context.read<SessionCubit>();
            return dependencies.createApiClient(
              context.read<ISecureStorage>(),
              onSessionExpired: () => session.endSession(reason: SessionExpiredReason.expired),
            );
          },
        ),
        RepositoryProvider<IAccountRepository>(
          create: (context) => dependencies.createAccountRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthorityRepository>(
          create: (context) => dependencies.createAuthorityRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthRepository>(
          create: (context) =>
              dependencies.createAuthRepository(context.read<IAuthSessionRepository>(), context.read<ApiClient>()),
        ),
        RepositoryProvider<IDynamicFormRepository>(
          create: (context) => dependencies.createDynamicFormRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<ILifecycleRepository>(
          create: (context) => dependencies.createLifecycleRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<MenuRepository>(create: (_) => dependencies.createMenuRepository()),
        RepositoryProvider<IUserRepository>(
          create: (context) => dependencies.createUserRepository(context.read<ApiClient>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()..monitor()),
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
          // Created, and the first check sent, when App's LifecycleGate first builds.
          BlocProvider<LifecycleBloc>(
            create: (context) => LifecycleBloc(
              fetchAppConfigUseCase: FetchAppConfigUseCase(context.read<ILifecycleRepository>()),
              featureFlagService: FeatureFlagService.instance,
            )..add(const LifecycleCheckEvent()),
          ),
          BlocProvider<LocaleCubit>(
            create: (_) =>
                LocaleCubit(storage: dependencies.createLocalStorage(), defaultLocale: defaultLocale)..restore(),
          ),
          BlocProvider<MenuBloc>(
            create: (context) => MenuBloc(
              logoutUseCase: LogoutUseCase(context.read<IAuthRepository>()),
              menuRepository: context.read<MenuRepository>(),
            ),
          ),
          // Created with the app instead of on first use, so the stored collapse state is restored before the shell
          // first shows the sidebar, which would otherwise open expanded and then animate closed.
          BlocProvider<SidebarBloc>(lazy: false, create: (_) => SidebarBloc()..add(const RestoreSidebarCollapse())),
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
