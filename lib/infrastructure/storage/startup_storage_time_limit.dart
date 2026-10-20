import 'dart:async';

/// An explicit time limit on the storage work that startup waits for.
///
/// Startup waits for secure storage twice. AppBootstrap.run awaits `runSessionMigration` before runApp, so the launch
/// screen stays up until the migration is done, and App shows a spinner instead of the router until
/// SessionCubit.restore has read the stored session. A secure storage that never answers would keep the user on one of
/// them for good, so each of them waits for its work at most [duration], then logs an error and goes on without it.
final class StartupStorageTimeLimit<T> {
  /// Starts waiting for [work], for at most [duration].
  StartupStorageTimeLimit(Future<T> work, {this.duration = defaultDuration}) {
    _timer = Timer(duration, () => _result.completeError(TimeoutException('Storage did not answer in time', duration)));
    unawaited(
      work.then(
        (value) {
          if (_result.isCompleted) return;
          _timer.cancel();
          _result.complete(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_result.isCompleted) return;
          _timer.cancel();
          _result.completeError(error, stackTrace);
        },
      ),
    );
  }

  /// Secure storage normally answers within milliseconds; a slow device may take a few seconds right after boot. Ten
  /// seconds stays well above that, so a working storage is not cut off, and still frees a user whose storage never
  /// answers before most would give up and close the app.
  static const defaultDuration = Duration(seconds: 10);

  final Duration duration;

  final _result = Completer<T>();
  late final Timer _timer;

  /// Completes like the work when it completes within [duration], and with a [TimeoutException] when [duration] passes
  /// first. The work goes on after a timeout; a caller that wants its late result keeps the work's own future.
  Future<T> get result => _result.future;

  /// Stops the time limit, so [result] waits for the work however long it takes.
  void cancel() => _timer.cancel();
}
