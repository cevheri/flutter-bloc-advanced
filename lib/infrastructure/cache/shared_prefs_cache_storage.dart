import 'dart:convert';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/cache/cache_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-based cache storage implementation.
///
/// Stores cache entries as JSON with metadata (createdAt, expiresAt).
/// Key prefix: `_cache_` to avoid conflicts with other storage.
///
/// An entry outlives its TTL until it is [CacheEntry.maxStaleAge] old, so
/// that it can answer a GET that cannot reach the server. On web the entries
/// live in localStorage, whose per-origin quota the stored session and the
/// preferences share, so the storage evicts: when it starts, on its first
/// use, and before each write it deletes the entries past that age, and
/// before each write it deletes the oldest entries until the new one fits
/// in [maxEntries] and [maxTotalLength]. [read] deletes an entry past that
/// age too, and [clear], which ending the session runs, deletes them all.
///
/// A write that fails, because the platform store cannot be loaded or
/// refuses the entry, such as one past the quota, is logged as an error and
/// the entry is not cached: the request it belongs to still succeeds.
class SharedPrefsCacheStorage implements ICacheStorage {
  SharedPrefsCacheStorage({this.maxEntries = defaultMaxEntries, this.maxTotalLength = defaultMaxTotalLength});

  static final _log = AppLogger.getLogger('CacheStorage');
  static const String _prefix = '_cache_';

  /// The default of [maxEntries].
  static const int defaultMaxEntries = 200;

  /// The default of [maxTotalLength]: 2 MB as the UTF-16 that localStorage stores, well under the 5 MB quota that
  /// browsers give an origin.
  static const int defaultMaxTotalLength = 1000000;

  static final SharedPrefsCacheStorage _singleton = SharedPrefsCacheStorage();
  static SharedPrefsCacheStorage get instance => _singleton;

  /// The most entries kept at once.
  final int maxEntries;

  /// The most characters, keys and values together, that the entries take at once.
  final int maxTotalLength;

  SharedPreferences? _prefs;

  /// What eviction reads of each stored entry, by its key in SharedPreferences, so that a write parses only the
  /// entries it has not seen yet.
  final Map<String, _StoredEntry> _stored = {};
  int _sequence = 0;

  /// SharedPreferences, evicting the entries past their maximum stale age the first time.
  Future<SharedPreferences> get _instance async {
    if (_prefs case final prefs?) return prefs;
    final prefs = await SharedPreferences.getInstance();
    if (_prefs != null) return _prefs!;
    _prefs = prefs;
    await _evict(prefs);
    return prefs;
  }

  /// Deletes the entries past their maximum stale age or unreadable, and then the oldest entries other than
  /// [incoming] until an entry of [incomingLength] characters fits in [maxEntries] and [maxTotalLength]. A delete
  /// that fails is logged, and eviction goes on with the next entry.
  Future<void> _evict(SharedPreferences prefs, {String? incoming, int incomingLength = 0}) async {
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toSet();
    _stored.removeWhere((key, _) => !keys.contains(key));
    final kept = <String, _StoredEntry>{};
    for (final key in keys) {
      final stored = _stored[key] ?? _StoredEntry.parse(key, prefs.get(key), _sequence++);
      if (stored == null) {
        _log.warn('Evicting unreadable cache entry: {}', [key]);
        await _delete(prefs, key);
        continue;
      }
      _stored[key] = stored;
      if (stored.isPastMaxStaleAge) {
        _log.debug('Evicting cache entry past its maximum stale age: {}', [key]);
        await _delete(prefs, key);
      } else if (key != incoming) {
        kept[key] = stored;
      }
    }
    if (incoming == null) return;

    final oldestFirst = kept.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    var count = oldestFirst.length;
    var length = oldestFirst.fold(0, (sum, e) => sum + e.value.length);
    for (final MapEntry(:key, value: stored) in oldestFirst) {
      if (count + 1 <= maxEntries && length + incomingLength <= maxTotalLength) break;
      _log.debug('Evicting oldest cache entry: {}', [key]);
      await _delete(prefs, key);
      count--;
      length -= stored.length;
    }
  }

  /// Deletes the entry stored under [key], the key in SharedPreferences, logging a delete that fails.
  Future<void> _delete(SharedPreferences prefs, String key) async {
    _stored.remove(key);
    try {
      if (!await prefs.remove(key)) _log.error('Cache delete refused by SharedPreferences for key {}', [key]);
    } catch (e) {
      _log.error('Cache delete error for key {}: {}', [key, e]);
    }
  }

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

      // An entry past its TTL is kept to answer a GET that cannot reach the server, up to CacheEntry.maxStaleAge.
      if (entry.isPastMaxStaleAge) {
        _log.debug('Cache entry past its maximum stale age for key: {}', [key]);
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
    final storedKey = '$_prefix$key';
    final now = DateTime.now();
    final value = jsonEncode({
      'data': data,
      'createdAt': now.toIso8601String(),
      if (ttl != null) 'expiresAt': now.add(ttl).toIso8601String(),
    });
    final length = storedKey.length + value.length;
    SharedPreferences? prefs;
    try {
      prefs = await _instance;
      // An entry larger than the cache is skipped before eviction makes room for it, which would delete every entry.
      // An earlier entry of the key is deleted rather than kept, so it does not answer for a response it does not hold.
      if (length > maxTotalLength) {
        _log.warn('Cache write skipped for key {} ({} characters): larger than the cache, which holds {}', [
          key,
          length,
          maxTotalLength,
        ]);
        await _evict(prefs);
        await _delete(prefs, storedKey);
        return;
      }
      await _evict(prefs, incoming: storedKey, incomingLength: length);
      if (!await prefs.setString(storedKey, value)) throw StateError('SharedPreferences refused the write');
      _stored[storedKey] = _StoredEntry(
        createdAt: now,
        expiresAt: ttl == null ? null : now.add(ttl),
        length: length,
        sequence: _sequence++,
      );
      _log.debug('Cache written for key: {} (ttl: {})', [key, ttl?.inSeconds]);
    } catch (e) {
      // Loading the platform store, eviction and the write itself can fail; the request the entry belongs to does not.
      _log.error('Cache write error for key {} ({} characters): {}', [key, length, e]);
      // SharedPreferences keeps the value in memory even when the platform store refused it.
      if (prefs != null) await _delete(prefs, storedKey);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final prefs = await _instance;
      _stored.remove('$_prefix$key');
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
    _stored.clear();
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

/// What eviction reads of a stored entry: its age, its TTL and the characters it takes.
class _StoredEntry implements Comparable<_StoredEntry> {
  _StoredEntry({required this.createdAt, required this.expiresAt, required this.length, required this.sequence});

  final DateTime createdAt;
  final DateTime? expiresAt;

  /// The characters that the key and the value take.
  final int length;

  /// The order in which this storage saw the entry, which orders two entries created at the same time.
  final int sequence;

  /// Parses [value], stored under [key]. Returns null when it is not an entry this storage wrote.
  static _StoredEntry? parse(String key, Object? value, int sequence) {
    if (value is! String) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final expiresAt = json['expiresAt'] as String?;
      return _StoredEntry(
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt),
        length: key.length + value.length,
        sequence: sequence,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  bool get isPastMaxStaleAge =>
      CacheEntry(key: '', data: '', createdAt: createdAt, expiresAt: expiresAt).isPastMaxStaleAge;

  /// Orders the oldest entry first.
  @override
  int compareTo(_StoredEntry other) {
    final byAge = createdAt.compareTo(other.createdAt);
    return byAge != 0 ? byAge : sequence.compareTo(other.sequence);
  }
}
