import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/load_form_schema_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/submit_form_usecase.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc({
    required this._loadFormSchemaUseCase,
    required this._submitFormUseCase,
    required this._loadFormBundleUseCase,
  }) : super(const DynamicFormInitial()) {
    on<DynamicFormLoadEvent>(_onLoad, transformer: EventTransformers.restart());
    on<DynamicFormLoadBundleEvent>(_onLoadBundle, transformer: EventTransformers.restart());
    on<DynamicFormSubmitEvent>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<DynamicFormResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('DynamicFormBloc');

  final LoadFormSchemaUseCase _loadFormSchemaUseCase;
  final SubmitFormUseCase _submitFormUseCase;
  final LoadFormBundleUseCase _loadFormBundleUseCase;

  FutureOr<void> _onLoad(DynamicFormLoadEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form schema: {}', [event.formId]);
    emit(const DynamicFormLoading());
    final result = await _loadFormSchemaUseCase(event.formId);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormLoaded(schema: data));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message));
    }
  }

  FutureOr<void> _onSubmit(DynamicFormSubmitEvent event, Emitter<DynamicFormState> emit) async {
    final (schema, submitPathParams) = switch (state) {
      DynamicFormLoaded(:final schema, :final submitPathParams) => (schema, submitPathParams),
      DynamicFormSubmitting(:final schema, :final submitPathParams) => (schema, submitPathParams),
      DynamicFormSubmitted(:final schema, :final submitPathParams) => (schema, submitPathParams),
      DynamicFormFailure(:final schema?, :final submitPathParams) => (schema, submitPathParams),
      _ => (null, null),
    };
    if (schema == null) return;

    _log.debug('Submitting form: {} pathParams: {}', [schema.id, submitPathParams]);
    emit(DynamicFormSubmitting(schema: schema, submitPathParams: submitPathParams));

    final action = schema.submitAction;
    if (action == null) {
      _log.info('No submit action defined — logging form data: {}', [event.data]);
      emit(
        DynamicFormSubmitted(schema: schema, submitResponse: 'Form data logged', submitPathParams: submitPathParams),
      );
      return;
    }

    final result = await _submitFormUseCase(action, event.data, pathParams: submitPathParams);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormSubmitted(schema: schema, submitResponse: data, submitPathParams: submitPathParams));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message, schema: schema, submitPathParams: submitPathParams));
    }
  }

  FutureOr<void> _onReset(DynamicFormResetEvent event, Emitter<DynamicFormState> emit) {
    emit(const DynamicFormInitial());
  }

  FutureOr<void> _onLoadBundle(DynamicFormLoadBundleEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form bundle: {} pathParams: {}', [event.basePath, event.pathParams]);
    emit(const DynamicFormLoading());
    final result = await _loadFormBundleUseCase(event.basePath, pathParams: event.pathParams);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormLoaded(schema: data.schema, initialValues: data.values, submitPathParams: event.pathParams));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message));
    }
  }
}
