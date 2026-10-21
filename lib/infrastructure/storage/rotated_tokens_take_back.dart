import 'dart:async';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';

/// The secure-storage values a token refresh stored, in the order it wrote them.
typedef StoredTokens = List<(SecureStorageKeys, String)>;

/// Takes back the rotated tokens this browser tab stored just as another tab ended the stored session.
///
/// Another tab's wipe and this tab's rotated tokens reach the browser's localStorage in no fixed order, and this tab's
/// copy of localStorage may not show the wipe yet when a refresh checks the stored session before it stores. Rotated
/// tokens stored after the wipe would bring the session back for every tab. Each writer of rotated tokens, the token
/// refresh of `TokenRefreshInterceptor` and the startup refresh of an `oidc` build, records here what it stored right
/// after its last check of the session generation, with no `await` in between, so an end heard from then on finds it.
///
/// One instance per tab, created when the tab starts, so it hears an end before anything can store: the startup
/// refresh may store before the first request builds the HTTP client. When [ISessionEndSignal.endedElsewhere] fires,
/// this tab's session generation ends, through [SessionGeneration.wipe], so a refresh still on its way drops its
/// answer. Inside that wipe, the tokens recorded last are deleted where they are still stored, unless they were stored
/// more than [crossTabDelay] before the other tab began its wipe: that wipe removed them, and this tab's copy, which
/// may be behind, must not decide about a session signed in to since. When the delete fails, the writer's
/// `onTakeBackFailed` ends the session as a 401 that a refresh cannot fix does. That end is told to the other tabs,
/// which take back only what they recorded since the last end they heard, so the ends stop.
///
/// The message usually reaches this tab before the other tab's deletes reach its copy, and a refresh that ran in that
/// gap would read the refresh token the other tab deleted and store its rotation after the wipe, with no later end to
/// take it back. So the wipe lasts until this tab's copy shows the end: until its refresh token is gone. A refresh
/// token that merely differs from the one the copy held when the end was heard does not end the wait: the changes of
/// the tabs reach every copy in one order, so a copy shows the deletes of a sign-out before any later sign-in, and a
/// refresh token it shows before them is one that the ending tab stored just before its deletes, such as its last
/// rotation, and deletes a moment later. [SessionGeneration.hasEnded] holds for every generation while the wipe runs,
/// so no 401 is refreshed or sent again and no refresh stores in that time. The wait follows
/// [ISessionEndSignal.storeChanges], since timers are throttled in a background tab, and lasts at most
/// [copyCatchUpLimit]; past it the wipe ends, and a refresh in this tab may again read a copy that is still behind,
/// such as when the other tab's deletes failed.
///
/// It fails closed on a late message: an end that arrives after this tab's copy already shows a session signed in to
/// since may take back the rotation of that session, which signs it out in every tab, and keeps that session's 401s
/// from being refreshed for up to [copyCatchUpLimit]. It never brings back a session that was ended.
final class RotatedTokensTakeBack {
  RotatedTokensTakeBack({
    required this._secureStorage,
    ISessionEndSignal? sessionEndSignal,
    this._now = DateTime.now,
    this.copyCatchUpLimit = defaultCopyCatchUpLimit,
  }) : _storeChanges = sessionEndSignal?.storeChanges ?? const Stream.empty() {
    _subscription = sessionEndSignal?.endedElsewhere.listen(_onSessionEndedElsewhere);
  }

  static final _log = AppLogger.getLogger('RotatedTokensTakeBack');

  /// How much earlier than the start of another tab's wipe rotated tokens can have been stored and still reach the
  /// storage after the wipe: the two tabs send their changes to the browser on separate channels.
  static const crossTabDelay = Duration(seconds: 1);

  /// How long the wipe waits for this tab's copy to show another tab's end: as long as a refresh waits for its copy
  /// to show the previous holder's writes, which come on a channel of their own as well.
  static const defaultCopyCatchUpLimit = HandOverTokenRefreshLock.defaultCatchUpLimit;

