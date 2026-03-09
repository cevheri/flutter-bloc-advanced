import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/authorities_lov_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/user_form_fields.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class UserEditorScreen extends StatelessWidget {
  final String? id;
  final String? username;
  final EditorFormMode mode;

  const UserEditorScreen({super.key, this.id, this.username, required this.mode});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserBloc>();
    final userId = id ?? username ?? '';
    final initialEvent = userId.isNotEmpty ? UserFetchEvent(userId) : const UserEditorInit();
    bloc.add(initialEvent);
    return _UserEditorView(mode: mode);
  }
}

class _UserEditorView extends StatelessWidget {
  final EditorFormMode mode;
  final _formKey = GlobalKey<FormBuilderState>();

  _UserEditorView({required this.mode});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UserStatus.loading) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.of(context).loading), duration: const Duration(seconds: 2)));
        }
        if (state.status == UserStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.of(context).success), duration: const Duration(seconds: 2)));
        }
        if (state.status == UserStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.of(context).failed), duration: const Duration(seconds: 2)));
        }
      },
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => _buildPage(context, state),
    );
  }

  Widget _buildPage(BuildContext context, UserState state) {
    if (state.status == UserStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((mode == EditorFormMode.edit || mode == EditorFormMode.view) && state.data == null) {
      return const Center(child: Text("No data"));
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ──────────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      key: const Key('userEditorAppBarBackButtonKey'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      onPressed: () async => _handleBack(context),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTitle(context), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_getSubtitle(context), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Card form ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: {
                      'login': state.data?.login ?? '',
                      'firstName': state.data?.firstName ?? '',
                      'lastName': state.data?.lastName ?? '',
                      'email': state.data?.email ?? '',
                      'activated': state.data?.activated ?? true,
                      'authorities': state.data?.authorities?.firstOrNull ?? '',
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CardContent — form fields with gap-6 (24px)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildFields(context, state),
                          ),
                        ),

                        // CardFooter — actions
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: cs.outlineVariant)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Cancel / back
                              OutlinedButton(
                                key: mode == EditorFormMode.view ? const Key('userEditorFormBackButtonKey') : null,
                                onPressed: () => _handleBack(context),
                                child: Text(mode == EditorFormMode.view ? S.of(context).back : 'Cancel'),
                              ),
                              if (mode != EditorFormMode.view) ...[
                                const SizedBox(width: 8),
                                FilledButton(
                                  key: const Key('userEditorSubmitButtonKey'),
                                  onPressed: state.status == UserStatus.loading
                                      ? null
                                      : () => _onSubmit(context, state),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (state.status == UserStatus.loading) ...[
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      const Text('Save'),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context, UserState state) {
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: mode == EditorFormMode.create),
      const SizedBox(height: 20),
      UserFormFields.firstNameField(context, state.data?.firstName, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 20),
      UserFormFields.lastNameField(context, state.data?.lastName, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 20),
      UserFormFields.emailField(context, state.data?.email, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 20),
      UserFormFields.activatedField(context, state.data?.activated, enabled: mode != EditorFormMode.view),
      const SizedBox(height: 20),
      AuthoritiesDropdown(enabled: mode != EditorFormMode.view, initialValue: state.data?.authorities?.firstOrNull),
    ];
  }

  Future<void> _handleBack(BuildContext context) async {
    if (mode == EditorFormMode.view) {
      context.go(ApplicationRoutesConstants.userList);
      context.read<UserBloc>().add(const UserViewCompleteEvent());
      return;
    }

    if (!context.mounted) return;

    if (!(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      _navigateBack(context);
      return;
    }

    final shouldPop =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.of(ctx).warning),
            content: Text(S.of(ctx).unsaved_changes),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(S.of(ctx).yes)),
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(S.of(ctx).no)),
            ],
          ),
        ) ??
        false;

    if (shouldPop && context.mounted) {
      _navigateBack(context);
    }
  }

  void _navigateBack(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    if (extra != null && extra is Map<String, dynamic>) {
      final fromRoute = extra['fromRoute'] as String?;
      if (fromRoute == ApplicationRoutesConstants.userList) {
        context.go(ApplicationRoutesConstants.userList);
      } else {
        context.go(ApplicationRoutesConstants.home);
      }
    } else {
      context.go(ApplicationRoutesConstants.home);
    }
  }

  void _onSubmit(BuildContext context, UserState state) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final id = context.read<UserBloc>().state.data?.id;

      final user = const User().copyWith(
        id: id,
        login: formData['login'],
        firstName: formData['firstName'],
        lastName: formData['lastName'],
        email: formData['email'],
        activated: formData['activated'],
        langKey: 'en',
        authorities: [formData['authorities'] ?? ''],
      );

      context.read<UserBloc>().add(UserSubmitEvent(user));
      context.read<UserBloc>().add(const UserSaveCompleteEvent());
      context.go(ApplicationRoutesConstants.userList);
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

  String _getSubtitle(BuildContext context) {
    switch (mode) {
      case EditorFormMode.create:
        return 'Fill in the details to create a new user.';
      case EditorFormMode.edit:
        return 'Update user information below.';
      case EditorFormMode.view:
        return 'View user details.';
    }
  }
}
