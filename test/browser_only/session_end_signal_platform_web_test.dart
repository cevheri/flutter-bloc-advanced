@TestOn('browser')
library;

import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal_platform.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
