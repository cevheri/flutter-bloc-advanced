import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [ISharedActivityStore] in [SharedPreferencesAsync], for web.
///
/// On web [SharedPreferencesAsync] reads and writes `window.localStorage`, which every tab of the app shares, and
/// keeps no per-tab cache as [SharedPreferences] does, so a read sees what the other tabs wrote.
class SharedPreferencesActivityStore implements ISharedActivityStore {
  /// The latest activity, in milliseconds since the epoch.
  static const _key = 'idleTimeout.lastActivity';

  final _preferences = SharedPreferencesAsync();

  @override
  Future<DateTime?> readLastActivity() async {
    final milliseconds = await _preferences.getInt(_key);
    return milliseconds == null ? null : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  Future<void> writeLastActivity(DateTime time) => _preferences.setInt(_key, time.millisecondsSinceEpoch);
}
