import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
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
  // ScaffoldMessenger.of(scaffoldKey.currentContext!).hideCurrentSnackBar();
  // ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
  //     behavior: SnackBarBehavior.floating,
  //     content: Text(S.of(context).content),
  //     backgroundColor: Theme.of(context).colorScheme.primary,
  //     width: MediaQuery.of(context).size.width * 0.8));
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
        // if (state.status == UserStatus.loading) {
        //   _showMessage(context, _scaffoldKey, S.of(context).loading, S.of(context).loading);
        // }

        if (state.status == UserStatus.success) {
          _showMessage(context, _scaffoldKey, S.of(context).success, S.of(context).success);
          context.pop();
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
      'login': state.user?.login ?? '',
      'firstName': state.user?.firstName ?? '',
      'lastName': state.user?.lastName ?? '',
      'email': state.user?.email ?? '',
      'activated': state.user?.activated ?? true,
      'authorities': state.user?.authorities?.first ?? state.user?.authorities?.firstOrNull,
    };

    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: initialValues,
          onChanged: () => _formKey.currentState?.save(),
          child: Column(
            children: [
              FormBuilderTextField(
                key: const Key('UserEditorLoginField'),
                name: 'login',
                enabled: mode == EditorFormMode.create,
                decoration: InputDecoration(
                  labelText: S.of(context).login,
                  border: const OutlineInputBorder(),
                  filled: true,
                  enabled: mode != EditorFormMode.view,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_field),
                  FormBuilderValidators.minLength(3, errorText: S.of(context).min_length_3),
                  FormBuilderValidators.maxLength(20, errorText: S.of(context).max_length_20),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                key: const Key('UserEditorFirstNameField'),
                name: 'firstName',
                decoration: InputDecoration(
                  labelText: S.of(context).first_name,
                  border: const OutlineInputBorder(),
                  filled: true,
                  enabled: mode != EditorFormMode.view,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_field),
                  FormBuilderValidators.minLength(3, errorText: S.of(context).min_length_3),
                  FormBuilderValidators.maxLength(20, errorText: S.of(context).max_length_20),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                key: const Key('UserEditorLastNameField'),
                name: 'lastName',
                decoration: InputDecoration(
                  labelText: S.of(context).last_name,
                  border: const OutlineInputBorder(),
                  filled: true,
                  enabled: mode != EditorFormMode.view,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_field),
                  FormBuilderValidators.minLength(3, errorText: S.of(context).min_length_3),
                  FormBuilderValidators.maxLength(20, errorText: S.of(context).max_length_20),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                key: const Key('UserEditorEmailField'),
                name: 'email',
                decoration: InputDecoration(
                  labelText: S.of(context).email,
                  border: const OutlineInputBorder(),
                  filled: true,
                  enabled: mode != EditorFormMode.view,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_field),
                  FormBuilderValidators.email(errorText: S.of(context).email_pattern),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderSwitch(
                key: const Key('UserEditorActivatedField'),
                name: 'activated',
                title: Text(S.of(context).active),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                enabled: mode != EditorFormMode.view,
              ),
              const SizedBox(height: 16),
              if (state.user?.authorities?.isNotEmpty ?? false) ...[
                FormBuilderDropdown<String>(
                  key: const Key('UserEditorAuthoritiesField'),
                  name: 'authorities',
                  decoration: InputDecoration(
                    labelText: S.of(context).authorities,
                    border: const OutlineInputBorder(),
                    filled: true,
                    enabled: mode != EditorFormMode.view,
                  ),
                  items: state.user?.authorities?.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList() ?? [],
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
    );
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      final user = User(
        id: context.read<UserBloc>().state.user?.id,
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
