import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/fetch_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/save_user_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/search_users_usecase.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_list_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_editor_page.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_list_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:go_router/go_router.dart';

class UsersFeatureRoutes {
  static Widget _withListBloc(BuildContext context, Widget child) {
    final repo = context.read<IUserRepository>();
    return BlocProvider(
      create: (_) =>
          UserListBloc(searchUsersUseCase: SearchUsersUseCase(repo), deleteUserUseCase: DeleteUserUseCase(repo)),
      child: child,
    );
  }

  static Widget _withEditorBloc(BuildContext context, Widget child) {
    final repo = context.read<IUserRepository>();
    return BlocProvider(
      create: (_) => UserEditorBloc(fetchUserUseCase: FetchUserUseCase(repo), saveUserUseCase: SaveUserUseCase(repo)),
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
        child: _withListBloc(context, const UserListPage()),
      ),
    ),
    GoRoute(
      name: 'userCreate',
      path: '/user/new',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, const UserEditorPage(mode: EditorFormMode.create)),
      ),
    ),
    GoRoute(
      name: 'userEdit',
      path: '/user/:id/edit',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
      ),
    ),
    GoRoute(
      name: 'userView',
      path: '/user/:id/view',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, UserEditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
      ),
    ),
    GoRoute(
      name: 'userExtendedInfo',
      path: '/user/:id/extended-info',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: DynamicFormsFeatureRoutes.withBloc(
          context,
          UserExtendedInfoPage(userId: state.pathParameters['id']!),
        ),
      ),
    ),
  ];
}
