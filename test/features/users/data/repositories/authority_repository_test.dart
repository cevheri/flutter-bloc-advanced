import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

void main() {
  late AuthorityRepositoryImpl repository;

  //region setup
  setUp(() {
    repository = AuthorityRepositoryImpl(TestEnv.apiClient());
  });
  //endregion setup

  //getAuthorities
  group("AuthorityRepository list", () {
    test("Given valid when getAuthorities then return authorities successfully", () async {
      TestEnv.authenticate();
      final result = await repository.list();

      expect(result, isA<Success<List<String>>>());
      final data = (result as Success<List<String>>).data;
      expect(data.length, 2);
      expect(data[0], "ROLE_USER");
      expect(data[1], "ROLE_ADMIN");
    });
    test("Given valid without AccessToken when getAuthorities then return failure", () async {
      final result = await repository.list();
      expect(result, isA<Failure<List<String>>>());
    });
  });

  // Regression: a pin mismatch came back as a NetworkError without a code, unlike the other requests of the user
  // screens.
  test('list reports AppErrorCode.networkCertInvalid over a connection whose certificate matches no pin', () async {
    final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
    apiClient.instance.httpClientAdapter = _PinMismatchAdapter();

    final result = await AuthorityRepositoryImpl(apiClient).list();

    expect(
      result,
      isA<Failure<List<String>>>()
          .having((failure) => failure.error, 'error', isA<NetworkError>())
          .having((failure) => failure.error.code, 'error.code', AppErrorCode.networkCertInvalid.key),
    );
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
