import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/services/sso_session_startup.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/startup_storage_time_limit.dart';

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
///
/// [signInError] is the error of a web sign-in that failed at startup,
/// with [SessionExpiredReason.signInFailed]; the login page shows it.
final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated({this.reason = SessionExpiredReason.unknown, this.signInError});

  final SessionExpiredReason reason;
  final AppErrorCode? signInError;

  @override
  List<Object?> get props => [reason, signInError];

  /// Leaves out a null [signInError], so a `jwt` build, which never sets
  /// one, prints this state as it did before the field existed.
  @override
  String toString() {
    if (signInError != null || !(stringify ?? EquatableConfig.stringify)) return super.toString();
    return '$runtimeType($reason)';
  }
}

/// Why the cubit emitted [SessionUnauthenticated]. Drives log fidelity
/// and lets tests assert specific failure pathways without coupling
/// them to log strings.
enum SessionExpiredReason {
  /// No token in secure storage (clean logged-out state), or an explicit
  /// logout: [SessionCubit.markLoggedOut] reports this reason also after a
  /// logout that could not clear all of the stored session, which can leave
  /// a token behind.
  noToken,

  /// Token present but past its `exp` claim, or rejected with a 401
  /// that a token refresh could not fix.
  expired,

  /// Secure storage read threw (platform / decryption failure).
  /// We fall back to unauthenticated as the safe default so the user
  /// re-authenticates cleanly instead of leaving the cubit in
  /// [SessionUnknown] forever.
  storageError,

  /// The stored session was not read within the restore time limit, so
  /// it could not be checked; see [SessionCubit.restore]. The login page
  /// shows, and a valid session that the read finds later still opens
  /// the app unless the user has signed in or out by then.
  storageTimeout,

  /// User was inactive past the configured idle threshold and the
  /// session was forcibly ended. Surfaced to the UI as a localized
  /// notice so the user understands why they were signed out.
  idleTimeout,

  /// A same-tab web sign-in failed while an `oidc` build started;
  /// [SessionUnauthenticated.signInError] says why.
  signInFailed,

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
  SessionCubit({
    ISecureStorage? secureStorage,
    IAuthSessionRepository? sessionRepository,
    this._appConfig = const AppConfig.dev(),
    this._restoreTimeLimit = defaultRestoreTimeLimit,
    this._ssoStartup,
    this._ssoStartupTimeLimit = defaultSsoStartupTimeLimit,
  }) : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
       super(const SessionUnknown()) {
    _sessionRepository = sessionRepository ?? AuthSessionRepository(secureStorage: _secureStorage);
  }

  /// How long [restore] waits for the stored session unless the
  /// constructor is given another `restoreTimeLimit`: ten seconds, the
  /// limit that the session migration before runApp has too, see
  /// [StartupStorageTimeLimit.defaultDuration].
  ///
  /// An answer that comes after the limit still settles the session while
  /// the user is signed out by it. On macOS a read waits while the login
  /// keychain asks for its password, so a password entered after ten
  /// seconds still opens the stored session.
  static const defaultRestoreTimeLimit = StartupStorageTimeLimit.defaultDuration;

  /// How long [restore] waits for the startup step of an `oidc` build
  /// unless the constructor is given another `ssoStartupTimeLimit`. The
  /// step makes network calls, so it has its own limit, outside the
  /// storage one.
  static const defaultSsoStartupTimeLimit = Duration(seconds: 15);

  static final _log = AppLogger.getLogger('SessionCubit');

  final ISecureStorage _secureStorage;
  late final IAuthSessionRepository _sessionRepository;
  final AppConfig _appConfig;
  final Duration _restoreTimeLimit;

  /// The startup step of an `oidc` build; null in a `jwt` build.
  final ISsoSessionStartup? _ssoStartup;
  final Duration _ssoStartupTimeLimit;

  /// The time limits of the restores in flight, cancelled by [close].
  final _restoreTimeLimits = <StartupStorageTimeLimit<SessionState>>{};

  /// The time limits of the startup steps in flight, cancelled by [close].
  final _ssoStartupTimers = <Timer>{};

  /// How many states this cubit has emitted, counting a state equal to the
  /// current one, so a late startup answer can tell that nothing has been
  /// emitted since the state it would change.
  int _emitCount = 0;

  @override
  void emit(SessionState state) {
    _emitCount++;
    super.emit(state);
  }

