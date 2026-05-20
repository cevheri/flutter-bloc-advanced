import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/security_utils.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';

class SessionState extends Equatable {
  const SessionState({required this.isAuthenticated});

  const SessionState.unknown() : isAuthenticated = false;

  final bool isAuthenticated;

  SessionState copyWith({bool? isAuthenticated}) {
    return SessionState(isAuthenticated: isAuthenticated ?? this.isAuthenticated);
  }

  @override
  List<Object?> get props => [isAuthenticated];
}

/// Owns the single source of truth for "is this user authenticated?".
///
/// Reads the JWT from [ISecureStorage] (the one place tokens live) and
/// runs presence + validity checks via the pure [SecurityUtils] helpers.
/// Consumers (router redirect, UI guards) read `state.isAuthenticated`;
/// callers that want to re-evaluate trigger [refresh].
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({ISecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
      super(const SessionState.unknown());

  static final _log = AppLogger.getLogger('SessionCubit');

  final ISecureStorage _secureStorage;

  Future<void> restore() async {
    final token = await _secureStorage.read(SecureStorageKeys.jwtToken.key);
    final hasToken = SecurityUtils.hasToken(token);
    if (!hasToken) {
      _log.info('restore: no token in secure storage → unauthenticated');
      emit(const SessionState(isAuthenticated: false));
      return;
    }
    // In production we additionally reject expired tokens. In non-prod
    // (mocks/dev) we stay lenient so a static MOCK_TOKEN without an
    // `exp` claim does not log the user out on every restart.
    if (ProfileConstants.isProduction) {
      final expired = SecurityUtils.isTokenExpired(token);
      _log.info('restore: token found, expired={} → authenticated={}', [expired, !expired]);
      emit(SessionState(isAuthenticated: !expired));
    } else {
      _log.info('restore: token found (dev/test lenient) → authenticated');
      emit(const SessionState(isAuthenticated: true));
    }
  }

  void markAuthenticated() {
    emit(const SessionState(isAuthenticated: true));
  }

  void markLoggedOut() {
    emit(const SessionState(isAuthenticated: false));
  }

  Future<void> refresh() => restore();
}
