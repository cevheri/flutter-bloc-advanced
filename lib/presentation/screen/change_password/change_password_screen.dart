import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../configuration/routes.dart';
import '../../../utils/message.dart';
import 'bloc/change_password_bloc.dart';

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key});

  final _changePasswordFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Şifre Değiştir"),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _changePasswordFormKey,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _logo(context),
            _currentPasswordField(context),
            _newPasswordField(context),
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
      'assets/images/img.png',
      width: 200,
      height: 200,
    );
  }

  _currentPasswordField(BuildContext context) {
    final fieldWidth = MediaQuery.of(context).size.width * 0.6;
    return SizedBox(
      width: fieldWidth,
      child: Row(
        children: [
          Expanded(
            child: FormBuilderTextField(
              name: 'currentPassword',
              decoration: InputDecoration(labelText: "Eski Şifreniz"),
              obscureText: true,
              maxLines: 1,
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: "Şifre boş bırakılamaz."),
                  (val) {
                    return null;
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _newPasswordField(BuildContext context) {
    final fieldWidth = MediaQuery.of(context).size.width * 0.6;
    return SizedBox(
      width: fieldWidth,
      child: Row(
        children: [
          Expanded(
            child: FormBuilderTextField(
              name: 'newPassword',
              decoration: InputDecoration(labelText: "Yeni Şifreniz"),
              obscureText: true,
              maxLines: 1,
              validator: FormBuilderValidators.compose(
                [
                  FormBuilderValidators.required(errorText: "Şifre boş bırakılamaz."),
                  (val) {
                    return null;
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _submitButton(BuildContext context) {
    return BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text("Şifre Değiştir"),
            onPressed: () {
              if (_changePasswordFormKey.currentState!.saveAndValidate() &&
                  _changePasswordFormKey.currentState!.value['currentPassword'] !=
                      _changePasswordFormKey.currentState!.value['newPassword'] &&
                  _changePasswordFormKey.currentState!.value['newPassword'] != null &&
                  _changePasswordFormKey.currentState!.value['currentPassword'] != null) {
                context.read<ChangePasswordBloc>().add(ChangePasswordChanged(
                      currentPassword: _changePasswordFormKey.currentState!.value['currentPassword'],
                      newPassword: _changePasswordFormKey.currentState!.value['newPassword'],
                    ));
              } else {}
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is ChangePasswordInitialState) {
          Message.getMessage(context: context, title: "Şifre değiştiriliyor...", content: "");
        }
        if (current is ChangePasswordPasswordCompletedState) {
          Message.getMessage(context: context, title: "Şifre değiştirildi", content: "");
          Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.home, (route) => false);
        }
        if (current is ChangePasswordPasswordErrorState) {
          Message.errorMessage(title: 'Şifre değiştirilemedi', context: context,content: "");
        }
        return true;
      },
    );
  }
}