  /// Reads the stored session and settles [state] from it.
  ///
  /// The read is bounded by the restore time limit
  /// ([defaultRestoreTimeLimit] unless the constructor is given another).
  /// Until restore settles the session, App shows a spinner instead of the
  /// router, so a secure storage that never answers would keep the user
  /// there forever. When the limit passes first, restore logs an error
  /// and emits [SessionUnauthenticated] with
  /// [SessionExpiredReason.storageTimeout], so the login page shows. This
  /// is an explicit error path, not a silent fallback: the error log says
  /// why the user is signed out. The stored session itself is left as it
  /// is.
  ///
  /// A read that answers after the limit settles the session as an
  /// in-time read would, as long as that storageTimeout sign-out is still
  /// the state: a valid stored session opens the app, and no session or
  /// an expired one keeps the login page. Once the user has signed in or
  /// out, the late answer is logged and ignored, so it can neither sign
  /// them back in nor replace the session they signed in to.
  ///
  /// In an `oidc` build the startup step runs first, under its own time
  /// limit ([defaultSsoStartupTimeLimit] unless the constructor is given
  /// another): it completes a pending web sign-in and refreshes an
  /// expired access token. Only when it keeps the stored session is that
  /// session read, and then without the JWT `exp` check, because the
  /// step owns the expiry. A step that does not answer in time is taken
  /// as a provider that cannot be reached: the stored session is read as
  /// it is.
  ///
  /// The step goes on after its limit, and what it answers then is acted
  /// on only while the state is still the one that the read after the
  /// limit settled, see [_settleLateSsoStartup].
  Future<void> restore() async {
    final ssoStartup = _ssoStartup;
    if (ssoStartup != null) {
      // Completes with the emit count once the stored read after a timed-out step has settled the state.
      final settledAfterLimit = Completer<int>();
      final SessionState? settled;
      final bool timedOut;
      try {
        final SsoStartupResult result;
        (:result, :timedOut) = await _runSsoStartup(
          ssoStartup,
          onLateAnswer: (late) => unawaited(_settleLateSsoStartup(late, settledAfterLimit.future)),
        );
        settled = switch (result) {
          SsoStartupSignedIn(:final roles) => SessionAuthenticated(roles: roles.toSet()),
          SsoStartupSignInFailed(:final errorCode) => SessionUnauthenticated(
            reason: SessionExpiredReason.signInFailed,
            signInError: errorCode,
          ),
          SsoStartupSessionEnded() => const SessionUnauthenticated(reason: SessionExpiredReason.expired),
          SsoStartupUseStoredSession() => null,
        };
      } catch (e) {
        // Only the type: the step handles every failure it expects, so this one is a defect.
        _log.error('restore: the startup step failed → unauthenticated: {}', [e.runtimeType]);
        ssoStartup.giveUp();
        if (!isClosed) {
          emit(
            const SessionUnauthenticated(
              reason: SessionExpiredReason.signInFailed,
              signInError: AppErrorCode.authOidcFailed,
            ),
          );
        }
        return;
      }
      if (isClosed) return;
      if (settled != null) {
        emit(settled);
        return;
      }
      await _restoreStoredSession(checkJwtExpiry: false);
      if (timedOut) settledAfterLimit.complete(_emitCount);
      return;
    }
    await _restoreStoredSession(checkJwtExpiry: true);
  }

  /// Runs [startup] for at most [_ssoStartupTimeLimit], after which it
  /// answers [SsoStartupUseStoredSession] with `timedOut` set, and hands
  /// what the step answers later to [onLateAnswer].
  Future<({SsoStartupResult result, bool timedOut})> _runSsoStartup(
    ISsoSessionStartup startup, {
    required void Function(SsoStartupResult late) onLateAnswer,
  }) {
    final result = Completer<({SsoStartupResult result, bool timedOut})>();
    late final Timer timer;
    timer = Timer(_ssoStartupTimeLimit, () {
      _ssoStartupTimers.remove(timer);
      _log.warn('restore: the identity provider did not answer within {} ms at startup → the stored session is read', [
        _ssoStartupTimeLimit.inMilliseconds,
      ]);
      startup.giveUp();
      result.complete((result: const SsoStartupUseStoredSession(), timedOut: true));
    });
    _ssoStartupTimers.add(timer);
    unawaited(
      startup.run().then(
        (value) {
          if (result.isCompleted) {
            onLateAnswer(value);
            return;
          }
          timer.cancel();
          _ssoStartupTimers.remove(timer);
          result.complete((result: value, timedOut: false));
        },
        onError: (Object error, StackTrace stackTrace) {
          if (result.isCompleted) {
            _log.error('restore: the startup step failed after its time limit: {}', [error.runtimeType]);
            return;
          }
          timer.cancel();
          _ssoStartupTimers.remove(timer);
          result.completeError(error, stackTrace);
        },
      ),
    );
    return result.future;
  }

