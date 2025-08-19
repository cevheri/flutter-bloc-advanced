import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_bloc_advance/configuration/padding_spacing.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n.dart';
import 'bloc/change_password_bloc.dart';

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key, this.returnToSettings = false});

  final bool returnToSettings;
  final _formKey = GlobalKey<FormBuilderState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangePasswordBloc, ChangePasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _handleStateChanges(context, state),
      child: PopScope(
        canPop: !(_formKey.currentState?.isDirty ?? false),
        onPopInvokedWithResult: (bool didPop, Object? data) async => _handlePopScope(didPop, data),
        child: Scaffold(key: _scaffoldKey, appBar: _buildAppBar(context), body: _buildBody(context)),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).change_password),
      leading: IconButton(
        key: const Key('changePasswordScreenAppBarBackButtonKey'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () async => _handlePopScope(false, null, context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            _logo(context),
            _currentPasswordField(context),
            _newPasswordField(context),
            _submitButton(context, state),
          ],
        );
      },
    );
  }

  Image _logo(BuildContext context) {
    return Image.asset(
      LocaleConstants.defaultImgUrl,
      width: Spacing.widthPercentage50(context),
      height: Spacing.heightPercentage30(context),
    );
  }

  FormBuilderTextField _currentPasswordField(BuildContext context) {
    return FormBuilderTextField(
      key: changePasswordTextFieldCurrentPasswordKey,
      name: 'currentPassword',
      decoration: InputDecoration(
        labelText: S.of(context).current_password,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      obscureText: true,
      maxLines: 1,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
      ]),
    );
  }

  FormBuilderTextField _newPasswordField(BuildContext context) {
    return FormBuilderTextField(
      key: changePasswordTextFieldNewPasswordKey,
      name: 'newPassword',
      decoration: InputDecoration(
        labelText: S.of(context).new_password,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      obscureText: true,
      maxLines: 1,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
      ]),
    );
  }

  Widget _submitButton(BuildContext context, ChangePasswordState state) {
    return ResponsiveSubmitButton(
      key: changePasswordButtonSubmitKey,
      onPressed: () => state.status == ChangePasswordStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == ChangePasswordStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, ChangePasswordState state) {
    debugPrint("onSubmit");
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint("validate");
      _showSnackBar(context, S.of(context).failed, const Duration(milliseconds: 1000));
      return;
    }

    if (!(_formKey.currentState?.isDirty ?? false)) {
      debugPrint("no changes made");
      _showSnackBar(context, S.of(context).no_changes_made, const Duration(milliseconds: 1000));
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      debugPrint("saveAndValidate");
      final currentPass = _formKey.currentState!.value['currentPassword'];
      final newPass = _formKey.currentState!.value['newPassword'];
      context.read<ChangePasswordBloc>().add(ChangePasswordChanged(currentPassword: currentPass, newPassword: newPass));
    }
  }

  void _handleStateChanges(BuildContext context, ChangePasswordState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state.status) {
      case ChangePasswordStatus.initial:
        //
        break;
      case ChangePasswordStatus.loading:
        _showSnackBar(context, S.of(context).loading, duration);
        break;
      case ChangePasswordStatus.success:
        _formKey.currentState?.fields['currentPassword']?.reset();
        _formKey.currentState?.fields['newPassword']?.reset();
        _formKey.currentState?.reset();
        _showSnackBar(context, S.of(context).success, duration);
        break;
      case ChangePasswordStatus.failure:
        _showSnackBar(context, S.of(context).failed, duration);
        break;
    }
  }

  void _showSnackBar(BuildContext context, String message, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<void> _handlePopScope(bool didPop, Object? data, [BuildContext? contextParam]) async {
    final context = contextParam ?? data as BuildContext;

    if (!context.mounted) return;

    if (didPop || !(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      // Eğer settings'den geldiyse settings'e, değilse home'a dön
      if (returnToSettings) {
        context.go(ApplicationRoutesConstants.settings);
      } else {
        context.go(ApplicationRoutesConstants.home);
      }
      return;
    }

    final shouldPop = await ConfirmationDialog.show(context: context, type: DialogType.unsavedChanges) ?? false;
    if (shouldPop && context.mounted) {
      // Eğer settings'den geldiyse settings'e, değilse home'a dön
      if (returnToSettings) {
        context.go(ApplicationRoutesConstants.settings);
      } else {
        context.go(ApplicationRoutesConstants.home);
      }
    }
  }
}
