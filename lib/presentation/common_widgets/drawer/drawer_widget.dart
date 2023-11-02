
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../configuration/routes.dart';
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
        BlocListener<AccountBloc, AccountState>(listener: (context, state) {
          if (state.status == AccountStatus.failure) {
            Navigator.popUntil(context, ModalRoute.withName(ApplicationRoutes.login));
            Navigator.pushNamed(context, ApplicationRoutes.login);
          }
        })
      ],
      child: BlocBuilder<DrawerBloc, DrawerState>(
        builder: (context, state) {
          return _buildStaticDrawer(context);
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
            leading: Icon(Icons.home, size: iconSize,),
            title: Text(S.of(context).drawerMenuHome),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.home),
          ),
          ListTile(
            leading: Icon(Icons.task, size: iconSize,),
            title: Text(S.of(context).drawerTasks),
            onTap: () => Navigator.pushNamed(context, ApplicationRoutes.tasks),
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

}
