import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key, this.returnToSettings = false});

  final bool returnToSettings;
  final _formKey = GlobalKey<FormBuilderState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
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
      title: Text(S.of(context).account),
      leading: IconButton(
        key: const Key('accountScreenAppBarBackButtonKey'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () async => _handlePopScope(false, null, context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        // final initialValues = {
        //   'login': state.data?.login,
        //   'firstName': state.data?.firstName,
        //   'lastName': state.data?.lastName,
        //   'email': state.data?.email
        // };

        return ResponsiveFormBuilder(
          formKey: _formKey,
          // initialValue: initialValues,
          children: [..._buildFormFields(context, state), _submitButton(context, state)],
        );
      },
    );
  }

  List<Widget> _buildFormFields(BuildContext context, AccountState state) {
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: false),
      UserFormFields.firstNameField(context, state.data?.firstName),
      UserFormFields.lastNameField(context, state.data?.lastName),
      UserFormFields.emailField(context, state.data?.email),
      //UserFormFields.activatedField(context, state.data?.activated),
    ];
  }

  Widget _submitButton(BuildContext context, AccountState state) {
    return ResponsiveSubmitButton(
      onPressed: () => state.status == AccountStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == AccountStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, AccountState state) {
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
      final formData = _formKey.currentState!.value;
      final user = _createUserFromData(formData, state.data?.id);
      context.read<AccountBloc>().add(AccountSubmitEvent(user));
      _formKey.currentState?.save();
      context.read<AccountBloc>().add(const AccountFetchEvent());
    }
  }

  User _createUserFromData(Map<String, dynamic> formData, String? userId) => User(
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
        //_formKey.currentState?.reset();
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
