import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/l10n/app_error_code_l10n.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

/// Page that renders a dynamic form from a remote JSON schema.
class DynamicFormPage extends StatefulWidget {
  const DynamicFormPage({super.key, required this.formId});

  final String formId;

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  /// What the form sent in its last successful submit.
  Map<String, dynamic> _submittedValues = const {};

  @override
  void initState() {
    super.initState();
    context.read<DynamicFormBloc>().add(DynamicFormLoadEvent(widget.formId));
  }

  /// The form holds unsaved changes once the user changes it, after it loads or after its last successful submit.
  bool _hasUnsavedChanges() => _formKey.currentState?.isDirty ?? false;

  /// Makes what the form submitted its unchanged state. The form stays on the page after a submit, so changes made
  /// after it must still count as unsaved.
  void _startFromSubmittedValues() {
    // The form saved the values it submitted, and the user could not change it while the submit ran.
    setState(() => _submittedValues = _formKey.currentState!.value);
    // The fields take the submitted values as their initial values when the page rebuilds, so the reset waits for it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _formKey.currentState?.reset());
  }

  /// Leaves the page for the page below it, or for the start page when nothing is below, as when the shell opened it.
  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      onBack: _navigateBack,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<DynamicFormBloc, DynamicFormState>(
      listener: (context, state) {
        if (state is DynamicFormSubmitted) {
          _startFromSubmittedValues();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Form submitted successfully'), duration: Duration(seconds: 2)));
        }
      },
      builder: (context, state) => switch (state) {
        DynamicFormInitial() || DynamicFormLoading() => const Center(child: CircularProgressIndicator()),
        DynamicFormFailure(:final error, :final errorCode) => AppErrorState(
          title: 'Error',
          description: errorCode?.resolve(context) ?? error,
          onRetry: () => context.read<DynamicFormBloc>().add(DynamicFormLoadEvent(widget.formId)),
        ),
        DynamicFormLoaded(:final schema) || DynamicFormSubmitting(:final schema) => _buildForm(
          context,
          schema,
          isSubmitting: state is DynamicFormSubmitting,
        ),
        DynamicFormSubmitted(:final schema) => _buildForm(
          context,
          schema,
          isSubmitting: false,
          initialValues: _submittedValues,
        ),
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    FormSchemaEntity schema, {
    required bool isSubmitting,
    Map<String, dynamic> initialValues = const {},
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(schema.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xl),
          DynamicFormRenderer(
            schema: schema,
            formKey: _formKey,
            readOnly: isSubmitting,
            initialValues: initialValues,
            onChanged: () => UnsavedChangesScope.formChanged(context),
            onSubmit: (data) => context.read<DynamicFormBloc>().add(DynamicFormSubmitEvent(data)),
          ),
        ],
      ),
    );
  }
}
