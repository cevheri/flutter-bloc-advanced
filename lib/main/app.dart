import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/app_go_router_config.dart';

import '../data/repository/account_repository.dart';
import '../data/repository/authority_repository.dart';
import '../data/repository/city_repository.dart';
import '../data/repository/district_repository.dart';
import '../data/repository/login_repository.dart';
import '../data/repository/menu_repository.dart';
import '../data/repository/user_repository.dart';
import '../presentation/common_blocs/account/account.dart';
import '../presentation/common_blocs/authority/authority_bloc.dart';
import '../presentation/common_blocs/city/city_bloc.dart';
import '../presentation/common_blocs/district/district_bloc.dart';
import '../presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import '../presentation/screen/login/bloc/login.dart';
import '../presentation/screen/user/bloc/user_bloc.dart';

/// Main application widget. This widget is the root of your application.
///
/// It is configured to provide a [ThemeData] based on the current
/// [AdaptiveThemeMode] and to provide a [MaterialApp] with the
/// [AdaptiveThemeMode] as the initial theme mode.
///

class App extends StatelessWidget {
  final String language;
  final AdaptiveThemeMode initialTheme;

  const App({super.key, required this.language, required this.initialTheme});

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

  ThemeData _buildDarkTheme() => ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blueGrey);

  ThemeData _buildLightTheme() => ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.blueGrey);

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
      child: AppGoRouterConfig.routeBuilder(light, dark, language),
    );
  }
}
