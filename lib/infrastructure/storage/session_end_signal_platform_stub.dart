import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';

/// No signal outside the browser: on mobile and desktop one running instance of the app holds the stored session.
ISessionEndSignal? createPlatformSessionEndSignal() => null;
