import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/data/repositories/dashboard_mock_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';

class AppDependencies {
  const AppDependencies();

  IAccountRepository createAccountRepository() => AccountRepository();

  AuthorityRepository createAuthorityRepository() => AuthorityRepository();

  IDashboardRepository createDashboardRepository() => DashboardMockRepository();

  IAuthRepository createAuthRepository() => LoginRepository();

  MenuRepository createMenuRepository() => MenuRepository();

  IUserRepository createUserRepository() => UserRepository();
}
