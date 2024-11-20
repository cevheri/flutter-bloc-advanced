import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../../generated/l10n.dart';
import '../../../../data/models/user.dart';
import '../../../../utils/message.dart';
import '../../../common_blocs/authority/authority_bloc.dart';
import '../bloc/user_bloc.dart';

// class EditFormPhoneNumber extends StatelessWidget {
//   final User user;
//
//   const EditFormPhoneNumber({super.key, required this.user});
//
//   @override
//   Widget build(BuildContext context) {
//     return FormBuilderTextField(
//       name: 'editPhoneNumber',
//       decoration: InputDecoration(
//         labelText: S.of(context).phone_number,
//       ),
//       validator: FormBuilderValidators.compose(
//         [FormBuilderValidators.required(errorText: S.of(context).required_phone_type)],
//       ),
//       initialValue: user.phoneNumber,
//     );
//   }
// }

class EditFormActive extends StatelessWidget {
  final User user;

  const EditFormActive({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FormBuilderSwitch(
      name: 'editActive',
      title: Text(S.of(context).active),
      initialValue: user.activated,
    );
  }
}

class EditFormEmail extends StatelessWidget {
  final User user;

  const EditFormEmail({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'editEmail',
      decoration: InputDecoration(
        labelText: S.of(context).email,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(errorText: S.of(context).email_required),
          FormBuilderValidators.email(errorText: S.of(context).email_pattern),
        ],
      ),
      initialValue: user.email,
    );
  }
}

class EditFormLastname extends StatelessWidget {
  final User user;

  const EditFormLastname({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'editLastName',
      decoration: InputDecoration(
        labelText: S.of(context).last_name,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(errorText: S.of(context).lastname_required),
          FormBuilderValidators.minLength(errorText: S.of(context).lastname_min_length, 3),
          FormBuilderValidators.maxLength(errorText: S.of(context).lastname_max_length, 20),
        ],
      ),
      initialValue: user.lastName,
    );
  }
}

class EditFormFirstName extends StatelessWidget {
  final User user;

  const EditFormFirstName({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'editFirstName',
      decoration: InputDecoration(
        labelText: S.of(context).first_name,
      ),
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(errorText: S.of(context).firstname_required),
          FormBuilderValidators.minLength(errorText: S.of(context).firstname_min_length, 3),
          FormBuilderValidators.maxLength(errorText: S.of(context).firstname_max_length, 20),
        ],
      ),
      initialValue: user.firstName,
    );
  }
}

class EditFormLoginName extends StatelessWidget {
  final User user;

  const EditFormLoginName({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'editLogin',
      decoration: InputDecoration(
        labelText: S.of(context).login,
      ),
      enabled: false,
      validator: FormBuilderValidators.compose(
        [
          FormBuilderValidators.required(errorText: S.of(context).username_required),
          FormBuilderValidators.minLength(errorText: S.of(context).username_min_length, 3),
          FormBuilderValidators.maxLength(errorText: S.of(context).username_max_length, 20),
          FormBuilderValidators.match((RegExp("^[a-zA-Z0-9]+\$")), errorText: S.of(context).username_regex_pattern),
        ],
      ),
      initialValue: user.login,
    );
  }
}

class EditFormAuthorities extends StatelessWidget {
  final GlobalKey<FormBuilderState>? formKey;
  final User user;

  const EditFormAuthorities({super.key, this.formKey, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthorityBloc, AuthorityState>(
      builder: (context, state) {
        if (state is AuthorityLoadSuccessState) {
          return FormBuilderDropdown(
            name: 'editAuthorities',
            decoration: InputDecoration(
              hintText: S.of(context).authorities,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: S.of(context).authorities_required),
            ]),
            items: state.authorities.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
            initialValue: () {}(),
            onChanged: (value) {},
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SubmitButton extends StatelessWidget {
  final User user;
  final GlobalKey<FormBuilderState> formKey;
  final String? editAccount;

  const SubmitButton(
    BuildContext context, {
    super.key,
    required this.user,
    required this.formKey,
    this.editAccount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).save),
            onPressed: () {
              User newUser = User(
                id: user.id,
                login: formKey.currentState!.fields['editLogin']!.value,
                activated: formKey.currentState!.fields['editActive']!.value,
                firstName: formKey.currentState!.fields['editFirstName']!.value,
                lastName: formKey.currentState!.fields['editLastName']!.value,
                email: formKey.currentState!.fields['editEmail']!.value,
                // phoneNumber: formKey.currentState!.fields['editPhoneNumber']!.value,
                authorities: [formKey.currentState!.fields['editAuthorities']?.value ?? ""],
              );
              User cacheUser = User(
                id: user.id,
                login: user.login,
                activated: user.activated,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                // phoneNumber: user.phoneNumber,
                authorities: user.authorities,
              );
              if (cacheUser != newUser) {
                BlocProvider.of<UserBloc>(context).add(UserEdit(user: newUser));
              }

              if (cacheUser == newUser) {
                Message.getMessage(context: context, title: "Değişiklik bulunmadı", content: ''); //TODO internationalization
                Navigator.pop(context);
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is UserEditInitialState) {
          Message.getMessage(context: context, title: S.of(context).loading, content: '');
        }
        if (current is UserEditSuccessState) {
          Message.getMessage(context: context, title: S.of(context).success, content: '');
          Navigator.pop(context);
        }
        if (current is UserEditFailureState) {
          Message.errorMessage(title: S.of(context).failed, context: context, content: '');
        }

        return true;
      },
    );
  }
}
