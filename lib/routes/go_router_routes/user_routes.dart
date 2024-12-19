import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/editor/user_editor_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:go_router/go_router.dart';

class UserRoutes {
  //@formatter:off
  static final List<GoRoute> routes = [
    GoRoute(name: 'userList',   path: '/user', builder: (context, state) => ListUserScreen()),
    GoRoute(name: 'userCreate', path: '/user/new', builder: (context, state) => const UserEditorScreen(mode: EditorFormMode.create)),
    GoRoute(name: 'userEdit',   path: '/user/:id/edit', builder: (context, state) => UserEditorScreen(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
    GoRoute(name: 'userView',   path: '/user/:id/view', builder: (context, state) => UserEditorScreen(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
  ];
  //@formatter:on
}
