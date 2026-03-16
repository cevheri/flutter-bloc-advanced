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

  /// Returns the number of cached entries.
  Future<int> count() async {
    final prefs = await _instance;
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

  @override
  Future<void> clear() async {
    try {
      final prefs = await _instance;
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      _log.info('Cache cleared ({} entries)', [keys.length]);
    } catch (e) {
      _log.error('Cache clear error: {}', [e]);
    }
  }
}
