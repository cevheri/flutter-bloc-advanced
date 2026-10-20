import 'dart:convert';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-based cache storage implementation.
///
/// Stores cache entries as JSON with metadata (createdAt, expiresAt).
/// Key prefix: `_cache_` to avoid conflicts with other storage.
class SharedPrefsCacheStorage implements ICacheStorage {
  static final _log = AppLogger.getLogger('CacheStorage');
  static const String _prefix = '_cache_';

  static final SharedPrefsCacheStorage _singleton = SharedPrefsCacheStorage();
  static SharedPrefsCacheStorage get instance => _singleton;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async => _prefs ??= await SharedPreferences.getInstance();

  /// Returns the number of cached entries in the platform store, which [clear] reads too.
  Future<int> count() async {
    final prefs = await _instance;
    await prefs.reload();
    return prefs.getKeys().where((k) => k.startsWith(_prefix)).length;
  }

  @override
  Future<CacheEntry?> read(String key) async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entry = CacheEntry(
        key: key,
        data: json['data'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      );

      // Auto-clean expired entries
      if (entry.isExpired) {
        _log.debug('Cache expired for key: {}', [key]);
        await remove(key);
        return null;
      }

      return entry;
    } catch (e) {
      _log.error('Cache read error for key {}: {}', [key, e]);
      return null;
    }
  }

  @override
  Future<void> write(String key, String data, {Duration? ttl}) async {
    try {
      final prefs = await _instance;
      final now = DateTime.now();
      final json = {
        'data': data,
        'createdAt': now.toIso8601String(),
        if (ttl != null) 'expiresAt': now.add(ttl).toIso8601String(),
      };
      await prefs.setString('$_prefix$key', jsonEncode(json));
      _log.debug('Cache written for key: {} (ttl: {})', [key, ttl?.inSeconds]);
    } catch (e) {
      _log.error('Cache write error for key {}: {}', [key, e]);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final prefs = await _instance;
      await prefs.remove('$_prefix$key');
    } catch (e) {
      _log.error('Cache remove error for key {}: {}', [key, e]);
    }
  }

  /// Removes every entry, going on past one that cannot be removed. When any entry stays, it then throws a
  /// [StateError] that says how many stayed and why, so the caller can report it.
  @override
  Future<void> clear() async {
    final prefs = await _instance;
    // The keys come from the platform store, not from the copy SharedPreferences keeps in memory: on web another tab
    // may have cached entries since this tab loaded, and SharedPreferences forgets a key whose remove was refused.
    await prefs.reload();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    final failures = <String>[];
    for (final key in keys) {
      try {
        if (!await prefs.remove(key)) failures.add('SharedPreferences refused the remove');
      } catch (e) {
        failures.add('$e');
      }
    }
    if (failures.isNotEmpty) {
      throw StateError('Cache clear left ${failures.length} of ${keys.length} entries: ${failures.toSet().join('; ')}');
    }
    _log.info('Cache cleared ({} entries)', [keys.length]);
  }
}
