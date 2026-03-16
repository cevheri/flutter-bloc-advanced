import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class AppDependencies {
  const AppDependencies({this.environment = Environment.dev});

  final Environment environment;

  IAccountRepository createAccountRepository() => AccountRepository();

  IAuthorityRepository createAuthorityRepository() => AuthorityRepositoryImpl();

  IAuthRepository createAuthRepository() => LoginRepository();

  MenuRepository createMenuRepository() => MenuRepository();

  IUserRepository createUserRepository() => UserRepository();
}
