import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../data/models/user.dart';
import '../../../../../generated/l10n.dart';
import '../../../../../utils/message.dart';
import '../../../common_blocs/authorities/authorities_bloc.dart';
import '../bloc/user_bloc.dart';
import 'create_form_field_widget.dart';

class CreateUserScreen extends StatelessWidget {
  CreateUserScreen({super.key});

  final formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AuthoritiesBloc>(context).add(AuthoritiesLoad());
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).create_user),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
          formKey.currentState!.fields['salesPersonCode']?.didChange("");
        },
      ),
    );
  }

  _buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: FormBuilder(
            key: formKey,
            child: Column(
              children: <Widget>[
                CreateFormLoginName(),
                CreateFormFirstName(),
                CreateFormLastname(),
                CreateFormEmail(),
                CreateFormPhoneNumber(),
                CreateFormPhoneActive(),
                SizedBox(height: 20),
                _submitButton(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  _submitButton(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            child: Text(S.of(context).create_user),
            onPressed: () {
              if (formKey.currentState!.saveAndValidate()) {
                var user = User(
                  login: formKey.currentState!.fields['login']!.value,
                  firstName: formKey.currentState!.fields['firstName']!.value,
                  lastName: formKey.currentState!.fields['lastName']!.value,
                  email: formKey.currentState!.fields['email']!.value,
                  // phoneNumber: formKey.currentState!.fields['phoneNumber']!.value,
                  authorities: [formKey.currentState!.fields['authorities']?.value ?? ""],
                  activated: formKey.currentState!.fields['userCreateActive']!.value,
                );
                context.read<UserBloc>().add(
                      UserCreate(
                        user: user,
                      ),
                    );
              }
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        if (current is UserInitialState) {
          Message.getMessage(context: context, title: "Kullanıcı oluşturuluyor...", content: "");
        }
        if (current is UserLoadSuccessState) {
          Message.getMessage(context: context, title: "Kullanıcı oluşturuldu", content: "");
          Navigator.pop(context);
        }
        if (current is UserLoadFailureState) {
          Message.errorMessage(title: 'Kullanıcı oluşturulamadı lütfen bilgileri kontrol ediniz.', context: context, content: "");
        }

        return true;
      },
    );
  }
}
