import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:string_2_icon/string_2_icon.dart';

import '../../../configuration/routes.dart';
import '../../../data/models/menu.dart';
import '../../../generated/l10n.dart';
import '../../common_blocs/account/account.dart';
import 'bloc/drawer.dart';

class ApplicationDrawer extends StatelessWidget {
  const ApplicationDrawer({super.key});

  static final double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DrawerBloc, DrawerState>(
          listener: (context, state) {
            print("DrawerBloc listener: ${state.isLogout}");

            if (state.isLogout) {
              Navigator.popUntil(
                  context, ModalRoute.withName(ApplicationRoutes.login));
              Navigator.pushNamed(context, ApplicationRoutes.login);
            }
          },
        ),
        BlocListener<AccountBloc, AccountState>(listener: (context, state) {
          if (state.status == AccountStatus.failure) {
            Navigator.popUntil(
                context, ModalRoute.withName(ApplicationRoutes.login));
            Navigator.pushNamed(context, ApplicationRoutes.login);
          }
        })
      ],
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          var parentMenus = [];
          if (state.menus.isEmpty) {
            return Text("Empty");
          }
          parentMenus =
              state.menus.where((element) => element.level == 1).toList();
          parentMenus
              .sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          return Drawer(
            child: SingleChildScrollView(
              child: ListView.builder(
                itemCount: parentMenus.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  List<Menu> sublistMenu = state.menus
                      .where((element) =>
                          element.parent?.id == parentMenus[index].id)
                      .toList();
                  sublistMenu.sort(
                      (a, b) => a.orderPriority.compareTo(b.orderPriority));
                  return ExpansionTileCard(
                    elevation: 0,
                    isThreeLine: false,
                    initiallyExpanded: false,
                    leading: Icon(
                      String2Icon.getIconDataFromString(
                          parentMenus[index].icon),
                    ),
                    title: Text(
                      S.of(context).translate_menu_title(
                      parentMenus[index].name),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    onExpansionChanged: (value) {
                      print("onExpansionChanged: $value");
                      print("parentMenus[index].url: ${parentMenus[index].url}");
                      if (index > 0) {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, parentMenus[index].url);
                      }
                    },
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: ListView.builder(
                          itemCount: sublistMenu.length,
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(
                                String2Icon.getIconDataFromString(
                                    sublistMenu[index].icon),
                              ),
                              title: Text(
                                S.of(context).translate_menu_title(
                                sublistMenu[index].name),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                    context, sublistMenu[index].url);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget header(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Text(
        "Erpet CRM",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  //TODO : Add your dynamic menu items here and navigate to the corresponding routes

  /// Sample static drawer
  Drawer _buildStaticDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: <Widget>[
          header(context),
          ListTile(
            leading: Icon(
              Icons.home,
              size: iconSize,
            ),
            title: Text(S.of(context).drawerMenuHome),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.home),
          ),
          ListTile(
            leading: Icon(
              Icons.task,
              size: iconSize,
            ),
            title: Text(S.of(context).drawerTasks),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.tasks),
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              size: iconSize,
            ),
            title: Text(S.of(context).drawerSettingsTitle),
            onTap: () =>
                Navigator.pushNamed(context, ApplicationRoutes.settings),
          ),
          ListTile(
              leading: Icon(
                Icons.exit_to_app,
                size: iconSize,
              ),
              title: Text(S.of(context).drawerLogoutTitle),
              onTap: () => context.read<DrawerBloc>().add(Logout())),
          Divider(thickness: 2),
        ],
      ),
    );
  }
}
