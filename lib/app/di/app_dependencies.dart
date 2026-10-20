import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/shared_prefs_cache_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/interceptors/token_refresh_interceptor.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/shared_preferences_activity_store.dart';

class AppDependencies {
  const AppDependencies({this.appConfig = const AppConfig.dev(), this.projectLinks = const ProjectLinks()});

  final AppConfig appConfig;

  /// The project's repository, documentation and sponsor links that the app shows.
  final ProjectLinks projectLinks;

  /// Returns the analytics implementation appropriate for the active
  /// environment. Production + non-empty DSN → [SentryAnalyticsService]
  /// (Sentry SDK assumed already-initialized by bootstrap); any other
  /// case → [LogAnalyticsService] (local-only, no network egress).
  IAnalyticsService createAnalyticsService() {
    if (appConfig.sentryDsn != null) {
      return SentryAnalyticsService();
    }
    return LogAnalyticsService();
  }

  /// [onSessionExpired] runs when a 401 cannot be fixed by a token refresh; the caller ends the session there.
  ApiClient createApiClient(ISecureStorage secureStorage, {required OnSessionExpired onSessionExpired}) =>
      ApiClient(appConfig: appConfig, secureStorage: secureStorage, onSessionExpired: onSessionExpired);

  IAccountRepository createAccountRepository(ApiClient apiClient) => AccountRepository(apiClient);

  /// The logout clears the session through [sessionRepository], as the idle timeout and an unrefreshable 401 do.
  IAuthRepository createAuthRepository(IAuthSessionRepository sessionRepository, ApiClient apiClient) =>
      LoginRepository(sessionRepository: sessionRepository, apiClient: apiClient);

  /// Ending a session also clears the cache of GET responses that [ApiClient] keeps in SharedPreferences.
  IAuthSessionRepository createAuthSessionRepository(ISecureStorage secureStorage) =>
      AuthSessionRepository(secureStorage: secureStorage, cacheStorage: SharedPrefsCacheStorage());

  IAuthorityRepository createAuthorityRepository(ApiClient apiClient) => AuthorityRepositoryImpl(apiClient);

  IDynamicFormRepository createDynamicFormRepository(ApiClient apiClient) => DynamicFormRepository(apiClient);

  /// Reads the remote app config that decides whether the app opens, shows the maintenance screen or asks for an
  /// update.
  ILifecycleRepository createLifecycleRepository(ApiClient apiClient) => LifecycleRepository(apiClient);

  /// The device preferences, such as the language the user picked.
  AppLocalStorage createLocalStorage() => AppLocalStorage();

  MenuRepository createMenuRepository() => MenuRepository();

  ISecureStorage createSecureStorage() => FlutterSecureStorageAdapter();

  /// Where the idle timeout records and reads the latest activity of every running instance of the app. On web all
  /// browser tabs share the session, so the activity of every tab counts; null on mobile and desktop, where one instance
  /// holds the session.
  ISharedActivityStore? createSharedActivityStore() => kIsWeb ? SharedPreferencesActivityStore() : null;

  IUserRepository createUserRepository(ApiClient apiClient) => UserRepository(apiClient);
}
