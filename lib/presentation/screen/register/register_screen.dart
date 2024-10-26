import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../generated/l10n.dart';
import '../../../utils/message.dart';
import '../../common_blocs/account/account_bloc.dart';
import 'bloc/register_bloc.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _registerFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AccountBloc>(context).add(AccountLoad());

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).register),
    );
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 50),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.account == null) {
            return Container();
          }

          return Column(
            children: [
              _forgotPasswordField(context, state.account),
            ],
          );
        },
      ),
    );
  }

  _forgotPasswordField(BuildContext context, User? account) {
    return FormBuilder(
      key: _registerFormKey,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FormBuilderTextField(
              name: "firstname",
              decoration: InputDecoration(labelText: S.of(context).first_name),
              maxLines: 1,
              initialValue: account!.firstName,
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: S.of(context).first_name),
                  (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).firstname_required;
                    }
                    return null;
                  },
                ],
              ),
            ),
            SizedBox(height: 20),
            FormBuilderTextField(
              name: "lastname",
              decoration: InputDecoration(labelText: S.of(context).last_name),
              maxLines: 1,
              initialValue: account.lastName,
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: S.of(context).last_name),
                  (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).lastname_required;
                    }
                    return null;
                  },
                ],
              ),
            ),
            SizedBox(height: 20),
            FormBuilderTextField(
              name: "email",
              decoration: InputDecoration(labelText: S.of(context).email),
              maxLines: 1,
              initialValue: account.email,
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: S.of(context).email_required),
                  (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).email_required;
                    }
                    return null;
                  },
                ],
              ),
            ),
            SizedBox(height: 20),
            _submitButton(context),
          ],
        ),
      ),
    );
  }

  _submitButton(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(builder: (context, state) {
      return SizedBox(
        child: ElevatedButton(
          child: Text(S.of(context).register),
          onPressed: () {
            if (_registerFormKey.currentState!.saveAndValidate()) {
              context.read<RegisterBloc>().add(
                    RegisterEmailChanged(
                      createUset: User(
                        firstName: _registerFormKey.currentState!.fields["firstname"]!.value,
                        lastName: _registerFormKey.currentState!.fields["lastname"]!.value,
                        email: _registerFormKey.currentState!.fields["email"]!.value,
                      ),
                    ),
                  );
            } else {}
          },
        ),
      );
    }, buildWhen: (previous, current) {
      if (current is RegisterInitialState) {
        Message.getMessage(context: context, title: S.of(context).create_user, content: "");
      }
      if (current is RegisterCompletedState) {
        Navigator.pop(context);
        Message.getMessage(context: context, title: S.of(context).create_user_success, content: "");
        Future.delayed(Duration(seconds: 1), () {});
      }
      if (current is RegisterErrorState) {
        Message.errorMessage(title: S.of(context).create_user_error, context: context, content: "");
      }
      return true;
    });
  }
}
