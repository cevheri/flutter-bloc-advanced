import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdleTimeoutObserver', () {
    test('disabled (null threshold): timeout never fires regardless of inactivity', () {
      fakeAsync((async) {
        var fired = 0;
        final observer = IdleTimeoutObserver(idleThreshold: null, onTimeout: () => fired++);
        observer.start();

        async.elapse(const Duration(hours: 24));

        expect(fired, 0);
        observer.stop();
      });
    });

    test('fires onTimeout after idleThreshold of inactivity', () {
      fakeAsync((async) {
        var fired = 0;
        final observer = IdleTimeoutObserver(idleThreshold: const Duration(minutes: 5), onTimeout: () => fired++);
        observer.start();

        async.elapse(const Duration(minutes: 4));
        expect(fired, 0);

        async.elapse(const Duration(minutes: 1, milliseconds: 1));
        expect(fired, 1);

        observer.stop();
      });
    });

    test('recordActivity resets the timer; timeout does not fire if activity is within threshold', () {
      fakeAsync((async) {
        var fired = 0;
        var now = DateTime(2026, 5, 21, 12);
        final observer = IdleTimeoutObserver(
          idleThreshold: const Duration(minutes: 5),
          onTimeout: () => fired++,
          clock: () => now,
        );
        observer.start();

        for (var i = 0; i < 10; i++) {
          async.elapse(const Duration(minutes: 4));
          now = now.add(const Duration(minutes: 4));
          observer.recordActivity();
        }
        // Cumulative wall time = 40 minutes, but each tick reset before threshold.
        expect(fired, 0);

        // Now stop pinging; the timer should expire 5 minutes later.
        async.elapse(const Duration(minutes: 5, milliseconds: 1));
        expect(fired, 1);

        observer.stop();
      });
    });

    test('recordActivity is throttled: rapid pings within the throttle window reset the timer only once', () {
      fakeAsync((async) {
        var fired = 0;
        var now = DateTime(2026, 5, 21, 12);
        final observer = IdleTimeoutObserver(
          idleThreshold: const Duration(minutes: 5),
          onTimeout: () => fired++,
          clock: () => now,
        );
        observer.start();

        // Burst of high-frequency activity (e.g. pointer move during a drag)
        // all landing inside the 1s throttle window: only the first records.
        for (var i = 0; i < 100; i++) {
          observer.recordActivity();
        }

        // The first ping reset the timer at t=0; throttled pings did not. So the
        // timeout still fires 5 minutes after that first (and only) reset.
        async.elapse(const Duration(minutes: 5, milliseconds: 1));
        expect(fired, 1);

        observer.stop();
      });
    });

    test('stop() cancels the timer; no further timeouts fire', () {
      fakeAsync((async) {
        var fired = 0;
        final observer = IdleTimeoutObserver(idleThreshold: const Duration(minutes: 5), onTimeout: () => fired++);
        observer.start();
        observer.stop();

        async.elapse(const Duration(hours: 1));
        expect(fired, 0);
      });
    });

    test('background-to-foreground elapsed past threshold: timeout fires on resume', () {
      // Cannot use fakeAsync here because didChangeAppLifecycleState reads
      // wall-clock DateTime.now() to compute elapsed; use a clock seam.
      var fired = 0;
      var now = DateTime(2026, 5, 21, 12);
      final observer = IdleTimeoutObserver(
        idleThreshold: const Duration(minutes: 5),
        onTimeout: () => fired++,
        clock: () => now,
      );
      observer.start();

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 10));
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(fired, 1);
      observer.stop();
    });

    test('background-to-foreground within threshold: timer resumes with remaining duration', () {
      fakeAsync((async) {
        var fired = 0;
        var now = DateTime(2026, 5, 21, 12);
        final observer = IdleTimeoutObserver(
          idleThreshold: const Duration(minutes: 5),
          onTimeout: () => fired++,
          clock: () => now,
        );
        observer.start();

        // 1 minute in foreground, then background for 3 minutes.
        async.elapse(const Duration(minutes: 1));
        now = now.add(const Duration(minutes: 1));
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        now = now.add(const Duration(minutes: 3));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // After resume, remaining is 5 - 3 = 2 minutes from the resume instant.
        expect(fired, 0);
        async.elapse(const Duration(minutes: 1, seconds: 59));
        expect(fired, 0);
        async.elapse(const Duration(seconds: 2));
        expect(fired, 1);

        observer.stop();
      });
    });

    test('disabled observer is unaffected by lifecycle callbacks', () {
      var fired = 0;
      final observer = IdleTimeoutObserver(idleThreshold: null, onTimeout: () => fired++);
      observer.start();

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(fired, 0);
      observer.stop();
    });
  });

  // On web every browser tab runs its own observer, and an idle timeout in any tab ends the session of all of them.
  group('IdleTimeoutObserver with activity shared between web tabs', () {
    const threshold = Duration(minutes: 15);
    final start = DateTime(2026, 10, 20, 12);

    test('a tab resumed past the threshold keeps the session while another tab saw activity, until all are idle', () {
      fakeAsync((async) {
        final store = _MemoryActivityStore();
        var timeouts = 0;
        IdleTimeoutObserver tab() => IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();
        final workingTab = tab();
        final oldTab = tab();

        // The user leaves the old tab and works in the other one for 20 minutes.
        oldTab.didChangeAppLifecycleState(AppLifecycleState.inactive);
        oldTab.didChangeAppLifecycleState(AppLifecycleState.hidden);
        for (var minute = 0; minute < 20; minute++) {
          async.elapse(const Duration(minutes: 1));
          workingTab.recordActivity();
        }

        // Then goes back to the old tab and does nothing more.
        workingTab.didChangeAppLifecycleState(AppLifecycleState.inactive);
        workingTab.didChangeAppLifecycleState(AppLifecycleState.hidden);
        oldTab.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(threshold - const Duration(seconds: 1));
        expect(timeouts, 0);

        async.elapse(const Duration(seconds: 1));
        expect(timeouts, 1);

        workingTab.stop();
        oldTab.stop();
      });
    });

    // On web a click that brings the user back reaches Flutter before the window focus event that resumes the tab, for
    // example when focus had moved to a platform view or to the page that embeds the app.
    test('a tab resumed past the threshold times out although it saw activity just before the resume', () {
      fakeAsync((async) {
        final store = _MemoryActivityStore();
        var timeouts = 0;
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        thisTab.didChangeAppLifecycleState(AppLifecycleState.inactive);
        async.elapse(const Duration(minutes: 20));
        thisTab.recordActivity();
        thisTab.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.flushMicrotasks();

        expect(timeouts, 1);
        thisTab.stop();
      });
    });

    test('a timer that runs out after activity in another tab waits for the rest of the threshold after it', () {
      fakeAsync((async) {
        final store = _MemoryActivityStore();
        var timeouts = 0;
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        async.elapse(const Duration(minutes: 10));
        store.lastActivity = start.add(const Duration(minutes: 10)); // Recorded by another tab.
        async.elapse(const Duration(minutes: 5));
        expect(timeouts, 0);

        async.elapse(const Duration(minutes: 10) - const Duration(seconds: 1));
        expect(timeouts, 0);

        async.elapse(const Duration(seconds: 1));
        expect(timeouts, 1);

        thisTab.stop();
      });
    });

    test('records activity for the other tabs at most once every 10 seconds', () {
      fakeAsync((async) {
        final store = _MemoryActivityStore();
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () {},
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        // A pointer event every second, as while the user scrolls a list.
        for (var second = 1; second <= 25; second++) {
          async.elapse(const Duration(seconds: 1));
          thisTab.recordActivity();
        }

        expect(store.writes, [start, start.add(const Duration(seconds: 10)), start.add(const Duration(seconds: 20))]);
        thisTab.stop();
      });
    });

    test('drops a timeout decision when this tab sees activity while the shared activity is read', () {
      fakeAsync((async) {
        final store = _MemoryActivityStore()..readGate = Completer<void>();
        var timeouts = 0;
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        // The timer runs out, and the user clicks before the read of the activity it started answers.
        async.elapse(threshold);
        thisTab.recordActivity();
        store.readGate!.complete();
        async.flushMicrotasks();
        expect(timeouts, 0);

        async.elapse(threshold - const Duration(seconds: 1));
        expect(timeouts, 0);

        async.elapse(const Duration(seconds: 1));
        expect(timeouts, 1);

        thisTab.stop();
      });
    });

    test('decides on its own activity and logs an error when the shared activity cannot be read', () {
      final errors = _recordErrorLogs();
      fakeAsync((async) {
        final store = _MemoryActivityStore()..readError = StateError('storage unavailable');
        var timeouts = 0;
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        async.elapse(threshold);

        expect(timeouts, 1);
        expect(errors, contains(allOf(contains('IdleTimeoutObserver'), contains('storage unavailable'))));
        thisTab.stop();
      });
    });

    test('logs an error and keeps timing this tab when its activity cannot be recorded for the other tabs', () {
      final errors = _recordErrorLogs();
      fakeAsync((async) {
        final store = _MemoryActivityStore()..writeError = StateError('quota exceeded');
        var timeouts = 0;
        final thisTab = IdleTimeoutObserver(
          idleThreshold: threshold,
          onTimeout: () => timeouts++,
          sharedActivity: store,
          clock: () => start.add(async.elapsed),
        )..start();

        async.elapse(const Duration(minutes: 10));
        thisTab.recordActivity();
        async.elapse(threshold - const Duration(seconds: 1));
        expect(timeouts, 0);

        async.elapse(const Duration(seconds: 1));
        expect(timeouts, 1);
        expect(errors, contains(allOf(contains('IdleTimeoutObserver'), contains('quota exceeded'))));
        thisTab.stop();
      });
    });
  });
}

/// One activity record that every tab reads and writes, like window.localStorage on web.
class _MemoryActivityStore implements ISharedActivityStore {
  DateTime? lastActivity;

  /// Every time written, in order.
  final writes = <DateTime>[];

  /// When set, a read answers with the record as it was when the read started, once this completes.
  Completer<void>? readGate;
  Object? readError;
  Object? writeError;

  @override
  Future<DateTime?> readLastActivity() async {
    final error = readError;
    if (error != null) throw error;
    final recorded = lastActivity;
    await readGate?.future;
    return recorded;
  }

  @override
  Future<void> writeLastActivity(DateTime time) async {
    final error = writeError;
    if (error != null) throw error;
    writes.add(time);
    lastActivity = time;
  }
}

/// Collects the lines logged at error level until the test ends.
List<String> _recordErrorLogs() {
  final errors = <String>[];
  void recordError(OutputEvent event) {
    if (event.level == Level.error) errors.addAll(event.lines);
  }

  Logger.addOutputListener(recordError);
  addTearDown(() => Logger.removeOutputListener(recordError));
  return errors;
}
