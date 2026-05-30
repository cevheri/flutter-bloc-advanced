import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDownAll(() async {
    await TestUtils().tearDownUnitTest();
  });

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
}
