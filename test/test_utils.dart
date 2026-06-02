import 'package:dio/dio.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

import 'support/test_env.dart';

/// DEPRECATED compatibility shim. Use [TestEnv] directly. Removed once all
/// files are migrated (see plan #150). Delegates to TestEnv so existing
/// `TestUtils().setupUnitTest()` call sites keep working during migration.
class TestUtils {
  static ApiClient apiClient({Dio? dio}) => TestEnv.apiClient(dio: dio);

  Future<void> setupUnitTest() => TestEnv.reset();
  Future<void> setupRepositoryUnitTest() => TestEnv.reset();
  Future<void> tearDownUnitTest() => TestEnv.reset();
  void setupAuthentication() => TestEnv.authenticate();
}
