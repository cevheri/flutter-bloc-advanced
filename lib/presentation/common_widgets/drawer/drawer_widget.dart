
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../common_blocs/account/account.dart';
import 'bloc/drawer.dart';

class ApplicationDrawer extends StatelessWidget {
  const ApplicationDrawer({super.key});

  static final double iconSize = 30;
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


  ListTile buildLogoutListTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.exit_to_app, size: 30),
      title: Text("Logout"),
      onTap: () => context.read<DrawerBloc>().add(Logout()),
    );
  }
  Drawer buildStaticDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: <Widget>[
          header(context),
          ListTile(
            leading: Icon(Icons.home, size: iconSize,),
            title: Text(S.of(context).drawerMenuHome),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.main),
          ),
          ListTile(
            leading: Icon(Icons.settings, size: iconSize,),
            title: Text(S.of(context).drawerSettingsTitle),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.settings),
          ),
          ListTile(
              leading: Icon(Icons.exit_to_app, size: iconSize,),
              title: Text(S.of(context).drawerLogoutTitle),
              onTap: () => context.read<DrawerBloc>().add(Logout())
          ),
          Divider(thickness: 2),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // account and draw multibloc listener

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
        BlocListener<AccountBloc, AccountState>(listener: (context, state) {
          if (state.status == AccountStatus.failure) {
            Navigator.popUntil(context, ModalRoute.withName(ApplicationRoutes.login));
            Navigator.pushNamed(context, ApplicationRoutes.login);
          }
        })
      ],
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          return Drawer(
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  header(context),
                  // buildMenu(context, MenuListCache.menus, 1),
                  //buildStaticDrawer(context),
                  ListTile(
                    leading: Icon(Icons.home, size: iconSize,),
                    title: Text(S.of(context).drawerMenuHome),
                    onTap: () => Navigator.pushNamed(context, ApplicationRoutes.main),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, size: iconSize,),
                    title: Text(S.of(context).drawerSettingsTitle),
                    onTap: () => Navigator.pushNamed(context, ApplicationRoutes.settings),
                  ),
                  buildLogoutListTile(context),
                  Divider(thickness: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
