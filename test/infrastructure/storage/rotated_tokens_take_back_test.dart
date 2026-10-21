import 'dart:async';

import 'package:flutter_bloc_advance/infrastructure/storage/rotated_tokens_take_back.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_generation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Channel channel;

  setUp(() => channel = _Channel());

  test('ends this tab\'s session generation when another tab ends the session, with nothing to take back', () async {
    final tab = _Tab(channel);
    final other = _Tab(channel);
    final before = SessionGeneration.current;

    other.signal.notifyEnded();
    await tab.signal.deliver();

    expect(SessionGeneration.hasEnded(before), isTrue, reason: 'a refresh still on its way here drops its answer');
  });

  test('stops hearing the other tabs once disposed', () async {
    final tab = _Tab(channel);
    final other = _Tab(channel);
    await tab.takeBack.dispose();
    final before = SessionGeneration.current;

    other.signal.notifyEnded();
    await tab.signal.deliver();

    expect(SessionGeneration.hasEnded(before), isFalse, reason: 'a disposed take-back runs no second wipe');
  });

  test('ends a wipe that waits for this tab\'s copy when disposed', () async {
    final tab = _Tab(channel);
    final other = _Tab(channel);
    // This tab's copy still holds the refresh token the other tab deletes, and no change of it ever arrives.
    tab.storage.values[SecureStorageKeys.refreshToken.key] = 'refresh-other-tab-deletes';
    other.signal.notifyEnded();
    await tab.signal.deliver();
    expect(SessionGeneration.hasEnded(SessionGeneration.current), isTrue, reason: 'the wipe waits for the copy');

    await tab.takeBack.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(SessionGeneration.hasEnded(SessionGeneration.current), isFalse);
  });

  test('prints which keys it holds, never their values', () {
    final tab = _Tab(channel);
    tab.takeBack.record([(SecureStorageKeys.jwtToken, 'secret-jwt')], onTakeBackFailed: () {});

    expect(tab.takeBack.toString(), contains(SecureStorageKeys.jwtToken.key));
    expect(tab.takeBack.toString(), isNot(contains('secret-jwt')));
  });

  // A failed take-back ends the session, and that end is told to the other tabs, which may take back again. Each tab
  // takes back only what it recorded since the last end it heard, so the ends stop.
  test('two tabs whose take-backs fail end the session once each, and the ends stop', () async {
    final a = _Tab(channel)..storeRotated('jwt-a');
    final b = _Tab(channel)..storeRotated('jwt-b');

    a.endSession();
    for (var round = 0; round < 10 && channel.hasUndelivered; round++) {
      await a.signal.deliver();
      await b.signal.deliver();
    }

    expect(channel.hasUndelivered, isFalse, reason: 'no end is still being told');
    expect(b.ends, 1, reason: 'its take-back after the first end failed');
    expect(a.ends, 2, reason: 'its own sign-out, and its take-back after the end of tab B failed');
  });
}

/// The BroadcastChannel between the tabs of the test: an end one tab tells reaches the others on [_TabSignal.deliver].
class _Channel {
  final _tabs = <_TabSignal>[];

  bool get hasUndelivered => _tabs.any((tab) => tab._undelivered.isNotEmpty);
}

class _TabSignal implements ISessionEndSignal {
  _TabSignal(this._channel) {
    _channel._tabs.add(this);
  }

  final _Channel _channel;
  final _undelivered = <DateTime>[];
  final _endedElsewhere = StreamController<DateTime>.broadcast(sync: true);

  @override
  void notifyEnded() {
    for (final tab in _channel._tabs) {
      if (!identical(tab, this)) tab._undelivered.add(DateTime.now());
    }
  }

  Future<void> deliver() async {
    final ends = List.of(_undelivered);
    _undelivered.clear();
    ends.forEach(_endedElsewhere.add);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<DateTime> get endedElsewhere => _endedElsewhere.stream;

  @override
  Stream<void> get storeChanges => const Stream.empty();
}

/// A tab whose stored session cannot be deleted, and whose end of the session tells the other tabs, as
/// AuthSessionRepository.clear does.
class _Tab {
  _Tab(_Channel channel) : signal = _TabSignal(channel) {
    takeBack = RotatedTokensTakeBack(secureStorage: storage, sessionEndSignal: signal);
  }

  final _TabSignal signal;
  final storage = _UndeletableStorage();
  late final RotatedTokensTakeBack takeBack;
  int ends = 0;

  void storeRotated(String jwt) {
    storage.values[SecureStorageKeys.jwtToken.key] = jwt;
    takeBack.record([(SecureStorageKeys.jwtToken, jwt)], onTakeBackFailed: endSession);
  }

  void endSession() {
    ends++;
    signal.notifyEnded();
  }
}

class _UndeletableStorage implements ISecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => throw StateError('boom on delete $key');

  @override
  Future<void> deleteAll() async => throw StateError('boom on deleteAll');
}
