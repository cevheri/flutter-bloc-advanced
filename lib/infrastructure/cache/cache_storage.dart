/// Cache policy determines how data is fetched and stored.
enum CachePolicy {
  /// Try network first; fall back to cache on failure.
  networkFirst,

  /// Try cache first; fetch from network if cache miss or expired.
  cacheFirst,

  /// Only use network — never cache.
  networkOnly,

  /// Only use cache — never fetch from network.
  cacheOnly,
}

/// Abstract cache storage interface.
///
/// Implementations can use SharedPreferences, Hive, SQLite, or any other
/// storage backend.
abstract class ICacheStorage {
  /// Read a cached value by key.
  Future<CacheEntry?> read(String key);

  /// Write a value to cache with optional TTL.
  Future<void> write(String key, String data, {Duration? ttl});

  /// Remove a cached value.
  Future<void> remove(String key);

  /// Clear all cached data.
  Future<void> clear();
}

/// A cache entry with metadata.
class CacheEntry {
  CacheEntry({required this.key, required this.data, required this.createdAt, this.expiresAt});

  final String key;
  final String data;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => !isExpired;
}
