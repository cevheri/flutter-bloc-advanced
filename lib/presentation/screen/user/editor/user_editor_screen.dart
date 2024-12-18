import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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

  //@formatter:off
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.loading) {
          _showMessage(context, _scaffoldKey, S.of(context).loading, S.of(context).loading);
        }

        if (state.status == UserStatus.success) {
          _showMessage(context, _scaffoldKey, S.of(context).success, S.of(context).success);
          //context.pop();
        }

        if (state.status == UserStatus.failure) {
          _showMessage(context, _scaffoldKey, S.of(context).failed, S.of(context).failed);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getTitle(context)),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }
  //@formatter:on

  Widget _buildBody(BuildContext context, UserState state) {
    if (state.status == UserStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get initial values for FormBuilder
    final initialValues = {
      'login': state.data?.login ?? '',
      'firstName': state.data?.firstName ?? '',
      'lastName': state.data?.lastName ?? '',
      'email': state.data?.email ?? '',
      'activated': state.data?.activated ?? true,
      'authorities': state.data?.authorities?.first ?? state.data?.authorities?.firstOrNull,
    };

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
                  if (state.data?.authorities?.isNotEmpty ?? false) ...[
                    FormBuilderDropdown<String>(
                      key: const Key('UserEditorAuthoritiesField'),
                      name: 'authorities',
                      decoration: InputDecoration(
                        labelText: S.of(context).authorities,
                        border: const OutlineInputBorder(),
                        filled: true,
                        enabled: mode != EditorFormMode.view,
                      ),
                      items: state.data?.authorities?.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList() ?? [],
                      validator: FormBuilderValidators.compose([FormBuilderValidators.required(errorText: S.of(context).required_field)]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (mode != EditorFormMode.view)
                    SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(onPressed: () => _onSubmit(context), child: Text(S.of(context).save))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildFormFields(BuildContext context, UserState state) {
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
  
  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      final user = User(
        id: context.read<UserBloc>().state.data?.id,
        login: formData['login'],
        firstName: formData['firstName'],
        lastName: formData['lastName'],
        email: formData['email'],
        activated: formData['activated'],
        authorities: [formData['authorities']],
      );

      context.read<UserBloc>().add(UserSubmitEvent(user));
    }
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
