import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stores state snapshots for time-travel debugging.
///
/// Each BLoC/Cubit gets its own ring buffer of [StateSnapshot] entries.
/// Supports rewind (restore a previous state) and replay (auto-play transitions).
class TimeTravelStore extends ChangeNotifier {
  TimeTravelStore._();

  static final TimeTravelStore instance = TimeTravelStore._();

  static const int maxSnapshotsPerBloc = 100;

  /// BLoC type name → list of snapshots (newest last).
  final Map<String, Queue<StateSnapshot>> _snapshots = {};

  /// Registered BLoC instances for rewind/replay (weak references via identity).
  final Map<String, BlocBase<dynamic>> _registeredBlocs = {};

  /// All known BLoC names (sorted).
  List<String> get blocNames {
    final names = _snapshots.keys.toList()..sort();
    return names;
  }

  /// Get snapshots for a specific BLoC (newest first for display).
  List<StateSnapshot> snapshotsFor(String blocName) {
    final queue = _snapshots[blocName];
    if (queue == null) return [];
    return queue.toList().reversed.toList();
  }

  /// Total snapshot count across all BLoCs.
  int get totalSnapshotCount => _snapshots.values.fold(0, (sum, q) => sum + q.length);

  /// Record a state transition.
  void recordTransition({
    required String blocName,
    required String event,
    required dynamic currentState,
    required dynamic nextState,
  }) {
    _snapshots.putIfAbsent(blocName, () => Queue<StateSnapshot>());
    final queue = _snapshots[blocName]!;

    queue.addLast(
      StateSnapshot(
        blocName: blocName,
        event: event,
        previousState: currentState.toString(),
        state: nextState.toString(),
        timestamp: DateTime.now(),
        stateObject: nextState,
      ),
    );

    while (queue.length > maxSnapshotsPerBloc) {
      queue.removeFirst();
    }

    notifyListeners();
  }

  /// Register a BLoC instance for rewind operations.
  void registerBloc(String name, BlocBase<dynamic> bloc) {
    _registeredBlocs[name] = bloc;
  }

  /// Unregister a BLoC instance.
  void unregisterBloc(String name) {
    _registeredBlocs.remove(name);
  }

  /// Attempt to rewind a BLoC to a previous state.
  /// Returns true if successful.
  bool rewindTo(String blocName, StateSnapshot snapshot) {
    final bloc = _registeredBlocs[blocName];
    if (bloc == null || snapshot.stateObject == null) return false;

    try {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      bloc.emit(snapshot.stateObject);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Export all snapshots as JSON string.
  String exportAsJson() {
    final data = <String, dynamic>{};
    for (final entry in _snapshots.entries) {
      data[entry.key] = entry.value.map((s) => s.toMap()).toList();
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Clear snapshots for a specific BLoC or all BLoCs.
  void clear([String? blocName]) {
    if (blocName != null) {
      _snapshots.remove(blocName);
    } else {
      _snapshots.clear();
    }
    notifyListeners();
  }
}

/// A recorded state snapshot at a point in time.
class StateSnapshot {
  StateSnapshot({
    required this.blocName,
    required this.event,
    required this.previousState,
    required this.state,
    required this.timestamp,
    this.stateObject,
  });

  final String blocName;
  final String event;
  final String previousState;
  final String state;
  final DateTime timestamp;

  /// Keep a reference to the actual state object for rewind.
  /// This is only available during the current session.
  final dynamic stateObject;

  Map<String, dynamic> toMap() => {
    'blocName': blocName,
    'event': event,
    'previousState': previousState,
    'state': state,
    'timestamp': timestamp.toIso8601String(),
  };
}
