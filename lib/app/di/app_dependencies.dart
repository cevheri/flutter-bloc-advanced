import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/core/analytics/analytics_service.dart';
import 'package:flutter_bloc_advance/core/analytics/log_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class AppDependencies {
  const AppDependencies({this.appConfig = const AppConfig.dev()});

  final AppConfig appConfig;

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

  ApiClient createApiClient(ISecureStorage secureStorage) =>
      ApiClient(appConfig: appConfig, secureStorage: secureStorage);

  IAccountRepository createAccountRepository(ApiClient apiClient) => AccountRepository(apiClient);

  IAuthRepository createAuthRepository(ISecureStorage secureStorage, ApiClient apiClient) =>
      LoginRepository(secureStorage: secureStorage, apiClient: apiClient);

  IAuthSessionRepository createAuthSessionRepository(ISecureStorage secureStorage) =>
      AuthSessionRepository(secureStorage: secureStorage);

  IAuthorityRepository createAuthorityRepository(ApiClient apiClient) => AuthorityRepositoryImpl(apiClient);

  IDynamicFormRepository createDynamicFormRepository(ApiClient apiClient) => DynamicFormRepository(apiClient);

  MenuRepository createMenuRepository() => MenuRepository();

  ISecureStorage createSecureStorage() => FlutterSecureStorageAdapter();

  IUserRepository createUserRepository(ApiClient apiClient) => UserRepository(apiClient);
}
