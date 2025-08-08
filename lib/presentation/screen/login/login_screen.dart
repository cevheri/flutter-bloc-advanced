import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_key_constants.dart';
import 'package:flutter_bloc_advance/configuration/constants.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
import 'package:flutter_bloc_advance/routes/app_router.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_bloc_advance/utils/app_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../generated/l10n.dart';
import 'bloc/login.dart';

class LoginScreen extends StatelessWidget {
  final GlobalKey<FormBuilderState> _loginFormKey = GlobalKey<FormBuilderState>(debugLabel: '__loginFormKey__');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: '__loginScaffoldKey__');

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(key: _scaffoldKey, appBar: _buildAppBar(context), body: _buildBody(context));
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(title: const Text(AppConstants.appName), leading: Container());

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return ResponsiveFormBuilder(
          formKey: _loginFormKey,
          children: <Widget>[
            _logo(context),
            _usernameField(context),
            _passwordField(context),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[_submitButton(context)]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_forgotPasswordLink(context)]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_register(context)]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_otpLoginButton(context)]),
            _validationZone(),
          ],
        );
      },
    );
  }

  Image _logo(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Image.asset(LocaleConstants.logoLightUrl, width: MediaQuery.of(context).size.width * 0.2);
    } else {
      return Image.asset(LocaleConstants.defaultImgUrl, width: MediaQuery.of(context).size.width * 0.2);
    }
  }

  Widget _usernameField(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: FormBuilderTextField(
            key: loginTextFieldUsernameKey,
            name: 'username',
            decoration: InputDecoration(labelText: S.of(context).login_user_name),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: S.of(context).required_field),
              FormBuilderValidators.minLength(4, errorText: S.of(context).min_length_4),
              FormBuilderValidators.maxLength(20, errorText: S.of(context).max_length_20),
            ]),
          ),
        );
      },
    );
  }

  Widget _passwordField(BuildContext context) {
    final fieldWidth = MediaQuery.of(context).size.width * 0.6;
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SizedBox(
          width: fieldWidth,
          child: Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  key: loginTextFieldPasswordKey,
                  name: 'password',
                  decoration: InputDecoration(labelText: S.of(context).login_password),
                  // when press the enter key, call submit button function
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (_loginFormKey.currentState!.saveAndValidate()) {
                      final username = _loginFormKey.currentState!.value['username'];
                      final password = _loginFormKey.currentState!.value['password'];
                      _submitEvent(context, username: username, password: password);
                    }
                  },
                  obscureText: !state.passwordVisible,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: S.of(context).required_field),
                    FormBuilderValidators.minLength(4, errorText: S.of(context).password_min_length),
                    FormBuilderValidators.maxLength(20, errorText: S.of(context).password_max_length),
                  ]),
                ),
              ),
              IconButton(
                key: loginButtonPasswordVisibilityKey,
                icon: Icon(state.passwordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => context.read<LoginBloc>().add(const TogglePasswordVisibility()),
              ),
            ],
          ),
        );
      },
    );
  }

  _submitButton(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        debugPrint("BEGIN: login submit button listener username${state.username}");

        if (state is LoginLoadingState) {
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(S.of(context).loading),
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          );
        } else if (state is LoginLoadedState) {
          debugPrint("BEGIN: login submit button listener LoginLoadedState");
          AppRouter().push(context, ApplicationRoutesConstants.home);
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).hideCurrentSnackBar();
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(S.of(context).success),
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          );
          debugPrint("END: login submit button listener LoginLoadedState");
        } else if (state is LoginErrorState) {
          debugPrint("BEGIN: login submit button listener LoginErrorState");
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).hideCurrentSnackBar();
          ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(S.of(context).failed),
              backgroundColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
          );
          debugPrint("END: login submit button listener LoginErrorState");
        }
      },
      child: SizedBox(
        child: FilledButton(
          key: loginButtonSubmitKey,
          child: Text(S.of(context).login_button),
          onPressed: () {
            if (_loginFormKey.currentState!.saveAndValidate()) {
              final username = _loginFormKey.currentState!.value['username'];
              final password = _loginFormKey.currentState!.value['password'];
              _submitEvent(context, username: username, password: password);
            }
          },
        ),
      ),
    );
  }

  void _submitEvent(BuildContext context, {required String username, required String password}) {
    context.read<LoginBloc>().add(LoginFormSubmitted(username: username, password: password));
  }

  _forgotPasswordLink(BuildContext context) {
    return SizedBox(
      child: TextButton(
        key: loginButtonForgotPasswordKey,
        onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.forgotPassword),
        child: Text(S.of(context).password_forgot),
      ),
    );
  }

  _register(BuildContext context) {
    return SizedBox(
      child: TextButton(
        key: loginButtonRegisterKey,
        onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.register),
        child: Text(S.of(context).register),
      ),
    );
  }

  Widget _validationZone() {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => current is LoginErrorState,
      builder: (context, state) {
        final font = Theme.of(context).textTheme.bodyLarge!.fontSize;
        final color = Theme.of(context).colorScheme.error;
        return Visibility(
          visible: state is LoginErrorState,
          child: Center(
            child: Text(
              S.of(context).failed,
              style: TextStyle(fontSize: font, color: color),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

Widget _otpLoginButton(BuildContext context) {
  return TextButton(
    key: const Key('loginButtonOtpKey'),
    onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.loginOtp),
    child: Text(S.of(context).login_with_email),
  );
}

class OtpEmailScreen extends StatelessWidget {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  OtpEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(S.of(context).login_with_email),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.login),
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.isOtpSent != current.isOtpSent ||
            previous.email != current.email,
        listener: (context, state) {
          debugPrint("BEGIN: otp email screen listener state: ${state.props}");
          if (state.status == LoginStatus.success && state.isOtpSent == true && state.email != null) {
            debugPrint("Navigating to verify screen with email: ${state.email}");
            AppRouter().push(context, '${ApplicationRoutesConstants.loginOtpVerify}/${state.email}');
          } else if (state.status == LoginStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).failed)));
          }
        },
        child: ResponsiveFormBuilder(formKey: _formKey, children: [_emailField(context), _submitButton(context)]),
      ),
    );
  }

  Widget _emailField(BuildContext context) {
    return FormBuilderTextField(
      name: 'email',
      decoration: InputDecoration(labelText: S.of(context).email, prefixIcon: const Icon(Icons.email)),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
        FormBuilderValidators.email(errorText: S.of(context).invalid_email),
      ]),
    );
  }

  Widget _submitButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        debugPrint("BEGIN: otp email screen submit button builder state: $state");
        return ResponsiveSubmitButton(
          buttonText: S.of(context).send_otp_code,
          isLoading: state.status == LoginStatus.loading,
          onPressed: () {
            if (_formKey.currentState?.saveAndValidate() ?? false) {
              final email = _formKey.currentState!.value['email'] as String;
              context.read<LoginBloc>().add(SendOtpRequested(email: email));
            }
          },
        );
      },
    );
  }
}

