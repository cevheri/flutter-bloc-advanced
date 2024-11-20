import 'package:flutter_bloc_advance/configuration/local_storage.dart';

/// Routes for the application
///
/// This class contains all the routes used in the application.
class ApplicationRoutes {
  static const home = '/';
  static const login = '/login';
  static const info = '/info';
  static const logout = '/logout';
  static const register = '/register';
  static const settings = '/settings';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/settings/change-password';
  static const account = '/account';
  static const createUser = '/admin/new-user';
  static const listUsers = '/admin/list-users';
}

String initialRouteControl() {
  if (AppLocalStorageCached.jwtToken != null) {
    return ApplicationRoutes.home;
  } else {
    return ApplicationRoutes.login;
  }
}
