import 'package:flutter_bloc_advance/configuration/routes.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/change_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:go_router/go_router.dart';

class AuthRoutes {
  static final List<GoRoute> routes = [
    GoRoute(name: 'login', path: ApplicationRoutes.login, builder: (context, state) => LoginScreen()),
    GoRoute(name: 'forgot-password', path: ApplicationRoutes.forgotPassword, builder: (context, state) => ForgotPasswordScreen()),
    GoRoute(name: 'change-password', path: ApplicationRoutes.changePassword, builder: (context, state) => ChangePasswordScreen()),
  ];
}
