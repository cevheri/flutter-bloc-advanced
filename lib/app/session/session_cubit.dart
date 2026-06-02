import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

/// Session state observed by router redirect and UI guards.
///
/// Sealed so consumers must exhaustively switch on the three real
/// outcomes — `unknown` (restore in flight), `authenticated`, and
/// `unauthenticated`. Collapsing them to a single `bool isAuthenticated`
/// (the previous shape) made it impossible to distinguish "still
/// restoring" from "we checked and there is no session" and forced
/// load-bearing comments where a type could carry the invariant.
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => const [];
}

/// Initial state, before [SessionCubit.restore] has completed.
///
/// The router treats this the same as [SessionUnauthenticated] for
/// redirect decisions (we cannot route into protected routes without
/// proof of session), but consumers that need to discriminate — e.g.
/// a splash screen — can pattern-match on the type rather than relying
/// on convention.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// User holds a valid session token in secure storage.
///
/// [roles] is the **OR** set used by router guards: a route requiring
/// `{'ROLE_ADMIN'}` accepts a user whose [roles] contains at least one
/// of the listed values. Defaulting to the empty set preserves the
/// pre-roles `const SessionAuthenticated()` callers while letting new
/// code pass a real set. Stored as [Set] so membership checks at every
/// route transition are O(1) — `AuthSession.roles` upstream is a list
/// for backend-shape parity; we normalize at the cubit boundary.
final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({this.roles = const <String>{}});

  final Set<String> roles;

  @override
  List<Object?> get props => [roles];
}

/// User holds no valid session token. The [reason] is for logs and
/// tests — it MUST NOT be surfaced to the user as a localized error
/// because the categories are deliberately coarse.
final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated({this.reason = SessionExpiredReason.unknown});

  final SessionExpiredReason reason;

  @override
  List<Object?> get props => [reason];
}

/// Why the cubit emitted [SessionUnauthenticated]. Drives log fidelity
/// and lets tests assert specific failure pathways without coupling
/// them to log strings.
enum SessionExpiredReason {
  /// No token in secure storage (clean logged-out state).
  noToken,

  /// Token present but past its `exp` claim.
  expired,

  /// Secure storage read threw (platform / decryption failure).
  /// We fall back to unauthenticated as the safe default so the user
  /// re-authenticates cleanly instead of leaving the cubit in
  /// [SessionUnknown] forever.
  storageError,

  /// User was inactive past the configured idle threshold and the
  /// session was forcibly ended. Surfaced to the UI as a localized
  /// notice so the user understands why they were signed out.
  idleTimeout,

  /// Initial or otherwise uncategorized — e.g. an explicit logout
  /// flow that does not need to distinguish further.
  unknown,
}

/// Owns the single source of truth for "is this user authenticated?".
///
/// Reads the JWT from [ISecureStorage] (the one place tokens live) and
/// runs presence + validity checks via the pure [SecurityUtils] helpers.
/// Consumers (router redirect, UI guards) pattern-match on [state];
/// callers that want to re-evaluate trigger [refresh].
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({ISecureStorage? secureStorage, this._appConfig = const AppConfig.dev()})
    : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
      super(const SessionUnknown());

  static final _log = AppLogger.getLogger('SessionCubit');

  final ISecureStorage _secureStorage;
  final AppConfig _appConfig;

  Future<void> restore() async {
    // ISecureStorage.read can throw on platform / decryption failure.
    // restore() is invoked fire-and-forget from BlocProvider, so any
    // escaping exception becomes an unhandled async error. Wrap the
    // read + decision in try/catch and treat any failure as
    // unauthenticated — the safe default that forces a fresh login
    // rather than leaving the cubit in `unknown` forever.
    try {
      final token = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
      final hasToken = SecurityUtils.hasToken(token);
      if (!hasToken) {
        _log.info('restore: no token in secure storage → unauthenticated');
        emit(const SessionUnauthenticated(reason: SessionExpiredReason.noToken));
        return;
      }
      // In production we additionally reject expired tokens. In non-prod
      // (mocks/dev) we stay lenient so a static MOCK_TOKEN without an
      // `exp` claim does not log the user out on every restart.
      if (_appConfig.isProduction) {
        final expired = SecurityUtils.isTokenExpired(token);
        _log.info('restore: token found, expired={} → authenticated={}', [expired, !expired]);
        if (expired) {
          emit(const SessionUnauthenticated(reason: SessionExpiredReason.expired));
        } else {
          emit(SessionAuthenticated(roles: await _readRoles()));
        }
      } else {
        _log.info('restore: token found (dev/test lenient) → authenticated');
        emit(SessionAuthenticated(roles: await _readRoles()));
      }
    } catch (e, st) {
      _log.error('restore: secure storage read failed → unauthenticated (safe default): {}\n{}', [e, st]);
      emit(const SessionUnauthenticated(reason: SessionExpiredReason.storageError));
    }
  }

  /// Flips the cubit into [SessionAuthenticated]. Caller-trusted —
  /// used after a login flow has already persisted tokens via
  /// [AuthSessionRepository.persist]. Does not re-read storage.
  ///
  /// [roles] defaults to the empty set; the post-login listener in
  /// `AppSessionListeners` reads the persisted roles and passes them
  /// here so route guards see them on the next router refresh.
  void markAuthenticated({Set<String> roles = const <String>{}}) {
    emit(SessionAuthenticated(roles: roles));
  }

  /// Flips the cubit into [SessionUnauthenticated] with the supplied
  /// [reason] (defaults to [SessionExpiredReason.noToken]). Caller-
  /// trusted — used after a logout flow has wiped tokens.
  void markLoggedOut({SessionExpiredReason reason = SessionExpiredReason.noToken}) {
    emit(SessionUnauthenticated(reason: reason));
  }

  /// Re-run [restore] from current secure-storage state. Fire-and-
  /// forget safe — see [restore] for the failure semantics.
  Future<void> refresh() => restore();

  /// Reads the persisted role list from [AppLocalStorage] and normalizes
  /// to a [Set]. Returns the empty set when the key is missing or the
  /// stored shape is unexpected — UI guards fall back to "no access"
  /// rather than failing open.
  Future<Set<String>> _readRoles() async {
    try {
      final raw = await AppLocalStorage().read(StorageKeys.roles.key);
      if (raw is List) {
        return raw.whereType<String>().toSet();
      }
    } catch (e) {
      _log.warn('_readRoles failed; returning empty set: {}', [e]);
    }
    return const <String>{};
  }
}
