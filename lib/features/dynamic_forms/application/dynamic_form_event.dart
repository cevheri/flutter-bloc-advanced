import 'package:equatable/equatable.dart';

class DynamicFormEvent extends Equatable {
  const DynamicFormEvent();
  @override
  List<Object?> get props => [];
}

/// Load a form schema by ID.
class DynamicFormLoadEvent extends DynamicFormEvent {
  const DynamicFormLoadEvent(this.formId);
  final String formId;
  @override
  List<Object?> get props => [formId];
}

/// Submit form data.
class DynamicFormSubmitEvent extends DynamicFormEvent {
  const DynamicFormSubmitEvent(this.data);
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [data];
}

/// Reset form to initial state.
class DynamicFormResetEvent extends DynamicFormEvent {
  const DynamicFormResetEvent();
}

/// Load a form schema bundled with prefilled values from an absolute endpoint.
class DynamicFormLoadBundleEvent extends DynamicFormEvent {
  const DynamicFormLoadBundleEvent(this.endpoint);
  final String endpoint;
  @override
  List<Object?> get props => [endpoint];
}
