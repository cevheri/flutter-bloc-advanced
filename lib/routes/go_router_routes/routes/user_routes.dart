import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/editor/user_editor_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/screen/user/bloc/user.dart';

class UserRoutes {
  static UserRepository? _userRepository;
  static UserBloc? _userBloc;

  static AuthorityBloc? _authorityBloc;
  static AuthorityRepository? _authorityRepository;

  static void init({
    UserBloc? userBloc,
    UserRepository? userRepository,
    AuthorityBloc? authorityBloc,
    AuthorityRepository? authorityRepository,
  }) {
    _userBloc = userBloc;
    _userRepository = userRepository;
    _authorityBloc = authorityBloc;
    _authorityRepository = authorityRepository;
  }

  static void dispose() {
    _userBloc = null;
    _userRepository = null;
    _authorityBloc = null;
    _authorityRepository = null;
  }

  static UserRepository get userRepository => _userRepository ?? UserRepository();
  static UserBloc get userBloc => _userBloc ?? UserBloc(repository: userRepository);

  static AuthorityRepository get authorityRepository => _authorityRepository ?? AuthorityRepository();
  static AuthorityBloc get authorityBloc => _authorityBloc ?? AuthorityBloc(repository: authorityRepository);

  static Widget _blocProvider(Widget child) {
    return BlocProvider.value(value: userBloc, child: child);
  }

  static final List<GoRoute> routes = <GoRoute>[
    GoRoute(
      name: 'userList',
      path: '/user',
      pageBuilder: (context, state) =>
          appTransitionPage(state: state, type: AppPageTransitionType.fade, child: _blocProvider(ListUserScreen())),
    ),
    GoRoute(
      name: 'userCreate',
      path: '/user/new',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _blocProvider(const UserEditorScreen(mode: EditorFormMode.create)),
      ),
    ),
    GoRoute(
      name: 'userEdit',
      path: '/user/:id/edit',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _blocProvider(UserEditorScreen(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
      ),
    ),
    GoRoute(
      name: 'userView',
      path: '/user/:id/view',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _blocProvider(UserEditorScreen(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
      ),
    ),
  ];
}
