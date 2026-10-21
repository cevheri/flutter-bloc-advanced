import 'dart:async';

import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InProcessTokenRefreshLock', () {
    test('runs the body at once and answers what it answers', () async {
      expect(await const InProcessTokenRefreshLock().hold(() async => 7), 7);
    });
  });

  // On web a Web Lock grant can reach a tab before the previous holder's localStorage writes do. The lock hands that
  // holder's state over through a stamp in IndexedDB, which is ordered with the lock, and a copy of it in localStorage.
  group('HandOverTokenRefreshLock', () {
    late _Browser browser;
    late _Tab tabA;
    late _Tab tabB;

    setUp(() {
      browser = _Browser();
      tabA = browser.openTab('A');
      tabB = browser.openTab('B');
    });

    test('runs the holders one at a time, in the order they asked, and answers what each body answers', () async {
      final release = Completer<void>();
      final events = <String>[];
      final first = tabA.lock().hold(() async {
        events.add('A in');
        await release.future;
        events.add('A out');
        return 'a';
      });
      final second = tabB.lock().hold(() async {
        events.add('B in');
        return 'b';
      });
      await _settle();
      expect(events, ['A in']);

      tabB.onGranted = () => Timer.run(tabB.receive);
      release.complete();

      expect(await first, 'a');
      expect(await second, 'b');
      expect(events, ['A in', 'A out', 'B in']);
    });

    test('ends a turn with a stamp in localStorage after the body\'s writes, committed to IndexedDB before the '
        'release', () async {
      await tabA.lock().hold(() async => tabA.write('refreshToken', 'refresh-1'));

      expect(browser.events, ['A granted', 'A wrote refreshToken', 'A wrote stamp', 'A committed', 'A released']);
      expect(browser.record, isNotNull);
      expect(browser.localStorage['stamp'], browser.record);
    });

    test('hands over a fresh random stamp each turn, which carries nothing the body wrote', () async {
      final stamps = <String?>[];
      for (var turn = 0; turn < 3; turn++) {
        await tabA.lock().hold(() async => tabA.write('refreshToken', 'refresh-$turn'));
        stamps.add(browser.record);
      }

      expect(stamps.toSet(), hasLength(3));
      for (final stamp in stamps) {
        expect(stamp, isNot(contains('refresh')));
      }
    });

    test('waits for this tab\'s copy to show the previous holder\'s writes before the body runs', () async {
      await tabA.lock().hold(() async => tabA.write('refreshToken', 'refresh-1'));
      // The grant reaches tab B before tab A's writes do; they arrive a moment later.
      tabB.onGranted = () => Timer.run(tabB.receive);

      final seen = await tabB.lock().hold(() async => tabB.read('refreshToken'));

      expect(seen, 'refresh-1');
    });

    test('runs the body at once when no turn was handed over yet', () async {
      expect(await tabB.lock().hold(() async => 'ran'), 'ran');
    });

    test('gives up the turn without running the body when the copy does not catch up in time, and leaves a stamp '
        'that the next holder can use', () async {
      await tabA.lock().hold(() async => tabA.write('refreshToken', 'refresh-1'));
      var ran = false;

      await expectLater(
        tabB.lock(catchUpLimit: const Duration(milliseconds: 20)).hold(() async => ran = true),
        throwsA(isA<TokenRefreshLockException>()),
      );

      expect(ran, isFalse, reason: 'a body that read a copy behind the hand-over could send a spent refresh token');
      expect(await tabB.lock().hold(() async => 'next turn'), 'next turn', reason: 'one stale stamp stops no turn');
    });

    test('passes an error of the body on unchanged and still hands over', () async {
      final error = StateError('boom');

      await expectLater(tabA.lock().hold<void>(() async => throw error), throwsA(same(error)));

      expect(browser.events.last, 'A released');
      expect(browser.record, isNotNull);
    });

    test('fails with TokenRefreshLockException without running the body when the lock cannot be taken', () async {
      tabA.refuseLock = true;
      var ran = false;

      await expectLater(tabA.lock().hold(() async => ran = true), throwsA(isA<TokenRefreshLockException>()));

      expect(ran, isFalse);
    });

    test('fails with TokenRefreshLockException without running the body when the hand-over cannot be read', () async {
      browser.failRecordReads = true;
      var ran = false;

      await expectLater(tabA.lock().hold(() async => ran = true), throwsA(isA<TokenRefreshLockException>()));

      expect(ran, isFalse);
    });

    test('fails with TokenRefreshLockException when the turn cannot be handed over after the body', () async {
      browser.failRecordWrites = true;

      await expectLater(tabA.lock().hold(() async => 'stored'), throwsA(isA<TokenRefreshLockException>()));

      expect(browser.events.last, 'A released');
    });
  });
}

