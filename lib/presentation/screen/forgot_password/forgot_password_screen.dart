import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n.dart';
import 'bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key, this.returnToSettings = false});

  final bool returnToSettings;
  final _formKey = GlobalKey<FormBuilderState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
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
      key: const Key('forgotPasswordScreenAppBarKey'),
      title: Text(S.of(context).password_forgot),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _handlePopScope(false, null, context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            // Alt başlık eklendi (AppBar'da zaten başlık var)
            Text(
              'Enter your email to reset your password',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            _forgotPasswordField(context),
            _submitButton(context, state),
          ],
        );
      },
    );
  }

  FormBuilderTextField _forgotPasswordField(BuildContext context) {
    final t = S.of(context);
    return FormBuilderTextField(
      key: forgotPasswordTextFieldEmailKey,
      name: "email",
      decoration: InputDecoration(
        labelText: t.email,
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
      maxLines: 1,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: t.required_field),
        FormBuilderValidators.email(errorText: t.email_pattern),
      ]),
    );
  }

  Widget _submitButton(BuildContext context, ForgotPasswordState state) {
    return ResponsiveSubmitButton(
      key: forgotPasswordButtonSubmitKey,
      onPressed: () => state.status == ForgotPasswordStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == ForgotPasswordStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, ForgotPasswordState state) {
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
      final email = _formKey.currentState!.value['email'];
      context.read<ForgotPasswordBloc>().add(ForgotPasswordEmailChanged(email: email));
    }
  }

  void _handleStateChanges(BuildContext context, ForgotPasswordState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state.status) {
      case ForgotPasswordStatus.initial:
        //
        break;
      case ForgotPasswordStatus.loading:
        _showSnackBar(context, S.of(context).loading, duration);
        break;
      case ForgotPasswordStatus.success:
        _formKey.currentState?.reset();
        _showSnackBar(context, S.of(context).success, duration);
        break;
      case ForgotPasswordStatus.failure:
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
