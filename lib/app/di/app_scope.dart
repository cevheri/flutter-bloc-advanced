import 'dart:async';

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
import 'package:flutter_bloc_advance/features/auth/application/usecases/sign_in_with_sso_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/sso_sign_out_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_sign_out_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/sso_sign_out_auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/services/misconfigured_sso_session_startup.dart';
import 'package:flutter_bloc_advance/features/auth/data/services/sso_session_startup_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/usecases/fetch_app_config_usecase.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_client.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/resilience_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';

class AppScope extends StatelessWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    this.secureStorage,
    required this.defaultLocale,
    required this.child,
    this.sessionEndSignal,
    this.tokenRefreshLock,
  });

  final AppDependencies dependencies;

  /// This browser tab's [ISessionEndSignal] and [ITokenRefreshLock], which `App` creates once per tab; on mobile and
  /// desktop no signal, and a lock that runs a refresh at once, which is also what a scope built without them gets.
  final ISessionEndSignal? sessionEndSignal;
  final ITokenRefreshLock? tokenRefreshLock;

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
    final oidcSettings = switch (dependencies.authMode) {
      OidcAuthMode(:final settings) => settings,
      JwtAuthMode() || OidcMisconfiguredAuthMode() => null,
    };
    return MultiRepositoryProvider(
      providers: [
        if (secure != null)
          RepositoryProvider<ISecureStorage>.value(value: secure)
        else
          RepositoryProvider<ISecureStorage>(create: (_) => dependencies.createSecureStorage()),
        RepositoryProvider<AppConfig>.value(value: dependencies.appConfig),
        RepositoryProvider<ProjectLinks>.value(value: dependencies.projectLinks),
        RepositoryProvider<AuthMode>.value(value: dependencies.authMode),
        // Created when the tab starts, not with the HTTP client, so it hears another tab's end before anything stores
        // rotated tokens: the startup refresh of an oidc build may store before the first request.
        RepositoryProvider<RotatedTokensTakeBack>(
          lazy: false,
          create: (context) =>
              RotatedTokensTakeBack(secureStorage: context.read<ISecureStorage>(), sessionEndSignal: sessionEndSignal),
          // A scope mounted again creates its own, so this one stops hearing: one end, one wipe.
          dispose: (takeBack) => unawaited(takeBack.dispose()),
        ),
        // Provided above SessionCubit and IAuthRepository, which clear the stored session when they end one.
        RepositoryProvider<IAuthSessionRepository>(
          create: (context) => dependencies.createAuthSessionRepository(
            context.read<ISecureStorage>(),
            sessionEndSignal: sessionEndSignal,
          ),
        ),
        // Only an oidc build signs in through the provider. These come before SessionCubit, which completes a web
        // sign-in and refreshes the session at startup, and the one TokenRotation is shared with the ApiClient.
        if (oidcSettings != null) ...[
          RepositoryProvider<IOidcClient>(create: (_) => dependencies.createOidcClient(oidcSettings)),
          RepositoryProvider<ISsoAuthRepository>(
            create: (context) => dependencies.createSsoAuthRepository(
              context.read<IOidcClient>(),
              context.read<IAuthSessionRepository>(),
              oidcSettings,
            ),
          ),
          RepositoryProvider<TokenRotation>(
            create: (context) =>
                dependencies.createOidcTokenRotation(context.read<IOidcClient>(), context.read<ISecureStorage>()),
          ),
          RepositoryProvider<SsoAutoRedirectGate>(create: (_) => SsoAutoRedirectGate()),
        ],
        // Provided above ApiClient so a failed token refresh can end the session.
        BlocProvider<SessionCubit>(
          create: (context) {
            late final SessionCubit session;
            session = SessionCubit(
              secureStorage: context.read<ISecureStorage>(),
              sessionRepository: context.read<IAuthSessionRepository>(),
              appConfig: context.read<AppConfig>(),
              ssoStartup: switch (dependencies.authMode) {
                OidcAuthMode() => SsoSessionStartup(
                  auth: context.read<ISsoAuthRepository>(),
                  rotation: context.read<TokenRotation>(),
                  secureStorage: context.read<ISecureStorage>(),
                  sessionRepository: context.read<IAuthSessionRepository>(),
                  gate: context.read<SsoAutoRedirectGate>(),
                  refreshLock: tokenRefreshLock ?? const InProcessTokenRefreshLock(),
                  takeBack: context.read<RotatedTokensTakeBack>(),
                  // What the startup refresh stored and cannot take back ends the session as an unfixable 401 does.
                  onSessionExpired: () => session.endSession(reason: SessionExpiredReason.expired),
                ),
                // Fails closed: a session that an earlier oidc build stored is never restored.
                OidcMisconfiguredAuthMode() => const MisconfiguredSsoSessionStartup(),
                JwtAuthMode() => null,
              },
            );
            return session..restore();
          },
        ),
        RepositoryProvider<ApiClient>(
          create: (context) {
            final session = context.read<SessionCubit>();
            void onSessionExpired() => session.endSession(reason: SessionExpiredReason.expired);
            return switch (dependencies.authMode) {
              JwtAuthMode() => dependencies.createApiClient(
                context.read<ISecureStorage>(),
                onSessionExpired: onSessionExpired,
                tokenRefreshLock: tokenRefreshLock,
                rotatedTokensTakeBack: context.read<RotatedTokensTakeBack>(),
              ),
              OidcAuthMode() => dependencies.createOidcApiClient(
                context.read<ISecureStorage>(),
                onSessionExpired: onSessionExpired,
                tokenRotation: context.read<TokenRotation>(),
                tokenRefreshLock: tokenRefreshLock,
                rotatedTokensTakeBack: context.read<RotatedTokensTakeBack>(),
              ),
              // A session that an earlier oidc build stored holds the provider's refresh token, which the backend's
              // refresh endpoint must never receive.
              OidcMisconfiguredAuthMode() => dependencies.createOidcApiClient(
                context.read<ISecureStorage>(),
                onSessionExpired: onSessionExpired,
                tokenRotation: const RefusingTokenRotation(),
                tokenRefreshLock: tokenRefreshLock,
                rotatedTokensTakeBack: context.read<RotatedTokensTakeBack>(),
              ),
            };
          },
        ),
        RepositoryProvider<IAccountRepository>(
          create: (context) => dependencies.createAccountRepository(context.read<ApiClient>()),
        ),
        RepositoryProvider<IAuthorityRepository>(
          create: (context) => dependencies.createAuthorityRepository(context.read<ApiClient>()),
        ),
        if (oidcSettings == null)
          RepositoryProvider<IAuthRepository>(
            create: (context) =>
                dependencies.createAuthRepository(context.read<IAuthSessionRepository>(), context.read<ApiClient>()),
          )
        else ...[
          // A logout the user starts in an oidc build also ends the session at the identity provider.
          RepositoryProvider<SsoSignOutAuthRepository>(
            create: (context) => SsoSignOutAuthRepository(
              inner: dependencies.createAuthRepository(
                context.read<IAuthSessionRepository>(),
                context.read<ApiClient>(),
              ),
              client: context.read<IOidcClient>(),
              secureStorage: context.read<ISecureStorage>(),
              settings: oidcSettings,
            ),
          ),
          RepositoryProvider<IAuthRepository>(create: (context) => context.read<SsoSignOutAuthRepository>()),
          RepositoryProvider<ISsoSignOutRepository>(create: (context) => context.read<SsoSignOutAuthRepository>()),
        ],
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
              signInWithSsoUseCase: oidcSettings == null
                  ? null
                  : SignInWithSsoUseCase(context.read<ISsoAuthRepository>()),
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
              ssoSignOutUseCase: oidcSettings == null ? null : SsoSignOutUseCase(context.read<ISsoSignOutRepository>()),
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
