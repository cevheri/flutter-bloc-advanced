import 'dart:async';
import 'dart:math';

/// Lets one token refresh at a time run across the browser tabs of the app, which share the stored session.
///
/// On web every tab reads and writes the same stored session in localStorage, and a server that accepts each refresh
/// token once refuses the second of two tabs that send the same one. A refresh that holds this lock reads, sends and
/// stores alone, so the next tab sees the rotated tokens instead of sending the spent one.
abstract interface class ITokenRefreshLock {
  /// Runs [body] while this tab holds the lock, and answers what [body] answers, or throws what it throws.
  ///
  /// Throws [TokenRefreshLockException] when [body] did not run because the lock could not be taken, or when the turn
  /// could not be handed over to the next holder after [body] ran.
  Future<T> hold<T>(Future<T> Function() body);
}

/// [ITokenRefreshLock] of one running instance of the app, which holds the stored session alone, as on mobile and
/// desktop: [body] runs at once.
final class InProcessTokenRefreshLock implements ITokenRefreshLock {
  const InProcessTokenRefreshLock();

  @override
  Future<T> hold<T>(Future<T> Function() body) => body();
}

/// The cross-tab lock did not give this tab a turn, or the turn could not be handed over: nothing was sent to the
/// server for it, or what was stored is not handed over to the next holder. [cause] is the error of the browser
/// primitive, if any. Neither carries token material.
final class TokenRefreshLockException implements Exception {
  const TokenRefreshLockException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? 'TokenRefreshLockException: $message' : 'TokenRefreshLockException: $message ($cause)';
}

/// The lock that every browser tab of the app's origin shares, which grants itself to one holder at a time: the Web
/// Locks API on web.
abstract interface class CrossTabMutex {
  /// Runs [body] once this tab holds the lock, and releases the lock when [body] completes. Throws without running
  /// [body] when the lock cannot be taken, in time or at all.
  Future<T> run<T>(Future<T> Function() body);
}

/// What a holder of [CrossTabMutex] left for the next holder: a fresh random [stamp], which carries no token material,
/// and when it was committed by the clock of the holder's tab, which all the tabs of one browser share.
final class HandOver {
  const HandOver(this.stamp, this.committedAt);

  final String stamp;
  final DateTime committedAt;
}

/// Where a holder of [CrossTabMutex] leaves its [HandOver] for the next holder: IndexedDB on web, whose writes are
/// ordered with the lock. A [write] that has completed before the lock is released is seen by a [read] that the next
/// holder makes once it is granted, in any tab.
abstract interface class HandOverRecord {
  Future<HandOver?> read();

  /// Completes once [handOver] is committed.
  Future<void> write(HandOver handOver);
}

/// This tab's copy of the hand-over stamp in the storage that holds the session, next to the tokens: localStorage on
/// web. The browser applies another tab's changes to this tab's copy later than they were made, but in the order that
/// tab made them, so a copy that shows a holder's stamp also shows the writes that holder made before it.
abstract interface class HandOverStampCopy {
  String? read();

  void write(String stamp);

  /// Fires when another tab's change to the stamp reaches this tab's copy.
  Stream<void> get changes;
}

/// [ITokenRefreshLock] over a [CrossTabMutex], which hands the localStorage state of each holder over to the next.
///
/// A lock grant does not bring the previous holder's localStorage writes with it: the browser delivers the grant and
/// those writes to this tab on separate channels, and in Chromium the grant often comes first. A holder that read its
/// copy at once could see the refresh token the previous holder spent and send it again. So each turn ends with a
/// fresh random stamp, which carries no token material: it is written to this tab's [HandOverStampCopy] after the
/// body's writes, then committed to the [HandOverRecord] before the lock is released. The next holder reads the record
/// once granted and, when its copy shows another stamp, waits for the copy to catch up before its body runs.
///
/// The wait listens for the copy's [HandOverStampCopy.changes], since timers are throttled in a background tab, and
/// lasts at most [catchUpLimit]. When the limit passes the body does not run, [hold] throws
/// [TokenRefreshLockException], and the record is left as it was: a stamp of this tab's own would show in its copy at
/// once, and its next turn would run on the copy that is still behind. A turn whose body did not run hands over
/// nothing, since it wrote nothing.
///
/// A stamp that no copy will show, such as one left when the user cleared localStorage alone, would then stop every
/// later turn. So a record that this tab's copy does not show, and that was committed more than [abandonedAfter]
/// before or after now, is taken for an abandoned one: the body runs at once, and its turn hands over a fresh stamp.
/// A copy that is that far behind the commit, or a clock set back by that much just after it, is taken for abandoned
/// too, and its body may read a refresh token that was spent.
///
/// A holder that closes during its body, after its token writes and before its stamp, leaves no hand-over: the next
/// holder may then read a copy that has not caught up yet.
final class HandOverTokenRefreshLock implements ITokenRefreshLock {
  HandOverTokenRefreshLock({
    required this._mutex,
    required this._record,
    required this._copy,
    this.catchUpLimit = defaultCatchUpLimit,
    this.abandonedAfter = defaultAbandonedAfter,
    Random? random,
    this._now = DateTime.now,
  }) : _random = random ?? Random.secure();

