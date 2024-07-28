import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../configuration/routes.dart';
import '../../../data/repository/login_repository.dart';
import '../../../data/repository/menu_repository.dart';
import '../../../generated/l10n.dart';
import '../../common_blocs/account/account_bloc.dart';
import '../../common_widgets/drawer/bloc/drawer_bloc.dart';
import '../../common_widgets/drawer/drawer_widget.dart';
import 'app_tab_controller.dart';
import 'bottom_navigator_bar.dart';
import 'faq_screen.dart';
import 'home_screen.dart';
import 'web_view_screen.dart';

class ScreenControllerPage extends StatelessWidget {
  ScreenControllerPage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppTabController tabx = Get.put(AppTabController());

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state.status == AccountStatus.failure) {
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
        } else {}
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          if (state.status == AccountStatus.success) {
            return Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).title),
                centerTitle: true,
              ),
              key: _scaffoldKey,
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/img.png"),
                    fit: BoxFit.scaleDown,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.2),
                      BlendMode.dstATop,
                    ),
                    invertColors: false,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: tabx.controller,
                        children: [
                          HomeScreen(),
                          WebViewScreen(content: S.of(context).services_detail),
                          WebViewScreen(content: S.of(context).products_detail),
                          WebViewScreen(content: S.of(context).about_us_detail),
                          WebViewScreen(content: S.of(context).our_references_detail),
                          const FaqListPage(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: BuildFloatingBarState(),
              drawer: _buildDrawer(context),
            );
          }
          return Container();
        },
      ),
    );
  }


  _buildDrawer(BuildContext context) {
    return BlocProvider<DrawerBloc>(
        create: (context) => DrawerBloc(
              loginRepository: LoginRepository(),
              menuRepository: MenuRepository(),
            )..add(LoadMenus()),
        child: ApplicationDrawer());
  }
}
