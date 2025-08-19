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

  AppBar _buildAppBar(BuildContext context) => AppBar(
    title: const Text(AppConstants.appName),
    leading: const SizedBox.shrink(),
    backgroundColor: Colors.transparent,
    elevation: 0,
  );

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(LocaleConstants.logoDarkUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.srcOver),
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final formCard = _buildFormCard(context);

            if (!isWide) {
              // Mobil cihazlar için
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: formCard),
              );
            } else {
              // Geniş ekranlar için - login formu ortada, quote altta
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Üstte boş alan
                    const Expanded(flex: 1, child: SizedBox()),
                    // Ortada login formu
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: formCard),
                    // Altta quote
                    const Expanded(flex: 1, child: SizedBox()),
                    // Quote metni
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '"Simply all the tools that my team and I need."',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            shadows: [const Shadow(blurRadius: 6, color: Colors.black45)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ResponsiveFormBuilder(
              formKey: _loginFormKey,
              children: <Widget>[
                Text(S.of(context).login, style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  AppConstants.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                _usernameField(context),
                _passwordField(context),
                Align(alignment: Alignment.centerRight, child: _submitButton(context)),
                _validationZone(),
                _orDivider(context),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_otpLoginButton(context)]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_forgotPasswordLink(context)]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[_register(context)]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orDivider(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('OR', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }

  Widget _usernameField(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: FormBuilderTextField(
            key: loginTextFieldUsernameKey,
            name: 'username',
            decoration: InputDecoration(
              labelText: S.of(context).login_user_name,
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
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
                  decoration: InputDecoration(
                    labelText: S.of(context).login_password,
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                  ),
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
        child: ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            // Alt başlık eklendi (AppBar'da zaten başlık var)
            Text(
              'Enter your email to receive OTP code',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            _emailField(context),
            _submitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _emailField(BuildContext context) {
    return FormBuilderTextField(
      name: 'email',
      decoration: InputDecoration(
        labelText: S.of(context).email,
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
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
      decoration: InputDecoration(
        labelText: S.of(context).otp_code,
        prefixIcon: const Icon(Icons.lock_clock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
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
