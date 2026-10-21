import 'package:flutter_bloc_advance/infrastructure/storage/token_refresh_lock.dart';

/// Outside the browser one running instance of the app holds the stored session, so a refresh runs at once and
/// [waitLimit] does not apply.
ITokenRefreshLock createPlatformTokenRefreshLock({required Duration waitLimit}) => const InProcessTokenRefreshLock();