  /// Acts on [late], what the startup step answered after its time limit,
  /// once [settledAfterLimit] gives the emit count at which the stored read
  /// after the limit settled the state, and only while nothing has been
  /// emitted since. A late [SsoStartupSessionEnded] has already cleared the
  /// stored session, so the session ends; a late [SsoStartupSignedIn] has
  /// stored a session the cubit has not read, so it is read now and the
  /// roles match the stored bearer. Any other late answer, or one that
  /// comes after the state has changed, is only logged: the automatic
  /// redirect gate closed at the limit.
  Future<void> _settleLateSsoStartup(SsoStartupResult late, Future<int> settledAfterLimit) async {
    final settledAt = await settledAfterLimit;
    if (isClosed || _emitCount != settledAt) {
      _log.warn('restore: the startup step answered after its time limit, the state changed since, ignored: {}', [
        late.runtimeType,
      ]);
      return;
    }
    _log.info('restore: the startup step answered after its time limit: {}', [late.runtimeType]);
    switch (late) {
      case SsoStartupSessionEnded():
        await endSession(reason: SessionExpiredReason.expired);
      case SsoStartupSignedIn():
        final stored = await _readStoredSession(checkJwtExpiry: false);
        if (isClosed || _emitCount != settledAt) {
          _log.warn('restore: the session stored after the time limit was read after the state changed, ignored: {}', [
            stored,
          ]);
          return;
        }
        emit(stored);
      case SsoStartupSignInFailed() || SsoStartupUseStoredSession():
        break;
    }
  }

  /// Settles [state] from the stored session, see [restore].
  Future<void> _restoreStoredSession({required bool checkJwtExpiry}) async {
    final storedSession = _readStoredSession(checkJwtExpiry: checkJwtExpiry);
    final timeLimit = StartupStorageTimeLimit(storedSession, duration: _restoreTimeLimit);
    _restoreTimeLimits.add(timeLimit);
    final SessionState session;
    try {
      session = await timeLimit.result;
    } on TimeoutException {
      _log.error(
        'restore: secure storage did not answer within {} ms → unauthenticated until it answers or the user signs in',
        [_restoreTimeLimit.inMilliseconds],
      );
      // Not const: only this instance is the sign-out of this restore, so a
      // late answer can tell that nobody has signed in or out since.
      final timedOut = SessionUnauthenticated(reason: SessionExpiredReason.storageTimeout);
      emit(timedOut);
      unawaited(storedSession.then((stored) => _settleLate(stored, timedOut)));
      return;
    } finally {
      _restoreTimeLimits.remove(timeLimit);
    }
    emit(session);
  }

  /// Settles [state] from [stored], which [restore] read only after its
  /// time limit had signed the user out with [timedOut].
  void _settleLate(SessionState stored, SessionUnauthenticated timedOut) {
    if (isClosed || !identical(state, timedOut)) {
      _log.warn('restore: secure storage answered after the time limit, ignored: {}', [stored]);
      return;
    }
    _log.info('restore: secure storage answered after the time limit, nobody signed in or out since → {}', [stored]);
    emit(stored);
  }

