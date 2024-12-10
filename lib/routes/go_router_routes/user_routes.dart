import 'package:flutter_bloc_advance/presentation/screen/user/create/create_user_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/edit/edit_user_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:go_router/go_router.dart';

class UserRoutes {
  static final List<GoRoute> routes = [
    GoRoute(name: 'userList', path: '/user', builder: (context, state) => ListUserScreen()),
    GoRoute(name: 'userNew', path: '/user/new', builder: (context, state) => CreateUserScreen()),
    GoRoute(name: 'userEdit', path: '/user/:id/edit', builder: (context, state) => EditUserScreen(id: state.pathParameters['id']!)),
    //GoRoute(name: 'userView'  , path: '/user/:id/view', builder: (context, state) => EditViewScreen(id: state.pathParameters['id']!)),
  ];
}
