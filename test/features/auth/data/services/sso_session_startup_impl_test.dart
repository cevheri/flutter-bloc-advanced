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
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
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

  SsoSessionStartup newStartup({
    RotatedTokensTakeBack? takeBack,
    void Function()? onSessionExpired,
    ITokenRefreshLock refreshLock = const InProcessTokenRefreshLock(),
    ISecureStorage? secureStorage,
  }) => SsoSessionStartup(
    auth: auth,
    rotation: rotation,
    secureStorage: secureStorage ?? storage,
    sessionRepository: sessionRepository,
    gate: gate,
    now: () => _now,
    takeBack: takeBack,
    onSessionExpired: onSessionExpired,
    refreshLock: refreshLock,
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

  // On web another browser tab may refresh the stored session while this tab starts, and a provider that accepts each
  // refresh token once refuses the second tab that sends it. The startup refresh takes its turn at the lock that the
  // tabs' token refreshes share.
  group('the startup refresh across browser tabs', () {
    test('takes no turn of the lock while the access token is still valid', () async {
      final lock = _RecordingLock();
      storeSession(expiresAt: _now.add(const Duration(minutes: 1)));

      expect(await newStartup(refreshLock: lock).run(), isA<SsoStartupUseStoredSession>());
      expect(lock.turns, 0, reason: 'a launch with a valid session does not wait for another tab\'s refresh');
    });

    test('does not refresh when another tab refreshed while this tab waited for the lock', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      final lock = _RecordingLock(
        beforeTurn: () {
          storage.store[SecureStorageKeys.jwtToken.key] = 'access-of-other-tab';
          storage.store[SecureStorageKeys.refreshToken.key] = 'refresh-of-other-tab';
          storage.store[SecureStorageKeys.accessTokenExpiresAt.key] = encodeAccessTokenExpiry(_newExpiry);
        },
      );
      when(() => rotation.rotate(any())).thenAnswer((_) async => const RotationUnavailable());

      expect(await newStartup(refreshLock: lock).run(), isA<SsoStartupUseStoredSession>());
      verifyNever(() => rotation.rotate(any()));
      verifyNever(() => sessionRepository.clear());
    });

    test('does not refresh when this tab\'s copy shows the other tab\'s refresh only after the grant', () async {
      final browser = _Browser();
      final otherTab = browser.openTab();
      final thisTab = browser.openTab();
      await otherTab.write(SecureStorageKeys.jwtToken.key, _opaqueBearer);
      await otherTab.write(SecureStorageKeys.refreshToken.key, 'stored-refresh');
      await otherTab.write(
        SecureStorageKeys.accessTokenExpiresAt.key,
        encodeAccessTokenExpiry(_now.subtract(const Duration(minutes: 1))),
      );
      thisTab.receive();
      // The other tab refreshes under the lock, and its writes reach this tab a moment after this tab's grant.
      await browser.lockOf(otherTab).hold(() async {
        await otherTab.write(SecureStorageKeys.jwtToken.key, 'access-of-other-tab');
        await otherTab.write(SecureStorageKeys.refreshToken.key, 'refresh-of-other-tab');
        await otherTab.write(SecureStorageKeys.accessTokenExpiresAt.key, encodeAccessTokenExpiry(_newExpiry));
      });
      // The provider accepts each refresh token once, and the other tab has spent this one.
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationRefused());
      final lock = browser.lockOf(
        thisTab,
        catchUpOnGrant: false,
        onGranted: () => Timer(const Duration(milliseconds: 5), thisTab.receive),
      );

      final result = await newStartup(refreshLock: lock, secureStorage: thisTab).run();

      expect(result, isA<SsoStartupUseStoredSession>());
      verifyNever(() => rotation.rotate(any()));
      verifyNever(() => sessionRepository.clear());
    });

    test('ends the session after the lock is released', () async {
      final lock = _RecordingLock();
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      when(() => rotation.rotate('stored-refresh')).thenAnswer((_) async => const RotationRefused());
      bool? heldWhileClearing;
      when(() => sessionRepository.clear()).thenAnswer((_) async {
        heldWhileClearing = lock.held;
        return const Success(null);
      });

      expect(await newStartup(refreshLock: lock).run(), isA<SsoStartupSessionEnded>());
      expect(lock.turns, 1);
      expect(heldWhileClearing, isFalse, reason: 'a wipe never waits behind a refresh in another tab');
    });

    test('keeps the stored session when the refresh does not get its turn', () async {
      storeSession(expiresAt: _now.subtract(const Duration(minutes: 1)));
      final lock = _RecordingLock(refuse: true);
      when(() => rotation.rotate(any())).thenAnswer((_) async => const RotationUnavailable());

      expect(await newStartup(refreshLock: lock).run(), isA<SsoStartupUseStoredSession>());
      verifyNever(() => rotation.rotate(any()));
      verifyNever(() => sessionRepository.clear());
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

/// An [ITokenRefreshLock] that counts its turns, knows whether one is running, and runs [beforeTurn] once it grants
/// one, as another tab whose refresh ends just then. With [refuse], it never grants a turn.
class _RecordingLock implements ITokenRefreshLock {
  _RecordingLock({this.beforeTurn, this.refuse = false});

  final void Function()? beforeTurn;
  final bool refuse;
  int turns = 0;
  bool held = false;

  @override
  Future<T> hold<T>(Future<T> Function() body) async {
    if (refuse) throw const TokenRefreshLockException('The token refresh lock was not granted');
    turns++;
    held = true;
    beforeTurn?.call();
    try {
      return await body();
    } finally {
      held = false;
    }
  }
}

/// The localStorage, the Web Lock and the IndexedDB hand-over record that the browser tabs share. Each tab reads a
/// copy of localStorage of its own, which takes another tab's changes only when [_BrowserTab.receive] runs.
class _Browser {
  final _tabs = <_BrowserTab>[];
  Future<void> _lockTail = Future<void>.value();
  String? _record;

  _BrowserTab openTab() {
    final tab = _BrowserTab._(this);
    _tabs.add(tab);
    return tab;
  }

  /// The token refresh lock of [tab]. With [catchUpOnGrant], the tab's copy takes the other tabs' changes before the
  /// grant; without it, they come when the test delivers them, from [onGranted] for one.
  HandOverTokenRefreshLock lockOf(_BrowserTab tab, {bool catchUpOnGrant = true, void Function()? onGranted}) =>
      HandOverTokenRefreshLock(
        mutex: _BrowserMutex(this, tab, catchUpOnGrant: catchUpOnGrant, onGranted: onGranted),
        record: _BrowserRecord(this),
        copy: _BrowserStampCopy(tab),
      );
}

/// A browser tab's copy of [_Browser]'s localStorage, as the secure storage reads and writes it.
class _BrowserTab implements ISecureStorage {
  _BrowserTab._(this._browser);

  final _Browser _browser;
  final _copy = <String, String?>{};
  final _undelivered = <(String, String?)>[];
  final _received = StreamController<String>.broadcast(sync: true);

  void _change(String key, String? value) {
    _copy[key] = value;
    for (final tab in _browser._tabs) {
      if (!identical(tab, this)) tab._undelivered.add((key, value));
    }
  }

  /// Applies the other tabs' changes since the last delivery, in their order.
  void receive() {
    final changes = List.of(_undelivered);
    _undelivered.clear();
    for (final (key, value) in changes) {
      _copy[key] = value;
      _received.add(key);
    }
  }

  @override
  Future<String?> read(String key) async => _copy[key];

  @override
  Future<void> write(String key, String value) async => _change(key, value);

  @override
  Future<void> delete(String key) async => _change(key, null);

  @override
  Future<void> deleteAll() async => throw UnimplementedError();
}

/// A tab's view of the Web Lock of [_Browser]: holders run one at a time, in the order they asked.
class _BrowserMutex implements CrossTabMutex {
  _BrowserMutex(this._browser, this._tab, {required this.catchUpOnGrant, this.onGranted});

  final _Browser _browser;
  final _BrowserTab _tab;
  final bool catchUpOnGrant;
  final void Function()? onGranted;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    final previous = _browser._lockTail;
    final released = Completer<void>();
    _browser._lockTail = released.future;
    return previous.then((_) async {
      if (catchUpOnGrant) _tab.receive();
      onGranted?.call();
      try {
        return await body();
      } finally {
        released.complete();
      }
    });
  }
}

/// The IndexedDB hand-over record of [_Browser]: every tab reads what was committed last.
class _BrowserRecord implements HandOverRecord {
  _BrowserRecord(this._browser);

  final _Browser _browser;

  @override
  Future<String?> read() async => _browser._record;

  @override
  Future<void> write(String stamp) async => _browser._record = stamp;
}

/// The hand-over stamp in a [_BrowserTab]'s copy of localStorage, next to the tokens.
class _BrowserStampCopy implements HandOverStampCopy {
  _BrowserStampCopy(this._tab);

  static const key = 'tokenRefreshHandOver';

  final _BrowserTab _tab;

  @override
  String? read() => _tab._copy[key];

  @override
  void write(String stamp) => _tab._change(key, stamp);

  @override
  Stream<void> get changes => _tab._received.stream.where((changed) => changed == key);
}
