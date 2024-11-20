import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configuration/routes.dart';
import '../../../data/repository/login_repository.dart';
import '../../../data/repository/menu_repository.dart';
import '../../../generated/l10n.dart';
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
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state.status == AccountStatus.failure) {
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
        }
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          if (state.status == AccountStatus.success) {
            return Scaffold(
              appBar: AppBar(title: Text(S.of(context).description)),
              key: _scaffoldKey,
              body: Center(child: Column(children: [backgroundImage(context)])),
              drawer: _buildDrawer(context),
            );
          }
          return Container();
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
              image: DecorationImage(image: AssetImage("assets/images/logoLight.png"), scale: 1, fit: BoxFit.contain),
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
                image: const AssetImage("assets/images/img.png"),
                colorFilter: ColorFilter.mode(
                    AdaptiveTheme.of(context).mode.isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1), BlendMode.dstIn),
              ),
            ),
          ),
        ),
      );
    }
  }

  _buildDrawer(BuildContext context) {
    return BlocProvider<DrawerBloc>(
      create: (context) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository())..add(LoadMenus()),
      child: const ApplicationDrawer(),
    );
  }
}
