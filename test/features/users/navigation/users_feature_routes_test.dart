import 'package:flutter_bloc_advance/features/users/navigation/users_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('users feature exposes list and editor routes', () {
    final routeNames = UsersFeatureRoutes.routes.map((route) => route.name).toList();
    final routePaths = UsersFeatureRoutes.routes.map((route) => route.path).toList();

    expect(routeNames, containsAll(<String?>['userList', 'userCreate', 'userEdit', 'userView']));
    expect(routePaths, containsAll(<String>['/user', '/user/new', '/user/:id/edit', '/user/:id/view']));
  });
}
