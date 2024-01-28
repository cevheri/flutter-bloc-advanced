import 'package:flutter_bloc_advance/configuration/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../../common_blocs/account/account_bloc.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen() : super(key: ApplicationKeys.accountsScreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).account),
    );
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: 50),
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            if (state.account == null) {
              return Container();
            }

            return Column(
              children: [
                _buildAccountInfo(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  _buildAccountInfo(BuildContext context, AccountState state) {
    return Column(
      children: [
        _buildAccountInfoItem(
          context,
          S.of(context).first_name,
          state.account!.firstName,
          Icons.person,
        ),
        _buildAccountInfoItem(
          context,
          S.of(context).last_name,
          state.account!.lastName,
          Icons.person,
        ),
        _buildAccountInfoItem(
          context,
          S.of(context).email,
          state.account!.email,
          Icons.email,
        ),
        _buildAccountInfoItem(
          context,
          S.of(context).phone_number,
          state.account!.phoneNumber,
          Icons.phone,
        ),
        _buildAccountInfoItem(
          context,
          S.of(context).sales_person_code,
          state.account!.salesPersonCode,
          Icons.code,
        ),
        _buildAccountInfoItem(
          context,
          S.of(context).authorities,
          state.account!.authorities.toString(),
          Icons.person,
        ),
      ],
    );
  }

  _buildAccountInfoItem(
      BuildContext context, text1, String? text2, IconData iconData) {
    return Center(
      child: Container(
        constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          Icon(
                            iconData,
                          ),
                          SizedBox(width: 10),
                          Text(
                            text1 + '..: ',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      text2 ?? '',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 30),
                  ],
                )
              ],
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
