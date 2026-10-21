import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:web/web.dart' as web;

/// The [HandOverTokenRefreshLock] of this tab, over the browser's Web Locks, IndexedDB and localStorage. A refresh
/// that waits longer than [waitLimit] for its turn fails with [TokenRefreshLockException].
///
/// Only `dart:js_interop` and `package:web` here, so the lock compiles on its own for a measurement in the browser.
ITokenRefreshLock createPlatformTokenRefreshLock({required Duration waitLimit}) => HandOverTokenRefreshLock(
  mutex: WebLocksMutex(waitLimit: waitLimit),
  record: IndexedDbHandOverRecord(),
  copy: LocalStorageStampCopy(),
);

/// [CrossTabMutex] over the Web Locks API: an exclusive lock across every tab and worker of the app's origin.
///
/// The Web Locks API exists only in a secure context (HTTPS or localhost), which flutter_secure_storage web needs as
/// well; without it [run] throws.
final class WebLocksMutex implements CrossTabMutex {
  WebLocksMutex({required this.waitLimit});

  /// The name of the lock. Every tab of the origin that requests it waits for the others.
  static const lockName = 'flutter_bloc_advance.token_refresh';

  /// How long a request waits for the lock before it is aborted. A granted turn has no limit from here.
  final Duration waitLimit;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    final result = Completer<T>();
    // The browser keeps the lock until the promise this returns settles, so until body has completed.
    JSPromise<JSAny?> onGranted(web.Lock? lock) => () async {
      try {
        result.complete(await body());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    }().toJS;
    web.window.navigator.locks
        .request(lockName, web.LockOptions(signal: web.AbortSignal.timeout(waitLimit.inMilliseconds)), onGranted.toJS)
        .toDart
        .then<void>(
          (_) {},
          // The request itself failed, so body never ran: it timed out, or the page is not a secure context.
          onError: (Object error, StackTrace stackTrace) {
            if (!result.isCompleted) result.completeError(error, stackTrace);
          },
        );
    return result.future;
  }
}

/// [HandOverRecord] in IndexedDB. A transaction that has completed is seen by every transaction any tab starts after
/// it, so a stamp committed before the lock is released is what the next holder reads.
final class IndexedDbHandOverRecord implements HandOverRecord {
  static const databaseName = 'flutter_bloc_advance.token_refresh';
  static const storeName = 'hand_over';
  static const recordKey = 'stamp';

  /// The connection of this tab, opened on first use and dropped when it fails or another tab upgrades the database.
  Future<web.IDBDatabase>? _database;

  @override
  Future<String?> read() async {
    final value = await _transact('read', 'readonly', (store) => store.get(recordKey.toJS));
    if (value == null || value.isUndefinedOrNull) return null;
    if (!value.isA<JSString>()) throw StateError('The hand-over record does not hold a stamp');
    return (value as JSString).toDart;
  }

  @override
  Future<void> write(String stamp) => _transact('write', 'readwrite', (store) => store.put(stamp.toJS, recordKey.toJS));

  /// Runs [operation] in a transaction of [mode], and answers the request's result once the transaction completed.
  Future<JSAny?> _transact(
    String name,
    web.IDBTransactionMode mode,
    web.IDBRequest Function(web.IDBObjectStore store) operation,
  ) async {
    final opening = _database ??= _open();
    try {
      final transaction = (await opening).transaction(storeName.toJS, mode);
      final request = operation(transaction.objectStore(storeName));
      final completed = Completer<JSAny?>();
      transaction.oncomplete = ((web.Event _) => completed.complete(request.result)).toJS;
      transaction.onabort = ((web.Event _) => completed.completeError(_failure(name, transaction.error))).toJS;
      return await completed.future;
    } catch (_) {
      if (identical(_database, opening)) _database = null;
      rethrow;
    }
  }

  Future<web.IDBDatabase> _open() {
    final opened = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(databaseName, 1);
    request.onupgradeneeded = ((web.Event _) {
      (request.result as web.IDBDatabase).createObjectStore(storeName);
    }).toJS;
    request.onsuccess = ((web.Event _) {
      final database = request.result as web.IDBDatabase;
      // Lets another tab upgrade or delete the database, such as when the user clears the site's data.
      database.onversionchange = ((web.Event _) {
        database.close();
        _database = null;
      }).toJS;
      opened.complete(database);
    }).toJS;
    request.onerror = ((web.Event _) => opened.completeError(_failure('open', request.error))).toJS;
    return opened.future;
  }

  static StateError _failure(String operation, web.DOMException? error) =>
      StateError('IndexedDB $operation of the hand-over failed: ${error?.name}: ${error?.message}');
}

/// [HandOverStampCopy] in this tab's localStorage, next to the tokens flutter_secure_storage web keeps there.
final class LocalStorageStampCopy implements HandOverStampCopy {
  LocalStorageStampCopy() {
    web.window.addEventListener('storage', _onStorage.toJS);
  }

  static const key = 'flutter_bloc_advance.token_refresh.hand_over';

  final _changes = StreamController<void>.broadcast();

  /// The browser fires `storage` in this tab when another tab's change reaches this tab's copy; a null key is a
  /// `clear()`.
  void _onStorage(web.StorageEvent event) {
    if (event.key == null || event.key == key) _changes.add(null);
  }

  @override
  String? read() => web.window.localStorage.getItem(key);

  @override
  void write(String stamp) => web.window.localStorage.setItem(key, stamp);

  @override
  Stream<void> get changes => _changes.stream;
}
