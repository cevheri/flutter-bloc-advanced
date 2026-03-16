/// In-App Developer Console — debug-only diagnostic panel.
///
/// Provides 5 tabs: Network Inspector, BLoC State Inspector, Time-Travel Debugging,
/// Storage Viewer, and Environment & Routes.
///
/// Access: Ctrl+Shift+D (desktop/web) — only visible in debug builds.
library;

export 'dev_console_bloc_observer.dart';
export 'dev_console_overlay.dart';
export 'time_travel/time_travel_bloc_observer.dart';
export 'time_travel/time_travel_store.dart';
