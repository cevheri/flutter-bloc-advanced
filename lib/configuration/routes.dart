import '../utils/storage.dart';

/// Routes for the application
///
/// This class contains all the routes used in the application.
class ApplicationRoutes {
  static final home = '/';
  static final login = '/login';
  static final info = '/info';
  static final logout = '/logout';
  static final register = '/register';
  static final settings = '/settings';
  static final forgotPassword = '/forgot-password';
  static final changePassword = '/settings/change-password';
  static final account = '/account';
  static final createUser = '/admin/new-user';
  static final listUsers = '/admin/list-users';
}

String initialRouteControl(context) {
  if (getStorageCache["jwtToken"] != null) {
    return "/";
  } else {
    return '/login';
  }
}
