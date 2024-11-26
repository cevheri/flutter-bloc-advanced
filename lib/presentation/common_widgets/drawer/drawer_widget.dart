import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/utils/security_utils.dart';
import 'package:string_2_icon/string_2_icon.dart';

import '../../../configuration/routes.dart';
import '../../../data/models/menu.dart';
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
          var parentMenus = [];
          if (state.menus.isEmpty) {
            return Container();
          }
          parentMenus = state.menus.where((element) => element.level == 1).toList();
          parentMenus.sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

          return Drawer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuList(parentMenus, state),
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

  ListView _buildMenuList(List<dynamic> parentMenus, DrawerState state) {
    return ListView.builder(
      itemCount: parentMenus.length,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        if (SecurityUtils.isCurrentUserAdmin() && parentMenus[index].name == 'userManagement') {
          return _buildMenuListUserManagement(state, parentMenus, index, context);
        } else if (SecurityUtils.isCurrentUserAdmin() && parentMenus[index].name == 'userManagement') {
          return Container();
        } else {
          return _buildMenuListListTile(parentMenus, index, context);
        }
      },
    );
  }

  ListTile _buildMenuListListTile(List<dynamic> parentMenus, int index, BuildContext context) {
    return ListTile(
      leading: Icon(String2Icon.getIconDataFromString(parentMenus[index].icon)),
      title: Text(S.of(context).translate_menu_title(parentMenus[index].name), style: Theme.of(context).textTheme.bodyMedium),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, parentMenus[index].url);
      },
    );
  }

  ExpansionTileCard _buildMenuListUserManagement(DrawerState state, List<dynamic> parentMenus, int index, BuildContext context) {
    List<Menu> sublistMenu = state.menus.where((element) => element.parent?.id == parentMenus[index].id).toList();
    sublistMenu.sort((a, b) => a.orderPriority.compareTo(b.orderPriority));
    return ExpansionTileCard(
      trailing: sublistMenu.isNotEmpty ? const Icon(Icons.keyboard_arrow_down) : const Icon(Icons.keyboard_arrow_right),
      onExpansionChanged: (value) {
        if (value) {
          if (sublistMenu.isEmpty) {
            Navigator.pop(context);
            Navigator.pushNamed(context, parentMenus[index].url);
          }
        }
      },
      elevation: 0,
      isThreeLine: false,
      initiallyExpanded: false,
      leading: Icon(String2Icon.getIconDataFromString(parentMenus[index].icon)),
      title: Text(S.of(context).translate_menu_title(parentMenus[index].name), style: Theme.of(context).textTheme.bodyLarge),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ListView.builder(
            itemCount: sublistMenu.length,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
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
  }

  _buildBlocListener(BuildContext context) {
    return [
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
    BlocProvider.of<DrawerBloc>(context).add(Logout());
    Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
  }

  void onCancel(context) {
    Navigator.pop(context);
  }
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
          setState(() {
            Navigator.pushNamed(context, ApplicationRoutes.home);
          });
        }
      },
    );
  }
}
