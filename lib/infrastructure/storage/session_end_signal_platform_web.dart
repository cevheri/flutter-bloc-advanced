import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:web/web.dart' as web;

/// The [BroadcastSessionEndSignal] of this tab.
ISessionEndSignal? createPlatformSessionEndSignal() => BroadcastSessionEndSignal();

/// [ISessionEndSignal] over a `BroadcastChannel`, which reaches every other tab of the app's origin.
///
/// A message is the time the sending tab began to end the session, in milliseconds since the epoch. A channel object
/// does not receive its own messages, so one instance serves the whole tab: the session wipe tells through it, and the
/// token refresh hears through it. A second instance in the same tab would hear the tab's own ends. A message that is
/// not such a time, which no tab of the app sends, is ignored ([sessionEndTimeOf]).
///
/// [storeChanges] are the browser's `storage` events, which it fires in this tab when another tab's change to
/// localStorage, where flutter_secure_storage web keeps the session, reaches this tab's copy.
class BroadcastSessionEndSignal implements ISessionEndSignal {
  BroadcastSessionEndSignal() : _channel = web.BroadcastChannel(channelName) {
    _channel.onmessage = _onMessage.toJS;
    web.window.addEventListener('storage', _onStorage.toJS);
  }

  static final _log = AppLogger.getLogger('BroadcastSessionEndSignal');

  /// The name of the channel. Every tab of the origin that opens a channel with this name hears the others.
  static const channelName = 'flutter_bloc_advance.session.ended';

  final web.BroadcastChannel _channel;
  final _endedElsewhere = StreamController<DateTime>.broadcast();
  final _storeChanges = StreamController<void>.broadcast();

  void _onMessage(web.MessageEvent event) {
    Object? message;
    try {
      message = event.data.dartify();
    } catch (_) {
      // A value that has no Dart form, such as a port, is not a time either.
      message = null;
    }
    final endedAt = sessionEndTimeOf(message);
    if (endedAt == null) {
      // The log names no part of the message: one that no tab of the app sent may carry anything.
      _log.warn('Ignored a message on the session end channel that is not a time');
      return;
    }
    _endedElsewhere.add(endedAt);
  }

  void _onStorage(web.StorageEvent _) => _storeChanges.add(null);

  @override
  void notifyEnded() => _channel.postMessage(DateTime.now().millisecondsSinceEpoch.toJS);

  @override
  Stream<DateTime> get endedElsewhere => _endedElsewhere.stream;

  @override
  Stream<void> get storeChanges => _storeChanges.stream;
}
