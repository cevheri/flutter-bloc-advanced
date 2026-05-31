import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

class _MemorySecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<void> deleteAll() async => _store.clear();
}

class _ReadThrowsSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => throw StateError('boom on read $key');
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
}

/// JWT with `exp` claim already in the past. Built statically so tests
/// can be const-friendly. Payload: `{"sub":"u","exp":1}` (1970-01-01).
const _expiredJwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1IiwiZXhwIjoxfQ.signature';

void main() {
  final testUtils = TestUtils();

  setUp(() async {
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  group('SessionState — sealed hierarchy', () {
    test('SessionUnknown is the initial state, distinct from unauthenticated', () {
      const unknown = SessionUnknown();
      const unauthenticated = SessionUnauthenticated(reason: SessionExpiredReason.noToken);
      expect(unknown, isNot(equals(unauthenticated)), reason: 'unknown ≠ unauthenticated by type');
    });

    test('SessionAuthenticated is a singleton-equivalent value type', () {
      const a = SessionAuthenticated();
      const b = SessionAuthenticated();
      expect(a, equals(b));
    });

    test('SessionUnauthenticated equality includes the reason', () {
      const noToken = SessionUnauthenticated(reason: SessionExpiredReason.noToken);
      const expired = SessionUnauthenticated(reason: SessionExpiredReason.expired);
      expect(noToken, isNot(equals(expired)));
    });

    test('exhaustive switch covers all variants without a default', () {
      // Compiler-enforced exhaustiveness — if a new variant is added
      // without updating callers, the analyzer fails this build.
      String label(SessionState s) => switch (s) {
        SessionUnknown() => 'unknown',
        SessionAuthenticated() => 'authenticated',
        SessionUnauthenticated() => 'unauthenticated',
      };
      expect(label(const SessionUnknown()), 'unknown');
      expect(label(const SessionAuthenticated()), 'authenticated');
      expect(label(const SessionUnauthenticated()), 'unauthenticated');
    });
  });

  group('SessionCubit', () {
    test('initial state is SessionUnknown — distinguishable from unauthenticated', () {
      final cubit = SessionCubit();
      expect(cubit.state, isA<SessionUnknown>());
      cubit.close();
    });

    blocTest<SessionCubit, SessionState>(
      'markAuthenticated emits SessionAuthenticated',
      build: () => SessionCubit(),
      act: (cubit) => cubit.markAuthenticated(),
      expect: () => [const SessionAuthenticated()],
    );

    blocTest<SessionCubit, SessionState>(
      'markLoggedOut emits SessionUnauthenticated with noToken reason by default',
      build: () => SessionCubit(),
      seed: () => const SessionAuthenticated(),
      act: (cubit) => cubit.markLoggedOut(),
      expect: () => [const SessionUnauthenticated(reason: SessionExpiredReason.noToken)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits SessionUnauthenticated(noToken) when secure storage is empty',
      build: () => SessionCubit(secureStorage: _MemorySecureStorage()),
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionUnauthenticated(reason: SessionExpiredReason.noToken)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits SessionAuthenticated when secure storage has a token',
      build: () {
        final secure = _MemorySecureStorage();
        // Direct map write; the async `write` wrapper only exists to
        // satisfy ISecureStorage. Seeding synchronously avoids the
        // unawaited-write race the linter would otherwise flag.
        secure._store[SecureStorageKeys.jwtToken.key] = 'MOCK_TOKEN';
        return SessionCubit(secureStorage: secure);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionAuthenticated()],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits SessionUnauthenticated(expired) for an expired token in prod',
      build: () {
        final secure = _MemorySecureStorage();
        secure._store[SecureStorageKeys.jwtToken.key] = _expiredJwt;
        return SessionCubit(secureStorage: secure, appConfig: const AppConfig.prod());
      },
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionUnauthenticated(reason: SessionExpiredReason.expired)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits SessionUnauthenticated(storageError) when secure read throws',
      build: () => SessionCubit(secureStorage: _ReadThrowsSecureStorage()),
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionUnauthenticated(reason: SessionExpiredReason.storageError)],
    );

    blocTest<SessionCubit, SessionState>(
      'refresh delegates to restore',
      build: () => SessionCubit(secureStorage: _MemorySecureStorage()),
      act: (cubit) => cubit.refresh(),
      expect: () => [const SessionUnauthenticated(reason: SessionExpiredReason.noToken)],
    );

    blocTest<SessionCubit, SessionState>(
      'markAuthenticated then markLoggedOut transitions correctly',
      build: () => SessionCubit(),
      act: (cubit) {
        cubit.markAuthenticated();
        cubit.markLoggedOut();
      },
      expect: () => [const SessionAuthenticated(), const SessionUnauthenticated(reason: SessionExpiredReason.noToken)],
    );
  });
}
