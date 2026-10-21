import 'dart:async';

import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/services/sso_session_startup_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/sso_sign_in_result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_auto_redirect_gate.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_session_startup.dart';
import 'package:flutter_bloc_advance/infrastructure/http/token_rotation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

/// An in-memory secure storage that records its writes, and fails the reads or the write of one key on request.
class _MemorySecureStorage implements ISecureStorage {
  final store = <String, String>{};
  final writes = <String>[];
  bool failReads = false;
  String? failWriteOf;
  bool failDeletes = false;

  /// Runs once, after the next write is applied, as a call that runs while the store is still on its way does.
  Future<void> Function()? onWrite;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('read failed');
    return store[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (key == failWriteOf) throw StateError('write failed');
    writes.add(key);
    store[key] = value;
    final hook = onWrite;
    onWrite = null;
    await hook?.call();
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('delete failed');
    store.remove(key);
  }

  @override
  Future<void> deleteAll() async => store.clear();
}

final _now = DateTime.utc(2026, 10, 21, 12);
final _newExpiry = DateTime.utc(2026, 10, 21, 12, 5);

/// A bearer that is not a JWT, as some providers issue.
const _opaqueBearer = 'opaque-access-token';

void main() {
  late MockISsoAuthRepository auth;
  late MockTokenRotation rotation;
  late _MemorySecureStorage storage;
  late MockIAuthSessionRepository sessionRepository;
  late SsoAutoRedirectGate gate;

  SsoSessionStartup newStartup({RotatedTokensTakeBack? takeBack, void Function()? onSessionExpired}) =>
      SsoSessionStartup(
        auth: auth,
        rotation: rotation,
        secureStorage: storage,
        sessionRepository: sessionRepository,
        gate: gate,
        now: () => _now,
        takeBack: takeBack,
        onSessionExpired: onSessionExpired,
      );

  void storeSession({required DateTime expiresAt, String? refreshToken = 'stored-refresh'}) {
    storage.store[SecureStorageKeys.jwtToken.key] = _opaqueBearer;
    storage.store[SecureStorageKeys.accessTokenExpiresAt.key] = encodeAccessTokenExpiry(expiresAt);
    if (refreshToken != null) storage.store[SecureStorageKeys.refreshToken.key] = refreshToken;
  }

  setUp(() {
    auth = MockISsoAuthRepository();
    rotation = MockTokenRotation();
    storage = _MemorySecureStorage();
    sessionRepository = MockIAuthSessionRepository();
    gate = SsoAutoRedirectGate();
    when(() => auth.completePendingSignIn()).thenAnswer((_) async => null);
    when(() => sessionRepository.clear()).thenAnswer((_) async => const Success(null));
  });

  group('a pending web sign-in', () {
    test('that succeeds gives SsoStartupSignedIn with its roles and leaves the gate open', () async {
      when(() => auth.completePendingSignIn())
          .thenAnswer((_) async => const SsoSignInSucceeded(username: 'jdoe', roles: ['ROLE_USER']));
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));

      final result = await newStartup().run();

      expect(result, isA<SsoStartupSignedIn>().having((r) => r.roles, 'roles', ['ROLE_USER']));
      expect(gate.isOpen, isTrue);
      verifyNever(() => rotation.rotate(any()));
    });

    test('that is rejected gives SsoStartupSignInFailed with its code and closes the gate', () async {
      when(() => auth.completePendingSignIn())
          .thenAnswer((_) async => const SsoSignInRejected(AppErrorCode.authOidcNoRole));

      final result = await newStartup().run();

      expect(
        result,
        isA<SsoStartupSignInFailed>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcNoRole),
      );
      expect(gate.isOpen, isFalse);
    });

    test('that was cancelled closes the gate and goes on to the stored expiry', () async {
      when(() => auth.completePendingSignIn()).thenAnswer((_) async => const SsoSignInCancelled());
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationUnavailable());

      final result = await newStartup().run();

      expect(result, isA<SsoStartupUseStoredSession>());
      expect(gate.isOpen, isFalse);
      verify(() => rotation.rotate('stored-refresh')).called(1);
    });

    test('that throws gives SsoStartupSignInFailed(authOidcFailed), closes the gate and logs only the type', () async {
      final errors = _recordLogs(Level.error);
      when(() => auth.completePendingSignIn()).thenThrow(const FormatException('oidc.keys.state secret-state-id'));

      final result = await newStartup().run();

      expect(
        result,
        isA<SsoStartupSignInFailed>().having((r) => r.errorCode, 'errorCode', AppErrorCode.authOidcFailed),
      );
      expect(gate.isOpen, isFalse);
      expect(errors, contains(allOf(contains('SsoSessionStartup'), contains('FormatException'))));
      expect(errors.join('\n'), isNot(contains('secret-state-id')));
    });

    test('that answers SsoSignInNavigatedAway is a StateError, since a completion never leaves the page', () async {
      when(() => auth.completePendingSignIn()).thenAnswer((_) async => const SsoSignInNavigatedAway());

      await expectLater(newStartup().run(), throwsStateError);
      expect(gate.isOpen, isFalse);
    });

    test('giveUp closes the gate', () {
      newStartup().giveUp();

      expect(gate.isOpen, isFalse);
    });

    test('that is not there goes on to the stored expiry and leaves the gate open', () async {
      storeSession(expiresAt: _now.add(const Duration(minutes: 1)));

      final result = await newStartup().run();

      expect(result, isA<SsoStartupUseStoredSession>());
      expect(gate.isOpen, isTrue);
    });
  });

  group('the stored expiry', () {
    test('an opaque bearer with a future expiry gives SsoStartupUseStoredSession and no refresh', () async {
      storeSession(expiresAt: _now.add(const Duration(seconds: 1)));

      expect(await newStartup().run(), isA<SsoStartupUseStoredSession>());
      verifyNever(() => rotation.rotate(any()));
      verifyNever(() => sessionRepository.clear());
    });

    test('no stored expiry gives SsoStartupUseStoredSession and no refresh', () async {
      storage.store[SecureStorageKeys.refreshToken.key] = 'stored-refresh';

      expect(await newStartup().run(), isA<SsoStartupUseStoredSession>());
      verifyNever(() => rotation.rotate(any()));
    });

    test('an expiry of exactly now is refreshed', () async {
      storeSession(expiresAt: _now);
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationUnavailable());

      await newStartup().run();

      verify(() => rotation.rotate('stored-refresh')).called(1);
    });

    test('a refreshed session is written in the order bearer, refresh token, ID token, expiry', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer(
        (_) async => TokensRotated(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          oidcIdToken: 'new-id',
          accessTokenExpiresAt: _newExpiry,
        ),
      );

      final result = await newStartup().run();

      expect(result, isA<SsoStartupUseStoredSession>());
      expect(storage.writes, [
        SecureStorageKeys.jwtToken.key,
        SecureStorageKeys.refreshToken.key,
        SecureStorageKeys.oidcIdToken.key,
        SecureStorageKeys.accessTokenExpiresAt.key,
      ]);
      expect(storage.store[SecureStorageKeys.jwtToken.key], 'new-access');
      expect(storage.store[SecureStorageKeys.refreshToken.key], 'new-refresh');
      expect(storage.store[SecureStorageKeys.oidcIdToken.key], 'new-id');
      expect(storage.store[SecureStorageKeys.accessTokenExpiresAt.key], encodeAccessTokenExpiry(_newExpiry));
      verifyNever(() => sessionRepository.clear());
    });

    test('a refresh writes only the fields that are present and not empty', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh'))
          .thenAnswer((_) async => const TokensRotated(accessToken: 'new-access', refreshToken: '', oidcIdToken: ''));

      await newStartup().run();

      expect(storage.writes, [SecureStorageKeys.jwtToken.key]);
      expect(storage.store[SecureStorageKeys.refreshToken.key], 'stored-refresh');
    });

    test('a refused refresh clears the session and gives SsoStartupSessionEnded', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationRefused());

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verify(() => sessionRepository.clear()).called(1);
      expect(storage.writes, isEmpty);
    });

    test('an unavailable provider keeps the stored session as it is', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationUnavailable());

      expect(await newStartup().run(), isA<SsoStartupUseStoredSession>());
      verifyNever(() => sessionRepository.clear());
      expect(storage.writes, isEmpty);
    });

    for (final refreshToken in [null, '']) {
      test('an expired access token with refresh token ${refreshToken == null ? 'absent' : 'empty'} ends the session '
          'without a refresh', () async {
        storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)), refreshToken: refreshToken);

        expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
        verify(() => sessionRepository.clear()).called(1);
        verifyNever(() => rotation.rotate(any()));
      });
    }

    test('a failed write of the refreshed tokens clears the session and logs an error', () async {
      final errors = _recordLogs(Level.error);
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      storage.failWriteOf = SecureStorageKeys.oidcIdToken.key;
      when(() => rotation.rotate('stored-refresh')).thenAnswer(
        (_) async => TokensRotated(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          oidcIdToken: 'new-id',
          accessTokenExpiresAt: _newExpiry,
        ),
      );

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verify(() => sessionRepository.clear()).called(1);
      expect(errors, contains(contains('SsoSessionStartup')));
      expect(errors.join('\n'), isNot(contains('new-')));
    });

    test('a failed read of the stored session clears it and logs an error', () async {
      final errors = _recordLogs(Level.error);
      storage.failReads = true;

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verify(() => sessionRepository.clear()).called(1);
      expect(errors, contains(contains('SsoSessionStartup')));
    });

    test('a stored expiry that is not a number clears the session and logs an error without the value', () async {
      final errors = _recordLogs(Level.error);
      storage.store[SecureStorageKeys.accessTokenExpiresAt.key] = 'not-a-number-secret';
      storage.store[SecureStorageKeys.refreshToken.key] = 'stored-refresh';

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verify(() => sessionRepository.clear()).called(1);
      verifyNever(() => rotation.rotate(any()));
      expect(errors, contains(contains('SsoSessionStartup')));
      expect(errors.join('\n'), isNot(contains('not-a-number-secret')));
    });

    test('a session that cannot be cleared still ends, and the failure is logged', () async {
      final errors = _recordLogs(Level.error);
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationRefused());
      when(() => sessionRepository.clear()).thenAnswer((_) async => const Failure(UnknownError('clear failed')));

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      expect(errors, contains(contains('SsoSessionStartup')));
    });

    test('a failed clear is logged by its type, not by the storage error text', () async {
      final errors = _recordLogs(Level.error);
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationRefused());
      when(() => sessionRepository.clear())
          .thenAnswer((_) async => const Failure(UnknownError('jwt: platform-detail-text')));

      await newStartup().run();

      expect(errors, contains(allOf(contains('SsoSessionStartup'), contains('UnknownError'))));
      expect(errors.join('\n'), isNot(contains('platform-detail-text')));
    });
  });

  // A logout, the end of the session, or on web another tab's end that this tab hears, can wipe the stored session
  // while the startup refresh is on its way. Its tokens must not bring that session back.
  group('the session ends during the startup refresh', () {
    final rotated = TokensRotated(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
      oidcIdToken: 'new-id',
      accessTokenExpiresAt: _newExpiry,
    );

    test('drops the rotated tokens when the session ends while the refresh is on its way', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async {
        await SessionGeneration.wipe(() async {});
        return rotated;
      });

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      expect(storage.writes, isEmpty);
      verifyNever(() => sessionRepository.clear());
    });

    test('drops a refusal when the session ended while the refresh was on its way, and ends nothing', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async {
        await SessionGeneration.wipe(() async {});
        return const RotationRefused();
      });

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verifyNever(() => sessionRepository.clear());
    });

    test('takes back what it stored when the session ends while it stores', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => rotated);
      storage.onWrite = () => SessionGeneration.wipe(() async {});

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      expect(storage.store.values, isNot(contains(startsWith('new-'))));
      expect(storage.store[SecureStorageKeys.accessTokenExpiresAt.key], isNot(encodeAccessTokenExpiry(_newExpiry)));
      verifyNever(() => sessionRepository.clear());
    });

    test('ends the session when what it stored as the session ended cannot be taken back', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => rotated);
      storage.onWrite = () => SessionGeneration.wipe(() async {});
      storage.failDeletes = true;

      expect(await newStartup().run(), isA<SsoStartupSessionEnded>());
      verify(() => sessionRepository.clear()).called(1);
    });

    test('lets another tab\'s end take back what it stored', () async {
      final signal = _ManualSessionEndSignal();
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => rotated);
      final takeBack = RotatedTokensTakeBack(secureStorage: storage, sessionEndSignal: signal);
      await newStartup(takeBack: takeBack, onSessionExpired: () {}).run();
      expect(storage.store[SecureStorageKeys.jwtToken.key], 'new-access');

      await signal.endInAnotherTab();

      expect(storage.store.values, isNot(contains(startsWith('new-'))));
    });

    test('ends the session as an unfixable 401 does when another tab\'s end cannot take back what it stored', () async {
      final signal = _ManualSessionEndSignal();
      var sessionExpiredCalls = 0;
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => rotated);
      final takeBack = RotatedTokensTakeBack(secureStorage: storage, sessionEndSignal: signal);
      await newStartup(takeBack: takeBack, onSessionExpired: () => sessionExpiredCalls++).run();
      storage.failDeletes = true;

      await signal.endInAnotherTab();

      expect(sessionExpiredCalls, 1);
    });
  });
}

/// Collects the lines logged at [level] until the test ends.
List<String> _recordLogs(Level level) {
  final lines = <String>[];
  void record(OutputEvent event) {
    if (event.level == level) lines.addAll(event.lines);
  }

  Logger.addOutputListener(record);
  addTearDown(() => Logger.removeOutputListener(record));
  return lines;
}

/// [ISessionEndSignal] whose other tab ends the session when the test says so.
class _ManualSessionEndSignal implements ISessionEndSignal {
  final _endedElsewhere = StreamController<DateTime>.broadcast(sync: true);

  @override
  void notifyEnded() {}

  @override
  Stream<DateTime> get endedElsewhere => _endedElsewhere.stream;

  /// Another tab begins to end the session now; completes once this tab has acted on it.
  Future<void> endInAnotherTab() async {
    _endedElsewhere.add(DateTime.now());
    await Future<void>.delayed(Duration.zero);
  }
}
