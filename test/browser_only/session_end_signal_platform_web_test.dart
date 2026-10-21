@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal_platform.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal_platform_web.dart'
    show BroadcastSessionEndSignal;
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  // Two channel objects in one page stand for two tabs: a BroadcastChannel delivers to every other object with its
  // name, in this page or another, and never to the one that sent.
  test('tells the other tabs when the session ends, with the time it began, and not itself', () async {
    final thisTab = createPlatformSessionEndSignal()!;
    final otherTab = createPlatformSessionEndSignal()!;
    final heardHere = <DateTime>[];
    thisTab.endedElsewhere.listen(heardHere.add);
    final before = DateTime.now();

    final heardThere = otherTab.endedElsewhere.first;
    thisTab.notifyEnded();
    final endedAt = await heardThere.timeout(const Duration(seconds: 5));

    expect(endedAt.isBefore(before.subtract(const Duration(milliseconds: 1))), isFalse);
    expect(endedAt.isAfter(DateTime.now()), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(heardHere, isEmpty);
  });

  test(
    'ignores a message that is not a whole number of milliseconds, without throwing, and hears the next end',
    () async {
      final thisTab = createPlatformSessionEndSignal()!;
      final heard = <DateTime>[];
      thisTab.endedElsewhere.listen(heard.add);
      final stranger = web.BroadcastChannel(BroadcastSessionEndSignal.channelName);
      addTearDown(() => stranger.close());
      final endedAt = DateTime.now();

      for (final message in <JSAny?>[double.nan.toJS, double.infinity.toJS, 1.5.toJS, 9e15.toJS, 'soon'.toJS, null]) {
        stranger.postMessage(message);
      }
      stranger.postMessage(endedAt.millisecondsSinceEpoch.toJS);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(heard, [DateTime.fromMillisecondsSinceEpoch(endedAt.millisecondsSinceEpoch)]);
    },
  );

  test('hears no end once disposed', () async {
    final thisTab = createPlatformSessionEndSignal()!;
    final heard = <DateTime>[];
    thisTab.endedElsewhere.listen(heard.add);
    final otherTab = createPlatformSessionEndSignal()!;
    addTearDown(otherTab.dispose);

    thisTab.dispose();
    otherTab.notifyEnded();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(heard, isEmpty);
  });
}
