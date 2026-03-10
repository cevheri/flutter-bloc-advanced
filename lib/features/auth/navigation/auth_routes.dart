import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/change_password_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

class AuthFeatureRoutes {
  static final List<GoRoute> routes = [
    GoRoute(name: 'login', path: ApplicationRoutesConstants.login, builder: (context, state) => const LoginScreen()),
    GoRoute(
      name: 'login-otp',
      path: ApplicationRoutesConstants.loginOtp,
      builder: (context, state) => OtpEmailScreen(),
    ),
    GoRoute(
      name: 'login-otp-verify',
      path: '/login-otp-verify/:email',
      builder: (context, state) => OtpVerifyScreen(email: state.pathParameters['email']!),
    ),
    GoRoute(
      name: 'forgot-password',
      path: ApplicationRoutesConstants.forgotPassword,
      builder: (context, state) => BlocProvider(
        create: (_) => ForgotPasswordBloc(repository: context.read<IAccountRepository>()),
        child: ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      name: 'change-password',
      path: ApplicationRoutesConstants.changePassword,
      builder: (context, state) => BlocProvider(
        create: (_) => ChangePasswordBloc(repository: context.read<IAccountRepository>()),
        child: ChangePasswordScreen(),
      ),
    ),
    GoRoute(
      name: 'register',
      path: ApplicationRoutesConstants.register,
      builder: (context, state) => BlocProvider(
        create: (_) => RegisterBloc(repository: context.read<IAccountRepository>()),
        child: RegisterScreen(),
      ),
    ),
  ];
}
