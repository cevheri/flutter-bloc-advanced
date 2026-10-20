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
  ///
  /// Returns the entry whether its TTL has passed or not, so that it can
  /// answer a GET that cannot reach the server. Returns null, and deletes the
  /// entry, once it is [CacheEntry.isPastMaxStaleAge].
  Future<CacheEntry?> read(String key);

  /// Write a value to cache with optional TTL, which is how long the entry
  /// stays fresh.
  Future<void> write(String key, String data, {Duration? ttl});

  /// Remove a cached value.
  Future<void> remove(String key);

  /// Clear all cached data. Throws when any entry stays behind: ending a session relies on it to keep one user's
  /// cached responses from the next user.
  Future<void> clear();
}

/// A cache entry with metadata.
///
/// An entry is fresh until [expiresAt], the end of its TTL, and only a fresh
/// entry answers a GET before the network (`cacheFirst`, `cacheOnly`). Past
/// its TTL it still answers, marked stale, a GET that cannot reach the
/// server, until it is [maxStaleAge] old.
class CacheEntry {
  CacheEntry({required this.key, required this.data, required this.createdAt, this.expiresAt});

  /// How long after [createdAt] an entry past its TTL may still answer a GET
  /// that cannot reach the server. Data loaded within the last day survives
  /// going offline; older data is more likely to mislead than to help.
  static const Duration maxStaleAge = Duration(hours: 24);

  final String key;
  final String data;
  final DateTime createdAt;
  final DateTime? expiresAt;

  /// Whether the TTL has passed, so the entry is no longer fresh.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Whether the entry is fresh.
  bool get isValid => !isExpired;

  /// Whether the entry is past its TTL and older than [maxStaleAge], so it
  /// may answer no request any more and a storage deletes it.
  bool get isPastMaxStaleAge => isExpired && DateTime.now().difference(createdAt) > maxStaleAge;
}
