import 'dart:collection';

import 'package:flutter/foundation.dart';

/// In-memory ring buffer that stores dev console entries.
///
/// All data is stored only in debug mode and never persisted.
/// Uses [ChangeNotifier] so UI tabs can rebuild on new entries.
class DevConsoleStore extends ChangeNotifier {
  DevConsoleStore._();

  static final DevConsoleStore instance = DevConsoleStore._();

  // ---------------------------------------------------------------------------
  // Network entries
  // ---------------------------------------------------------------------------

  static const int _maxNetworkEntries = 200;
  final _networkEntries = Queue<NetworkEntry>();

  UnmodifiableListView<NetworkEntry> get networkEntries => UnmodifiableListView(_networkEntries.toList().reversed);

  void addNetworkEntry(NetworkEntry entry) {
    _networkEntries.addLast(entry);
    while (_networkEntries.length > _maxNetworkEntries) {
      _networkEntries.removeFirst();
    }
    notifyListeners();
  }

  void updateNetworkEntry(String id, NetworkEntry Function(NetworkEntry) updater) {
    final list = _networkEntries.toList();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = updater(list[index]);
      _networkEntries.clear();
      _networkEntries.addAll(list);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // BLoC state transitions
  // ---------------------------------------------------------------------------

  static const int _maxBlocEntries = 500;
  final _blocEntries = Queue<BlocTransitionEntry>();

  UnmodifiableListView<BlocTransitionEntry> get blocEntries => UnmodifiableListView(_blocEntries.toList().reversed);

  void addBlocTransition(BlocTransitionEntry entry) {
    _blocEntries.addLast(entry);
    while (_blocEntries.length > _maxBlocEntries) {
      _blocEntries.removeFirst();
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  void clearAll() {
    _networkEntries.clear();
    _blocEntries.clear();
    notifyListeners();
  }

  void clearNetwork() {
    _networkEntries.clear();
    notifyListeners();
  }

  void clearBloc() {
    _blocEntries.clear();
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class NetworkEntry {
  NetworkEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.startTime,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.endTime,
    this.error,
  });

  final String id;
  final String method;
  final String url;
  final DateTime startTime;
  final Map<String, dynamic> requestHeaders;
  final String? requestBody;

  final int? statusCode;
  final Map<String, dynamic> responseHeaders;
  final String? responseBody;
  final DateTime? endTime;
  final String? error;

  Duration? get duration => endTime?.difference(startTime);
  bool get isComplete => endTime != null;
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);

  NetworkEntry copyWith({
    int? statusCode,
    Map<String, dynamic>? responseHeaders,
    String? responseBody,
    DateTime? endTime,
    String? error,
  }) {
    return NetworkEntry(
      id: id,
      method: method,
      url: url,
      startTime: startTime,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
    );
  }
}

class BlocTransitionEntry {
  BlocTransitionEntry({
    required this.blocName,
    required this.event,
    required this.currentState,
    required this.nextState,
    required this.timestamp,
  });

  final String blocName;
  final String event;
  final String currentState;
  final String nextState;
  final DateTime timestamp;
}
