import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/confirmation_dialog_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({super.key});

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

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).account),
      leading: IconButton(
        key: const Key('accountScreenAppBarBackButtonKey'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () async => _handlePopScope(false, null, context),
      ),
    );
  }

  _buildBody(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      buildWhen: (previous, current) => previous.data != current.data || previous.status != current.status,
      builder: (context, state) {
        if (state.data == null) {
          return Center(child: Text(S.of(context).no_data));
        }
        if (state.status == AccountStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._buildFormFields(context, state),
                      const SizedBox(height: 20),
                      _submitButton(context, state),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _buildFormFields(BuildContext context, AccountState state) {
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: false),
      const SizedBox(height: 16),
      UserFormFields.firstNameField(context, state.data?.firstName),
      const SizedBox(height: 16),
      UserFormFields.lastNameField(context, state.data?.lastName),
      const SizedBox(height: 16),
      UserFormFields.emailField(context, state.data?.email),
      const SizedBox(height: 16),
      UserFormFields.activatedField(context, state.data?.activated),
    ];
  }

  /// Submit button
  /// This button is used to submit the form.
  ///
  /// [context] BuildContext current context
  /// [state] AccountState state of the bloc
  /// return ElevatedButton
  Widget _submitButton(BuildContext context, AccountState state) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => state.status == AccountStatus.loading ? null : _onSubmit(context, state),
        child: Text(S.of(context).save),
      ),
    );
  }

  void _onSubmit(BuildContext context, AccountState state) {
    if (!(_formKey.currentState?.isDirty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).no_changes_made)),
      );
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final user = _createUserFromFormData(formData, state.data?.id);

      context.read<UserBloc>().add(UserSubmitEvent(user));
      late final StreamSubscription<UserState> subscription;
      subscription = context.read<UserBloc>().stream.listen((userState) {
        if ((userState.status == UserStatus.success || userState.status == UserStatus.saveSuccess) && context.mounted) {
          context.read<AccountBloc>().add(const AccountFetchEvent());
          _formKey.currentState?.reset();
          subscription.cancel();
        }
      }); // cancel the stream after the first event
    }
  }

  User _createUserFromFormData(Map<String, dynamic> formData, String? userId) {
    return User(
      id: userId,
      login: formData['login'],
      firstName: formData['firstName'],
      lastName: formData['lastName'],
      email: formData['email'],
      activated: formData['activated'],
    );
  }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  Future<void> _handlePopScope(bool didPop, Object? data, [BuildContext? contextParam]) async {
    final context = contextParam ?? data as BuildContext;

    if (!context.mounted) return;

    if (didPop || !(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      context.go(ApplicationRoutesConstants.home);
      return;
    }

    final shouldPop = await ConfirmationDialog.show(context: context, type: DialogType.unsavedChanges) ?? false;
    if (shouldPop && context.mounted) {
      context.go(ApplicationRoutesConstants.home);
    }
  }

}
