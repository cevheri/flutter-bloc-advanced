
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
  static final entityAudit = '/admin/entity-audit';
  static final entityAuditDetail = '/admin/entity-audit/:entityName/:entityId';
  static final logs = '/admin/logs';
  static final logsDetail = '/admin/logs/:logId';
  static final health = '/admin/health';
  static final healthDetail = '/admin/health/:healthkey';
  static final metrics = '/admin/metrics';
  static final metricsDetail = '/admin/metrics/:metricName';
  static final configuration = '/admin/configuration';
  static final docs = '/admin/docs';


}