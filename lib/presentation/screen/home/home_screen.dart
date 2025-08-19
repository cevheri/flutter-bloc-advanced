import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';

import '../../common_blocs/account/account.dart';
import '../../common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import '../../common_widgets/drawer/drawer_widget.dart';
import '../../common_widgets/top_actions_widget.dart';
import '../../common_widgets/language_notifier.dart';
import '../dashboard/dashboard_page.dart';
import '../dashboard/bloc/dashboard_cubit.dart';
import '../../../data/repository/dashboard_repository.dart';

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
            return ValueListenableBuilder<String>(
              valueListenable: LanguageNotifier.current,
              builder: (context, lang, _) {
                return Localizations.override(
                  context: context,
                  locale: Locale(lang),
                  child: Scaffold(
                    appBar: AppBar(title: const Text(AppConstants.appName), actions: const [TopActionsWidget()]),
                    key: _scaffoldKey,
                    body: BlocProvider(
                      create: (context) => DashboardCubit(repository: DashboardMockRepository())..load(),
                      child: const DashboardPage(),
                    ),
                    drawer: _buildDrawer(context),
                  ),
                );
              },
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
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withAlpha(128)
                      : Colors.white.withAlpha(128),
                  BlendMode.dstIn,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    debugPrint("HomeScreen _buildDrawer : init-theme ${AppLocalStorageCached.theme}");
    // Reuse existing DrawerBloc from app-level provider to avoid multiple instances
    final drawerBloc = context.read<DrawerBloc>();
    // Ensure menus are loaded once if empty
    if (drawerBloc.state.menus.isEmpty) {
      final initialLanguage = AppLocalStorageCached.language ?? 'en';
      drawerBloc.add(LoadMenus(language: initialLanguage));
    }
    return const ApplicationDrawer();
  }
}
