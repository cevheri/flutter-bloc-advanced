import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';

import '../../../data/repository/login_repository.dart';
import '../../../data/repository/menu_repository.dart';
import '../../common_blocs/account/account.dart';
import '../../common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import '../../common_widgets/drawer/drawer_widget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    debugPrint("HomeScreen _buildBody theme: ${AppLocalStorageCached.theme}");
    return BlocProvider(
      create: (context) {
        //debugPrint("HomeScreen account blocProvider");
        return AccountBloc(repository: AccountRepository())..add(const AccountFetchEvent());
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) {
          return current.status != previous.status;
          // if(previous.status != current.status) {
          //   debugPrint("HomeScreen account bloc builder: ${current.status}");
          // }
          // return current.account != null;
        },
        builder: (context, state) {
          debugPrint("HomeScreen account bloc builder: ${state.status}");
          if (state.status == AccountStatus.success) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(AppConstants.appName),
              ),
              key: _scaffoldKey,
              body: Center(child: Column(children: [backgroundImage(context)])),
              drawer: _buildDrawer(context),
            );
          }

          if (state.status == AccountStatus.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // else {
          debugPrint("Unexpected state : ${state.toString()}");
          //return Scaffold(body: Center(child: Text("Home Screen Unexpected state : ${state.props}   ${state.toString()}")));
          return Container();
          // }
        },
      ),
    );
  }

  Widget backgroundImage(BuildContext context) {
    // dark or light mode row decoration
    if (Theme.of(context).brightness == Brightness.dark) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(200),
          child: Container(
            height: 300,
            width: 300,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage(LocaleConstants.logoLightUrl), scale: 1, fit: BoxFit.contain),
            ),
          ),
        ),
      );
    } else {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(LocaleConstants.defaultImgUrl),
                colorFilter: ColorFilter.mode(
                    AdaptiveTheme.of(context).mode.isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1), BlendMode.dstIn),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    debugPrint("HomeScreen _buildDrawer : init-theme ${AppLocalStorageCached.theme}");
    AdaptiveThemeMode initialAppThemeType;
    if (AppLocalStorageCached.theme == 'light') {
      initialAppThemeType = AdaptiveThemeMode.light;
    } else {
      initialAppThemeType = AdaptiveThemeMode.dark;
    }
    final initialAppLanguage = AppLocalStorageCached.language ?? 'en';
    return BlocProvider<DrawerBloc>(
      create: (context) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository())
        ..add(
          LoadMenus(language: initialAppLanguage, theme: initialAppThemeType),
        ),
      child: const ApplicationDrawer(),
    );
  }
}