  /// How long a holder waits for its copy to show the previous holder's writes. Another tab's change usually reaches
  /// the copy within milliseconds of the grant.
  static const defaultCatchUpLimit = Duration(seconds: 5);

  final CrossTabMutex _mutex;
  final HandOverRecord _record;
  final HandOverStampCopy _copy;
  final Random _random;
  final DateTime Function() _now;

  /// How long a holder waits for its copy to catch up with the hand-over before it gives up its turn.
  final Duration catchUpLimit;

  /// How long after its commit a record that this tab's copy does not show is taken for an abandoned one.
  final Duration abandonedAfter;

  /// Six times [defaultCatchUpLimit]: another tab's change that has not reached the copy by then is not coming.
  static const defaultAbandonedAfter = Duration(seconds: 30);

  @override
  Future<T> hold<T>(Future<T> Function() body) async {
    final _BodyOutcome<T> outcome;
    try {
      outcome = await _mutex.run(() => _turn(body));
    } on TokenRefreshLockException {
      rethrow;
    } catch (error) {
      // The body's own errors come back inside the outcome, so this one is the lock's.
      throw TokenRefreshLockException('The token refresh lock was not granted', error);
    }
    return switch (outcome) {
      _BodyAnswered(:final value) => value,
      _BodyThrew(:final error, :final stackTrace) => Error.throwWithStackTrace(error, stackTrace),
    };
  }

  /// One turn of the lock: catch up with the previous holder, run [body], hand over to the next holder. A turn that
  /// did not catch up throws before [body] runs and leaves the record as it was.
  Future<_BodyOutcome<T>> _turn<T>(Future<T> Function() body) async {
    await _catchUp();
    final outcome = await _run(body);
    await _handOver();
    return outcome;
  }

  /// Runs [body], and carries what it answered or threw.
  static Future<_BodyOutcome<T>> _run<T>(Future<T> Function() body) async {
    try {
      return _BodyAnswered(await body());
    } catch (error, stackTrace) {
      return _BodyThrew(error, stackTrace);
    }
  }

  /// Waits until this tab's copy shows the stamp the previous holder committed, so the body reads what it stored.
  Future<void> _catchUp() async {
    final HandOver? handedOver;
    try {
      handedOver = await _record.read();
    } catch (error) {
      throw TokenRefreshLockException('The hand-over of the previous token refresh could not be read', error);
    }
    if (handedOver == null) return;
    final stamp = handedOver.stamp;
    final caughtUp = Completer<void>();
    // Listening before the first comparison, so a change that arrives in between is not missed.
    final subscription = _copy.changes.listen((_) {
      if (!caughtUp.isCompleted && _copy.read() == stamp) caughtUp.complete();
    });
    try {
      if (_copy.read() == stamp) return;
      if (_now().difference(handedOver.committedAt).abs() > abandonedAfter) return;
      await caughtUp.future.timeout(
        catchUpLimit,
        onTimeout: () => throw TokenRefreshLockException(
          'The writes of the previous token refresh did not reach this tab within ${catchUpLimit.inMilliseconds} ms',
        ),
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Leaves a fresh stamp for the next holder: in this tab's copy after the body's writes, then committed to the
  /// record before the lock is released.
  Future<void> _handOver() async {
    final stamp = _newStamp();
    try {
      _copy.write(stamp);
      await _record.write(HandOver(stamp, _now()));
    } catch (error) {
      throw TokenRefreshLockException('The token refresh could not hand over to the next holder', error);
    }
  }

  /// 128 random bits as hex.
  String _newStamp() => [for (var i = 0; i < 16; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}

/// What the body of a turn answered, carried out of [CrossTabMutex.run] apart from the errors of the lock itself.
sealed class _BodyOutcome<T> {
  const _BodyOutcome();
}

final class _BodyAnswered<T> extends _BodyOutcome<T> {
  const _BodyAnswered(this.value);

  final T value;
}

final class _BodyThrew<T> extends _BodyOutcome<T> {
  const _BodyThrew(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
