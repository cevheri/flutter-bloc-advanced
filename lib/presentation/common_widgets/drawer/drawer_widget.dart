import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:string_2_icon/string_2_icon.dart';

import 'drawer_bloc/drawer_bloc.dart';

class ApplicationDrawer extends StatelessWidget {
  const ApplicationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("ApplicationDrawer build");
    return MultiBlocListener(
      listeners: [
        BlocListener<DrawerBloc, DrawerState>(
          listener: (context, state) {
            //debugPrint("INITIAL - current language : ${AppLocalStorageCached.language}");
            //debugPrint("DrawerBloc listener: ${state.status}");
            if (state.isLogout) {
              context.read<DrawerBloc>().add(Logout());
              AppRouter().push(context, ApplicationRoutesConstants.login);
            }
          },
        ),
        // BlocListener<AccountBloc, AccountState>(
        //   listener: (context, state) {
        //     if (state.status == AccountStatus.failure) {
        //       context.read<DrawerBloc>().add(Logout());
        //       AppRouter().push(context, ApplicationRoutesConstants.login);
        //     }
        //   },
        // ),
      ],
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          final isDarkMode = state.theme == AdaptiveThemeMode.dark;

          // debugPrint("BUILDER - current lang : ${AppLocalStorageCached.language}");
          // debugPrint("BUILDER - state lang : ${state.language}");
          //
          //
          // debugPrint("BUILDER - current theme : ${AppLocalStorageCached.theme}");
          // debugPrint("BUILDER - state theme : ${state.theme}");

          var isEnglish = state.language == 'en';

          final menuNodes = state.menus.where((e) => e.level == 1 && e.active).toList()
            ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          return Drawer(
            key: Key("drawer-${state.language}-${state.theme}"),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuList(menuNodes, state),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    key: const Key("drawer-switch-theme"),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode)],
                    ),
                    value: isDarkMode,
                    onChanged: (value) {
                      //debugPrint("BEGIN:ON_PRESSED.value - ${value}");
                      final newTheme = value ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light;
                      //debugPrint("BEGIN:ON_PRESSED - current theme : ${AppLocalStorageCached.theme}");
                      //debugPrint("BEGIN:ON_PRESSED - current newTheme : ${newTheme}");
                      context.read<DrawerBloc>().add(ChangeThemeEvent(theme: newTheme));
                      if (value) {
                        AdaptiveTheme.of(context).setDark();
                      } else {
                        AdaptiveTheme.of(context).setLight();
                      }
                      Scaffold.of(context).closeDrawer();
                      AppRouter().push(context, ApplicationRoutesConstants.home);

                      //debugPrint("END:ON_PRESSED - current cached theme : ${AppLocalStorageCached.theme}");
                    },
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    key: const Key("drawer-switch-language"),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text(isEnglish ? S.of(context).english : S.of(context).turkish)],
                    ),
                    value: isEnglish,
                    onChanged: (value) {
                      final newLang = value ? 'en' : 'tr';
                      context.read<DrawerBloc>().add(ChangeLanguageEvent(language: newLang));
                      AppRouter().push(context, ApplicationRoutesConstants.home);

                      //debugPrint("ON_PRESSED - current language : ${AppLocalStorageCached.language}");
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList(List<dynamic> menuNodes, DrawerState state) {
    final currentUserRoles = AppLocalStorageCached.roles;
    return ListView.builder(
      itemCount: menuNodes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        //debugPrint("menuNodes.length: ${menuNodes.length}");
        final node = menuNodes[index];
        // debugPrint("node: ${node.name}");

        if (!_hasAccess(node, currentUserRoles)) {
          return const SizedBox.shrink();
        }

        // filter child menus
        final childMenus = state.menus.where((e) => e.parent?.id == node.id && e.active && _hasAccess(e, currentUserRoles)).toList()
          ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

        if (childMenus.isEmpty) {
          // debugPrint("childMenus.isEmpty ");
          // if child menu is leaf, add click event
          return ListTile(
            leading: Icon(String2Icon.getIconDataFromString(node.icon)),
            title: Text(S.of(context).translate_menu_title(node.name), style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              // debugPrint("parent Menu: ${node.name}");
              if (node.leaf && node.url.isNotEmpty) {
                AppRouter().push(context, node.url);
              }
            },
          );
        } else {
          // debugPrint("childMenus.isNotEmpty : ${childMenus.toString()}");
          // if menu is not leaf, use ExpansionTile for child menus
          return ExpansionTile(
            leading: Icon(String2Icon.getIconDataFromString(node.icon)),
            title: Text(S.of(context).translate_menu_title(node.name), style: Theme.of(context).textTheme.bodyMedium),
            children: childMenus.map((childMenu) {
              return ListTile(
                leading: Icon(String2Icon.getIconDataFromString(childMenu.icon)),
                title: Text(S.of(context).translate_menu_title(childMenu.name), style: Theme.of(context).textTheme.bodySmall),
                onTap: () {
                  // debugPrint("child menu name: ${childMenu.name}");
                  if (childMenu.leaf! && childMenu.url.isNotEmpty) {
                    AppRouter().push(context, childMenu.url);
                  }
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Padding _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: drawerButtonLogoutKey,
            style: ElevatedButton.styleFrom(elevation: 0),
            onPressed: () => logOutDialog(context),
            child: Text(S.of(context).logout, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future logOutDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).logout),
          content: Text(S.of(context).logout_sure),
          actions: [
            TextButton(
              key: drawerButtonLogoutYesKey,
              onPressed: () => onLogout(context),
              child: Text(S.of(context).yes),
            ),
            TextButton(
              key: drawerButtonLogoutNoKey,
              onPressed: () => onCancel(context),
              child: Text(S.of(context).no),
            ),
          ],
        );
      },
    );
  }

  void onLogout(context) {
    debugPrint("BEGIN: logout");
    BlocProvider.of<DrawerBloc>(context).add(Logout());
    AppRouter().push(context, ApplicationRoutesConstants.login);
    debugPrint("END: logout");
  }

  void onCancel(context) {
    debugPrint("BEGIN: logout cancel");
    AppRouter().pop(context);
    debugPrint("END: logout cancel");
  }
}

bool _hasAccess(Menu menu, List<String>? userRoles) {
  if (userRoles == null) return false;
  final menuAuthorities = menu.authorities ?? [];
  return menuAuthorities.any((authority) => userRoles.contains(authority));
}
