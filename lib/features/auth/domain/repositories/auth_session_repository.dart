import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_session.dart';

/// Persists / clears the authenticated session as one logical unit.
///
/// The application layer hands this a fully-formed [AuthSession]; the
/// data layer decides how to write it (SharedPreferences keys, secure
/// storage, etc.) and is responsible for rolling back partial writes if
/// any step fails so the caller never sees a half-persisted session.
abstract class IAuthSessionRepository {
  /// Persist the session atomically. Implementations must roll back
  /// previously-written keys if a later write fails, so a partial
  /// session never lingers in storage on error.
  Future<Result<void>> persist(AuthSession session);

  /// Clear all session keys.
  Future<Result<void>> clear();
}
