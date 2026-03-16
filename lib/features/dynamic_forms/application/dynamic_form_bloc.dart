import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc() : super(const DynamicFormState()) {
    on<DynamicFormLoadEvent>(_onLoad);
    on<DynamicFormSubmitEvent>(_onSubmit);
    on<DynamicFormResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('DynamicFormBloc');

  FutureOr<void> _onLoad(DynamicFormLoadEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form schema: {}', [event.formId]);
    emit(state.copyWith(status: DynamicFormStatus.loading));
    try {
      final response = await ApiClient.get('/dynamic_forms', pathParams: event.formId);
      final schema = FormSchemaModel.fromJsonString(response.data!);
      emit(state.copyWith(status: DynamicFormStatus.loaded, schema: schema));
    } on AppException catch (e) {
      emit(state.copyWith(status: DynamicFormStatus.failure, error: e.toString()));
    } catch (e) {
      emit(state.copyWith(status: DynamicFormStatus.failure, error: e.toString()));
    }
  }

  FutureOr<void> _onSubmit(DynamicFormSubmitEvent event, Emitter<DynamicFormState> emit) async {
    final schema = state.schema;
    if (schema == null) return;

    _log.debug('Submitting form: {}', [schema.id]);
    emit(state.copyWith(status: DynamicFormStatus.submitting));

    try {
      final action = schema.submitAction;
      if (action == null) {
        _log.info('No submit action defined — logging form data: {}', [event.data]);
        emit(state.copyWith(status: DynamicFormStatus.submitted, submitResponse: 'Form data logged'));
        return;
      }

      final response = switch (action.method.toUpperCase()) {
        'POST' => await ApiClient.post(action.endpoint, event.data),
        'PUT' => await ApiClient.put(action.endpoint, event.data),
        _ => await ApiClient.post(action.endpoint, event.data),
      };

      emit(state.copyWith(status: DynamicFormStatus.submitted, submitResponse: response.data));
    } on AppException catch (e) {
      emit(state.copyWith(status: DynamicFormStatus.failure, error: e.toString()));
    } catch (e) {
      emit(state.copyWith(status: DynamicFormStatus.failure, error: e.toString()));
    }
  }

  FutureOr<void> _onReset(DynamicFormResetEvent event, Emitter<DynamicFormState> emit) {
    emit(const DynamicFormState());
  }
}
