import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../../generated/l10n.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangePasswordBloc, ChangePasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _handleStateChanges(context, state),
      child: PopScope(
        canPop: !(_formKey.currentState?.isDirty ?? false),
        onPopInvokedWithResult: (bool didPop, Object? data) async => _handlePopScope(context, didPop),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ChangePasswordBloc, ChangePasswordState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('changePasswordScreenAppBarBackButtonKey'),
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async => _handlePopScope(context, false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        S.of(context).change_password,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ResponsiveFormBuilder(
                        formKey: _formKey,
                        children: [
                          Text(
                            S.of(context).change_password_description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const Divider(),
                          _currentPasswordField(context),
                          _newPasswordField(context),
                          const SizedBox(height: AppSpacing.sm),
                          _submitButton(context, state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  FormBuilderTextField _currentPasswordField(BuildContext context) {
    return FormBuilderTextField(
      key: changePasswordTextFieldCurrentPasswordKey,
      name: 'currentPassword',
      decoration: InputDecoration(
        labelText: S.of(context).current_password,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_showCurrentPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
        ),
      ),
      obscureText: !_showCurrentPassword,
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
        prefixIcon: const Icon(Icons.lock_reset),
        suffixIcon: IconButton(
          icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
        ),
      ),
      obscureText: !_showNewPassword,
      maxLines: 1,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
      ]),
    );
  }

  Widget _submitButton(BuildContext context, ChangePasswordState state) {
    return SizedBox(
      width: double.infinity,
      child: ResponsiveSubmitButton(
        key: changePasswordButtonSubmitKey,
        buttonText: S.of(context).save,
        onPressed: state.status == ChangePasswordStatus.loading ? null : () => _onSubmit(context, state),
        isLoading: state.status == ChangePasswordStatus.loading,
      ),
    );
  }

  void _onSubmit(BuildContext context, ChangePasswordState state) {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar(context, S.of(context).failed, const Duration(milliseconds: 1000));
      return;
    }

    if (!(_formKey.currentState?.isDirty ?? false)) {
      _showSnackBar(context, S.of(context).no_changes_made, const Duration(milliseconds: 1000));
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final currentPass = _formKey.currentState!.value['currentPassword'];
      final newPass = _formKey.currentState!.value['newPassword'];
      context.read<ChangePasswordBloc>().add(ChangePasswordChanged(currentPassword: currentPass, newPassword: newPass));
    }
  }

  void _handleStateChanges(BuildContext context, ChangePasswordState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state.status) {
      case ChangePasswordStatus.initial:
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

  Future<void> _handlePopScope(BuildContext context, bool didPop) async {
    if (didPop) return;
    if (!context.mounted) return;

    if (!(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      _navigateBack(context);
      return;
    }

    final shouldPop = await ConfirmationDialog.show(context: context, type: DialogType.unsavedChanges) ?? false;
    if (shouldPop && context.mounted) {
      _navigateBack(context);
    }
  }

  void _navigateBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go(ApplicationRoutesConstants.home);
    }
  }
}
