import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/shared/widgets/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/shared/widgets/submit_button_widget.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

import '../../application/login_bloc.dart';
import '../../../../generated/l10n.dart';
import '../widgets/community_section_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onToggleTheme});

  /// Wired by the router; null = non-interactive badge (features cannot import app/theme).
  final VoidCallback? onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<FormBuilderState> _loginFormKey = GlobalKey<FormBuilderState>(debugLabel: '__loginFormKey__');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: '__loginScaffoldKey__');
  late AnimationController _animController;
  final FocusNode _forgotPwFocus = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
  }

  @override
  void dispose() {
    _forgotPwFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: BlocListener<LoginBloc, LoginState>(
        listener: _onLoginStateChange,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              return isDesktop ? _desktopLayout(context, isDark) : _mobileLayout(context, isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(flex: 55, child: _brandPanel(context, isDark)),
        Expanded(flex: 45, child: _formPanel(context, isDark)),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(color: cs.surface),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: FadeTransition(
                opacity: _animController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandIcon(isDark),
                    const SizedBox(height: 32),
                    _formHeading(context),
                    const SizedBox(height: 32),
                    _formBody(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 12, right: 12, child: _themeBadge(isDark)),
      ],
    );
  }

  Widget _brandPanel(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF020617), const Color(0xFF0C1222), const Color(0xFF020617)]
              : [const Color(0xFF0f172a), const Color(0xFF1B2B4B), const Color(0xFF0f172a)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -120, left: -80, child: _gradientOrb(420, const Color(0xFF6366F1), isDark ? 0.25 : 0.3)),
          Positioned(bottom: -180, right: -120, child: _gradientOrb(480, const Color(0xFF8B5CF6), isDark ? 0.2 : 0.25)),
          Positioned(top: 180, right: -60, child: _gradientOrb(280, const Color(0xFF06B6D4), isDark ? 0.15 : 0.18)),
          Positioned(bottom: 100, left: -40, child: _gradientOrb(200, const Color(0xFF3B82F6), isDark ? 0.12 : 0.15)),
          Padding(
            padding: const EdgeInsets.all(48),
            child: FadeTransition(
              opacity: _animController,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _brandBadges(),
                      const SizedBox(height: 40),
                      _heroText(),
                      const SizedBox(height: 16),
                      _heroSubtext(),
                      const SizedBox(height: 20),
                      _statsRow(),
                      const SizedBox(height: 40),
                      _featureCards(),
                      const SizedBox(height: 10),
                      const CommunitySectionWidget(isDesktop: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _brandBadges() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _glassPill('Advanced Flutter BLoC Template', const Color(0xFFA5B4FC)),
        _glassPill('Flutter 3.41.8', const Color(0xFF94A3B8)),
      ],
    );
  }

  Widget _glassPill(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.2),
      ),
    );
  }

  Widget _heroText() {
    return const Text(
      'Scale from prototype\nto production.',
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
        letterSpacing: -1.5,
      ),
    );
  }

  Widget _heroSubtext() {
    return Text(
      'Authentication, role-based access, user management,\ntheming, and multi-environment support in one robust starter.',
      style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.55), height: 1.65),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statItem('7+', 'Platforms'),
        _statDot(),
        _statItem('5', 'Core Layers'),
        _statDot(),
        _statItem('100%', 'BLoC Ready'),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
      ],
    );
  }

  Widget _statDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }

  Widget _featureCards() {
    return Column(
      children: [
        _glassFeatureCard(
          Icons.shield_outlined,
          'Authentication & Access Control',
          'Password and OTP login flows with role-based routing guards.',
        ),
        const SizedBox(height: 10),
        _glassFeatureCard(
          Icons.layers_outlined,
          'Clean Architecture',
          'BLoC + Repository pattern with clear separation of concerns.',
        ),
        const SizedBox(height: 10),
        _glassFeatureCard(
          Icons.swap_horiz_outlined,
          'Mock to Real API',
          'Develop locally with mock data and switch to production endpoints.',
        ),
      ],
    );
  }

  Widget _glassFeatureCard(IconData icon, String title, String subtitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFA5B4FC)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formPanel(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _animController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _brandIcon(isDark),
                      const SizedBox(height: 36),
                      _formHeading(context),
                      const SizedBox(height: 32),
                      _formBody(context, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 16, right: 16, child: _themeBadge(isDark)),
        ],
      ),
    );
  }

  Widget _brandIcon(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Icon(Icons.bolt_rounded, size: 24, color: cs.onSurface),
    );
  }

  Widget _formHeading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your credentials to access your account',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _formBody(BuildContext context, bool isDark) {
    return FormBuilder(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(context, S.of(context).login_user_name),
          const SizedBox(height: 8),
          _usernameField(context),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _fieldLabel(context, S.of(context).login_password)),
              _forgotPasswordLink(context),
            ],
          ),
          const SizedBox(height: 8),
          _passwordField(context),
          const SizedBox(height: 8),
          _validationZone(),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: _submitButton(context)),
          const SizedBox(height: 16),
          _dividerWithOr(context),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _otpLoginButton(context)),
          const SizedBox(height: 28),
          _registerLink(context),
          const SizedBox(height: 4),
          const CommunitySectionWidget(isDesktop: false),
          const SizedBox(height: 16),
          _versionText(context),
        ],
      ),
    );
  }

  Widget _versionText(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'v${AppConstants.appVersion}+${AppConstants.appBuildNumber}',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _dividerWithOr(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }

  Widget _registerLink(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text("Don't have an account? ", style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          TextButton(
            key: loginButtonRegisterKey,
            onPressed: () => context.push(ApplicationRoutesConstants.register),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              S.of(context).register,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeBadge(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final badge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 18, color: cs.onSurfaceVariant),
    );

    final onToggle = widget.onToggleTheme;
    if (onToggle == null) return badge;

    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onToggle, borderRadius: radius, child: badge),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500));
  }

  Widget _usernameField(BuildContext context) {
    return FormBuilderTextField(
      key: loginTextFieldUsernameKey,
      name: 'username',
      decoration: const InputDecoration(hintText: 'm@example.com'),
      textInputAction: TextInputAction.next,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: S.of(context).required_field),
        FormBuilderValidators.minLength(4, errorText: S.of(context).min_length_4),
        FormBuilderValidators.maxLength(20, errorText: S.of(context).max_length_20),
      ]),
    );
  }

  Widget _passwordField(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return FormBuilderTextField(
          key: loginTextFieldPasswordKey,
          name: 'password',
          decoration: InputDecoration(
            hintText: '********',
            suffixIcon: IconButton(
              key: loginButtonPasswordVisibilityKey,
              icon: Icon(state.passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => context.read<LoginBloc>().add(const TogglePasswordVisibility()),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _trySubmit(context),
          obscureText: !state.passwordVisible,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: S.of(context).required_field),
            FormBuilderValidators.minLength(4, errorText: S.of(context).password_min_length),
            FormBuilderValidators.maxLength(20, errorText: S.of(context).password_max_length),
          ]),
        );
      },
    );
  }

  Widget _submitButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        final isLoading = state is LoginLoadingState;
        return FilledButton(
          key: loginButtonSubmitKey,
          onPressed: isLoading ? null : () => _trySubmit(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                  )
                : Text(S.of(context).login_button),
          ),
        );
      },
    );
  }

  Widget _forgotPasswordLink(BuildContext context) {
    return TextButton(
      key: loginButtonForgotPasswordKey,
      focusNode: _forgotPwFocus,
      onPressed: () => context.push(ApplicationRoutesConstants.forgotPassword),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(S.of(context).password_forgot, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _validationZone() {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => current is LoginErrorState,
      builder: (context, state) {
        final color = Theme.of(context).colorScheme.error;
        return Visibility(
          visible: state is LoginErrorState,
          child: Center(
            child: Text(
              S.of(context).failed,
              style: TextStyle(fontSize: 14, color: color),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  void _trySubmit(BuildContext context) {
    if (_loginFormKey.currentState?.saveAndValidate() ?? false) {
      final username = _loginFormKey.currentState!.value['username'] as String;
      final password = _loginFormKey.currentState!.value['password'] as String;
      context.read<LoginBloc>().add(LoginFormSubmitted(username: username, password: password));
    }
  }

  void _onLoginStateChange(BuildContext context, LoginState state) {
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
      context.go(ApplicationRoutesConstants.home);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).hideCurrentSnackBar();
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(S.of(context).success),
          backgroundColor: Theme.of(context).colorScheme.primary,
          width: MediaQuery.of(context).size.width * 0.8,
        ),
      );
    } else if (state is LoginErrorState) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).hideCurrentSnackBar();
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(S.of(context).failed),
          backgroundColor: Theme.of(context).colorScheme.error,
          width: MediaQuery.of(context).size.width * 0.8,
        ),
      );
    }
  }
}

