/// Routes for the application
///
/// This class contains all the routes used in the application.
class ApplicationRoutesConstants {
  static const home = '/';

  // Auth routes
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';
  static const loginOtp = '/login-otp';
  static const loginOtpVerify = '/login-otp-verify';

  // Account routes
  static const account = '/account';

  // User routes
  static const userList = '/user';
  static const userView = '/user/:id/view';
  static const userEdit = '/user/:id/edit';
  static const userNew = '/user/new';

  // Settings routes
  static const settings = '/settings';

  // Error routes
  static const notFound = '/not-found';
  static const error = '/error';
  static const error500 = '/error/500';
}
