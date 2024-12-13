import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:string_2_icon/string_2_icon.dart';

import '../../../generated/l10n.dart';
import '../../common_blocs/account/account.dart';
import 'drawer_bloc/drawer_bloc.dart';

class ApplicationDrawer extends StatelessWidget {
  const ApplicationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: _buildBlocListener(context),
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          if (state.menus.isEmpty) {
            return const Center(child: Text('No menu found'));
          }
          final menuNodes = state.menus.where((e) => e.level == 1 && e.active).toList()
            ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          return Drawer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuList(menuNodes, state),
                  const SizedBox(height: 20),
                  const ThemeSwitchButton(),
                  const SizedBox(height: 20),
                  const LanguageSwitchButton(),
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
        debugPrint("menuNodes.length: ${menuNodes.length}");
        final node = menuNodes[index];
        debugPrint("node: ${node.name}");

        if (!_hasAccess(node, currentUserRoles)) {
          return const SizedBox.shrink();
        }

        // filter child menus
        final childMenus = state.menus.where((e) => e.parent?.id == node.id && e.active && _hasAccess(e, currentUserRoles)).toList()
          ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

        if (childMenus.isEmpty) {
          debugPrint("childMenus.isEmpty ");
          // if child menu is leaf, add click event
          return ListTile(
            leading: Icon(String2Icon.getIconDataFromString(node.icon)),
            title: Text(S.of(context).translate_menu_title(node.name), style: Theme.of(context).textTheme.bodyMedium),
            onTap: () {
              debugPrint("parent Menu: ${node.name}");
              if (node.leaf && node.url.isNotEmpty) {
                AppRouter().push(context, node.url);
              }
            },
          );
        } else {
          debugPrint("childMenus.isNotEmpty : ${childMenus.toString()}");
          // if menu is not leaf, use ExpansionTile for child menus
          return ExpansionTile(
            leading: Icon(String2Icon.getIconDataFromString(node.icon)),
            title: Text(S.of(context).translate_menu_title(node.name), style: Theme.of(context).textTheme.bodyMedium),
            children: childMenus.map((childMenu) {
              return ListTile(
                leading: Icon(String2Icon.getIconDataFromString(childMenu.icon)),
                title: Text(S.of(context).translate_menu_title(childMenu.name), style: Theme.of(context).textTheme.bodySmall),
                onTap: () {
                  debugPrint("child menu name: ${childMenu.name}");
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

  _buildBlocListener(BuildContext context) {
    return [
      BlocListener<DrawerBloc, DrawerState>(
        listener: (context, state) {
          if (state.isLogout) {
            context.read<DrawerBloc>().add(Logout());
            AppRouter().push(context, ApplicationRoutesConstants.login);
          }
        },
      ),
      BlocListener<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state.status == AccountStatus.failure) {
            context.read<DrawerBloc>().add(Logout());
            AppRouter().push(context, ApplicationRoutesConstants.login);
          }
        },
      ),
    ];
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
  if(userRoles == null) return false;
  final menuAuthorities = menu.authorities ?? [];
  return menuAuthorities.any((authority) => userRoles.contains(authority));
}

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode.isDark;

    return SwitchListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        ],
      ),
      value: isDarkMode,
      onChanged: (value) {
        if (value) {
          AdaptiveTheme.of(context).setDark();
        } else {
          AdaptiveTheme.of(context).setLight();
        }
      },
    );
  }
}

class LanguageSwitchButton extends StatefulWidget {
  const LanguageSwitchButton({super.key});

  @override
  LanguageSwitchButtonState createState() => LanguageSwitchButtonState();
}

class LanguageSwitchButtonState extends State<LanguageSwitchButton> {
  bool isTurkish = true;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final lang = await AppLocalStorage().read(StorageKeys.language.name);
    setState(() {
      isTurkish = lang == 'tr';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isTurkish ? S.of(context).turkish : S.of(context).english),
        ],
      ),
      value: isTurkish,
      onChanged: (value) async {
        isTurkish = value;

        final lang = isTurkish ? 'tr' : 'en';
        await AppLocalStorage().save(StorageKeys.language.name, lang);
        await S.load(Locale(isTurkish ? 'tr' : 'en'));
        if (mounted) {
          setState(
            () => AppRouter().push(context, ApplicationRoutesConstants.home),
          );
        }
      },
    );
  }
}
