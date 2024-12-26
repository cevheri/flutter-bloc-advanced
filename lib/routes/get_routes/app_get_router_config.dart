import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/presentation/screen/account/account_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/change_password/change_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/forgot_password/forgot_password_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/home/home_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/login/login_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/settings_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:get/get.dart';

/// GetX Router Configuration
/// WARN: Not Tested
class AppGetRouterConfig {
  // static final List<GetPage> routes = [
  //   GetPage(name: 'login', page: () => LoginScreen()),
  //   GetPage(name: 'forgot-password', page: () => ForgotPasswordScreen()),
  //   GetPage(name: 'change-password', page: () => ChangePasswordScreen()),
  //   GetPage(name: 'home', page: () => HomeScreen()),
  //   GetPage(name: 'settings', page: () => SettingsScreen()),
  //   GetPage(name: 'account', page: () => AccountScreen()),
  //   GetPage(name: 'user', page: () => ListUserScreen()),
  //   //TODO user create, edit, view in GetX
  //   // GetPage(name:'user/:id', page:()=>ViewUserScreen()),
  //   // GetPage(name: 'user/new', page: () => CreateUserScreen()),
  //   // GetPage(name: 'user/:id/edit', page: () => EditUserScreen(id: "")),
  //
  //   // last item is the 404 page
  //   GetPage(name: 'not-found', page: () => const Scaffold(body: Center(child: Text('Not Found')))),
  // ];
  //
  // static GetMaterialApp routeBuilder(ThemeData light, ThemeData dark, String language) {
  //   return GetMaterialApp(
  //     title: 'Flutter Bloc Advance',
  //     theme: light,
  //     darkTheme: dark,
  //     themeMode: ThemeMode.system,
  //     getPages: routes,
  //     initialRoute: 'login',
  //     unknownRoute: routes.last,
  //   );
  // }
}
