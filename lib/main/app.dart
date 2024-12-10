import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/route/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../configuration/environment.dart';
import '../configuration/routes.dart';
import '../data/repository/account_repository.dart';
import '../data/repository/authority_repository.dart';
import '../data/repository/city_repository.dart';
import '../data/repository/district_repository.dart';
import '../data/repository/login_repository.dart';
import '../data/repository/menu_repository.dart';
import '../data/repository/user_repository.dart';
import '../generated/l10n.dart';
import '../presentation/common_blocs/account/account.dart';
import '../presentation/common_blocs/authority/authority_bloc.dart';
import '../presentation/common_blocs/city/city_bloc.dart';
import '../presentation/common_blocs/district/district_bloc.dart';
import '../presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import '../presentation/screen/account/account_screen.dart';
import '../presentation/screen/change_password/bloc/change_password_bloc.dart';
import '../presentation/screen/change_password/change_password_screen.dart';
import '../presentation/screen/forgot_password/bloc/forgot_password_bloc.dart';
import '../presentation/screen/forgot_password/forgot_password_screen.dart';
import '../presentation/screen/home/home_screen.dart';
import '../presentation/screen/login/bloc/login.dart';
import '../presentation/screen/login/login_screen.dart';
import '../presentation/screen/register/bloc/register_bloc.dart';
import '../presentation/screen/register/register_screen.dart';
import '../presentation/screen/settings/bloc/settings.dart';
import '../presentation/screen/settings/settings_screen.dart';
import '../presentation/screen/user/bloc/user_bloc.dart';
import '../presentation/screen/user/create/create_user_screen.dart';
import '../presentation/screen/user/list/list_user_screen.dart';

/// Main application widget. This widget is the root of your application.
///
/// It is configured to provide a [ThemeData] based on the current
/// [AdaptiveThemeMode] and to provide a [MaterialApp] with the
/// [AdaptiveThemeMode] as the initial theme mode.
///

class App extends StatelessWidget {
  final String language;
  final AdaptiveThemeMode initialTheme;

  App({super.key, required this.language, required this.initialTheme});

  @override
  Widget build(BuildContext context) {
    return buildHomeApp();
  }

  AdaptiveTheme buildHomeApp() {
    return AdaptiveTheme(
      light: _buildLightTheme(),
      dark: _buildDarkTheme(),
      debugShowFloatingThemeButton: false,
      initial: initialTheme,
      builder: (light, dark) => _buildMultiBlocProvider(light, dark),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blueGrey);
  }

  ThemeData _buildLightTheme() {
    return ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.blueGrey);
  }

  MultiBlocProvider _buildMultiBlocProvider(ThemeData light, ThemeData dark) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (_) => LoginBloc(repository: LoginRepository())),
        BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(repository: AuthorityRepository())),
        BlocProvider<AccountBloc>(create: (_) => AccountBloc(repository: AccountRepository())),
        BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
        BlocProvider<CityBloc>(create: (_) => CityBloc(repository: CityRepository())),
        BlocProvider<DistrictBloc>(create: (_) => DistrictBloc(repository: DistrictRepository())),
        BlocProvider<DrawerBloc>(create: (_) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository())),
      ],
      child: _buildMaterialApp(light, dark),
    );
  }

  MaterialApp _buildMaterialApp(ThemeData light, ThemeData dark) {
    return MaterialApp.router(
      theme: light,
      darkTheme: dark,
      debugShowCheckedModeBanner: ProfileConstants.isDevelopment,
      debugShowMaterialGrid: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: Locale(language),
      routerConfig: AppRouter.router,
    );
  }

}
