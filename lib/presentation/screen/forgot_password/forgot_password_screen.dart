import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../utils/message.dart';
import 'bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final _forgotPasswordFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Şifremi Unuttum"),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _forgotPasswordFormKey,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _logo(context),
            _forgotPasswordField(context),
            SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[_submitButton(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _logo(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      width: 200,
      height: 200,
    );
  }

  _forgotPasswordField(BuildContext context) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: FormBuilderTextField(
            name: "email",
            decoration: InputDecoration(labelText: "email"),
            maxLines: 1,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: "email.required"),
              FormBuilderValidators.email(errorText: "email.pattern"),
              (value) {
                if (value == null || value.isEmpty) {
                  return "email.pattern";
                }
                return null;
              },
            ]),
          ),
        );
      },
      buildWhen: (previous, current) {
        if (previous.status != current.status) {
          return true;
        }
        return false;
      },
    );
  }

  _submitButton(BuildContext context) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(builder: (context, state) {
      return ElevatedButton(
        child: Text("Send Email"),
        onPressed: () {
          if (_forgotPasswordFormKey.currentState!.saveAndValidate()) {
            context
                .read<ForgotPasswordBloc>()
                .add(ForgotPasswordEmailChanged(email: _forgotPasswordFormKey.currentState!.fields["email"]!.value));
          } else {
            log("email.pattern");
          }
        },
      );
    }, buildWhen: (previous, current) {
      if (current is AccountResetPasswordInitialState) {
        Message.info(context: context, message: "email.reset");
      }
      if (current is AccountResetPasswordCompletedState) {
        Navigator.pop(context);
        Message.info(context: context, message: "email.new");
        Future.delayed(Duration(seconds: 1), () {});
      }
      if (current is AccountResetPasswordErrorState) {
        Message.error(message: 'email.error', context: context);
      }
      return true;
    });
  }
}
