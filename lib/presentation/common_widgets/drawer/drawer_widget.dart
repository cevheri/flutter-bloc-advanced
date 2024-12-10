import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:string_2_icon/string_2_icon.dart';

import '../../../configuration/routes.dart';
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
          final parentMenus = state.menus.where((e) => e.level == 1 && e.active).toList()
            ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

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

  Widget _buildMenuList(List<dynamic> parentMenus, DrawerState state) {
    return ListView.builder(
      itemCount: parentMenus.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final parentMenu = parentMenus[index];
        // Filter child menus
        final childMenus = state.menus.where((menu) => menu.parent?.id == parentMenu.id && menu.active).toList()
          ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

        return ExpansionTile(
          leading: Icon(String2Icon.getIconDataFromString(parentMenu.icon)),
          title: Text(
            S.of(context).translate_menu_title(parentMenu.name),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          children: childMenus.map((childMenu) {
            return ListTile(
              leading: Icon(String2Icon.getIconDataFromString(childMenu.icon)),
              title: Text(
                S.of(context).translate_menu_title(childMenu.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.pop(context);
                context.go(childMenu.url);
              },
            );
          }).toList(),
        );
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
            context.go(ApplicationRoutes.login);
          }
        },
      ),
      BlocListener<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state.status == AccountStatus.failure) {
            context.read<DrawerBloc>().add(Logout());
            context.go(ApplicationRoutes.login);
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
    Navigator.pop(context);
    context.go(ApplicationRoutes.login);
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
          setState(
            () => context.go(ApplicationRoutes.home),
          );
        }
      },
    );
  }
}
