import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../../data/models/user.dart';
import '../../../../../generated/l10n.dart';
import '../bloc/user.dart';
import 'edit_form_widget.dart';

class EditUserScreen extends StatelessWidget {
  final String id;

  EditUserScreen({super.key, required this.id});

  final formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocProvider(
        create: (context) => UserBloc(userRepository: UserRepository())..add(FetchUserEvent(id)),
        child: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).edit_user),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.home)),
    );
  }

  _buildBody(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoadInProgressState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UserLoadFailureState) {
          return Center(child: Text(S.of(context).failed + state.message));
        } else if (state is UserLoadSuccessState) {
          final user = state.userLoadSuccess;
          return _buildForm(context, user);
        } else {
          return Center(child: Text("Unexpected state: ${state.toString()}"));
        }
      },
    );
  }

  _buildForm(BuildContext context, User user) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 700),
          padding: const EdgeInsets.all(10),
          alignment: Alignment.center,
          child: FormBuilder(
            key: formKey,
            child: Column(
              children: <Widget>[
                EditFormLoginName(user: user),
                EditFormFirstName(user: user),
                EditFormLastname(user: user),
                EditFormEmail(user: user),
                // EditFormPhoneNumber(user: user),
                EditFormActive(user: user),
                EditFormAuthorities(user: user, formKey: formKey),
                const SizedBox(height: 20),
                SubmitButton(context, user: user, formKey: formKey)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
