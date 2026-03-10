import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:go_router/go_router.dart';

class UsersFeatureRoutes {
  static Widget _withUserBloc(BuildContext context, Widget child) {
    return BlocProvider(
      create: (_) => UserBloc(
        searchUsersUseCase: SearchUsersUseCase(context.read<IUserRepository>()),
        fetchUserUseCase: FetchUserUseCase(context.read<IUserRepository>()),
        saveUserUseCase: SaveUserUseCase(context.read<IUserRepository>()),
        deleteUserUseCase: DeleteUserUseCase(context.read<IUserRepository>()),
      ),
      child: child,
    );
  }

  static final List<GoRoute> routes = <GoRoute>[
    GoRoute(
      name: 'userList',
      path: '/user',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.fade,
        child: _withUserBloc(context, const UserListPage()),
      ),
    ),
    GoRoute(
      name: 'userCreate',
      path: '/user/new',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withUserBloc(context, const UserEditorPage(mode: EditorFormMode.create)),
      ),
    ),
    GoRoute(
      name: 'userEdit',
      path: '/user/:id/edit',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withUserBloc(context, UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
      ),
    ),
    GoRoute(
      name: 'userView',
      path: '/user/:id/view',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withUserBloc(context, UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
      ),
    ),
  ];
}
