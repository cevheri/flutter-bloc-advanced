import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/session/session_cubit.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/idle_timeout_observer.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';

class AppSessionListeners extends StatefulWidget {
  const AppSessionListeners({
    super.key,
    required this.scaffoldMessengerKey,
    required this.sharedActivity,
    required this.child,
    this.idleTimeoutOverride,
  });

  /// The ScaffoldMessenger of the MaterialApp in [child], which shows the
  /// session notices: the idle timeout, and a logout that could not remove
  /// all stored data. This widget sits above MaterialApp, where its context
  /// finds no ScaffoldMessenger.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  /// The activity of every browser tab, which the idle timeout counts on
  /// web, where all tabs share the session. Null on mobile and desktop;
  /// see `AppDependencies.createSharedActivityStore`.
  final ISharedActivityStore? sharedActivity;

  final Widget child;

  /// Test seam — lets a widget test inject a smaller threshold than the
  /// injected [AppConfig]. Null falls back to the [AppConfig.idleTimeout]
  /// read from the widget tree via [context.read<AppConfig>()].
  final Duration? idleTimeoutOverride;

  @override
  State<AppSessionListeners> createState() => _AppSessionListenersState();
}

class _AppSessionListenersState extends State<AppSessionListeners> {
  static final _log = AppLogger.getLogger('AppSessionListeners');

  IdleTimeoutObserver? _idleObserver;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _idleObserver?.stop();
    _idleObserver = null;
    super.dispose();
  }

  void _startIdleObserver() {
    if (_idleObserver != null) return;
    final threshold = widget.idleTimeoutOverride ?? context.read<AppConfig>().idleTimeout;
    if (threshold == null) {
      _log.debug('idle timeout disabled (no threshold configured)');
      return;
    }
    final cubit = context.read<SessionCubit>();
    final observer = IdleTimeoutObserver(
      idleThreshold: threshold,
      sharedActivity: widget.sharedActivity,
      onTimeout: () {
        _log.info('idle timeout fired — signing out');
        cubit.endSession(reason: SessionExpiredReason.idleTimeout);
      },
    );
    observer.start();
    _idleObserver = observer;
  }

  /// Counts a key the user pressed as activity, as typing in a form or moving the focus with the keyboard does on
  /// desktop and web. Returns false, so the key still reaches the focused widget. A key event Flutter synthesized to
  /// match the keyboard state, such as the release of a key held down when the window lost focus, is no activity.
  bool _onKeyEvent(KeyEvent event) {
    if (!event.synthesized) _idleObserver?.recordActivity();
    return false;
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
              // Mark the session authenticated SYNCHRONOUSLY using the roles
              // carried on LoginLoadedState. As an ancestor of the login page
              // this listener fires before the page's success listener, so the
              // session is already authenticated (with roles) when that listener
              // navigates to the `returnUrl` deep link. The previous version
              // awaited a storage read here, which let navigation win the race
              // and bounce the deep link back to /login → home.
              context.read<SessionCubit>().markAuthenticated(roles: state.roles.toSet());
            }
          },
        ),
        BlocListener<MenuBloc, MenuState>(
          listenWhen: (previous, current) => previous.isLogout != current.isLogout,
          listener: (context, state) {
            if (state.isLogout) {
              context.read<SessionCubit>().markLoggedOut();
              // MenuBloc signs out with the error status when the logout could not remove all stored data.
              if (state.status == MenuStateStatus.error) {
                _showNotice((strings) => strings.logout_stored_data_left);
              }
            }
          },
        ),
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: (context, state) {
            switch (state) {
              case SessionAuthenticated():
                _startIdleObserver();
                // Loaded here rather than by one page, since a sign-in can return the user to any page and the top
                // bar shows the account on all of them.
                context.read<AccountBloc>().add(const AccountFetchEvent());
              case SessionUnauthenticated(:final reason):
                _stopIdleObserver();
                _forgetSignedOutUser(context);
                if (reason == SessionExpiredReason.idleTimeout) {
                  _showNotice((strings) => strings.idle_timeout_signed_out);
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
        // A mouse wheel and a trackpad scroll the page on desktop and web without a pointer down or move.
        onPointerSignal: (_) => _idleObserver?.recordActivity(),
        onPointerPanZoomStart: (_) => _idleObserver?.recordActivity(),
        onPointerPanZoomUpdate: (_) => _idleObserver?.recordActivity(),
        child: widget.child,
      ),
    );
  }

  /// The app-scoped blocs outlive the session, so the next user to sign in would see what they hold about the one
  /// who signed out: the account in the top bar and on the dashboard, the authorities loaded with that user's rights,
  /// and the sign-in form state, a password shown in plain text among it.
  void _forgetSignedOutUser(BuildContext context) {
    context.read<AccountBloc>().add(const AccountResetEvent());
    context.read<AuthorityBloc>().add(const AuthorityReset());
    context.read<LoginBloc>().add(const LoginReset());
  }

  /// Shows the [message] of a session ending through the ScaffoldMessenger of the MaterialApp, so it stays on screen
  /// when the login page opens.
  void _showNotice(String Function(S strings) message) {
    final messenger = widget.scaffoldMessengerKey.currentState;
    if (messenger == null) {
      throw StateError('No ScaffoldMessenger is mounted with scaffoldMessengerKey to show a session notice');
    }
    messenger.showSnackBar(SnackBar(content: Text(message(S.of(messenger.context)))));
  }
}
