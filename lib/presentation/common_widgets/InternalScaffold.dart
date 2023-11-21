import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repository/login_repository.dart';
import '../../data/repository/menu_repository.dart';
import 'drawer/bloc/drawer.dart';
import 'drawer/drawer_widget.dart';

/// InternalScaffold is a wrapper for Scaffold widget that provides a common look and feel for the app.
class InternalScaffold extends StatelessWidget {
  final String? title;
  final Widget body;

  const InternalScaffold({super.key, this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: AppBar(title: Text(title ?? "app bar")),
      drawer: _buildDrawer(context),
      body: body,
    );
  }

  _buildDrawer(BuildContext context) {
    return BlocProvider<DrawerBloc>(
        create: (context) => DrawerBloc(
              loginRepository: LoginRepository(),
          menuRepository: MenuRepository(),
            ),
        child: ApplicationDrawer());
  }
}