/// Lets the microtasks and zero timers that are due run.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 1));

/// The browser of the test: one Web Lock name, the IndexedDB hand-over record and the localStorage its tabs share.
class _Browser {
  /// What the tabs did to the lock and the stores, in order.
  final events = <String>[];

  /// The committed hand-over stamp.
  String? record;
  bool failRecordReads = false;
  bool failRecordWrites = false;

  /// The browser's copy of localStorage, which takes every change at once.
  final localStorage = <String, String>{};
  final _tabs = <_Tab>[];
  Future<void> _lockTail = Future<void>.value();

  _Tab openTab(String name) {
    final tab = _Tab._(this, name);
    _tabs.add(tab);
    return tab;
  }
}

/// A browser tab of [_Browser]. Its copy of localStorage takes another tab's changes only when [receive] runs, in the
/// order that tab made them; the Web Lock grants itself without delivering them first.
class _Tab {
  _Tab._(this._browser, this._name) : _copy = Map.of(_browser.localStorage);

  final _Browser _browser;
  final String _name;
  final Map<String, String> _copy;
  final _undelivered = <(String, String)>[];
  final _stampChanges = StreamController<void>.broadcast(sync: true);

  /// Runs once this tab is granted the lock, before its turn starts.
  void Function()? onGranted;
  bool refuseLock = false;

  HandOverTokenRefreshLock lock({Duration catchUpLimit = HandOverTokenRefreshLock.defaultCatchUpLimit}) =>
      HandOverTokenRefreshLock(
        mutex: _TabMutex(this),
        record: _TabRecord(this),
        copy: _TabStampCopy(this),
        catchUpLimit: catchUpLimit,
      );

  String? read(String key) => _copy[key];

  void write(String key, String value) {
    _browser.events.add('$_name wrote $key');
    _copy[key] = value;
    _browser.localStorage[key] = value;
    for (final tab in _browser._tabs) {
      if (!identical(tab, this)) tab._undelivered.add((key, value));
    }
  }

  /// Applies the other tabs' changes since the last delivery, in their order.
  void receive() {
    final changes = List.of(_undelivered);
    _undelivered.clear();
    for (final (key, value) in changes) {
      _copy[key] = value;
      if (key == _TabStampCopy.key) _stampChanges.add(null);
    }
  }
}

/// The Web Lock as [_Tab] sees it: granted in the order the tabs asked.
class _TabMutex implements CrossTabMutex {
  _TabMutex(this._tab);

  final _Tab _tab;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    final browser = _tab._browser;
    if (_tab.refuseLock) return Future.error(StateError('navigator.locks is not available'));
    final previous = browser._lockTail;
    final released = Completer<void>();
    browser._lockTail = released.future;
    return previous.then((_) async {
      browser.events.add('${_tab._name} granted');
      _tab.onGranted?.call();
      try {
        return await body();
      } finally {
        browser.events.add('${_tab._name} released');
        released.complete();
      }
    });
  }
}

/// The IndexedDB hand-over record as [_Tab] sees it: every tab reads what was committed last.
class _TabRecord implements HandOverRecord {
  _TabRecord(this._tab);

  final _Tab _tab;

  @override
  Future<String?> read() async {
    if (_tab._browser.failRecordReads) throw StateError('IndexedDB read failed');
    return _tab._browser.record;
  }

  @override
  Future<void> write(String stamp) async {
    final browser = _tab._browser;
    if (browser.failRecordWrites) throw StateError('IndexedDB write failed');
    browser.record = stamp;
    browser.events.add('${_tab._name} committed');
  }
}

/// The stamp in [_Tab]'s copy of localStorage.
class _TabStampCopy implements HandOverStampCopy {
  _TabStampCopy(this._tab);

  static const key = 'stamp';

  final _Tab _tab;

  @override
  String? read() => _tab.read(key);

  @override
  void write(String stamp) => _tab.write(key, stamp);

  @override
  Stream<void> get changes => _tab._stampChanges.stream;
}
