import 'dart:io';

import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/data/repositories/lifecycle_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_env.dart';

/// Guards that the mock answers every request the app's repositories send in mock mode.
///
/// `MockInterceptor` fails a GET, POST, PUT or PATCH whose file under `assets/mock/` is missing with 501, so each
/// repository method is sent through the mock-backed [TestEnv.apiClient] and must succeed. Driving the real
/// repositories, instead of deriving file names from their source, sends the paths and parameters the repositories
/// build through the name resolution `MockInterceptor` uses, so the test cannot drift from either. A dynamic form
/// submits to the endpoint its schema declares, so each form the app opens is submitted through the schema its mock
/// serves.
///
/// The last test fails when a repository that sends requests through [ApiClient] gains a method the table does not
/// drive.
void main() {
  // Keyed by test name; the part before the first space is the repository method.
  final requests = <String, Future<Result<Object?>> Function(ApiClient client)>{
    'IAccountRepository.register': (client) =>
        AccountRepository(client).register(const UserEntity(email: 'new.user@sample.tech')),
    'IAccountRepository.changePassword': (client) =>
        AccountRepository(client)
            .changePassword(const PasswordChangeDTO(currentPassword: 'password', newPassword: 'new_password')),
    'IAccountRepository.resetPassword': (client) => AccountRepository(client).resetPassword('admin@sample.tech'),
    'IAccountRepository.getAccount': (client) => AccountRepository(client).getAccount(),
    'IAccountRepository.update': (client) =>
        AccountRepository(client).update(const UserEntity(id: 'user-1', login: 'admin', email: 'admin@sample.tech')),
    'IAuthRepository.authenticate': (client) =>
        LoginRepository(apiClient: client)
            .authenticate(const AuthCredentialsEntity(username: 'admin', password: 'admin')),
    'IAuthRepository.logout': (client) => LoginRepository(apiClient: client).logout(),
    'IAuthRepository.sendOtp': (client) =>
        LoginRepository(apiClient: client).sendOtp(const SendOtpEntity(email: 'admin@sample.tech')),
    'IAuthRepository.verifyOtp': (client) =>
        LoginRepository(apiClient: client).verifyOtp(const VerifyOtpEntity(email: 'admin@sample.tech', otp: '123456')),
    'IAuthorityRepository.list': (client) => AuthorityRepositoryImpl(client).list(),
    'IUserRepository.retrieve': (client) => UserRepository(client).retrieve('user-1'),
    'IUserRepository.create': (client) =>
        UserRepository(client).create(const UserEntity(login: 'new_user', email: 'new_user@sample.tech')),
    'IUserRepository.update': (client) =>
        UserRepository(client).update(const UserEntity(id: 'user-1', login: 'admin', email: 'admin@sample.tech')),
    'IUserRepository.list': (client) => UserRepository(client).list(),
    'IUserRepository.listByAuthority': (client) => UserRepository(client).listByAuthority(0, 10, 'ROLE_ADMIN'),
    'IUserRepository.listByName': (client) => UserRepository(client).listByName(0, 10, 'admin'),
    'IUserRepository.listByNameAndRole': (client) =>
        UserRepository(client).listByNameAndRole(0, 10, 'admin', 'ROLE_ADMIN'),
    'IUserRepository.delete': (client) => UserRepository(client).delete('user-1'),
    'IDynamicFormRepository.fetchSchema': (client) => DynamicFormRepository(client).fetchSchema('sample'),
    'IDynamicFormRepository.fetchBundle': (client) =>
        DynamicFormRepository(client).fetchBundle(UserExtendedInfoPage.basePath, pathParams: 'user-1'),
    'IDynamicFormRepository.submit of the sample form the dashboard opens': (client) async {
      final repository = DynamicFormRepository(client);
      final schema = (await repository.fetchSchema('sample')).dataOrNull!;
      return repository.submit(schema.submitAction!, const {
        'name': 'Jane Doe',
        'email': 'jane.doe@example.com',
        'source': 'Referral',
      });
    },
    'IDynamicFormRepository.submit of the user extended info form': (client) async {
      final repository = DynamicFormRepository(client);
      final bundle = (await repository.fetchBundle(UserExtendedInfoPage.basePath, pathParams: 'user-1')).dataOrNull!;
      return repository.submit(bundle.schema.submitAction!, bundle.values, pathParams: 'user-1');
    },
    'ILifecycleRepository.fetchAppConfig': (client) => LifecycleRepository(client).fetchAppConfig(),
  };

  for (final MapEntry(key: name, value: send) in requests.entries) {
    test('$name succeeds through the mock-backed client', () async {
      TestEnv.authenticate();

      final result = await send(TestEnv.apiClient());

      expect(result, isA<Success<Object?>>(), reason: '$result');
    });
  }

  test('every method of a repository that sends requests through ApiClient is driven above', () {
    final driven = requests.keys.map((name) => name.split(' ').first).toSet();
    final methods = _apiClientRepositoryMethods();

    expect(methods.difference(driven), isEmpty, reason: 'Drive these methods above and add the mock files they need');
    expect(driven.difference(methods), isEmpty, reason: 'These entries match no repository method');
  });
}

/// `Interface.method` for every method of a repository interface that a class importing [ApiClient] implements.
Set<String> _apiClientRepositoryMethods() {
  final sources = [
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart')) file.readAsStringSync(),
  ];
  final implemented = {
    for (final source in sources)
      if (source.contains("import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';"))
        for (final match in RegExp(r'class \w+ implements (I\w+Repository)\b').allMatches(source)) match[1]!,
  };
  final declared = {
    for (final source in sources)
      for (final interface in RegExp(
        r'^abstract class (I\w+Repository) \{$(.*?)^\}',
        multiLine: true,
        dotAll: true,
      ).allMatches(source))
        interface[1]!: {
          for (final method in RegExp(r'^  Future<.*?> (\w+)\(', multiLine: true).allMatches(interface[2]!)) method[1]!,
        },
  };
  // The patterns above match how the interfaces are written today. One written another way would otherwise drop out
  // of the check without a failure.
  expect(implemented, isNotEmpty, reason: 'No class importing ApiClient implements an I*Repository interface');
  for (final interface in implemented) {
    expect(declared[interface], isNotEmpty, reason: 'Found no methods of $interface: extend the patterns to read it');
  }
  return {
    for (final interface in implemented)
      for (final method in declared[interface]!) '$interface.$method',
  };
}
