import 'dart:convert';

import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TimeTravelStore is a singleton so we must clear between tests.
  late TimeTravelStore store;

  setUp(() {
    store = TimeTravelStore.instance;
    store.clear();
  });

  tearDown(() {
    store.clear();
  });

  group('TimeTravelStore', () {
    test('instance returns the same singleton', () {
      final store1 = TimeTravelStore.instance;
      final store2 = TimeTravelStore.instance;
      expect(identical(store1, store2), isTrue);
    });

    test('initial state has no bloc names', () {
      expect(store.blocNames, isEmpty);
    });

    test('initial totalSnapshotCount is 0', () {
      expect(store.totalSnapshotCount, 0);
    });

    test('snapshotsFor returns empty list for unknown bloc', () {
      expect(store.snapshotsFor('UnknownBloc'), isEmpty);
    });
  });

  group('recordTransition', () {
    test('records a single transition', () {
      store.recordTransition(blocName: 'TestBloc', event: 'TestEvent', currentState: 'StateA', nextState: 'StateB');

      expect(store.blocNames, ['TestBloc']);
      expect(store.totalSnapshotCount, 1);
    });

    test('records multiple transitions for the same bloc', () {
      store.recordTransition(blocName: 'TestBloc', event: 'Event1', currentState: 'S0', nextState: 'S1');
      store.recordTransition(blocName: 'TestBloc', event: 'Event2', currentState: 'S1', nextState: 'S2');

      expect(store.totalSnapshotCount, 2);
      expect(store.snapshotsFor('TestBloc'), hasLength(2));
    });

    test('records transitions for multiple blocs', () {
      store.recordTransition(blocName: 'BlocA', event: 'Event1', currentState: 'S0', nextState: 'S1');
      store.recordTransition(blocName: 'BlocB', event: 'Event2', currentState: 'S0', nextState: 'S1');

      expect(store.blocNames, ['BlocA', 'BlocB']);
      expect(store.totalSnapshotCount, 2);
    });

    test('blocNames returns sorted list', () {
      store.recordTransition(blocName: 'Zebra', event: 'E', currentState: 'A', nextState: 'B');
      store.recordTransition(blocName: 'Alpha', event: 'E', currentState: 'A', nextState: 'B');
      store.recordTransition(blocName: 'Middle', event: 'E', currentState: 'A', nextState: 'B');

      expect(store.blocNames, ['Alpha', 'Middle', 'Zebra']);
    });

    test('snapshotsFor returns entries in newest-first order', () {
      store.recordTransition(blocName: 'TestBloc', event: 'E1', currentState: 'S0', nextState: 'S1');
      store.recordTransition(blocName: 'TestBloc', event: 'E2', currentState: 'S1', nextState: 'S2');
      store.recordTransition(blocName: 'TestBloc', event: 'E3', currentState: 'S2', nextState: 'S3');

      final snapshots = store.snapshotsFor('TestBloc');
      expect(snapshots[0].event, 'E3');
      expect(snapshots[1].event, 'E2');
      expect(snapshots[2].event, 'E1');
    });

    test('snapshot stores state as toString', () {
      store.recordTransition(blocName: 'TestBloc', event: 'TestEvent', currentState: 42, nextState: 99);

      final snapshot = store.snapshotsFor('TestBloc').first;
      expect(snapshot.previousState, '42');
      expect(snapshot.state, '99');
    });

    test('snapshot stores stateObject reference', () {
      final stateObj = {'key': 'value'};
      store.recordTransition(blocName: 'TestBloc', event: 'TestEvent', currentState: 'prev', nextState: stateObj);

      final snapshot = store.snapshotsFor('TestBloc').first;
      expect(snapshot.stateObject, same(stateObj));
    });

    test('notifies listeners on record', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.recordTransition(blocName: 'TestBloc', event: 'E', currentState: 'A', nextState: 'B');

      expect(callCount, 1);
    });
  });

  group('ring buffer limit', () {
    test('enforces maxSnapshotsPerBloc (100) per bloc', () {
      for (int i = 0; i < 110; i++) {
        store.recordTransition(blocName: 'TestBloc', event: 'Event_$i', currentState: 'S$i', nextState: 'S${i + 1}');
      }

      expect(store.snapshotsFor('TestBloc'), hasLength(100));
      // Newest first: last recorded is Event_109
      expect(store.snapshotsFor('TestBloc').first.event, 'Event_109');
      // Oldest remaining: Event_10
      expect(store.snapshotsFor('TestBloc').last.event, 'Event_10');
    });

    test('maxSnapshotsPerBloc constant is 100', () {
      expect(TimeTravelStore.maxSnapshotsPerBloc, 100);
    });

    test('ring buffer is per-bloc (independent limits)', () {
      for (int i = 0; i < 110; i++) {
        store.recordTransition(blocName: 'BlocA', event: 'A_$i', currentState: 'S', nextState: 'S');
      }
      for (int i = 0; i < 50; i++) {
        store.recordTransition(blocName: 'BlocB', event: 'B_$i', currentState: 'S', nextState: 'S');
      }

      expect(store.snapshotsFor('BlocA'), hasLength(100));
      expect(store.snapshotsFor('BlocB'), hasLength(50));
      expect(store.totalSnapshotCount, 150);
    });
  });

  group('clear', () {
    test('clear() without arguments clears all blocs', () {
      store.recordTransition(blocName: 'BlocA', event: 'E', currentState: 'A', nextState: 'B');
      store.recordTransition(blocName: 'BlocB', event: 'E', currentState: 'A', nextState: 'B');

      store.clear();

      expect(store.blocNames, isEmpty);
      expect(store.totalSnapshotCount, 0);
    });

    test('clear(blocName) clears only the specified bloc', () {
      store.recordTransition(blocName: 'BlocA', event: 'E', currentState: 'A', nextState: 'B');
      store.recordTransition(blocName: 'BlocB', event: 'E', currentState: 'A', nextState: 'B');

      store.clear('BlocA');

      expect(store.blocNames, ['BlocB']);
      expect(store.snapshotsFor('BlocA'), isEmpty);
      expect(store.snapshotsFor('BlocB'), hasLength(1));
    });

    test('clear notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clear();

      expect(callCount, 1);
    });

    test('clear(blocName) notifies listeners', () {
      store.recordTransition(blocName: 'BlocA', event: 'E', currentState: 'A', nextState: 'B');

      int callCount = 0;
      store.addListener(() => callCount++);

      store.clear('BlocA');

      expect(callCount, 1);
    });
  });

  group('exportAsJson', () {
    test('returns valid JSON string', () {
      store.recordTransition(blocName: 'TestBloc', event: 'E1', currentState: 'S0', nextState: 'S1');

      final jsonStr = store.exportAsJson();
      expect(() => jsonDecode(jsonStr), returnsNormally);
    });

    test('exported JSON contains bloc entries', () {
      store.recordTransition(blocName: 'TestBloc', event: 'E1', currentState: 'S0', nextState: 'S1');

      final jsonStr = store.exportAsJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data.containsKey('TestBloc'), isTrue);
      final entries = data['TestBloc'] as List;
      expect(entries, hasLength(1));
      expect(entries[0]['blocName'], 'TestBloc');
      expect(entries[0]['event'], 'E1');
      expect(entries[0]['previousState'], 'S0');
      expect(entries[0]['state'], 'S1');
      expect(entries[0]['timestamp'], isNotNull);
    });

    test('exported JSON is empty object when no snapshots', () {
      final jsonStr = store.exportAsJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(data, isEmpty);
    });
  });

  group('StateSnapshot', () {
    test('toMap returns correct map', () {
      final timestamp = DateTime(2026, 3, 14, 10, 30);
      final snapshot = StateSnapshot(
        blocName: 'TestBloc',
        event: 'TestEvent',
        previousState: 'StateA',
        state: 'StateB',
        timestamp: timestamp,
      );

      final map = snapshot.toMap();
      expect(map['blocName'], 'TestBloc');
      expect(map['event'], 'TestEvent');
      expect(map['previousState'], 'StateA');
      expect(map['state'], 'StateB');
      expect(map['timestamp'], timestamp.toIso8601String());
    });

    test('stateObject defaults to null', () {
      final snapshot = StateSnapshot(
        blocName: 'TestBloc',
        event: 'TestEvent',
        previousState: 'A',
        state: 'B',
        timestamp: DateTime.now(),
      );
      expect(snapshot.stateObject, isNull);
    });

    test('stateObject stores provided value', () {
      final stateObj = {'data': 123};
      final snapshot = StateSnapshot(
        blocName: 'TestBloc',
        event: 'TestEvent',
        previousState: 'A',
        state: 'B',
        timestamp: DateTime.now(),
        stateObject: stateObj,
      );
      expect(snapshot.stateObject, same(stateObj));
    });
  });
}
