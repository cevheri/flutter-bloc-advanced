import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';

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
final class RotatedTokensTakeBack {
  RotatedTokensTakeBack({required this._secureStorage, ISessionEndSignal? sessionEndSignal, this._now = DateTime.now}) {
    sessionEndSignal?.endedElsewhere.listen(_onSessionEndedElsewhere);
  }

  static final _log = AppLogger.getLogger('RotatedTokensTakeBack');

  /// How much earlier than the start of another tab's wipe rotated tokens can have been stored and still reach the
  /// storage after the wipe: the two tabs send their changes to the browser on separate channels.
  static const crossTabDelay = Duration(seconds: 1);

  final ISecureStorage _secureStorage;
  final DateTime Function() _now;

  /// What the latest refresh stored, until another tab ends the session.
  ({StoredTokens values, DateTime storedAt, void Function() onTakeBackFailed})? _lastStored;

  /// Records that a refresh stored [values] just now. [onTakeBackFailed] ends the session when they cannot be taken
  /// back.
  void record(StoredTokens values, {required void Function() onTakeBackFailed}) {
    _lastStored = (values: List.unmodifiable(values), storedAt: _now(), onTakeBackFailed: onTakeBackFailed);
  }

  /// Names the keys it holds, never their values.
  @override
  String toString() => 'RotatedTokensTakeBack(${_lastStored?.values.map((value) => value.$1.key).join(', ') ?? ''})';

  /// Another tab began to end the stored session at [endedAt]: this tab's share of that wipe.
  Future<void> _onSessionEndedElsewhere(DateTime endedAt) => SessionGeneration.wipe(() async {
    final stored = _lastStored;
    _lastStored = null;
    if (stored == null || stored.storedAt.isBefore(endedAt.subtract(crossTabDelay))) return;
    _log.warn('Session ended in another tab just as the rotated tokens were stored: taking them back');
    try {
      for (final (key, value) in stored.values) {
        if (await _secureStorage.read(key.key) == value) await _secureStorage.delete(key.key);
      }
    } catch (e) {
      _log.error('Taking back the rotated tokens after the session ended in another tab failed: {}', [e]);
      stored.onTakeBackFailed();
    }
  });
}
