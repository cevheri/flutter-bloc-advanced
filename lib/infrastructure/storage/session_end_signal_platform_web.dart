import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:web/web.dart' as web;

/// The [BroadcastSessionEndSignal] of this tab.
ISessionEndSignal? createPlatformSessionEndSignal() => BroadcastSessionEndSignal();

/// [ISessionEndSignal] over a `BroadcastChannel`, which reaches every other tab of the app's origin.
///
/// A message is the time the sending tab began to end the session, in milliseconds since the epoch. A channel object
/// does not receive its own messages, so one instance serves the whole tab: the session wipe tells through it, and the
/// token refresh hears through it. A second instance in the same tab would hear the tab's own ends.
class BroadcastSessionEndSignal implements ISessionEndSignal {
  BroadcastSessionEndSignal() : _channel = web.BroadcastChannel(channelName) {
    _channel.onmessage = _onMessage.toJS;
  }

  /// The name of the channel. Every tab of the origin that opens a channel with this name hears the others.
  static const channelName = 'flutter_bloc_advance.session.ended';

  final web.BroadcastChannel _channel;
  final _endedElsewhere = StreamController<DateTime>.broadcast();

  void _onMessage(web.MessageEvent event) {
    final endedAt = event.data.dartify();
    if (endedAt is num) _endedElsewhere.add(DateTime.fromMillisecondsSinceEpoch(endedAt.toInt()));
  }

  @override
  void notifyEnded() => _channel.postMessage(DateTime.now().millisecondsSinceEpoch.toJS);

  @override
  Stream<DateTime> get endedElsewhere => _endedElsewhere.stream;
}
