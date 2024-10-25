import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            if (state.isLogout) {
              Navigator.popUntil(context, ModalRoute.withName(ApplicationRoutes.login));
              Navigator.pushNamed(context, ApplicationRoutes.login);
            }
          },
        ),
        BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state.status == AccountStatus.failure) {
              Navigator.popUntil(context, ModalRoute.withName(ApplicationRoutes.login));
              Navigator.pushNamed(context, ApplicationRoutes.login);
            }
          },
        ),
      ],
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          var parentMenus = [];
          if (state.menus.isEmpty) {
            return Container();
          }
          parentMenus = state.menus.where((element) => element.level == 1).toList();
          parentMenus.sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          return Drawer(
            child: SingleChildScrollView(
              child: ListView.builder(
                itemCount: parentMenus.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  List<Menu> sublistMenu = state.menus.where((element) => element.parent?.id == parentMenus[index].id).toList();
                  sublistMenu.sort((a, b) => a.orderPriority.compareTo(b.orderPriority));
                  return ExpansionTileCard(
                    trailing: sublistMenu.length != 0
                        ? Icon(
                            Icons.keyboard_arrow_down,
                          )
                        : Icon(
                            Icons.keyboard_arrow_right,
                          ),
                    onExpansionChanged: (value) {
                      if (value) {
                        if (sublistMenu.length == 0) {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, parentMenus[index].url);
                        }
                      }
                    },
                    elevation: 0,
                    isThreeLine: false,
                    initiallyExpanded: false,
                    leading: Icon(
                      String2Icon.getIconDataFromString(parentMenus[index].icon),
                    ),
                    title: Text(
                      S.of(context).translate_menu_title(parentMenus[index].name),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
                                String2Icon.getIconDataFromString(sublistMenu[index].icon),
                              ),
                              title: Text(
                                S.of(context).translate_menu_title(sublistMenu[index].name),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, sublistMenu[index].url);
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
}
