//ListOffersScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/l10n.dart';
import '../../../common_blocs/status/status_bloc.dart';
import '../../user/bloc/user_bloc.dart';

class MaturityCalculateScreen extends StatelessWidget {
  MaturityCalculateScreen({super.key});

  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<UserBloc>(context).add(UserList());
    BlocProvider.of<StatusBloc>(context).add(StatusLoadList());

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).calculated_maturity_screen),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return layoutBody(context, 600, 1100, constraints.maxWidth);
          } else if (constraints.maxWidth > 700 && constraints.maxWidth < 900) {
            return layoutBody(context, 600, 1200, constraints.maxWidth);
          } else {
            return Center(
              child: Text(S.of(context).screen_size_error),
            );
          }
        },
      ),
    );
  }

  Column layoutBody(BuildContext context, double min, double max, double maxWidth) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

      ],
    );
  }
}
