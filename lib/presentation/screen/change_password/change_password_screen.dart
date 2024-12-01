import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../generated/l10n.dart';
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
      title: Text(S.of(context).change_password),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
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
            const SizedBox(height: 20),
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
    return Image.asset(LocaleConstants.defaultImgUrl, width: 200, height: 200);
  }

  _currentPasswordField(BuildContext context) {
    final fieldWidth = MediaQuery.of(context).size.width * 0.6;
    return SizedBox(
      width: fieldWidth,
      child: Row(
        children: [
          Expanded(
            child: FormBuilderTextField(
              key: changePasswordTextFieldCurrentPasswordKey,
              name: 'currentPassword',
              decoration: InputDecoration(labelText: S.of(context).current_password),
              obscureText: true,
              maxLines: 1,
              validator: FormBuilderValidators.compose(
                [FormBuilderValidators.required(errorText: S.of(context).required_field)],
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
              key: changePasswordTextFieldNewPasswordKey,
              name: 'newPassword',
              decoration: InputDecoration(labelText: S.of(context).new_password),
              obscureText: true,
              maxLines: 1,
              validator: FormBuilderValidators.compose(
                [FormBuilderValidators.required(errorText: S.of(context).required_field)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final t = S.of(context);
    return BlocListener<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        // Loading state
        if (state is ChangePasswordLoadingState) {
          Message.getMessage(context: context, title: t.loading, content: "");
        }
        // Completed state
        else if (state is ChangePasswordCompletedState) {
          Navigator.pop(context);
          Message.getMessage(context: context, title: t.success, content: "");
          //Navigator.pushNamedAndRemoveUntil(context, ApplicationRoutes.home, (route) => false);
        }
        // Error state
        else if (state is ChangePasswordErrorState) {
          Message.errorMessage(title: t.failed, context: context, content: "");
        }
      },
      listenWhen: (previous, current) {
        return current is ChangePasswordLoadingState || current is ChangePasswordCompletedState || current is ChangePasswordErrorState;
      },
      child: SizedBox(
        child: ElevatedButton(
          key: changePasswordButtonSubmitKey,
          child: Text(S.of(context).change_password),
          onPressed: () {
            //without blocConsumer access to bloc directly
            final currentState = context.read<ChangePasswordBloc>().state;
            if (currentState is ChangePasswordLoadingState) {
              return;
            }

            final currentPass = _changePasswordFormKey.currentState!.value['currentPassword'];
            final newPass = _changePasswordFormKey.currentState!.value['newPassword'];
            if (_changePasswordFormKey.currentState!.saveAndValidate() && currentPass != newPass && newPass != null && currentPass != null) {
              context.read<ChangePasswordBloc>().add(ChangePasswordChanged(currentPassword: currentPass, newPassword: newPass));
            }
          },
        ),
      ),
    );
  }
}
