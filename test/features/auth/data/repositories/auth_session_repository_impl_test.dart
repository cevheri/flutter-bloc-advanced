import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_utils.dart';

void main() {
  late AppLocalStorage storage;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = AppLocalStorage();
    storage.setPreferencesInstance(await SharedPreferences.getInstance());
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('AuthSessionRepository', () {
    test('persist writes jwtToken, username, and roles', () async {
      final repo = AuthSessionRepository(storage: storage);
      const session = AuthSession(idToken: 'TOKEN', refreshToken: 'REFRESH', username: 'alice', roles: ['ROLE_USER']);

      final result = await repo.persist(session);

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.jwtToken.key), 'TOKEN');
      expect(await storage.read(StorageKeys.refreshToken.key), 'REFRESH');
      expect(await storage.read(StorageKeys.username.key), 'alice');
      expect(await storage.read(StorageKeys.roles.key), ['ROLE_USER']);
    });

    test('persist skips refreshToken when null', () async {
      final repo = AuthSessionRepository(storage: storage);
      const session = AuthSession(idToken: 'TOKEN', username: 'alice');

      await repo.persist(session);

      expect(await storage.read(StorageKeys.jwtToken.key), 'TOKEN');
      expect(await storage.read(StorageKeys.refreshToken.key), isNull);
    });

    test('clear empties the storage', () async {
      final repo = AuthSessionRepository(storage: storage);
      await storage.save(StorageKeys.jwtToken.key, 'TOKEN');
      await storage.save(StorageKeys.username.key, 'alice');

      final result = await repo.clear();

      expect(result, isA<Success<void>>());
      expect(await storage.read(StorageKeys.jwtToken.key), isNull);
      expect(await storage.read(StorageKeys.username.key), isNull);
    });
  });
}
