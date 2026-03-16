import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Connectivity status enum representing online/offline state.
enum ConnectivityStatus { online, offline }

/// Service that monitors network connectivity state.
///
/// Uses [connectivity_plus] for platform connectivity changes and optionally
/// performs a lightweight HTTP ping to verify real connectivity (captive portals, etc.).
///
/// Follows singleton pattern (like [AppLocalStorage]).
class ConnectivityService {
  static final _log = AppLogger.getLogger('ConnectivityService');

  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController = StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  /// The current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Initialize the service and start listening for connectivity changes.
  Future<void> initialize() async {
    _log.info('Initializing ConnectivityService');

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _currentStatus = _mapResults(results);

    // Verify with a real ping if platform reports online
    if (_currentStatus == ConnectivityStatus.online) {
      _currentStatus = await _verifyConnectivity();
    }

    _log.info('Initial connectivity status: {}', [_currentStatus.name]);
    _statusController.add(_currentStatus);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    _log.debug('Connectivity changed: {}', [results.map((r) => r.name).join(', ')]);

    final platformStatus = _mapResults(results);

    ConnectivityStatus newStatus;
    if (platformStatus == ConnectivityStatus.offline) {
      newStatus = ConnectivityStatus.offline;
    } else {
      // Platform says we have a connection — verify with a real ping
      newStatus = await _verifyConnectivity();
    }

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _log.info('Connectivity status changed to: {}', [_currentStatus.name]);
      _statusController.add(_currentStatus);
    }
  }

  /// Map platform connectivity results to our status enum.
  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  /// Verify real internet connectivity.
  ///
  /// On web: trust the platform (Navigator.onLine) since dart:io is unavailable.
  /// On native: perform a lightweight DNS lookup to catch captive portals.
  Future<ConnectivityStatus> _verifyConnectivity() async {
    if (kIsWeb) {
      // dart:io (InternetAddress, SocketException) is not available on web.
      // connectivity_plus already uses Navigator.onLine on web, so trust it.
      return ConnectivityStatus.online;
    }

    final hasInternet = await _nativeLookup();
    return hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  /// Native-only DNS lookup. Guarded by kIsWeb check — never called on web.
  Future<bool> _nativeLookup() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _log.debug('DNS lookup failed — marking offline');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Dispose of the service and cancel subscriptions.
  void dispose() {
    _log.info('Disposing ConnectivityService');
    _subscription?.cancel();
    _statusController.close();
  }
}
