import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n.dart';
import 'bloc/register_bloc.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key, this.returnToSettings = false});

  final bool returnToSettings;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _handleStateChanges(context, state),
      child: Scaffold(appBar: _buildAppBar(context), body: _buildBody(context)),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).register),
      leading: IconButton(
        key: const Key('registerScreenAppBarBackButtonKey'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handlePopScope(false, null, context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            // Alt başlık eklendi (AppBar'da zaten başlık var)
            Text(
              'Create your account',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            ..._buildFormFields(context, state),
            _submitButton(context, state),
          ],
        );
      },
    );
  }

  List<Widget> _buildFormFields(BuildContext context, RegisterState state) {
    return [
      UserFormFields.firstNameField(context, state.data?.firstName),
      UserFormFields.lastNameField(context, state.data?.lastName),
      UserFormFields.emailField(context, state.data?.email),
    ];
  }

  Widget _submitButton(BuildContext context, RegisterState state) {
    return ResponsiveSubmitButton(
      key: const Key('registerSubmitButtonKey'),
      onPressed: () => state.status == RegisterStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == RegisterStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, RegisterState state) {
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
      User data = User(
        firstName: _formKey.currentState!.value['firstName'],
        lastName: _formKey.currentState!.value['lastName'],
        email: _formKey.currentState!.value['email'],
      );
      context.read<RegisterBloc>().add(RegisterFormSubmitted(data: data));
    }
  }

  void _handleStateChanges(BuildContext context, RegisterState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state.status) {
      case RegisterStatus.initial:
        //
        break;
      case RegisterStatus.loading:
        _showSnackBar(context, S.of(context).loading, duration);
        break;
      case RegisterStatus.success:
        _formKey.currentState?.reset();
        _showSnackBar(context, S.of(context).success, duration);
        break;
      case RegisterStatus.error:
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
