import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Callback fired when the user has been inactive past the configured
/// idle threshold. Wiring layer translates this to
/// `SessionCubit.endSession(reason: SessionExpiredReason.idleTimeout)`.
typedef OnIdleTimeout = void Function();

/// The time of the latest user activity, kept where every running
/// instance of the app reads and writes the same value.
///
/// On web every browser tab runs its own instance of the app, and all of
/// them share one session through `window.localStorage`, so an idle
/// timeout in one tab ends the session in every tab. Through this store
/// the [IdleTimeoutObserver] of a tab counts the activity of the others.
abstract interface class ISharedActivityStore {
  /// The latest activity that any instance recorded, or null when none has.
  Future<DateTime?> readLastActivity();

  /// Records [time] as the latest activity.
  Future<void> writeLastActivity(DateTime time);
}

/// Inactivity-based auto-logout helper.
///
/// **Wiring contract.** The observer is a passive object: it owns a
/// [Timer] that fires after [idleThreshold] of no activity and a
/// [WidgetsBindingObserver] registration that handles background /
/// foreground transitions. It does **not** know about session state or
/// the widget tree. The integration layer (see `AppSessionListeners`)
/// starts it when authenticated, stops it on logout, and pumps
/// [recordActivity] from its pointer and keyboard listeners.
///
/// **Background timing.** Dart [Timer]s pause on iOS while the app is
/// backgrounded. Relying on the timer alone would let a 12-hour
/// background pass and the user would still be logged in on resume.
/// The lifecycle callback captures `_backgroundedAt = clock()` on
/// pause and computes elapsed wall time on resume — if the elapsed
/// time exceeds [idleThreshold], it fires immediately; otherwise it
/// resumes the timer with the remaining duration.
///
/// **Activity in other tabs.** With a [sharedActivity] store, as on web,
/// the observer records its activity there while the app is in the
/// foreground, at most once every 10 seconds. Before it fires, from its
/// timer or on resume, it reads the latest activity of every tab, and
/// when another tab saw activity within [idleThreshold], it waits for
/// the rest of the threshold after that activity instead. Since another
/// tab's activity can reach the store up to 10 seconds late, the session
/// can end up to 10 seconds early. Without a store, as on mobile and
/// desktop, only this instance's activity counts.
///
/// **Disabled mode.** Passing `idleThreshold: null` makes every method
/// a no-op so a template fork can ship with idle-timeout off without
/// per-call-site conditionals.
class IdleTimeoutObserver with WidgetsBindingObserver {
  IdleTimeoutObserver({
    required this.idleThreshold,
    required this.onTimeout,
    this.sharedActivity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Inactivity window before [onTimeout] fires. `null` disables the
  /// observer entirely.
  final Duration? idleThreshold;

  /// Callback fired on timeout. Wired by integration layer to logout.
  final OnIdleTimeout onTimeout;

  /// The activity of every tab, on web. Null on mobile and desktop, where
  /// a single instance of the app holds the session.
  final ISharedActivityStore? sharedActivity;

  /// Wall-clock source. Injected so tests can drive elapsed time
  /// without sleeping.
  final DateTime Function() _clock;

  static final _log = AppLogger.getLogger('IdleTimeoutObserver');

  /// Minimum spacing between two activity records. High-frequency signals
  /// (e.g. `onPointerMove` during a drag/scroll) would otherwise cancel and
  /// recreate the timer on every event; throttling collapses that churn while
  /// staying well below any realistic [idleThreshold].
  static const Duration _activityThrottle = Duration(seconds: 1);

  /// Minimum spacing between two writes of this tab's activity to
  /// [sharedActivity]. Pointer events come far more often; this keeps the
  /// writes few, while the record stays well within any realistic
  /// [idleThreshold] of the latest activity.
  static const Duration _sharedActivityThrottle = Duration(seconds: 10);

  Timer? _timer;
  DateTime? _backgroundedAt;
  DateTime? _lastActivity;
  DateTime? _lastSharedActivity;
  bool _started = false;

  /// Counts the timer resets and cancellations, so a timeout that waited
  /// for [sharedActivity] can tell that activity, a lifecycle change or
  /// [stop] came first.
  int _timerGeneration = 0;

  /// Registers the lifecycle observer and starts the idle timer.
  /// Idempotent: a second call while already started is a no-op.
  void start() {
    if (idleThreshold == null || _started) return;
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
    _started = true;
    _shareActivity(_clock());
    _log.debug('start — threshold={}s', [idleThreshold!.inSeconds]);
  }

  /// Cancels the timer and removes the lifecycle observer.
  /// Idempotent: a second call after stop is a no-op.
  void stop() {
    if (!_started) return;
    _cancelTimer();
    _backgroundedAt = null;
    _lastActivity = null;
    _lastSharedActivity = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _log.debug('stop');
  }

  /// Pings the observer from the activity listener. Resets the timer
  /// so the user has another [idleThreshold] window of inactivity
  /// before logout, and records the activity in [sharedActivity] while
  /// the app is in the foreground.
  ///
  /// Activity that arrives while the app is in the background is not
  /// shared: on web the click that brings the user back to a tab reaches
  /// the observer before the focus event that resumes it, and recorded
  /// for the other tabs it would cancel the timeout that this tab's own
  /// time in the background calls for on resume.
  void recordActivity() {
    if (!_started || idleThreshold == null) return;
    final now = _clock();
    final last = _lastActivity;
    if (last != null && now.difference(last) < _activityThrottle) return;
    _lastActivity = now;
    _resetTimer();
    if (_backgroundedAt == null) _shareActivity(now);
  }

  void _resetTimer() {
    final threshold = idleThreshold;
    if (threshold == null) return;
    _scheduleTimeout(threshold);
  }

  void _scheduleTimeout(Duration after) {
    _cancelTimer();
    final generation = _timerGeneration;
    _timer = Timer(after, () => _timeOut(generation));
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _timerGeneration++;
  }

  /// Records [now] as this tab's activity in [sharedActivity], at most
  /// once every [_sharedActivityThrottle].
  void _shareActivity(DateTime now) {
    final shared = sharedActivity;
    if (shared == null) return;
    final last = _lastSharedActivity;
    if (last != null && now.difference(last) < _sharedActivityThrottle) return;
    _lastSharedActivity = now;
    unawaited(_writeSharedActivity(shared, now));
  }

  Future<void> _writeSharedActivity(ISharedActivityStore shared, DateTime time) async {
    try {
      await shared.writeLastActivity(time);
    } catch (e) {
      _log.error('recording the activity for the other tabs failed, they may time out early: {}', [e]);
    }
  }

  /// This instance has seen no activity for [idleThreshold]. Without
  /// [sharedActivity] that fires the timeout; with it, the timeout fires
  /// only when no other tab saw activity within [idleThreshold] either.
  void _timeOut(int generation) {
    final shared = sharedActivity;
    if (shared == null) {
      _fire();
      return;
    }
    unawaited(_timeOutUnlessActiveElsewhere(shared, generation));
  }

  Future<void> _timeOutUnlessActiveElsewhere(ISharedActivityStore shared, int generation) async {
    DateTime? latest;
    try {
      latest = await shared.readLastActivity();
    } catch (e) {
      _log.error('reading the activity of the other tabs failed, timing out on this tab alone: {}', [e]);
    }
    // Activity, a lifecycle change or stop() came first: they decide instead.
    if (generation != _timerGeneration) return;
    if (latest != null) {
      final idle = _clock().difference(latest);
      if (idle < idleThreshold!) {
        final remaining = idleThreshold! - idle;
        _log.debug('another tab saw activity {}s ago, {}s left before timeout', [idle.inSeconds, remaining.inSeconds]);
        _scheduleTimeout(remaining);
        return;
      }
    }
    _fire();
  }

  void _fire() {
    _log.info('idle threshold reached — firing onTimeout');
    onTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (idleThreshold == null) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Capture background instant once. The first pause-style
        // transition wins; subsequent ones do not re-anchor (e.g.
        // hidden after paused). We only care about the earliest
        // moment of no-foreground.
        _backgroundedAt ??= _clock();
        _cancelTimer();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt == null) return;
        final elapsed = _clock().difference(backgroundedAt);
        if (elapsed >= idleThreshold!) {
          _log.info('resumed after {}s of background, past the {}s threshold', [
            elapsed.inSeconds,
            idleThreshold!.inSeconds,
          ]);
          _timeOut(_timerGeneration);
          return;
        }
        final remaining = idleThreshold! - elapsed;
        _log.debug('resumed; remaining {}ms before timeout', [remaining.inMilliseconds]);
        _scheduleTimeout(remaining);
      case AppLifecycleState.detached:
        // Process is detaching; stop() will be called by the host or
        // the app is closing. No work here.
        break;
    }
  }
}
