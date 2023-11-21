
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../configuration/app_keys.dart';
import '../../../configuration/locale_constants.dart';
import '../../../generated/l10n.dart';
import 'bloc/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen() : super(key: ApplicationKeys.settingsScreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }


  submit(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
      return ElevatedButton(
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Visibility(
                replacement: CircularProgressIndicator(value: null),
                visible: state.status != SettingsStatus.loaded,
                child: Text(S.of(context).pageSettingsTitle.toUpperCase()),
              ),
            )),
        onPressed: () {}, //context.read<SettingsBloc>().add(SaveSettings()),
      );
    });
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).pageSettingsTitle),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      child: Wrap(
        runSpacing: 15,
        children: <Widget>[
          _firstNameField(context),
          _lastNameNameField(context),
          _emailField(context),
          _submit(context),
        ],
      ),
    );
  }

  /// FirstName field widget generating by form_builder and bloc_builder
  Widget _firstNameField(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) => previous.firstName != current.firstName,
        builder: (context, state) {
          return FormBuilderTextField(
              name: 'firstName',
              decoration: InputDecoration(labelText: S.of(context).firstName),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(SettingsFirstNameChanged(firstName: value));
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                } else if (value.length < 3) {
                  return 'First name must be at least 3 characters long';
                } else {
                  return null;
                }
              });
        });
  }

  Widget _lastNameNameField(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) => previous.lastName != current.lastName,
        builder: (context, state) {
          return FormBuilderTextField(
              name: 'lastName',
              decoration: InputDecoration(labelText: 'Last Name'),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(SettingsLastNameChanged(lastName: value));
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                } else if (value.length < 3) {
                  return 'Last name must be at least 3 characters long';
                } else {
                  return null;
                }
              });
        });
  }

  Widget _emailField(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) => previous.email != current.email,
        builder: (context, state) {
          return FormBuilderTextField(
              name: 'email',
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(SettingsEmailChanged(email: value));
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!value.contains('@')) {
                  return 'Please enter a valid email';
                } else {
                  return null;
                }
              });
        });
  }


  Widget _submit(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return ElevatedButton(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Visibility(
                replacement: CircularProgressIndicator(value: null),
                visible: state.status != SettingsStatus.loaded,
                child: Text("S.of(context).pageSettingsFormSave.toUpperCase()"),
              ),
            ),
          ),
          onPressed: () {}, //context.read<SettingsBloc>().add(SaveSettings()),
        );
      },
    );
  }
}
