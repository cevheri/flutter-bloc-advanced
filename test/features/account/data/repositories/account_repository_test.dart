import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/fake_data.dart';
import '../../../../support/test_env.dart';

void main() {
  late AccountRepository repository;

  //region setup
  setUp(() {
    repository = AccountRepository(TestEnv.apiClient());
  });
  //endregion setup

  //test register
  group("AccountRepository Register success", () {
    test("Given valid user when register then return user successfully", () async {
      final entity = mockUserFullPayload;
      final result = await repository.register(entity);

      //check assets/mock/POST_register.json
      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-2");
      expect(data.login, "user");
      expect(data.email, "user@sample.tech");
      expect(data.firstName, "User");
      expect(data.lastName, "User");
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_USER"]);
    });

    test("Given valid without langKey user when register then return user successfully", () async {
      var entity = mockUserFullPayload;
      entity = entity.copyWith(langKey: "");
      final result = await repository.register(entity);

      //check assets/mock/POST_register.json
      expect(result, isA<Success<UserEntity>>());
      final data = (result as Success<UserEntity>).data;
      expect(data.id, "user-2");
      expect(data.login, "user");
      expect(data.email, "user@sample.tech");
      expect(data.firstName, "User");
      expect(data.lastName, "User");
      expect(data.langKey, "en");
      expect(data.createdBy, "system");
      expect(data.createdDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.lastModifiedBy, "admin");
      expect(data.lastModifiedDate?.toIso8601String(), "2024-01-04T06:02:47.757Z");
      expect(data.authorities, ["ROLE_USER"]);
    });

    test("Given user with empty email when register then return Failure with ValidationError", () async {
      final entity = mockUserFullPayload.copyWith(email: "");
      final result = await repository.register(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with null login when register then return Success", () async {
      const entity = User(firstName: "test", lastName: "test", email: "test@test.com");
      final result = await repository.register(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    /// Register endpoint does not require AccessToken, this endpoint added to the allowed endpoints in the HttpUtils class
    test("Given valid user without token when register then return user successfully", () async {
      final entity = mockUserFullPayload;
      final result = await repository.register(entity);
      expect(result, isA<Success<UserEntity>>());
    });
  });

  //test changePassword
  group("AccountRepository Change Password", () {
    test("Given valid passwordChangeDTO when changePassword then return Success", () async {
      TestEnv.authenticate();
      const passwordChangeDTO = mockPasswordChangePayload;
      final result = await repository.changePassword(passwordChangeDTO);
      expect(result, isA<Success<void>>());
    });

    test("Given empty value passwordChangeDTO when changePassword then return Failure", () async {
      const passwordChangeDTO = PasswordChangeDTO();
      final result = await repository.changePassword(passwordChangeDTO);
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test("Given empty passwords passwordChangeDTO when changePassword then return Failure", () async {
      final passwordChangeDTO = mockPasswordChangePayload.copyWith(currentPassword: "", newPassword: "");
      final result = await repository.changePassword(passwordChangeDTO);
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    // Regression: the start line printed the PasswordChangeDTO, whose text carries both passwords, so a debug build
    // of main_local put the user's current and new password into the console.
    test("Given a password change when changePassword then the log says so without either password", () async {
      TestEnv.authenticate();
      final lines = <String>[];

      await runZoned(
        () =>
            repository.changePassword(const PasswordChangeDTO(currentPassword: 'OldPass#1', newPassword: 'NewPass#2')),
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => lines.add(line)),
      );

      expect(lines, anyElement(contains('AccountRepository : BEGIN:changePassword')));
      expect(lines, everyElement(allOf(isNot(contains('OldPass#1')), isNot(contains('NewPass#2')))));
    });
  });

  //test resetPassword
  group("AccountRepository Reset Password", () {
    test("Given valid mailAddress when resetPassword then return Success", () async {
      TestEnv.authenticate();
      const mailAddress = "admin@sample.tech";
      final result = await repository.resetPassword(mailAddress);
      expect(result, isA<Success<void>>());
    });

    test("Given empty mailAddress when resetPassword then return Failure with ValidationError", () async {
      final result = await repository.resetPassword("");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });

    test("Given invalid mailAddress when resetPassword then return Failure with ValidationError", () async {
      final result = await repository.resetPassword("test");
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<ValidationError>());
    });
  });

  //test getAccount
  group("AccountRepository Get Account", () {
    //success
    test("Given valid user when getAccount then return Success", () async {
      TestEnv.authenticate();
      final result = await repository.getAccount();
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given getAccount without AccessToken then return Failure with AuthError", () async {
      final result = await repository.getAccount();
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });
  });

  //test saveAccount
  group("AccountRepository Save Account", () {
    //success
    test("Given valid user when saveAccount then return Success", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload;
      final result = await repository.update(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given valid user when saveAccount without AccessToken then return Failure with AuthError", () async {
      final entity = mockUserFullPayload;
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });

    test("Given user with empty id when saveAccount then return Failure with ValidationError", () async {
      TestEnv.authenticate();
      const entity = User();
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with blank id when saveAccount then return Failure with ValidationError", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload.copyWith(id: "");
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  //test updateAccount
  group("AccountRepository Update Account", () {
    //success
    test("Given valid user when updateAccount then return Success", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload;
      final result = await repository.update(entity);
      expect(result, isA<Success<UserEntity>>());
    });

    //fail: without AccessToken
    test("Given valid user when updateAccount without AccessToken then return Failure with AuthError", () async {
      final entity = mockUserFullPayload;
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<AuthError>());
    });

    test("Given user with null id when updateAccount then return Failure with ValidationError", () async {
      TestEnv.authenticate();
      const entity = User();
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });

    test("Given user with blank id when updateAccount then return Failure with ValidationError", () async {
      TestEnv.authenticate();
      final entity = mockUserFullPayload.copyWith(id: "");
      final result = await repository.update(entity);
      expect(result, isA<Failure<UserEntity>>());
      expect((result as Failure<UserEntity>).error, isA<ValidationError>());
    });
  });

  // Regression: a pin mismatch came back as an UnknownError without a code, so the account, registration and password
  // screens said "Failed" instead of telling the user that the connection was blocked.
  group('AccountRepository over a connection whose certificate matches no pin', () {
    late AccountRepository pinned;

    setUp(() {
      final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
      apiClient.instance.httpClientAdapter = _PinMismatchAdapter();
      pinned = AccountRepository(apiClient);
    });

    final certInvalid = isA<Failure<Object?>>()
        .having((failure) => failure.error, 'error', isA<NetworkError>())
        .having((failure) => failure.error.code, 'error.code', AppErrorCode.networkCertInvalid.key);

    test('getAccount reports AppErrorCode.networkCertInvalid', () async {
      expect(await pinned.getAccount(), certInvalid);
    });

    test('update reports AppErrorCode.networkCertInvalid', () async {
      expect(await pinned.update(const UserEntity(id: 'user-1', login: 'admin')), certInvalid);
    });

    test('register reports AppErrorCode.networkCertInvalid', () async {
      expect(await pinned.register(const UserEntity(email: 'new.user@sample.tech')), certInvalid);
    });

    test('resetPassword reports AppErrorCode.networkCertInvalid', () async {
      expect(await pinned.resetPassword('admin@sample.tech'), certInvalid);
    });

    test('changePassword reports AppErrorCode.networkCertInvalid', () async {
      const request = PasswordChangeDTO(currentPassword: 'password', newPassword: 'new_password');
      expect(await pinned.changePassword(request), certInvalid);
    });
  });
}

/// Production chain (no MockInterceptor) with certificate pinning configured.
const _pinnedProdConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: ['test-pin'],
  idleTimeout: null,
);

/// Fails every request as the pinning adapter fails a server whose certificate matches no configured pin.
class _PinMismatchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw const CertificatePinningException('api.example.test', 443);
  }

  @override
  void close({bool force = false}) {}
}
