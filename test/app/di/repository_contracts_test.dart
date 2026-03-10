import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dependencies = AppDependencies();

  test('app dependencies expose account repository contract', () {
    expect(dependencies.createAccountRepository(), isA<IAccountRepository>());
  });

  test('app dependencies expose auth repository contract', () {
    expect(dependencies.createAuthRepository(), isA<IAuthRepository>());
  });

  test('app dependencies expose dashboard repository contract', () {
    expect(dependencies.createDashboardRepository(), isA<IDashboardRepository>());
  });

  test('app dependencies expose user repository contract', () {
    expect(dependencies.createUserRepository(), isA<IUserRepository>());
  });
}
