import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/task_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/language_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/task/list/bloc/task_list.dart';
import 'package:flutter_bloc_advance/presentation/screen/task/list/task_list_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../configuration/environment.dart';
import '../configuration/routes.dart';
import '../data/repository/account_repository.dart';
import '../data/repository/login_repository.dart';
import '../generated/l10n.dart';
import '../presentation/common_blocs/account/account_bloc.dart';
import '../presentation/screen/account/account_screen.dart';
import '../presentation/screen/home/home_screen.dart';
import '../presentation/screen/login/bloc/login_bloc.dart';
import '../presentation/screen/login/login_screen.dart';
import '../presentation/screen/settings/bloc/settings_bloc.dart';
import '../presentation/screen/settings/settings_screen.dart';

/// Main application widget. This widget is the root of your application.
///
/// It is configured to provide a [ThemeData] based on the current
/// [AdaptiveThemeMode] and to provide a [MaterialApp] with the
/// [AdaptiveThemeMode] as the initial theme mode.
///
class App extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const App({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueGrey,
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      debugShowFloatingThemeButton: true,
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (light, dark) {
        return MaterialApp(
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
          supportedLocales: const [
            Locale('en'), // English
            Locale('tr'), // Turkish
          ],
          locale: Locale('tr'),
          //supportedLocales: context.supportedLocales,
          //localizationsDelegates: context.localizationDelegates,
          routes: {
            ApplicationRoutes.home: (context) {
              return BlocProvider<AccountBloc>(
                  create: (context) =>
                      AccountBloc(accountRepository: AccountRepository())
                        ..add(AccountLoad()),
                  child: HomeScreen());
            },
            ApplicationRoutes.login: (context) {
              return BlocProvider<LoginBloc>(
                  create: (context) =>
                      LoginBloc(loginRepository: LoginRepository()),
                  child: LoginScreen());
            },
            ApplicationRoutes.settings: (context) {
              return BlocProvider<SettingsBloc>(
                  create: (context) =>
                      SettingsBloc(accountRepository: AccountRepository()),
                  child: SettingsScreen());
            },
            ApplicationRoutes.account: (context) {
              return BlocProvider<AccountBloc>(
                  create: (context) =>
                      AccountBloc(accountRepository: AccountRepository())
                        ..add(AccountLoad()),
                  child: AccountsScreen());
            },

            ApplicationRoutes.tasks: (context) {
              return BlocProvider<TaskListBloc>(create: (context) => TaskListBloc(taskRepository: TaskRepository()), child: TaskListScreen());
            },
            ApplicationRoutes.language: (context) {
              return BlocProvider<TaskListBloc>(create: (context) => TaskListBloc(taskRepository: TaskRepository()), child: LanguageScreen());
            },

            // ApplicationRoutes.taskNew: (context) {
            //   return BlocProvider<TaskSaveBloc>(create: (context) => TaskSaveBloc(taskRepository: TaskRepository()), child: TaskSaveScreen());
            // },
          },
        );
      },
    );
  }
}
