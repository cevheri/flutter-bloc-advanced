import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Since DevConsoleStore is a singleton, we need to clear it between tests.
  late DevConsoleStore store;

  setUp(() {
    store = DevConsoleStore.instance;
    store.clearAll();
  });

  tearDown(() {
    store.clearAll();
  });

  NetworkEntry createNetworkEntry({
    String id = '1',
    String method = 'GET',
    String url = 'https://api.example.com/test',
    int? statusCode,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
  }) {
    return NetworkEntry(
      id: id,
      method: method,
      url: url,
      startTime: startTime ?? DateTime(2026, 1, 1),
      statusCode: statusCode,
      endTime: endTime,
      error: error,
    );
  }

  BlocTransitionEntry createBlocEntry({
    String blocName = 'TestBloc',
    String event = 'TestEvent',
    String currentState = 'InitialState',
    String nextState = 'LoadedState',
    DateTime? timestamp,
  }) {
    return BlocTransitionEntry(
      blocName: blocName,
      event: event,
      currentState: currentState,
      nextState: nextState,
      timestamp: timestamp ?? DateTime(2026, 1, 1),
    );
  }

  group('DevConsoleStore', () {
    test('instance returns the same singleton', () {
      final store1 = DevConsoleStore.instance;
      final store2 = DevConsoleStore.instance;
      expect(identical(store1, store2), isTrue);
    });

    test('initial state has empty network entries', () {
      expect(store.networkEntries, isEmpty);
    });

    test('initial state has empty bloc entries', () {
      expect(store.blocEntries, isEmpty);
    });
  });

  group('Network entries', () {
    test('addNetworkEntry adds an entry', () {
      final entry = createNetworkEntry();
      store.addNetworkEntry(entry);

      expect(store.networkEntries, hasLength(1));
      expect(store.networkEntries.first.id, '1');
    });

    test('addNetworkEntry adds multiple entries', () {
      store.addNetworkEntry(createNetworkEntry(id: '1'));
      store.addNetworkEntry(createNetworkEntry(id: '2'));
      store.addNetworkEntry(createNetworkEntry(id: '3'));

      expect(store.networkEntries, hasLength(3));
    });

    test('networkEntries returns entries in reversed order (newest first)', () {
      store.addNetworkEntry(createNetworkEntry(id: '1'));
      store.addNetworkEntry(createNetworkEntry(id: '2'));
      store.addNetworkEntry(createNetworkEntry(id: '3'));

      expect(store.networkEntries[0].id, '3');
      expect(store.networkEntries[1].id, '2');
      expect(store.networkEntries[2].id, '1');
    });

    test('ring buffer enforces max 200 network entries', () {
      for (int i = 0; i < 210; i++) {
        store.addNetworkEntry(createNetworkEntry(id: 'entry_$i'));
      }

      expect(store.networkEntries, hasLength(200));
      // First 10 entries should have been evicted; newest is entry_209
      expect(store.networkEntries.first.id, 'entry_209');
      expect(store.networkEntries.last.id, 'entry_10');
    });

    test('updateNetworkEntry updates an existing entry', () {
      store.addNetworkEntry(createNetworkEntry(id: 'req_1'));

      store.updateNetworkEntry('req_1', (entry) {
        return entry.copyWith(statusCode: 200, endTime: DateTime(2026, 1, 2));
      });

      expect(store.networkEntries.first.statusCode, 200);
      expect(store.networkEntries.first.endTime, DateTime(2026, 1, 2));
    });

    test('updateNetworkEntry does nothing if id is not found', () {
      store.addNetworkEntry(createNetworkEntry(id: 'req_1'));

      store.updateNetworkEntry('non_existent', (entry) {
        return entry.copyWith(statusCode: 500);
      });

      expect(store.networkEntries.first.statusCode, isNull);
    });

    test('clearNetwork removes all network entries', () {
      store.addNetworkEntry(createNetworkEntry(id: '1'));
      store.addNetworkEntry(createNetworkEntry(id: '2'));

      store.clearNetwork();

      expect(store.networkEntries, isEmpty);
    });

    test('clearNetwork does not affect bloc entries', () {
      store.addNetworkEntry(createNetworkEntry());
      store.addBlocTransition(createBlocEntry());

      store.clearNetwork();

      expect(store.networkEntries, isEmpty);
      expect(store.blocEntries, hasLength(1));
    });
  });

  group('BLoC transition entries', () {
    test('addBlocTransition adds an entry', () {
      store.addBlocTransition(createBlocEntry());

      expect(store.blocEntries, hasLength(1));
      expect(store.blocEntries.first.blocName, 'TestBloc');
    });

    test('addBlocTransition adds multiple entries', () {
      store.addBlocTransition(createBlocEntry(blocName: 'BlocA'));
      store.addBlocTransition(createBlocEntry(blocName: 'BlocB'));

      expect(store.blocEntries, hasLength(2));
    });

    test('blocEntries returns entries in reversed order (newest first)', () {
      store.addBlocTransition(createBlocEntry(event: 'Event1'));
      store.addBlocTransition(createBlocEntry(event: 'Event2'));
      store.addBlocTransition(createBlocEntry(event: 'Event3'));

      expect(store.blocEntries[0].event, 'Event3');
      expect(store.blocEntries[1].event, 'Event2');
      expect(store.blocEntries[2].event, 'Event1');
    });

    test('ring buffer enforces max 500 bloc entries', () {
      for (int i = 0; i < 510; i++) {
        store.addBlocTransition(createBlocEntry(event: 'Event_$i'));
      }

      expect(store.blocEntries, hasLength(500));
      expect(store.blocEntries.first.event, 'Event_509');
      expect(store.blocEntries.last.event, 'Event_10');
    });

    test('clearBloc removes all bloc entries', () {
      store.addBlocTransition(createBlocEntry());
      store.addBlocTransition(createBlocEntry());

      store.clearBloc();

      expect(store.blocEntries, isEmpty);
    });

    test('clearBloc does not affect network entries', () {
      store.addNetworkEntry(createNetworkEntry());
      store.addBlocTransition(createBlocEntry());

      store.clearBloc();

      expect(store.blocEntries, isEmpty);
      expect(store.networkEntries, hasLength(1));
    });
  });

  group('clearAll', () {
    test('clears both network and bloc entries', () {
      store.addNetworkEntry(createNetworkEntry());
      store.addBlocTransition(createBlocEntry());

      store.clearAll();

      expect(store.networkEntries, isEmpty);
      expect(store.blocEntries, isEmpty);
    });
  });

  group('Listener notifications', () {
    test('addNetworkEntry notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.addNetworkEntry(createNetworkEntry());

      expect(callCount, 1);
    });

    test('updateNetworkEntry notifies listeners when entry found', () {
      store.addNetworkEntry(createNetworkEntry(id: 'req_1'));

      int callCount = 0;
      store.addListener(() => callCount++);

      store.updateNetworkEntry('req_1', (e) => e.copyWith(statusCode: 200));

      expect(callCount, 1);
    });

    test('updateNetworkEntry does not notify listeners when entry not found', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.updateNetworkEntry('non_existent', (e) => e.copyWith(statusCode: 200));

      expect(callCount, 0);
    });

    test('addBlocTransition notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.addBlocTransition(createBlocEntry());

      expect(callCount, 1);
    });

    test('clearAll notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clearAll();

      expect(callCount, 1);
    });

    test('clearNetwork notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clearNetwork();

      expect(callCount, 1);
    });

    test('clearBloc notifies listeners', () {
      int callCount = 0;
      store.addListener(() => callCount++);

      store.clearBloc();

      expect(callCount, 1);
    });
  });

  group('NetworkEntry', () {
    test('duration returns difference between endTime and startTime', () {
      final entry = NetworkEntry(
        id: '1',
        method: 'GET',
        url: 'https://api.example.com',
        startTime: DateTime(2026, 1, 1, 12, 0, 0),
        endTime: DateTime(2026, 1, 1, 12, 0, 2),
      );

      expect(entry.duration, const Duration(seconds: 2));
    });

    test('duration returns null when endTime is null', () {
      final entry = createNetworkEntry();
      expect(entry.duration, isNull);
    });

    test('isComplete returns true when endTime is set', () {
      final entry = NetworkEntry(
        id: '1',
        method: 'GET',
        url: 'https://api.example.com',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 0, 0, 1),
      );
      expect(entry.isComplete, isTrue);
    });

    test('isComplete returns false when endTime is null', () {
      final entry = createNetworkEntry();
      expect(entry.isComplete, isFalse);
    });

    test('isError returns true when error is set', () {
      final entry = createNetworkEntry(error: 'Timeout');
      expect(entry.isError, isTrue);
    });

    test('isError returns true when statusCode >= 400', () {
      final entry = createNetworkEntry(statusCode: 500);
      expect(entry.isError, isTrue);
    });

    test('isError returns true when statusCode is 400', () {
      final entry = createNetworkEntry(statusCode: 400);
      expect(entry.isError, isTrue);
    });

    test('isError returns false when statusCode < 400 and no error', () {
      final entry = createNetworkEntry(statusCode: 200);
      expect(entry.isError, isFalse);
    });

    test('isError returns false when no statusCode and no error', () {
      final entry = createNetworkEntry();
      expect(entry.isError, isFalse);
    });

    test('copyWith creates a new entry with updated fields', () {
      final original = createNetworkEntry(id: 'req_1');
      final updated = original.copyWith(statusCode: 201, responseBody: '{"ok":true}');

      expect(updated.id, 'req_1');
      expect(updated.statusCode, 201);
      expect(updated.responseBody, '{"ok":true}');
      expect(updated.method, original.method);
      expect(updated.url, original.url);
    });

    test('copyWith preserves original values when no arguments given', () {
      final original = NetworkEntry(
        id: '1',
        method: 'POST',
        url: 'https://api.example.com',
        startTime: DateTime(2026, 1, 1),
        statusCode: 200,
        responseBody: 'data',
        endTime: DateTime(2026, 1, 2),
      );
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.method, original.method);
      expect(copy.url, original.url);
      expect(copy.statusCode, original.statusCode);
      expect(copy.responseBody, original.responseBody);
      expect(copy.endTime, original.endTime);
    });
  });

  group('BlocTransitionEntry', () {
    test('stores all provided fields', () {
      final timestamp = DateTime(2026, 3, 14, 10, 30);
      final entry = BlocTransitionEntry(
        blocName: 'LoginBloc',
        event: 'LoginFormSubmitted',
        currentState: 'LoginInitial',
        nextState: 'LoginLoading',
        timestamp: timestamp,
      );

      expect(entry.blocName, 'LoginBloc');
      expect(entry.event, 'LoginFormSubmitted');
      expect(entry.currentState, 'LoginInitial');
      expect(entry.nextState, 'LoginLoading');
      expect(entry.timestamp, timestamp);
    });
  });
}