  final ISecureStorage _secureStorage;
  final DateTime Function() _now;
  final Stream<void> _storeChanges;
  StreamSubscription<DateTime>? _subscription;

  /// Completes when this tab no longer hears the ends of other tabs, which ends a wait that is still running.
  final _disposed = Completer<void>();

  /// The longest wait for this tab's copy to show another tab's end.
  final Duration copyCatchUpLimit;

  /// What the latest refresh stored, until another tab ends the session.
  ({StoredTokens values, DateTime storedAt, void Function() onTakeBackFailed})? _lastStored;

  /// Records that a refresh stored [values] just now. [onTakeBackFailed] ends the session when they cannot be taken
  /// back.
  void record(StoredTokens values, {required void Function() onTakeBackFailed}) {
    _lastStored = (values: List.unmodifiable(values), storedAt: _now(), onTakeBackFailed: onTakeBackFailed);
  }

  /// Stops hearing the ends of other tabs, and ends a wipe that waits for this tab's copy.
  Future<void> dispose() async {
    if (!_disposed.isCompleted) _disposed.complete();
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Names the keys it holds, never their values.
  @override
  String toString() => 'RotatedTokensTakeBack(${_lastStored?.values.map((value) => value.$1.key).join(', ') ?? ''})';

  /// Another tab began to end the stored session at [endedAt]: this tab's share of that wipe.
  Future<void> _onSessionEndedElsewhere(DateTime endedAt) => SessionGeneration.wipe(() async {
    final stored = _lastStored;
    _lastStored = null;
    if (stored != null && !stored.storedAt.isBefore(endedAt.subtract(crossTabDelay))) await _takeBack(stored);
    await _untilCopyShowsEnd();
  });

  /// Deletes what [stored] holds where it is still stored.
  Future<void> _takeBack(({StoredTokens values, DateTime storedAt, void Function() onTakeBackFailed}) stored) async {
    _log.warn('Session ended in another tab just as the rotated tokens were stored: taking them back');
    try {
      for (final (key, value) in stored.values) {
        if (await _secureStorage.read(key.key) == value) await _secureStorage.delete(key.key);
      }
    } catch (e) {
      _log.error('Taking back the rotated tokens after the session ended in another tab failed: {}', [e]);
      stored.onTakeBackFailed();
    }
  }

  /// Waits until this tab's copy shows no refresh token, for at most [copyCatchUpLimit]. A copy that cannot be read is
  /// taken to be behind, so the wait goes on.
  Future<void> _untilCopyShowsEnd() async {
    final shown = Completer<void>();
    Future<void> check() async {
      final now = await _readRefreshToken();
      final showsEnd = switch (now) {
        _Read(:final value) => value == null,
        _Unreadable() => false,
      };
      if (showsEnd && !shown.isCompleted) shown.complete();
    }

    // Listening before the first check, so a change that arrives in between is not missed.
    final subscription = _storeChanges.listen((_) => unawaited(check()));
    try {
      await check();
      if (shown.isCompleted) return;
      await Future.any([shown.future, _disposed.future]).timeout(
        copyCatchUpLimit,
        onTimeout: () => _log.warn(
          'This tab\'s copy of the stored session did not show the end of another tab within {} ms: the wipe ends',
          [copyCatchUpLimit.inMilliseconds],
        ),
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<_CopyRead> _readRefreshToken() async {
    try {
      return _Read(await _secureStorage.read(SecureStorageKeys.refreshToken.key));
    } catch (e) {
      _log.error('Reading this tab\'s copy of the refresh token after the session ended in another tab failed: {}', [
        e,
      ]);
      return const _Unreadable();
    }
  }
}

/// What a read of this tab's copy of the refresh token gave.
sealed class _CopyRead {
  const _CopyRead();
}

final class _Read extends _CopyRead {
  const _Read(this.value);

  final String? value;
}

final class _Unreadable extends _CopyRead {
  const _Unreadable();
}
