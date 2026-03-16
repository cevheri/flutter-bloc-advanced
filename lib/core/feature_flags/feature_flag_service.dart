import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

/// Runtime feature flag service.
///
/// Flags can be loaded from a remote config endpoint and cached locally.
/// Each flag is a simple boolean toggle.
class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._();

  static final FeatureFlagService instance = FeatureFlagService._();
  static final _log = AppLogger.getLogger('FeatureFlagService');

  final Map<String, bool> _flags = {};
  DateTime? _lastFetched;

  /// Check if a feature is enabled.
  bool isEnabled(String featureKey) => _flags[featureKey] ?? false;

  /// Get all flags as a map.
  Map<String, bool> get allFlags => Map.unmodifiable(_flags);

  /// When flags were last updated.
  DateTime? get lastFetched => _lastFetched;

  /// Update flags from a remote config map.
  void updateFlags(Map<String, bool> flags) {
    _log.info('Updating feature flags: {}', [flags.keys.join(', ')]);
    _flags
      ..clear()
      ..addAll(flags);
    _lastFetched = DateTime.now();
    notifyListeners();
  }

  /// Set a single flag (useful for testing or local overrides).
  void setFlag(String key, bool value) {
    _flags[key] = value;
    notifyListeners();
  }

  /// Clear all flags.
  void clear() {
    _flags.clear();
    _lastFetched = null;
    notifyListeners();
  }
}
