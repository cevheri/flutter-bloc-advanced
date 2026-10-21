import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Lets one token refresh at a time run across the browser tabs of the app, which share the stored session.
///
/// On web every tab reads and writes the same stored session in localStorage, and a server that accepts each refresh
/// token once refuses the second of two tabs that send the same one. A refresh that holds this lock reads, sends and
/// stores alone, so the next tab sees the rotated tokens instead of sending the spent one.
abstract interface class ITokenRefreshLock {
  /// Runs [body] while this tab holds the lock, and answers what [body] answers, or throws what it throws.
  ///
  /// Throws [TokenRefreshLockException] when [body] did not run because the lock could not be taken or the turn could
  /// not be prepared.
  Future<T> hold<T>(Future<T> Function() body);
}

/// [ITokenRefreshLock] of one running instance of the app, which holds the stored session alone, as on mobile and
/// desktop: [body] runs at once.
final class InProcessTokenRefreshLock implements ITokenRefreshLock {
  const InProcessTokenRefreshLock();

  @override
  Future<T> hold<T>(Future<T> Function() body) => body();
}

/// The cross-tab lock did not give this tab a turn, or the turn could not be prepared, so its body did not run and
/// nothing was sent to the server for it. [cause] is the error of the browser primitive, if any. Neither carries token
/// material.
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
  /// The hand-over committed last, or null when none was. Throws [HandOverRecordMalformed] when what is stored is not
  /// a hand-over.
  Future<HandOver?> read();

  /// Completes once [handOver] is committed.
  Future<void> write(HandOver handOver);
}

/// What [HandOverRecord] holds is not a hand-over, such as after a script of the origin wrote there. It carries no
/// part of what is stored.
final class HandOverRecordMalformed implements Exception {
  const HandOverRecordMalformed(this.message);

  final String message;

  @override
  String toString() => 'HandOverRecordMalformed: $message';
}

/// This tab's copy of the hand-over stamp in the storage that holds the session, next to the tokens: localStorage on
/// web. The browser applies another tab's changes to this tab's copy later than they were made, but in the order that
/// tab made them, so a copy that shows a holder's stamp also shows the writes that holder made before it.
abstract interface class HandOverStampCopy {
  String? read();

  void write(String stamp);

  /// Fires when another tab's change to the stamp, or a clear of the store, reaches this tab's copy.
  Stream<void> get changes;
}

/// [ITokenRefreshLock] over a [CrossTabMutex], which hands the localStorage state of each holder over to the next.
///
/// A lock grant does not bring the previous holder's localStorage writes with it: the browser delivers the grant and
/// those writes to this tab on separate channels, and in Chromium the grant often comes first. A holder that read its
/// copy at once could see the refresh token the previous holder spent and send it again. So each turn hands over a
/// fresh random stamp, which carries no token material: it is committed to the [HandOverRecord] before the body runs,
/// and written to this tab's [HandOverStampCopy] after the body's writes. The next holder reads the record once
/// granted and, when its copy shows another stamp, waits for the copy to catch up before its body runs. A commit that
/// fails, or does not complete within [catchUpLimit], fails the turn before the body runs, so no turn's writes go
/// without a hand-over in the record.
///
/// The wait listens for the copy's [HandOverStampCopy.changes], since timers are throttled in a background tab, and
/// lasts at most [catchUpLimit]. When the limit passes the body does not run, [hold] throws
/// [TokenRefreshLockException], and the record is left as it was: a stamp of this tab's own would show in its copy at
/// once, and its next turn would run on the copy that is still behind.
///
/// A record that this tab's copy does not show, and that was committed more than [abandonedAfter] before or after
/// now, is taken for an abandoned one: its copy may never show it, such as when the user cleared localStorage alone,
/// and it would stop every later turn. The holder still waits up to [catchUpLimit] for its copy, as a tab that resumes
/// from the background takes the changes it missed then, and its body runs when that wait passes. A copy that is
/// behind the commit for longer still, or a clock set back by that much just after it, is taken for abandoned too, and
/// its body may read a refresh token that was spent.
///
/// A holder that closes or hangs during its body leaves a stamp in the record that no copy shows, so the next
/// holders fail their turns, a request each, until the record is taken for abandoned. When the stamp cannot be
/// written to the copy after the body, such as when localStorage is full, the body's outcome still stands, since its
/// tokens may be stored or the server may have refused them, and the next holders wait for that stamp in the same way.
///
/// A record that is not a hand-over ([HandOverRecordMalformed]) is taken for none, as on first use: the turn runs, and
/// its commit replaces it. Reading the record, as committing it, fails the turn when it does not complete within
/// [catchUpLimit].
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

  static final _log = AppLogger.getLogger('HandOverTokenRefreshLock');

  final CrossTabMutex _mutex;
  final HandOverRecord _record;
  final HandOverStampCopy _copy;
  final Random _random;
  final DateTime Function() _now;

  /// How long a holder waits for its copy to catch up with the hand-over before it gives up its turn, and for a read or
  /// a commit of the record.
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

  /// One turn of the lock: catch up with the previous holder, commit this turn's stamp, run [body], then show the
  /// stamp in this tab's copy. A turn that did not catch up or commit throws before [body] runs.
  Future<_BodyOutcome<T>> _turn<T>(Future<T> Function() body) async {
    await _catchUp();
    final stamp = _newStamp();
    await _commit(stamp);
    final outcome = await _run(body);
    _showInCopy(stamp);
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
      handedOver = await _record.read().timeout(
        catchUpLimit,
        onTimeout: () => throw TokenRefreshLockException(
          'The hand-over of the previous token refresh was not read within ${catchUpLimit.inMilliseconds} ms',
        ),
      );
    } on TokenRefreshLockException {
      rethrow;
    } on HandOverRecordMalformed catch (error) {
      _log.error('The hand-over record is not one, so this turn runs as the first and replaces it: {}', [error]);
      return;
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
      if (_now().difference(handedOver.committedAt).abs() > abandonedAfter) {
        await caughtUp.future.timeout(
          catchUpLimit,
          onTimeout: () =>
              _log.warn('The hand-over of an earlier token refresh is taken for abandoned: this turn runs'),
        );
        return;
      }
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

  /// Commits [stamp] for the next holder before the body runs, so a turn whose writes have no hand-over never runs.
  Future<void> _commit(String stamp) async {
    try {
      await _record
          .write(HandOver(stamp, _now()))
          .timeout(
            catchUpLimit,
            onTimeout: () => throw TokenRefreshLockException(
              'The hand-over of this token refresh was not committed within ${catchUpLimit.inMilliseconds} ms',
            ),
          );
    } on TokenRefreshLockException {
      rethrow;
    } catch (error) {
      throw TokenRefreshLockException('The token refresh could not commit its hand-over for the next holder', error);
    }
  }

  /// Writes [stamp] to this tab's copy after the body's writes, so a copy that shows it shows them too. A failure
  /// leaves the body's outcome as it is: the next holders wait for the stamp until it is taken for abandoned.
  void _showInCopy(String stamp) {
    try {
      _copy.write(stamp);
    } catch (error) {
      _log.error('The hand-over stamp of this token refresh could not be written to this tab\'s copy: {}', [error]);
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
