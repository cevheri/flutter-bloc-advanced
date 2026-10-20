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

  /// Removes what the signed-in session stored: the tokens, the user's
  /// keys and the cached responses. Device preferences, such as the
  /// language and theme, stay. A step that fails does not stop the
  /// others, and the failures come back as one [Failure].
  Future<Result<void>> clear();
}
