/// Tells the other browser tabs of the app that this tab ended the stored session, and hears when one of them does.
///
/// On web every tab of the app reads and writes the same stored session in localStorage, but each tab counts its own
/// `SessionGeneration`, and a tab learns another tab's change to localStorage only some time after it was made: the
/// browser keeps a copy of localStorage in each tab and updates it from the others later, with no lock across tabs. A
/// token refresh that read the stored session before another tab's wipe reached this tab's copy can store its rotated
/// tokens after the wipe, which brings back the session that tab ended. Hearing the end lets this tab take them back.
///
/// The ends a tab tells are its own session wipes: a logout, the idle timeout, and a 401 that a token refresh cannot fix.
abstract interface class ISessionEndSignal {
  /// Tells the other tabs that this tab begins to end the stored session now. Called before the wipe's first storage
  /// call.
  void notifyEnded();

  /// Fires when another tab ended the stored session, with the time that tab began to end it, read from the clock of
  /// the device, which every tab shares. Never fires for [notifyEnded] of this tab.
  Stream<DateTime> get endedElsewhere;

  /// Fires when another tab's change to the stored session, or a clear of the store, reaches this tab's copy of it.
  /// Another tab's wipe reaches this copy some time after [endedElsewhere] fired for it, on a channel of its own.
  Stream<void> get storeChanges;
}

/// The time that a session end message of another tab carries, in milliseconds since the epoch, or null when the
/// message is not one: anything other than a whole number of milliseconds that [DateTime] holds.
DateTime? sessionEndTimeOf(Object? message) {
  if (message is! num || !message.isFinite || message.abs() > _latestTime) return null;
  if (message != message.roundToDouble()) return null;
  return DateTime.fromMillisecondsSinceEpoch(message.toInt());
}

/// The latest time [DateTime] holds, in milliseconds since the epoch.
const _latestTime = 8640000000000000;
