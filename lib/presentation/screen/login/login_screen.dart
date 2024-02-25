import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../configuration/app_keys.dart';
import '../../../configuration/routes.dart';
import '../../../generated/l10n.dart';
import '../../../utils/message.dart';
import 'bloc/login.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen() : super(key: ApplicationKeys.loginScreen);

  final _loginFormKey = GlobalKey<FormBuilderState>();

  // Future<bool> _onWillPop() async {
  //   return false;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Sekoya Demo CRM"),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _loginFormKey,
      // onWillPop: _onWillPop,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _logo(context),
              _usernameField(context),
              _passwordField(context),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[_submitButton(context)],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[_forgotPasswordLink(context)],
              ),
              _validationZone(),
            ],
          ),
        ),
      ),
    );
  }

  _logo(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Image.asset(
        'assets/images/img.png', //TODO change dark mode image
        width: 200,
        height: 200,
      );
    } else {
      return Image.asset(
        'assets/images/img.png', // TODO change light mode image
        width: 200,
        height: 200,
      );
    }
  }

  _usernameField(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: FormBuilderTextField(
          name: 'username',
          decoration: InputDecoration(labelText: S.of(context).login_user_name),
          maxLines: 1,
          validator: FormBuilderValidators.compose(
            [
              FormBuilderValidators.required(errorText: S.of(context).username_required),
              FormBuilderValidators.minLength(5, errorText: S.of(context).username_min_length),
              FormBuilderValidators.maxLength(20, errorText: S.of(context).username_max_length),
              (val) {
                return null;
              },
            ],
          ),
        ),
      );
    });
  }

  _passwordField(BuildContext context) {
    final fieldWidth = MediaQuery.of(context).size.width * 0.6;
    return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
      return SizedBox(
        width: fieldWidth,
        child: Row(
          children: [
            Expanded(
              child: FormBuilderTextField(
                name: 'password',
                decoration: InputDecoration(labelText: S.of(context).login_password),
                // when press the enter key, call submit button function
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (_loginFormKey.currentState!.saveAndValidate()) {
                    _submitEvent(context);
                  }
                },

                obscureText: !state.passwordVisible,
                maxLines: 1,
                validator: FormBuilderValidators.compose(
                  [
                    FormBuilderValidators.required(errorText: S.of(context).password_required),
                    FormBuilderValidators.minLength(6, errorText: S.of(context).password_min_length),
                    FormBuilderValidators.maxLength(20, errorText: S.of(context).password_max_length),
                    (val) {
                      return null;
                    },
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(state.passwordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                context.read<LoginBloc>().add(TogglePasswordVisibility());
              },
            ),
          ],
        ),
      );
    });
  }

  _submitButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).login_button),
            onPressed: () {
              if (_loginFormKey.currentState!.saveAndValidate()) {
                _submitEvent(context);
              } else {}
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is LoginLoadingState) {
          Message.getMessage(context: context, title: S.of(context).logging_in, content: "");
        }
        if (current is LoginLoadedState) {
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.home, (route) => false);
        }
        if (current is LoginErrorState) {
          Message.errorMessage(context: context, title: S.of(context).login_error, content: "");
        }
        return true;
      },
    );
  }

  void _submitEvent(BuildContext context) {
    context.read<LoginBloc>().add(LoginFormSubmitted(
          username: _loginFormKey.currentState!.value['username'],
          password: _loginFormKey.currentState!.value['password'],
        ));
  }

  _forgotPasswordLink(BuildContext context) {
    return SizedBox(
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, ApplicationRoutes.forgotPassword);
        },
        child: Text(S.of(context).password_forgot),
      ),
    );
  }

  Widget _validationZone() {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return Visibility(
          visible: state.status == LoginStatus.failure,
          child: Center(
            child: Text(
              S.of(context).login_error,
              style: TextStyle(fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize, color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
