import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Callback fired when the user has been inactive past the configured
/// idle threshold. Wiring layer translates this to
/// `SessionCubit.markLoggedOut(reason: SessionExpiredReason.idleTimeout)`.
typedef OnIdleTimeout = void Function();

/// Inactivity-based auto-logout helper.
///
/// **Wiring contract.** The observer is a passive object: it owns a
/// [Timer] that fires after [idleThreshold] of no activity and a
/// [WidgetsBindingObserver] registration that handles background /
/// foreground transitions. It does **not** know about session state or
/// the widget tree. The integration layer (see `AppSessionListeners`)
/// starts it when authenticated, stops it on logout, and pumps
/// [recordActivity] from a top-level pointer listener.
///
/// **Background timing.** Dart [Timer]s pause on iOS while the app is
/// backgrounded. Relying on the timer alone would let a 12-hour
/// background pass and the user would still be logged in on resume.
/// The lifecycle callback captures `_backgroundedAt = clock()` on
/// pause and computes elapsed wall time on resume — if the elapsed
/// time exceeds [idleThreshold], it fires immediately; otherwise it
/// resumes the timer with the remaining duration.
///
/// **Disabled mode.** Passing `idleThreshold: null` makes every method
/// a no-op so a template fork can ship with idle-timeout off without
/// per-call-site conditionals.
class IdleTimeoutObserver with WidgetsBindingObserver {
  IdleTimeoutObserver({required this.idleThreshold, required this.onTimeout, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Inactivity window before [onTimeout] fires. `null` disables the
  /// observer entirely.
  final Duration? idleThreshold;

  /// Callback fired on timeout. Wired by integration layer to logout.
  final OnIdleTimeout onTimeout;

  /// Wall-clock source. Injected so tests can drive elapsed time
  /// without sleeping.
  final DateTime Function() _clock;

  static final _log = AppLogger.getLogger('IdleTimeoutObserver');

  /// Minimum spacing between two activity records. High-frequency signals
  /// (e.g. `onPointerMove` during a drag/scroll) would otherwise cancel and
  /// recreate the timer on every event; throttling collapses that churn while
  /// staying well below any realistic [idleThreshold].
  static const Duration _activityThrottle = Duration(seconds: 1);

  Timer? _timer;
  DateTime? _backgroundedAt;
  DateTime? _lastActivity;
  bool _started = false;

  /// Registers the lifecycle observer and starts the idle timer.
  /// Idempotent: a second call while already started is a no-op.
  void start() {
    if (idleThreshold == null || _started) return;
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
    _started = true;
    _log.debug('start — threshold={}s', [idleThreshold!.inSeconds]);
  }

  /// Cancels the timer and removes the lifecycle observer.
  /// Idempotent: a second call after stop is a no-op.
  void stop() {
    if (!_started) return;
    _timer?.cancel();
    _timer = null;
    _backgroundedAt = null;
    _lastActivity = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _log.debug('stop');
  }

  /// Pings the observer from the activity listener. Resets the timer
  /// so the user has another [idleThreshold] window of inactivity
  /// before logout.
  void recordActivity() {
    if (!_started || idleThreshold == null) return;
    final now = _clock();
    final last = _lastActivity;
    if (last != null && now.difference(last) < _activityThrottle) return;
    _lastActivity = now;
    _resetTimer();
  }

  void _resetTimer() {
    final threshold = idleThreshold;
    if (threshold == null) return;
    _timer?.cancel();
    _timer = Timer(threshold, _fire);
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
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt == null) return;
        final elapsed = _clock().difference(backgroundedAt);
        if (elapsed >= idleThreshold!) {
          _log.info('resumed after {}s of background (threshold {}s) — firing timeout', [
            elapsed.inSeconds,
            idleThreshold!.inSeconds,
          ]);
          _fire();
          return;
        }
        final remaining = idleThreshold! - elapsed;
        _log.debug('resumed; remaining {}ms before timeout', [remaining.inMilliseconds]);
        _timer = Timer(remaining, _fire);
      case AppLifecycleState.detached:
        // Process is detaching; stop() will be called by the host or
        // the app is closing. No work here.
        break;
    }
  }
}
