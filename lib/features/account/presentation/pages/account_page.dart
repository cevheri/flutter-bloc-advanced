import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_avatar.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart' show AppComponentSize;
import 'package:flutter_bloc_advance/shared/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/widgets/user_form_fields.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _handleStateChanges(context, state),
      child: PopScope(
        canPop: !(_formKey.currentState?.isDirty ?? false),
        onPopInvokedWithResult: (bool didPop, Object? data) async => _handlePopScope(didPop, data),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
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
                        key: const Key('accountScreenAppBarBackButtonKey'),
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async => _handlePopScope(false, null, context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        S.of(context).account,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Column(
                      children: [
                        AppAvatar(
                          initials: _getInitials(state.data?.firstName, state.data?.lastName),
                          size: AppComponentSize.lg,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (state.data?.firstName != null)
                          Text(
                            '${state.data?.firstName ?? ''} ${state.data?.lastName ?? ''}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        if (state.data?.email != null)
                          Text(
                            state.data?.email ?? '',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    variant: AppCardVariant.outlined,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ResponsiveFormBuilder(
                      formKey: _formKey,
                      children: [..._buildFormFields(context, state), _submitButton(context, state)],
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

  String _getInitials(String? first, String? last) {
    final f = first?.isNotEmpty == true ? first![0].toUpperCase() : '';
    final l = last?.isNotEmpty == true ? last![0].toUpperCase() : '';
    return '$f$l';
  }

  List<Widget> _buildFormFields(BuildContext context, AccountState state) {
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: false),
      UserFormFields.firstNameField(context, state.data?.firstName),
      UserFormFields.lastNameField(context, state.data?.lastName),
      UserFormFields.emailField(context, state.data?.email),
    ];
  }

  Widget _submitButton(BuildContext context, AccountState state) {
    return ResponsiveSubmitButton(
      onPressed: () => state.status == AccountStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == AccountStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, AccountState state) {
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
      final formData = _formKey.currentState!.value;
      final user = _createUserFromData(formData, state.data?.id);
      context.read<AccountBloc>().add(AccountSubmitEvent(user));
      _formKey.currentState?.save();
      context.read<AccountBloc>().add(const AccountFetchEvent());
    }
  }

  UserEntity _createUserFromData(Map<String, dynamic> formData, String? userId) => UserEntity(
    id: userId,
    login: formData['login'],
    firstName: formData['firstName'],
    lastName: formData['lastName'],
    email: formData['email'],
    activated: formData['activated'],
  );

  void _handleStateChanges(BuildContext context, AccountState state) {
    const duration = Duration(milliseconds: 1000);
    switch (state.status) {
      case AccountStatus.initial:
        context.read<AccountBloc>().add(const AccountFetchEvent());
        break;
      case AccountStatus.loading:
        _showSnackBar(context, S.of(context).loading, duration);
        break;
      case AccountStatus.success:
        _showSnackBar(context, S.of(context).success, duration);
        break;
      case AccountStatus.failure:
        _showSnackBar(context, S.of(context).failed, duration);
        break;
    }
  }

  void _showSnackBar(BuildContext context, String message, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<void> _handlePopScope(bool didPop, Object? data, [BuildContext? contextParam]) async {
    if (didPop) return;

    final context = contextParam ?? data as BuildContext;
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

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountScreen();
  }
}
