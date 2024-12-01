import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';


import '../../../generated/l10n.dart';
import '../../common_blocs/account/account_bloc.dart';
import 'bloc/register_bloc.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _registerFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AccountBloc>(context).add(const AccountLoad());

    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
        title: Text(S.of(context).register), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)));
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            // if (state.account == null) {
            //   return Container();
            // }
            return Column(
              children: [
                FormBuilder(
                  key: _registerFormKey,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _formBuilderTextFieldFirstName(context),
                          const SizedBox(height: 20),
                          _formBuilderTextFieldLastName(context),
                          const SizedBox(height: 20),
                          _formBuilderTextFieldEmail(context),
                          const SizedBox(height: 20),
                          _submitButton(context),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  FormBuilderTextField _formBuilderTextFieldFirstName(BuildContext context) {
    return FormBuilderTextField(
      key: registerFirstNameTextFieldKey,
      name: "firstname",
      decoration: InputDecoration(labelText: S.of(context).first_name),
      maxLines: 1,
      validator: FormBuilderValidators.required(errorText: S.of(context).required_field),
    );
  }

  FormBuilderTextField _formBuilderTextFieldLastName(BuildContext context) {
    return FormBuilderTextField(
      key: registerLastNameTextFieldKey,
      name: "lastname",
      decoration: InputDecoration(labelText: S.of(context).last_name),
      maxLines: 1,
      validator: FormBuilderValidators.required(errorText: S.of(context).required_field),
    );
  }

  FormBuilderTextField _formBuilderTextFieldEmail(BuildContext context) {
    return FormBuilderTextField(
      key: registerEmailTextFieldKey,
      name: "email",
      decoration: InputDecoration(labelText: S.of(context).email),
      maxLines: 1,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
        FormBuilderValidators.email(errorText: S.of(context).email_pattern),
      ]),
    );
  }

  Widget _submitButton(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterCompletedState) {
          Navigator.pop(context);
          //Get.snackbar("Create User", "Success");
        }
        if (state is RegisterErrorState) {
          //Get.snackbar("Create User", "Error");
        }
      },
      child: SizedBox(
        child: ElevatedButton(
            key: registerSubmitButtonKey,
            child: Text(S.of(context).save),
            onPressed: () {
              if (_registerFormKey.currentState?.saveAndValidate() ?? false) {
                context.read<RegisterBloc>().add(RegisterFormSubmitted(
                    createUser: User(
                        firstName: _registerFormKey.currentState!.fields["firstname"]!.value,
                        lastName: _registerFormKey.currentState!.fields["lastname"]!.value,
                        email: _registerFormKey.currentState!.fields["email"]!.value)));
              }
            },
          ),
      ),
    );
  }
}
