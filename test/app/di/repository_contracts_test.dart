import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

void main() {
  setUpAll(() {
    AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
  });

  const dependencies = AppDependencies();

  test('app dependencies expose account repository contract', () {
    expect(dependencies.createAccountRepository(), isA<IAccountRepository>());
  });

  test('app dependencies expose auth repository contract', () {
    expect(dependencies.createAuthRepository(_StubSecureStorage()), isA<IAuthRepository>());
  });

  test('app dependencies expose user repository contract', () {
    expect(dependencies.createUserRepository(), isA<IUserRepository>());
  });
}
