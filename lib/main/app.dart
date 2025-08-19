import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/web_back_button_disabler.dart';
import 'package:flutter_bloc_advance/routes/go_router_routes/app_go_router_config.dart';

import '../data/repository/account_repository.dart';
import '../data/repository/authority_repository.dart';
import '../data/repository/login_repository.dart';
import '../data/repository/menu_repository.dart';
import '../presentation/common_blocs/account/account.dart';
import '../presentation/common_blocs/authority/authority_bloc.dart';
import '../presentation/common_blocs/theme/theme_bloc.dart';
import '../presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import '../presentation/screen/login/bloc/login.dart';
import '../presentation/design_system/theme/app_theme.dart';

/// Main application widget. This widget is the root of your application.
///
/// It is configured to provide a [ThemeData] based on the current
/// ThemeBloc state and to provide a [MaterialApp] with the
/// theme management through ThemeBloc.
///

class App extends StatelessWidget {
  final String language;

  const App({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return buildHomeApp();
  }

  Widget buildHomeApp() {
    return _buildMultiBlocProvider();
  }

  MultiBlocProvider _buildMultiBlocProvider() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (_) => LoginBloc(repository: LoginRepository())),
        BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(repository: AuthorityRepository())),
        BlocProvider<AccountBloc>(create: (_) => AccountBloc(repository: AccountRepository())),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()..add(const LoadTheme())),
        BlocProvider<DrawerBloc>(
          create: (_) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository()),
        ),
      ],
      child: _buildAdaptiveThemeWrapper(),
    );
  }

  Widget _buildAdaptiveThemeWrapper() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        debugPrint("Main App: ThemeBloc state - isDarkMode: ${themeState.isDarkMode}, palette: ${themeState.palette}");
        // Use ThemeBloc's isDarkMode instead of system brightness
        final brightness = themeState.isDarkMode ? Brightness.dark : Brightness.light;
        final currentTheme = brightness == Brightness.light
            ? AppTheme.light(themeState.palette)
            : AppTheme.dark(themeState.palette);

        debugPrint("Main App: Building theme with brightness: $brightness");
        return WebBackButtonDisabler(
          child: AppGoRouterConfig.routeBuilder(
            currentTheme,
            AppTheme.dark(themeState.palette),
            language,
            themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          ),
        );
      },
    );
  }
}
