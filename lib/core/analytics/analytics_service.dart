/// Abstract analytics interface.
///
/// Implement this interface to integrate with any analytics provider
/// (Firebase, Amplitude, Mixpanel, etc.). The default [LogAnalyticsService]
/// writes events to [AppLogger] — no SDK required.
///
/// To switch providers: implement this interface and swap the DI registration.
abstract class IAnalyticsService {
  /// Log a screen view event.
  void logScreenView({required String screenName, String? screenClass});

  /// Log a custom event with optional parameters.
  void logEvent({required String name, Map<String, dynamic>? parameters});

  /// Log a user action (button press, form submit, etc.).
  void logUserAction({required String action, String? target, Map<String, dynamic>? parameters});

  /// Set the current user identifier for analytics.
  void setUserId(String? userId);

  /// Set a user property (e.g., role, plan).
  void setUserProperty({required String name, required String? value});

  /// Report a non-fatal error.
  void logError({required Object error, StackTrace? stackTrace, String? reason});
}
