import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/authorities_lov_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/editor_form_mode.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/submit_button_widget.dart';
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
    return UserEditorWidget(mode: mode);
  }
}

_showMessage(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey, String title, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(content), duration: const Duration(seconds: 2)));
}

class UserEditorWidget extends StatelessWidget {
  final EditorFormMode mode;
  final _formKey = GlobalKey<FormBuilderState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  UserEditorWidget({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UserStatus.loading) {
          _showMessage(context, _scaffoldKey, S.of(context).loading, S.of(context).loading);
        }

        if (state.status == UserStatus.success) {
          _showMessage(context, _scaffoldKey, S.of(context).success, S.of(context).success);
        }

        if (state.status == UserStatus.failure) {
          _showMessage(context, _scaffoldKey, S.of(context).failed, S.of(context).failed);
        }
      },
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context, state));
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(_getTitle(context)),
      leading: IconButton(
        key: const Key('userEditorAppBarBackButtonKey'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () async => _handlePopScope(false, null, context),
      ),
    );
  }

  Future<void> _handlePopScope(bool didPop, Object? data, [BuildContext? contextParam]) async {
    final context = contextParam ?? data as BuildContext;

    if (mode == EditorFormMode.view) {
      // View modunda user list'e dön
      context.go(ApplicationRoutesConstants.userList);
      context.read<UserBloc>().add(const UserViewCompleteEvent());
      return;
    }

    if (!context.mounted) return;

    if (didPop || !(_formKey.currentState?.isDirty ?? false) || _formKey.currentState == null) {
      // Nereden geldiğine göre yönlendirme yap
      _navigateBack(context);
      return;
    }

    final shouldPop = await _buildShowDialog(context) ?? false;
    if (shouldPop && context.mounted) {
      // Nereden geldiğine göre yönlendirme yap
      _navigateBack(context);
    }
  }

  void _navigateBack(BuildContext context) {
    // GoRouter'ın extra parametresini kontrol et
    final extra = GoRouterState.of(context).extra;

    if (extra != null && extra is Map<String, dynamic>) {
      final fromRoute = extra['fromRoute'] as String?;

      if (fromRoute == ApplicationRoutesConstants.userList) {
        // User list'ten geldiyse user list'e dön
        context.go(ApplicationRoutesConstants.userList);
      } else {
        // Diğer durumlarda ana sayfaya dön
        context.go(ApplicationRoutesConstants.home);
      }
    } else {
      // Extra parametre yoksa ana sayfaya dön
      context.go(ApplicationRoutesConstants.home);
    }
  }

  Future<bool?> _buildShowDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).warning),
        content: Text(S.of(context).unsaved_changes),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(S.of(context).yes)),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.of(context).no)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserState state) {
    if (state.status == UserStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((mode == EditorFormMode.edit || mode == EditorFormMode.view) && state.data == null) {
      //return const Center(child: CircularProgressIndicator());
      return const Center(child: Text("No data"));
    }

    debugPrint("checkpoint data: ${state.data?.login}");
    debugPrint("checkpoint status: ${state.status}");
    // Get initial values for FormBuilder
    final initialValue = {
      'login': state.data?.login ?? '',
      'firstName': state.data?.firstName ?? '',
      'lastName': state.data?.lastName ?? '',
      'email': state.data?.email ?? '',
      'activated': state.data?.activated ?? true,
      'authorities': state.data?.authorities?.firstOrNull ?? '',
    };
    debugPrint("checkpoint initial value: $initialValue");
    return ResponsiveFormBuilder(
      formKey: _formKey,
      initialValue: initialValue,
      children: [
        ..._buildFormFields(context, state),
        if (mode == EditorFormMode.view) _backButtonField(context),
        if (mode != EditorFormMode.view) _submitButtonField(context, state),
      ],
    );
  }

  Widget _backButtonField(BuildContext context) {
    return ResponsiveSubmitButton(
      key: const Key('userEditorFormBackButtonKey'),
      buttonText: S.of(context).back,
      onPressed: () {
        context.go(ApplicationRoutesConstants.userList);
        context.read<UserBloc>().add(const UserViewCompleteEvent());
      },
    );
  }

  //TODO loading state
  Widget _submitButtonField(BuildContext context, UserState state) {
    return ResponsiveSubmitButton(
      key: const Key('userEditorSubmitButtonKey'),
      onPressed: () => state.status == UserStatus.loading ? null : _onSubmit(context, state),
      isLoading: state.status == UserStatus.loading,
    );
  }

  void _onSubmit(BuildContext context, UserState state) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final id = context.read<UserBloc>().state.data?.id;
      debugPrint("checkpoint form data: $formData");

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

  List<Widget> _buildFormFields(BuildContext context, UserState state) {
    debugPrint("checkpoint build form fields: ${state.data?.login}");
    return [
      UserFormFields.usernameField(context, state.data?.login, enabled: mode == EditorFormMode.create),
      UserFormFields.firstNameField(context, state.data?.firstName, enabled: mode != EditorFormMode.view),
      UserFormFields.lastNameField(context, state.data?.lastName, enabled: mode != EditorFormMode.view),
      UserFormFields.emailField(context, state.data?.email, enabled: mode != EditorFormMode.view),
      UserFormFields.activatedField(context, state.data?.activated, enabled: mode != EditorFormMode.view),
      AuthoritiesDropdown(enabled: mode != EditorFormMode.view, initialValue: state.data?.authorities?.firstOrNull),
    ];
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
}