  /// The session that the stored token proves, for [restore]. Without
  /// [checkJwtExpiry], which an `oidc` build turns off, a stored token is
  /// a session in every environment.
  Future<SessionState> _readStoredSession({required bool checkJwtExpiry}) async {
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
        return const SessionUnauthenticated(reason: SessionExpiredReason.noToken);
      }
      // In production we additionally reject expired tokens. In non-prod
      // (mocks/dev) we stay lenient so a static MOCK_TOKEN without an
      // `exp` claim does not log the user out on every restart.
      //
      // An expired session stays stored until a sign-in replaces it. The
      // screens a signed-out user can reach only call public endpoints,
      // which never receive it, and clearing it here would sign out other
      // browser tabs, which share the stored session and refresh it on
      // their next request.
      if (!checkJwtExpiry) {
        _log.info('restore: token found, its expiry checked by the startup step → authenticated');
        return SessionAuthenticated(roles: await _readRoles());
      }
      if (_appConfig.isProduction) {
        final expired = SecurityUtils.isTokenExpired(token);
        _log.info('restore: token found, expired={} → authenticated={}', [expired, !expired]);
        if (expired) {
          return const SessionUnauthenticated(reason: SessionExpiredReason.expired);
        } else {
          return SessionAuthenticated(roles: await _readRoles());
        }
      } else {
        _log.info('restore: token found (dev/test lenient) → authenticated');
        return SessionAuthenticated(roles: await _readRoles());
      }
    } catch (e, st) {
      _log.error('restore: secure storage read failed → unauthenticated (safe default): {}\n{}', [e, st]);
      return const SessionUnauthenticated(reason: SessionExpiredReason.storageError);
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

  /// Flips the cubit into [SessionUnauthenticated] with
  /// [SessionExpiredReason.noToken]. Caller-trusted: used after the explicit
  /// logout flow (`LoginRepository.logout`) has cleared the stored session
  /// through [IAuthSessionRepository.clear], or failed to clear all of it:
  /// like [endSession], the logout ends the session either way. Any other
  /// path that ends a session calls [endSession] instead.
  void markLoggedOut() {
    emit(const SessionUnauthenticated(reason: SessionExpiredReason.noToken));
  }

  /// Ends the session: wipes the stored session through
  /// [IAuthSessionRepository.clear], the same cleanup the explicit logout
  /// runs, then emits [SessionUnauthenticated] with [reason] unless the
  /// cubit is already signed out. Used by the idle timeout and by a 401
  /// that a token refresh cannot fix, so a restart cannot restore a
  /// session they ended.
  ///
  /// The wipe depends on what is stored, not on [state]. It is skipped
  /// when no token is stored, so a 401 from a request still in flight when
  /// the user signed out leaves storage alone. A stored token is
  /// wiped even when the cubit is signed out, so no session the app has
  /// ended stays stored for a restart to restore. The wipe ends the
  /// session generation, so a token refresh still on its way does not
  /// leave its rotated tokens stored: it drops them, or takes back what
  /// it stored when the wipe ran meanwhile.
  ///
  /// A failed wipe is logged at error level with the storage error, which
  /// names each step that failed, and the in-memory session still ends:
  /// staying signed in would defeat the idle timeout, and after an
  /// unrefreshable 401 the server has already rejected the session. A
  /// token left behind lets the next launch restore the session; a
  /// session key or cached responses left behind do not.
  Future<void> endSession({required SessionExpiredReason reason}) async {
    if (await _hasStoredSession()) {
      switch (await _sessionRepository.clear()) {
        case Success():
          _log.info('endSession({}): stored session cleared', [reason.name]);
        case Failure(:final error):
          _log.error('endSession({}): stored session not fully cleared: {}', [reason.name, error]);
      }
    } else {
      _log.debug('endSession({}): no stored session to clear', [reason.name]);
    }
    if (state is! SessionUnauthenticated) emit(SessionUnauthenticated(reason: reason));
  }

  /// Whether secure storage holds a JWT or a refresh token. A failed read
  /// counts as stored, so [endSession] wipes rather than leaves a session
  /// it could not inspect.
  Future<bool> _hasStoredSession() async {
    try {
      for (final key in [SecureStorageKeys.jwtToken, SecureStorageKeys.refreshToken]) {
        if (await _secureStorage.read(key.key) != null) return true;
      }
      return false;
    } catch (e) {
      _log.error('endSession: reading the stored session failed, clearing it anyway: {}', [e]);
      return true;
    }
  }

  /// Re-run [restore] from current secure-storage state. Fire-and-
  /// forget safe: see [restore] for the failure semantics. In an `oidc`
  /// build this runs the startup step again first, through [restore]: it
  /// completes a pending web sign-in, normally none by then, and refreshes
  /// the access token when it has expired.
  Future<void> refresh() => restore();

  @override
  Future<void> close() {
    for (final timeLimit in _restoreTimeLimits) {
      timeLimit.cancel();
    }
    _restoreTimeLimits.clear();
    for (final timer in _ssoStartupTimers) {
      timer.cancel();
    }
    _ssoStartupTimers.clear();
    return super.close();
  }

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
