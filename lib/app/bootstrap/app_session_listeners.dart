import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class AppSessionListeners extends StatefulWidget {
  const AppSessionListeners({super.key, required this.child, this.idleTimeoutOverride});

  final Widget child;

  /// Test seam — lets a widget test inject a smaller threshold than
  /// production without re-pointing [ProfileConstants]. Null falls back
  /// to [ProfileConstants.idleTimeout].
  final Duration? idleTimeoutOverride;

  @override
  State<AppSessionListeners> createState() => _AppSessionListenersState();
}

class _AppSessionListenersState extends State<AppSessionListeners> {
  static final _log = AppLogger.getLogger('AppSessionListeners');

  IdleTimeoutObserver? _idleObserver;

  @override
  void dispose() {
    _idleObserver?.stop();
    _idleObserver = null;
    super.dispose();
  }

  void _startIdleObserver() {
    if (_idleObserver != null) return;
    final threshold = widget.idleTimeoutOverride ?? ProfileConstants.idleTimeout;
    if (threshold == null) {
      _log.debug('idle timeout disabled (no threshold configured)');
      return;
    }
    final cubit = context.read<SessionCubit>();
    final observer = IdleTimeoutObserver(
      idleThreshold: threshold,
      onTimeout: () {
        _log.info('idle timeout fired — signing out');
        cubit.markLoggedOut(reason: SessionExpiredReason.idleTimeout);
      },
    );
    observer.start();
    _idleObserver = observer;
  }

  void _stopIdleObserver() {
    _idleObserver?.stop();
    _idleObserver = null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            if (state is LoginLoadedState) {
              context.read<SessionCubit>().markAuthenticated();
            }
          },
        ),
        BlocListener<MenuBloc, MenuState>(
          listenWhen: (previous, current) => previous.isLogout != current.isLogout,
          listener: (context, state) {
            if (state.isLogout) {
              context.read<SessionCubit>().markLoggedOut();
            }
          },
        ),
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            switch (state) {
              case SessionAuthenticated():
                _startIdleObserver();
              case SessionUnauthenticated(:final reason):
                _stopIdleObserver();
                if (reason == SessionExpiredReason.idleTimeout) {
                  _showIdleTimeoutNotice(context);
                }
              case SessionUnknown():
                break;
            }
          },
        ),
      ],
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _idleObserver?.recordActivity(),
        onPointerMove: (_) => _idleObserver?.recordActivity(),
        child: widget.child,
      ),
    );
  }

  void _showIdleTimeoutNotice(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(S.of(context).idle_timeout_signed_out)));
  }
}
