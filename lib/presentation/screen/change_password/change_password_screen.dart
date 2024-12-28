import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_bloc_advance/configuration/padding_spacing.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).change_password),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.home)),
    );
  }

  FormBuilder _buildBody(BuildContext context) {
    return FormBuilder(
      key: _changePasswordFormKey,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Spacing.formMaxWidthLarge),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.medium),
              child: Column(
                spacing: Spacing.medium,
                children: <Widget>[
                  _logo(context),
                  _currentPasswordField(context),
                  _newPasswordField(context),
                  Align(alignment: Alignment.centerRight, child: _submitButton(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Image _logo(BuildContext context) {
    return Image.asset(LocaleConstants.defaultImgUrl, width: Spacing.widthPercentage50(context), height: Spacing.heightPercentage30(context));
  }

  FormBuilderTextField _currentPasswordField(BuildContext context) {
    return FormBuilderTextField(
      key: changePasswordTextFieldCurrentPasswordKey,
      name: 'currentPassword',
      decoration: InputDecoration(labelText: S.of(context).current_password),
      obscureText: true,
      maxLines: 1,
      validator: FormBuilderValidators.compose(
        [FormBuilderValidators.required(errorText: S.of(context).required_field)],
      ),
    );
  }

  FormBuilderTextField _newPasswordField(BuildContext context) {
    return FormBuilderTextField(
      key: changePasswordTextFieldNewPasswordKey,
      name: 'newPassword',
      decoration: InputDecoration(labelText: S.of(context).new_password),
      obscureText: true,
      maxLines: 1,
      validator: FormBuilderValidators.compose(
        [FormBuilderValidators.required(errorText: S.of(context).required_field)],
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
      child: FilledButton(
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
    );
  }
}
