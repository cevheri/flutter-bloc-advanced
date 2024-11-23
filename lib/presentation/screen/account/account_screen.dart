import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../generated/l10n.dart';
import '../../common_blocs/account/account_bloc.dart';
import '../user/edit/edit_form_widget.dart';

class AccountsScreen extends StatelessWidget {
  AccountsScreen({super.key});

  final formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).account),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
    );
  }

  _buildBody(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state.account == null) {
          return Container();
        }

        return Column(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 300, maxWidth: 700),
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  child: FormBuilder(
                    key: formKey,
                    child: Column(
                      children: <Widget>[
                        EditFormLoginName(user: state.account!),
                        EditFormFirstName(user: state.account!),
                        EditFormLastname(user: state.account!),
                        EditFormEmail(user: state.account!),
                        // EditFormPhoneNumber(user: state.account!),
                        EditFormActive(user: state.account!),
                        EditFormAuthorities(user: state.account!, formKey: formKey),
                        const SizedBox(height: 20),
                        SubmitButton(editAccount: "edit_page", context, user: state.account!, formKey: formKey)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
