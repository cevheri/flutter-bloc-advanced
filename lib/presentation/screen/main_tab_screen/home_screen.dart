import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configuration/routes.dart';
import '../../common_blocs/account/account_bloc.dart';

class HomeScreen extends StatelessWidget {
   HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
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
           if (state.status == AccountStatus.success) {
             return Center(
               child: Column(
                 children: [
                 ],
               ),
             );
           }
           return Container();
         },
       ),
     );
   }
}