class OtpVerifyScreen extends StatelessWidget {
  final String email;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  OtpVerifyScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(S.of(context).verify_otp_code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter().push(context, ApplicationRoutesConstants.loginOtp),
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        // listenWhen: (previous, current) =>
        //   previous.status != current.status &&
        //   current.loginMethod == LoginMethod.otp,
        listener: (context, state) {
          debugPrint("BEGIN: otp verify screen listener state: $state");
          if (state is LoginLoadedState) {
            AppRouter().push(context, ApplicationRoutesConstants.home);
          }
        },
        child: ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            Text('${S.of(context).otp_sent_to} $email'),
            _otpField(context),
            _submitButton(context),
            _resendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _otpField(BuildContext context) {
    return FormBuilderTextField(
      name: 'otpCode',
      decoration: InputDecoration(labelText: S.of(context).otp_code, prefixIcon: const Icon(Icons.lock_clock)),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
        FormBuilderValidators.numeric(errorText: S.of(context).only_numbers),
        FormBuilderValidators.minLength(6, errorText: S.of(context).otp_length),
        FormBuilderValidators.maxLength(6, errorText: S.of(context).otp_length),
      ]),
    );
  }

  Widget _submitButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status && current.loginMethod == LoginMethod.otp,
      builder: (context, state) {
        return ResponsiveSubmitButton(
          buttonText: S.of(context).verify_otp_code,
          isLoading: state.status == LoginStatus.loading,
          onPressed: () {
            if (_formKey.currentState?.saveAndValidate() ?? false) {
              final otpCode = _formKey.currentState!.value['otpCode'] as String;
              context.read<LoginBloc>().add(VerifyOtpSubmitted(email: email, otpCode: otpCode));
            }
          },
        );
      },
    );
  }

  Widget _resendButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.read<LoginBloc>().add(SendOtpRequested(email: email)),
      child: Text(S.of(context).resend_otp_code),
    );
  }
}
