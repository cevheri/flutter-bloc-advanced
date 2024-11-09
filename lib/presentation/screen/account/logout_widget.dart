// logout confirmation popup dialog with stateless widget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../common_widgets/drawer/drawer_bloc/drawer_bloc.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlertDialog(
        title: Text(S.of(context).logout),
        content: Text(S.of(context).logout_sure),
        actions: [
          TextButton(
            onPressed: () => onLogout(context),
            child: Text(S.of(context).yes),
          ),
          TextButton(
            onPressed: () => onCancel(context),
            child: Text(S.of(context).no),
          ),
        ],
      ),
    );
  }

  void onLogout(context) {
    BlocProvider.of<DrawerBloc>(context).add(Logout());
    Navigator.pushNamed(context, ApplicationRoutes.login);
  }

  void onCancel(context) {
    Navigator.pushNamed(context, ApplicationRoutes.home);
  }
}
