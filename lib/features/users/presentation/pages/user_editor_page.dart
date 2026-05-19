import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:flutter_bloc_advance/shared/widgets/user_form_fields.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/components.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

class UserEditorScreen extends StatefulWidget {
  const UserEditorScreen({super.key, this.id, this.username, required this.mode});

  final String? id;
  final String? username;
  final EditorFormMode mode;

  @override
  State<UserEditorScreen> createState() => _UserEditorScreenState();
}

class _UserEditorScreenState extends State<UserEditorScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<UserBloc>();
    final userId = widget.id ?? widget.username ?? '';
    final initialEvent = userId.isNotEmpty ? UserFetchEvent(userId) : const UserEditorInit();
    bloc.add(initialEvent);
  }

  @override
  Widget build(BuildContext context) {
    return _UserEditorView(mode: widget.mode);
  }
}

class _UserEditorView extends StatefulWidget {
  const _UserEditorView({required this.mode});

  final EditorFormMode mode;

  @override
  State<_UserEditorView> createState() => _UserEditorViewState();
}

class _UserEditorViewState extends State<_UserEditorView> {
  final _formKey = GlobalKey<FormBuilderState>();

  /// Extract the user payload from whichever variant currently holds one
  /// (Loading carries it forward during submit; success states carry their
  /// own copy).
  UserEntity? _userOf(UserState state) => switch (state) {
    UserLoading(:final data) => data,
    UserFetchSuccess(:final data) => data,
    UserSaveSuccess(:final data) => data,
    UserViewSuccess(:final data) => data,
    _ => null,
  };

  bool _isInitialLoading(UserState state) {
    return state is UserLoading && widget.mode != EditorFormMode.create && _userOf(state) == null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        if (state is UserSaveSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.of(context).success), duration: const Duration(seconds: 2)));
          context.go(ApplicationRoutesConstants.userList);
        }
        if (state is UserFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(S.of(context).failed), duration: const Duration(seconds: 2)));
        }
      },
      buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      builder: (context, state) => _buildPage(context, state),
    );
  }

  Widget _buildPage(BuildContext context, UserState state) {
    final user = _userOf(state);

    if (_isInitialLoading(state)) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((widget.mode == EditorFormMode.edit || widget.mode == EditorFormMode.view) && user == null) {
      return const Center(child: Text('No data'));
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isSubmitting = state is UserLoading && !_isInitialLoading(state);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                AppFormCard(
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Information', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Manage identity, contact, and access settings.',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  footer: AppFormActions(
                    secondaryAction: OutlinedButton(
                      key: widget.mode == EditorFormMode.view ? const Key('userEditorFormBackButtonKey') : null,
                      onPressed: () => _handleBack(context),
                      child: Text(widget.mode == EditorFormMode.view ? S.of(context).back : 'Cancel'),
                    ),
                    primaryAction: widget.mode == EditorFormMode.view
                        ? null
                        : FilledButton(
                            key: const Key('userEditorSubmitButtonKey'),
                            onPressed: isSubmitting ? null : () => _onSubmit(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSubmitting) ...[
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
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: {
                      'login': user?.login ?? '',
                      'firstName': user?.firstName ?? '',
                      'lastName': user?.lastName ?? '',
                      'email': user?.email ?? '',
                      'activated': user?.activated ?? true,
                      'authorities': user?.authorities?.firstOrNull ?? '',
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildFields(context, user)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context, UserEntity? user) {
    final readOnly = widget.mode == EditorFormMode.view;
    return [
      AppFormSection(
        title: 'Identity',
        description: 'Basic account identity details.',
        children: [
          AppFormField(
            label: S.of(context).login,
            child: UserFormFields.usernameField(context, user?.login, enabled: widget.mode == EditorFormMode.create),
          ),
          const SizedBox(height: 20),
          AppFormField(
            label: S.of(context).first_name,
            child: UserFormFields.firstNameField(context, user?.firstName, enabled: !readOnly),
          ),
          const SizedBox(height: 20),
          AppFormField(
            label: S.of(context).last_name,
            child: UserFormFields.lastNameField(context, user?.lastName, enabled: !readOnly),
          ),
        ],
      ),
      const SizedBox(height: 28),
      AppFormSection(
        title: 'Contact',
        description: 'Primary contact information.',
        children: [
          AppFormField(
            label: S.of(context).email,
            child: UserFormFields.emailField(context, user?.email, enabled: !readOnly),
          ),
        ],
      ),
      const SizedBox(height: 28),
      AppFormSection(
        title: 'Access',
        description: 'Account status and role permissions.',
        children: [
          AppFormField(
            label: S.of(context).active,
            child: UserFormFields.activatedField(context, user?.activated, enabled: !readOnly, showTitle: false),
          ),
          const SizedBox(height: 20),
          AppFormField(
            label: S.of(context).authorities,
            child: AuthoritiesDropdown(
              enabled: !readOnly,
              initialValue: user?.authorities?.firstOrNull,
              hintText: S.of(context).authorities,
              isRequired: true,
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _handleBack(BuildContext context) async {
    if (widget.mode == EditorFormMode.view) {
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

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final id = _userOf(context.read<UserBloc>().state)?.id;

      final user = const UserEntity().copyWith(
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
    }
  }

  String _getTitle(BuildContext context) {
    switch (widget.mode) {
      case EditorFormMode.create:
        return S.of(context).create_user;
      case EditorFormMode.edit:
        return S.of(context).edit_user;
      case EditorFormMode.view:
        return S.of(context).view_user;
    }
  }

  String _getSubtitle(BuildContext context) {
    switch (widget.mode) {
      case EditorFormMode.create:
        return 'Fill in the details to create a new user.';
      case EditorFormMode.edit:
        return 'Update user information below.';
      case EditorFormMode.view:
        return 'View user details.';
    }
  }
}

class UserEditorPage extends StatelessWidget {
  const UserEditorPage({super.key, this.id, this.username, required this.mode});

  final String? id;
  final String? username;
  final EditorFormMode mode;

  @override
  Widget build(BuildContext context) {
    return UserEditorScreen(id: id, username: username, mode: mode);
  }
}
