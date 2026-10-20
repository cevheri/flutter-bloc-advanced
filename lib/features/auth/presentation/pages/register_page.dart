import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/shared/widgets/user_form_fields.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../generated/l10n.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: (context, state) => _handleStateChanges(context, state),
      child: UnsavedChangesScope(
        hasUnsavedChanges: () => _formKey.currentState?.isDirty ?? false,
        onBack: () => _navigateBack(context),
        child: Scaffold(appBar: _buildAppBar(context), body: _buildBody(context)),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).register),
      leading: IconButton(
        key: const Key('registerScreenAppBarBackButtonKey'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _navigateBack(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return ResponsiveFormBuilder(
          formKey: _formKey,
          onChanged: () => UnsavedChangesScope.formChanged(context),
          children: [
            Text(
              S.of(context).register_subtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final user = state is RegisterCompletedState ? state.user : null;
    return [
      UserFormFields.firstNameField(context, user?.firstName),
      UserFormFields.lastNameField(context, user?.lastName),
      UserFormFields.emailField(context, user?.email),
    ];
  }

  Widget _submitButton(BuildContext context, RegisterState state) {
    final isLoading = state is RegisterLoadingState;
    return ResponsiveSubmitButton(
      key: const Key('registerSubmitButtonKey'),
      buttonText: S.of(context).save,
      onPressed: () => isLoading ? null : _onSubmit(context, state),
      isLoading: isLoading,
    );
  }

  void _onSubmit(BuildContext context, RegisterState state) {
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
      final data = UserEntity(
        firstName: _formKey.currentState!.value['firstName'],
        lastName: _formKey.currentState!.value['lastName'],
        email: _formKey.currentState!.value['email'],
      );
      context.read<RegisterBloc>().add(RegisterFormSubmitted(data: data));
    }
  }

  void _handleStateChanges(BuildContext context, RegisterState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state) {
      case RegisterInitialState():
        break;
      case RegisterLoadingState():
        _showSnackBar(context, S.of(context).loading, duration);
      case RegisterCompletedState():
        _formKey.currentState?.reset();
        _showSnackBar(context, S.of(context).success, duration);
      case RegisterErrorState():
        _showSnackBar(context, S.of(context).failed, duration);
    }
  }

  void _showSnackBar(BuildContext context, String message, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  void _navigateBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go(ApplicationRoutesConstants.login);
    }
  }
}
