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
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class AppDependencies {
  const AppDependencies({this.environment = Environment.dev});

  final Environment environment;

  IAccountRepository createAccountRepository() => AccountRepository();

  IAuthRepository createAuthRepository() => LoginRepository();

  IAuthSessionRepository createAuthSessionRepository(ISecureStorage secureStorage) =>
      AuthSessionRepository(secureStorage: secureStorage);

  IAuthorityRepository createAuthorityRepository() => AuthorityRepositoryImpl();

  IDynamicFormRepository createDynamicFormRepository() => DynamicFormRepository();

  MenuRepository createMenuRepository() => MenuRepository();

  ISecureStorage createSecureStorage() => FlutterSecureStorageAdapter();

  IUserRepository createUserRepository() => UserRepository();
}