Widget _otpLoginButton(BuildContext context) {
  return OutlinedButton(
    key: const Key('loginButtonOtpKey'),
    onPressed: () => context.push(ApplicationRoutesConstants.loginOtp),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(S.of(context).login_with_email)),
  );
}

class OtpEmailScreen extends StatelessWidget {
  OtpEmailScreen({super.key});

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(S.of(context).login_with_email),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _popOrFallback(context, ApplicationRoutesConstants.login),
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.isOtpSent != current.isOtpSent ||
            previous.email != current.email,
        listener: (context, state) {
          if (state.status == LoginStatus.success && state.isOtpSent == true && state.email != null) {
            context.go('${ApplicationRoutesConstants.loginOtpVerify}/${state.email}');
          } else if (state.status == LoginStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).failed)));
          }
        },
        child: ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
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
            _submitOtpButton(context),
          ],
        ),
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

  Widget _submitOtpButton(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
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
  OtpVerifyScreen({super.key, required this.email});

  final String email;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(S.of(context).verify_otp_code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _popOrFallback(context, ApplicationRoutesConstants.loginOtp),
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginLoadedState) {
            context.go(ApplicationRoutesConstants.home);
          }
        },
        child: ResponsiveFormBuilder(
          formKey: _formKey,
          children: [
            Text('${S.of(context).otp_sent_to} $email'),
            _otpField(context),
            _submitVerifyButton(context),
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

  Widget _submitVerifyButton(BuildContext context) {
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

void _popOrFallback(BuildContext context, String fallbackRoute) {
  if (GoRouter.of(context).canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}
