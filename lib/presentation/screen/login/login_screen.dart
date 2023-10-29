import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../configuration/app_keys.dart';
import '../../../configuration/routes.dart';
import 'bloc/login.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen() : super(key: ApplicationKeys.loginScreen);

  final _loginFormKey = GlobalKey<FormBuilderState>();

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        log("LoginBloc listener: ${state.status}");
        if (state.status == LoginStatus.authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.home, (route) => false);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Login"),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
        key: _loginFormKey,
        onWillPop: _onWillPop,
        child: Center(
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
        ));
  }

  _logo(BuildContext context) {
    return Image.asset(
      'assets/images/Icon-192.png',
      width: 200,
      height: 200,
    );
  }

  _usernameField(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: FormBuilderTextField(
          name: 'username',
          decoration: InputDecoration(labelText: "Username"),
          maxLines: 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter username';
            }
            return null;
          },
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
                decoration: InputDecoration(labelText: "Password"),
                obscureText: !state.passwordVisible,
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
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

  /// Login button
  /// When username and password is valid, then submit form
  _submitButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
      return ElevatedButton(
        child: Text("Login"),
        onPressed: () {
          if (_loginFormKey.currentState!.saveAndValidate()) {
            context.read<LoginBloc>().add(LoginFormSubmitted(
                  username: _loginFormKey.currentState!.value['username'],
                  password: _loginFormKey.currentState!.value['password'],
                ));
          } else {
            log("validation failed");
          }
        },
      );
    });
  }

  _forgotPasswordLink(BuildContext context) {
    return Text("Forgot Password?");
  }

  Widget _validationZone() {
    return BlocBuilder<LoginBloc, LoginState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          return Visibility(
              visible: state.status == LoginStatus.failure,
              child: Center(
                child: Text(
                  "Login failed",
                  style: TextStyle(fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize, color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ));
        });
  }
}
