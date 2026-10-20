import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;

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

/// Holds a token for every key but cannot delete one.
class _DeleteThrowsSecureStorage implements ISecureStorage {
  @override
  Future<String?> read(String key) async => 'stored-$key';
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async => throw StateError('boom on delete $key');
  @override
  Future<void> deleteAll() async => throw StateError('boom on deleteAll');
}

/// JWT with `exp` claim already in the past. Built statically so tests
/// can be const-friendly. Payload: `{"sub":"u","exp":1}` (1970-01-01).
const _expiredJwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1IiwiZXhwIjoxfQ.signature';

void main() {
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

    test('endSession logs an error and still ends the session when the stored session cannot be cleared', () async {
      final errors = <String>[];
      void recordError(OutputEvent event) {
        if (event.level == Level.error) errors.addAll(event.lines);
      }

      Logger.addOutputListener(recordError);
      addTearDown(() => Logger.removeOutputListener(recordError));
      final cubit = SessionCubit(secureStorage: _DeleteThrowsSecureStorage())..markAuthenticated();
      addTearDown(cubit.close);

      await cubit.endSession(reason: SessionExpiredReason.idleTimeout);

      expect(cubit.state, const SessionUnauthenticated(reason: SessionExpiredReason.idleTimeout));
      expect(errors, contains(allOf(contains('SessionCubit : endSession(idleTimeout)'), contains('boom on delete'))));
    });

    // A request still in flight when the user signs out can end in a 401 that no refresh can fix, so endSession runs
    // with no session to end.
    blocTest<SessionCubit, SessionState>(
      'endSession leaves storage and state alone when no session is stored',
      setUp: () => AppLocalStorage().save(StorageKeys.language.key, 'tr'),
      build: () => SessionCubit(secureStorage: _MemorySecureStorage()),
      seed: () => const SessionUnauthenticated(reason: SessionExpiredReason.noToken),
      act: (cubit) => cubit.endSession(reason: SessionExpiredReason.expired),
      expect: () => const <SessionState>[],
      verify: (_) async => expect(await AppLocalStorage().read(StorageKeys.language.key), 'tr'),
    );

    // A token refresh still in flight when the session ends can store a fresh session while the cubit is signed out;
    // a restart would restore it.
    test('endSession clears a stored session even when the cubit is already signed out', () async {
      final storage = _MemorySecureStorage();
      await storage.write(SecureStorageKeys.jwtToken.key, 'fresh-jwt');
      await storage.write(SecureStorageKeys.refreshToken.key, 'fresh-refresh');
      final cubit = SessionCubit(secureStorage: storage)..markLoggedOut();
      addTearDown(cubit.close);

      await cubit.endSession(reason: SessionExpiredReason.expired);

      expect(await storage.read(SecureStorageKeys.jwtToken.key), isNull);
      expect(await storage.read(SecureStorageKeys.refreshToken.key), isNull);
      expect(cubit.state, const SessionUnauthenticated(reason: SessionExpiredReason.noToken));
    });
  });
}
