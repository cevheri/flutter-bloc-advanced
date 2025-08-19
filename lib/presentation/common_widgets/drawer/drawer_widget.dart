import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/language_notifier.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/utils/icon_utils.dart';

import 'drawer_bloc/drawer_bloc.dart';

class ApplicationDrawer extends StatelessWidget {
  const ApplicationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("ApplicationDrawer build");
    return BlocListener<DrawerBloc, DrawerState>(
      listener: (context, state) {
        //debugPrint("DrawerBloc listener: ${state.status}");
        if (state.isLogout) {
          AppRouter().push(context, ApplicationRoutesConstants.login);
        }
      },
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, drawerState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkMode = themeState.isDarkMode;

              var isEnglish = drawerState.language == 'en';

              final menuNodes = drawerState.menus.where((e) => e.level == 1 && e.active).toList()
                ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

              return ValueListenableBuilder<String>(
                valueListenable: LanguageNotifier.current,
                builder: (context, lang, _) {
                  return Drawer(
                    key: Key("drawer-${drawerState.language}-$isDarkMode"),
                    child: SingleChildScrollView(
                      child: Column(
                        spacing: 16,
                        children: [
                          _buildMenuList(menuNodes, drawerState),
                          SwitchListTile(
                            key: const Key("drawer-switch-theme"),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode)],
                            ),
                            value: isDarkMode,
                            onChanged: (value) {
                              debugPrint("Theme switch clicked! Value: $value, Current isDarkMode: $isDarkMode");
                              // Tema değişikliği ThemeBloc ile yönetiliyor
                              context.read<ThemeBloc>().add(const ToggleBrightness());
                              debugPrint("ToggleBrightness event sent to ThemeBloc");
                              // Drawer'ı kapatma - tema değişikliği için drawer açık kalmalı
                              // Scaffold.of(context).closeDrawer();
                              // Stay on the same route; theme change rebuilds automatically
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveThumbColor: Theme.of(context).colorScheme.outline,
                            inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          ),
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
                              // Stay on the same route; localization builder will rebuild
                            },
                          ),

                          _buildLogoutButton(context),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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
        final childMenus =
            state.menus.where((e) => e.parent?.id == node.id && e.active && _hasAccess(e, currentUserRoles)).toList()
              ..sort((a, b) => a.orderPriority.compareTo(b.orderPriority));

        if (childMenus.isEmpty) {
          // debugPrint("childMenus.isEmpty ");
          // if child menu is leaf, add click event
          return ListTile(
            leading: Icon(getIconFromString(node.icon)),
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
            leading: Icon(getIconFromString(node.icon)),
            title: Text(S.of(context).translate_menu_title(node.name), style: Theme.of(context).textTheme.bodyMedium),
            children: childMenus.map((childMenu) {
              return ListTile(
                leading: Icon(getIconFromString(childMenu.icon)),
                title: Text(
                  S.of(context).translate_menu_title(childMenu.name),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
          child: FilledButton(
            key: drawerButtonLogoutKey,
            onPressed: () => _handleLogout(context),
            child: Text(S.of(context).logout, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmationDialog.show(context: context, type: DialogType.logout) ?? false;

    if (shouldLogout && context.mounted) {
      debugPrint("BEGIN: logout");
      BlocProvider.of<DrawerBloc>(context).add(Logout());
      AppRouter().push(context, ApplicationRoutesConstants.login);
      debugPrint("END: logout");
    }
  }
}

bool _hasAccess(Menu menu, List<String>? userRoles) {
  if (userRoles == null) return false;
  final menuAuthorities = menu.authorities ?? [];
  return menuAuthorities.any((authority) => userRoles.contains(authority));
}
