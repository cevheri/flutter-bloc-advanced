
/// Routes for the application
///
/// This class contains all the routes used in the application.
class AppRoutes {

  static final login = '/';
  static final register = '/register';
  static final main = '/main';
  static final settings = '/settings';
  static final forgotPassword = '/forgot-password';
  static final changePassword = '/change-password';
  static final account = '/account';
  static final admin = '/admin';
  static final userManagement = '/admin/user-management';
  static final userManagementDetail = '/admin/user-management/:login';
  static final logs = '/admin/logs';
  static final logsDetail = '/admin/logs/:logId';
  static final configuration = '/admin/configuration';
  static final tasks = '/tasks';
  static final tasksDetail = '/tasks/:id';
  static final taskNew = '/tasks/new';
  static final taskEdit = '/tasks/:id/edit';
  static final taskDelete = '/tasks/:id/delete';
  static final taskComplete = '/tasks/:id/complete';

}