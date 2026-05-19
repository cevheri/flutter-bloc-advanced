import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Page that renders a dynamic form from a remote JSON schema.
class DynamicFormPage extends StatefulWidget {
  const DynamicFormPage({super.key, required this.formId});

  final String formId;

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    context.read<DynamicFormBloc>().add(DynamicFormLoadEvent(widget.formId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DynamicFormBloc, DynamicFormState>(
      listener: (context, state) {
        if (state is DynamicFormSubmitted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Form submitted successfully'), duration: Duration(seconds: 2)));
        }
      },
      builder: (context, state) => switch (state) {
        DynamicFormInitial() || DynamicFormLoading() => const Center(child: CircularProgressIndicator()),
        DynamicFormFailure(:final error) => AppErrorState(
          title: 'Error',
          description: error,
          onRetry: () => context.read<DynamicFormBloc>().add(DynamicFormLoadEvent(widget.formId)),
        ),
        DynamicFormLoaded(:final schema) ||
        DynamicFormSubmitting(:final schema) ||
        DynamicFormSubmitted(
          :final schema,
        ) => _buildForm(context, schema, isSubmitting: state is DynamicFormSubmitting),
      },
    );
  }

  Widget _buildForm(BuildContext context, FormSchemaEntity schema, {required bool isSubmitting}) {
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
            onSubmit: (data) => context.read<DynamicFormBloc>().add(DynamicFormSubmitEvent(data)),
          ),
        ],
      ),
    );
  }
}
