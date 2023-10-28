
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configuration/routes.dart';
import '../../../data/repository/login_repository.dart';
import '../../common_blocs/account/account.dart';
import '../../common_widgets/drawer/bloc/drawer_bloc.dart';
import '../../common_widgets/drawer/drawer_widget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openDrawer(context);
    });
    return _buildBody(context);
  }

  void _openDrawer(BuildContext context) {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildBody(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state.status == AccountStatus.failure) {
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.login, (route) => false);
        } else {}
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          if (state.status == AccountStatus.loaded) {
            return Scaffold(
              appBar: AppBar(
                title: Text("Home Page"),
              ),
              key: _scaffoldKey,
              body: _body(),
              drawer: _buildDrawer(context),
            );
          }
          return Container();
        },
      ),
    );
  }

  _buildDrawer(BuildContext context) {
    return BlocProvider<DrawerBloc>(
        create: (context) => DrawerBloc(
              loginRepository: LoginRepository(),
            ),
        child: ApplicationDrawer());
  }

  Center _body() {
    return Center(
      child: Column(
        children: const [
          Text("Home Page"),
        ],
      ),
    );
  }
}
