import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/authority_lov_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class UserEditorScreen extends StatelessWidget {
  final String? id;
  final EditorFormMode mode;

  const UserEditorScreen({
    super.key,
    this.id,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final initialEvent = id != null ? UserFetchEvent(id!) : const UserEditorInit();
    return BlocProvider(
      create: (context) => UserBloc(repository: UserRepository())..add(initialEvent),
      child: UserEditorWidget(mode: mode),
    );
  }
}

_showMessage(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey, String title, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(content),
    duration: const Duration(seconds: 2),
  ));
}

class UserEditorWidget extends StatelessWidget {
  final EditorFormMode mode;
  final _formKey = GlobalKey<FormBuilderState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  UserEditorWidget({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UserStatus.loading) {
          _showMessage(context, _scaffoldKey, S.of(context).loading, S.of(context).loading);
        }

        if (state.status == UserStatus.success) {
          _showMessage(context, _scaffoldKey, S.of(context).success, S.of(context).success);
        }

        if (state.status == UserStatus.failure) {
          _showMessage(context, _scaffoldKey, S.of(context).failed, S.of(context).failed);
        }
      },
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context, state),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(_getTitle(context)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async => _handlePopScope(false, null, context),
      ),
    );
  }

  Future<void> _handlePopScope(bool didPop, Object? data, [BuildContext? contextParam]) async {
    final context = contextParam ?? data as BuildContext;

    if (mode == EditorFormMode.view) {
      context.go(ApplicationRoutesConstants.userList);
      context.read<UserBloc>().add(const UserViewCompleteEvent());
      return;
    }

    if (!context.mounted) return;

    if (didPop || !(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      context.go(ApplicationRoutesConstants.userList);
      return;
    }

    final shouldPop = await _buildShowDialog(context) ?? false;
    if (shouldPop && context.mounted) {
      context.go(ApplicationRoutesConstants.userList);
    }
  }

  Future<bool?> _buildShowDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).warning),
        content: Text(S.of(context).unsaved_changes),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).yes),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).no),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserState state) {
    if (state.status == UserStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((mode == EditorFormMode.edit || mode == EditorFormMode.view) && state.data == null) {
      //return const Center(child: CircularProgressIndicator());
      return const Center(child: Text("No data"));
    }

    debugPrint("checkpoint data: ${state.data?.login}");
    debugPrint("checkpoint status: ${state.status}");
    // Get initial values for FormBuilder
    final initialValue = {
      'login': state.data?.login ?? '',
      'firstName': state.data?.firstName ?? '',
      'lastName': state.data?.lastName ?? '',
      'email': state.data?.email ?? '',
      'activated': state.data?.activated ?? true,
      'authorities': state.data?.authorities?.first ?? state.data?.authorities?.firstOrNull,
    };
    debugPrint("checkpoint initial value: $initialValue");
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: FormBuilder(
              key: _formKey,
              initialValue: initialValue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildFormFields(context, state),
                  const SizedBox(height: 20),
                  if (mode == EditorFormMode.view) _backButtonField(context),
                  if (mode != EditorFormMode.view) _submitButtonField(context, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _backButtonField(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          context.go('/user');
          context.read<UserBloc>().add(const UserViewCompleteEvent());
        },
        child: Text(S.of(context).back),
      ),
    );
  }

  _submitButtonField(BuildContext context, UserState state) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _onSubmit(context),
        child: Text(S.of(context).save),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final id = context.read<UserBloc>().state.data?.id;
      debugPrint("checkpoint form data: $formData");

      final user = const User().copyWith(
        id: id,
        login: formData['login'],
        firstName: formData['firstName'],
        lastName: formData['lastName'],
        email: formData['email'],
        activated: formData['activated'],
        langKey: 'en',
        authorities: [formData['authority'] ?? ''],
      );

      context.read<UserBloc>().add(UserSubmitEvent(user));
      context.read<UserBloc>().add(const UserSaveCompleteEvent());
      context.go(ApplicationRoutesConstants.userList);
    }
  }

  _buildFormFields(BuildContext context, UserState state) {
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: mode == EditorFormMode.create),
      const SizedBox(height: 16),
      UserFormFields.firstNameField(context, state.data?.firstName, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 16),
      UserFormFields.lastNameField(context, state.data?.lastName, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 16),
      UserFormFields.emailField(context, state.data?.email, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 16),
      UserFormFields.activatedField(context, state.data?.activated, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 16),
      //TODO when mode == EditorFormMode.view, select the user authorities
      // if (state.data?.authorities?.isNotEmpty ?? false) ...[
      //   const SizedBox(height: 16),
      // ],
      AuthorityDropdown(enabled: mode != EditorFormMode.view),
      const SizedBox(height: 16),
    ];
  }

  String _getTitle(BuildContext context) {
    switch (mode) {
      case EditorFormMode.create:
        return S.of(context).create_user;
      case EditorFormMode.edit:
        return S.of(context).edit_user;
      case EditorFormMode.view:
        return S.of(context).view_user;
    }
  }
}
