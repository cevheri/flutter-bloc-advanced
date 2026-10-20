import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/users/domain/user_roles.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:flutter_bloc_advance/shared/widgets/user_form_fields.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/components.dart';
import 'package:flutter_bloc_advance/shared/l10n/app_error_code_l10n.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
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
  String get _userId => widget.id ?? widget.username ?? '';

  @override
  void initState() {
    super.initState();
    final bloc = context.read<UserEditorBloc>();
    final initialEvent = _userId.isNotEmpty ? UserEditorFetch(_userId) : const UserEditorReset();
    bloc.add(initialEvent);
  }

  @override
  Widget build(BuildContext context) {
    return _UserEditorView(
      mode: widget.mode,
      onRetry: () => context.read<UserEditorBloc>().add(UserEditorFetch(_userId)),
    );
  }
}

class _UserEditorView extends StatefulWidget {
  const _UserEditorView({required this.mode, required this.onRetry});

  final EditorFormMode mode;

  /// Fetches the user again after the fetch failed.
  final VoidCallback onRetry;

  @override
  State<_UserEditorView> createState() => _UserEditorViewState();
}

class _UserEditorViewState extends State<_UserEditorView> {
  final _formKey = GlobalKey<FormBuilderState>();

  /// Extract the user payload from whichever variant currently holds one
  /// (Loading carries it forward during submit, a failed save keeps it,
  /// and success states carry their own copy).
  UserEntity? _userOf(UserEditorState state) => switch (state) {
    UserEditorLoaded(:final data) => data,
    UserEditorLoading(:final data) ||
    UserEditorSaved(:final data) ||
    UserEditorViewed(:final data) ||
    UserEditorSaveFailure(:final data) => data,
    UserEditorInitial() || UserEditorFetchFailure() => null,
  };

  /// Edit and view show the form only once the user is fetched; create starts from an empty form.
  bool get _fetchesUser => widget.mode != EditorFormMode.create;

  /// The form holds unsaved changes until the save succeeds; the page then leaves for the list without asking.
  bool _hasUnsavedChanges() => switch (context.read<UserEditorBloc>().state) {
    UserEditorSaved() => false,
    _ => _formKey.currentState?.isDirty ?? false,
  };

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      onBack: () => _handleBack(context),
      child: _buildEditor(context),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return BlocConsumer<UserEditorBloc, UserEditorState>(
      listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        switch (state) {
          case UserEditorSaved():
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(S.of(context).success), duration: const Duration(seconds: 2)));
            context.go(ApplicationRoutesConstants.userList);
          case UserEditorSaveFailure():
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(S.of(context).failed), duration: const Duration(seconds: 2)));
          case UserEditorInitial() ||
              UserEditorLoading() ||
              UserEditorLoaded() ||
              UserEditorViewed() ||
              UserEditorFetchFailure():
            break;
        }
      },
      buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      builder: (context, state) => switch (state) {
        UserEditorInitial() ||
        UserEditorLoading(data: null) when _fetchesUser => const Center(child: CircularProgressIndicator()),
        UserEditorFetchFailure(:final errorCode) => _buildPage(
          context,
          body: AppErrorState(
            title: S.of(context).user_load_failed,
            description: errorCode.resolve(context),
            retryLabel: S.of(context).refresh,
            onRetry: widget.onRetry,
          ),
        ),
        UserEditorInitial() => _buildPage(context, body: _buildForm(context, null)),
        UserEditorLoading(:final data) => _buildPage(context, body: _buildForm(context, data, isSubmitting: true)),
        UserEditorLoaded(:final data) => _buildPage(context, body: _buildForm(context, data)),
        UserEditorSaved(:final data) ||
        UserEditorViewed(:final data) ||
        UserEditorSaveFailure(:final data) => _buildPage(context, body: _buildForm(context, data)),
      },
    );
  }

  /// The page header with the back button, above [body].
  Widget _buildPage(BuildContext context, {required Widget body}) {
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
                Row(
                  children: [
                    IconButton(
                      key: const Key('userEditorAppBarBackButtonKey'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      onPressed: () => _handleBack(context),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getTitle(context), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_getSubtitle(context), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, UserEntity? user, {bool isSubmitting = false}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppFormCard(
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
        onChanged: () => UnsavedChangesScope.formChanged(context),
        initialValue: {
          'login': user?.login ?? '',
          'firstName': user?.firstName ?? '',
          'lastName': user?.lastName ?? '',
          'email': user?.email ?? '',
          'activated': user?.activated ?? true,
          'authorities': primaryRole(user?.authorities) ?? '',
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.mode != EditorFormMode.create && user?.id != null) ...[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  key: const Key('userExtendedInfoButtonKey'),
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(S.of(context).user_extended_info_button),
                  onPressed: () => context.push('/user/${user!.id}/extended-info'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ..._buildFields(context, user),
          ],
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
              initialValue: primaryRole(user?.authorities),
              hintText: S.of(context).authorities,
              isRequired: true,
            ),
          ),
        ],
      ),
    ];
  }

  void _handleBack(BuildContext context) {
    if (widget.mode == EditorFormMode.view) {
      context.go(ApplicationRoutesConstants.userList);
      context.read<UserEditorBloc>().add(const UserEditorViewComplete());
      return;
    }
    _navigateBack(context);
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
      // An edit starts from the fetched user, so what the form does not show, such as the language, is saved as
      // it was. A new user starts in English.
      final original = _userOf(context.read<UserEditorBloc>().state) ?? const UserEntity(langKey: 'en');
      // The roles field shows only the user's primary role, so leaving it keeps all of the user's roles and picking
      // another role replaces them with that role.
      final role = formData['authorities'] as String;
      final authorities = role == primaryRole(original.authorities) ? original.authorities : [role];

      final user = original.copyWith(
        login: formData['login'],
        firstName: formData['firstName'],
        lastName: formData['lastName'],
        email: formData['email'],
        activated: formData['activated'],
        authorities: authorities,
      );

      context.read<UserEditorBloc>().add(UserEditorSubmit(user));
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
