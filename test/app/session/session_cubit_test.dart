import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
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

void main() {
  final testUtils = TestUtils();

  setUp(() async {
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  group('SessionState', () {
    test('unknown() factory creates unauthenticated state', () {
      const state = SessionState.unknown();
      expect(state.isAuthenticated, isFalse);
    });

    test('constructor creates state with given authentication status', () {
      const authenticated = SessionState(isAuthenticated: true);
      expect(authenticated.isAuthenticated, isTrue);

      const unauthenticated = SessionState(isAuthenticated: false);
      expect(unauthenticated.isAuthenticated, isFalse);
    });

    test('copyWith returns new state with updated isAuthenticated', () {
      const state = SessionState(isAuthenticated: false);
      final updated = state.copyWith(isAuthenticated: true);
      expect(updated.isAuthenticated, isTrue);
    });

    test('copyWith preserves isAuthenticated when not provided', () {
      const state = SessionState(isAuthenticated: true);
      final updated = state.copyWith();
      expect(updated.isAuthenticated, isTrue);
    });

    test('props contains isAuthenticated', () {
      const state = SessionState(isAuthenticated: true);
      expect(state.props, [true]);
    });

    test('two states with same isAuthenticated are equal', () {
      const a = SessionState(isAuthenticated: true);
      const b = SessionState(isAuthenticated: true);
      expect(a, equals(b));
    });

    test('two states with different isAuthenticated are not equal', () {
      const a = SessionState(isAuthenticated: true);
      const b = SessionState(isAuthenticated: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('SessionCubit', () {
    test('initial state is unauthenticated', () {
      final cubit = SessionCubit();
      expect(cubit.state.isAuthenticated, isFalse);
      cubit.close();
    });

    blocTest<SessionCubit, SessionState>(
      'markAuthenticated emits authenticated state',
      build: () => SessionCubit(),
      act: (cubit) => cubit.markAuthenticated(),
      expect: () => [const SessionState(isAuthenticated: true)],
    );

    blocTest<SessionCubit, SessionState>(
      'markLoggedOut emits unauthenticated state',
      build: () => SessionCubit(),
      seed: () => const SessionState(isAuthenticated: true),
      act: (cubit) => cubit.markLoggedOut(),
      expect: () => [const SessionState(isAuthenticated: false)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits unauthenticated when secure storage has no token',
      build: () => SessionCubit(secureStorage: _MemorySecureStorage()),
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionState(isAuthenticated: false)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits authenticated when secure storage has a token',
      build: () {
        final secure = _MemorySecureStorage();
        secure.write(SecureStorageKeys.jwtToken.key, 'MOCK_TOKEN');
        return SessionCubit(secureStorage: secure);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionState(isAuthenticated: true)],
    );

    blocTest<SessionCubit, SessionState>(
      'refresh delegates to restore and emits correct state',
      build: () => SessionCubit(secureStorage: _MemorySecureStorage()),
      act: (cubit) => cubit.refresh(),
      expect: () => [const SessionState(isAuthenticated: false)],
    );

    blocTest<SessionCubit, SessionState>(
      'refresh emits authenticated when secure storage has a token',
      build: () {
        final secure = _MemorySecureStorage();
        secure.write(SecureStorageKeys.jwtToken.key, 'MOCK_TOKEN');
        return SessionCubit(secureStorage: secure);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [const SessionState(isAuthenticated: true)],
    );

    blocTest<SessionCubit, SessionState>(
      'restore emits unauthenticated (safe default) when secure read throws',
      build: () => SessionCubit(secureStorage: _ReadThrowsSecureStorage()),
      act: (cubit) => cubit.restore(),
      expect: () => [const SessionState(isAuthenticated: false)],
    );

    blocTest<SessionCubit, SessionState>(
      'markAuthenticated then markLoggedOut transitions correctly',
      build: () => SessionCubit(),
      act: (cubit) {
        cubit.markAuthenticated();
        cubit.markLoggedOut();
      },
      expect: () => [const SessionState(isAuthenticated: true), const SessionState(isAuthenticated: false)],
    );

    blocTest<SessionCubit, SessionState>(
      'markLoggedOut re-emits unauthenticated even when already unauthenticated',
      build: () => SessionCubit(),
      act: (cubit) => cubit.markLoggedOut(),
      expect: () => [const SessionState(isAuthenticated: false)],
    );
  });
}
