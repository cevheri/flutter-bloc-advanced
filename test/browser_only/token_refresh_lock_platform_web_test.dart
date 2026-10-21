@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock_platform_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  // Two lock objects in one page stand for two tabs: the Web Lock is shared by every holder of the origin. They share
  // this page's localStorage copy too, so the hand-over is seen at once here; a real second tab can lag behind.
  ITokenRefreshLock newLock({Duration waitLimit = const Duration(seconds: 10)}) =>
      createPlatformTokenRefreshLock(waitLimit: waitLimit);

  test('two holders run one after the other and each gets its result', () async {
    final events = <String>[];
    final release = Completer<void>();
    final first = newLock().hold(() async {
      events.add('first in');
      await release.future;
      events.add('first out');
      return 1;
    });
    final second = newLock().hold(() async {
      events.add('second in');
      return 2;
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(events, ['first in']);

    release.complete();

    expect(await first, 1);
    expect(await second, 2);
    expect(events, ['first in', 'first out', 'second in']);
  });

  test('an error in the body reaches the caller and frees the lock', () async {
    await expectLater(newLock().hold<void>(() async => throw StateError('boom')), throwsStateError);
    expect(await newLock().hold(() async => 3), 3);
  });

  test('a turn leaves the same stamp in IndexedDB and in localStorage', () async {
    await newLock().hold(() async {});
    final committed = (await IndexedDbHandOverRecord().read())?.stamp;

    expect(committed, isNotNull);
    expect(LocalStorageStampCopy().read(), committed);

    await newLock().hold(() async {});
    expect(
      (await IndexedDbHandOverRecord().read())?.stamp,
      isNot(committed),
      reason: 'every turn hands over a fresh stamp',
    );
  });

  test('the record in IndexedDB keeps the time its turn committed it', () async {
    final before = DateTime.now();
    await newLock().hold(() async {});
    final committedAt = (await IndexedDbHandOverRecord().read())?.committedAt;

    expect(committedAt, isNotNull);
    expect(committedAt!.isBefore(before.subtract(const Duration(milliseconds: 1))), isFalse);
    expect(committedAt.isAfter(DateTime.now()), isFalse);
  });

  test('a request that waits longer than its limit fails without running the body', () async {
    final release = Completer<void>();
    final holding = newLock().hold(() => release.future);
    var ran = false;

    await expectLater(
      newLock(waitLimit: const Duration(milliseconds: 100)).hold(() async => ran = true),
      throwsA(isA<TokenRefreshLockException>()),
    );

    expect(ran, isFalse);
    release.complete();
    await holding;
  });

  test(
    'a record in IndexedDB that is not a hand-over is reported as such, and the next turn runs and replaces it',
    () async {
      await newLock().hold(() async {});
      await _putRecord({'stamp': 7, 'committedAt': 'yesterday'}.jsify());

      await expectLater(IndexedDbHandOverRecord().read(), throwsA(isA<HandOverRecordMalformed>()));
      expect(await newLock().hold(() async => 'ran'), 'ran');
      expect((await IndexedDbHandOverRecord().read())?.stamp, LocalStorageStampCopy().read());
    },
  );
}

/// Writes [value] where [IndexedDbHandOverRecord] keeps its record, as a script of the origin could.
Future<void> _putRecord(JSAny? value) async {
  final opened = Completer<web.IDBDatabase>();
  final request = web.window.indexedDB.open(IndexedDbHandOverRecord.databaseName, 1);
  request.onsuccess = ((web.Event _) => opened.complete(request.result as web.IDBDatabase)).toJS;
  request.onerror = ((web.Event _) => opened.completeError(StateError('open failed'))).toJS;
  final database = await opened.future;
  final transaction = database.transaction(IndexedDbHandOverRecord.storeName.toJS, 'readwrite');
  transaction.objectStore(IndexedDbHandOverRecord.storeName).put(value, IndexedDbHandOverRecord.recordKey.toJS);
  final completed = Completer<void>();
  transaction.oncomplete = ((web.Event _) => completed.complete()).toJS;
  transaction.onabort = ((web.Event _) => completed.completeError(StateError('put failed'))).toJS;
  await completed.future;
  database.close();
}
