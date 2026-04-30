import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure key-value storage.
///
/// Used for sensitive data like JWT tokens that should not be stored
/// in plaintext SharedPreferences.
abstract interface class ISecureStorage {
  /// Read a value by [key]. Returns null if not found.
  Future<String?> read(String key);

  /// Write a [value] for the given [key].
  Future<void> write(String key, String value);

  /// Delete the value for the given [key].
  Future<void> delete(String key);

  /// Delete all stored values.
  Future<void> deleteAll();
}

/// Production implementation backed by [FlutterSecureStorage].
class FlutterSecureStorageAdapter implements ISecureStorage {
  static final _log = AppLogger.getLogger('FlutterSecureStorageAdapter');

  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    _log.trace('Reading secure storage key: {}', [key]);
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _log.error('Error reading secure storage key {}: {}', [key, e]);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    _log.trace('Writing secure storage key: {}', [key]);
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _log.error('Error writing secure storage key {}: {}', [key, e]);
    }
  }

  @override
  Future<void> delete(String key) async {
    _log.trace('Deleting secure storage key: {}', [key]);
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _log.error('Error deleting secure storage key {}: {}', [key, e]);
    }
  }

  @override
  Future<void> deleteAll() async {
    _log.info('Deleting all secure storage data');
    try {
      await _storage.deleteAll();
    } catch (e) {
      _log.error('Error deleting all secure storage data: {}', [e]);
    }
  }
}
