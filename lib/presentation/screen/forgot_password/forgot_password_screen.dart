import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../generated/l10n.dart';
import '../../../utils/message.dart';
import 'bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final _forgotPasswordFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(title: Text(S.of(context).password_forgot));
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _forgotPasswordFormKey,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _logo(context),
            _forgotPasswordField(context),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[_submitButton(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _logo(BuildContext context) {
    return Image.asset(LocaleConstants.defaultImgUrl, width: 200, height: 200);
  }

  _forgotPasswordField(BuildContext context) {
    final t = S.of(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: FormBuilderTextField(
        key: forgotPasswordTextFieldEmailKey,
        name: "email",
        decoration: InputDecoration(labelText: t.email),
        maxLines: 1,
        validator: FormBuilderValidators.compose(
          [FormBuilderValidators.required(errorText: t.email_required), FormBuilderValidators.email(errorText: t.email_pattern)],
        ),
      ),
    );
  }

  // bad usage for bloc builder !!!
  // _submitButton(BuildContext context) {
  //   return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(builder: (context, state) {
  //     return SizedBox(
  //       child: ElevatedButton(
  //         key: forgotPasswordButtonSubmit,
  //         child: Text(S.of(context).email_send),
  //         onPressed: () {
  //           if (_forgotPasswordFormKey.currentState!.saveAndValidate()) {
  //             context
  //                 .read<ForgotPasswordBloc>()
  //                 .add(ForgotPasswordEmailChanged(email: _forgotPasswordFormKey.currentState!.fields["email"]!.value));
  //           } else {}
  //         },
  //       ),
  //     );
  //   }, buildWhen: (previous, current) {
  //     if (current is ForgotPasswordInitialState) {
  //       Message.getMessage(context: context, title: S.of(context).loading, content: "");
  //     }
  //     if (current is ForgotPasswordCompletedState) {
  //       Navigator.pop(context);
  //       Message.getMessage(context: context, title: S.of(context).success, content: "");
  //       Future.delayed(const Duration(seconds: 1), () {});
  //     }
  //     if (current is ForgotPasswordErrorState) {
  //       Message.errorMessage(title: S.of(context).failed, context: context, content: "");
  //     }
  //     return true;
  //   });
  // }

  // good usage for bloc consumer
  Widget _submitButton(BuildContext context) {
    final t = S.of(context);
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        // Loading state
        if (state is ForgotPasswordLoadingState) {
          Message.getMessage(context: context, title: t.loading, content: "");
        }
        // Completed state
        else if (state is ForgotPasswordCompletedState) {
          Navigator.pop(context);
          Message.getMessage(context: context, title: t.success, content: "");
          Future.delayed(const Duration(seconds: 1), () {});
        }
        // Error state
        else if (state is ForgotPasswordErrorState) {
          //Navigator.pop(context);
          Message.errorMessage(title: t.failed, context: context, content: state.message);
        }
      },
      listenWhen: (previous, current) {
        return current is ForgotPasswordLoadingState || current is ForgotPasswordCompletedState || current is ForgotPasswordErrorState;
      },
      builder: (context, state) {
        return SizedBox(
          child: ElevatedButton(
            key: forgotPasswordButtonSubmitKey,
            child: Text(t.email_send),
            onPressed: () {
              if (state is ForgotPasswordLoadingState) {
                return;
              }
              if (_forgotPasswordFormKey.currentState!.saveAndValidate()) {
                context
                    .read<ForgotPasswordBloc>()
                    .add(ForgotPasswordEmailChanged(email: _forgotPasswordFormKey.currentState!.fields["email"]!.value));
              }
            },
          ),
        );
      },
    );
  }
}
