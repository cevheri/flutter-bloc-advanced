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

/// Load a form schema bundled with prefilled values.
///
/// The request URL is composed as `basePath[/pathParams]` so the mock
/// interceptor's filename resolution sees a stable `basePath` regardless
/// of the per-instance [pathParams] (e.g. user id). [pathParams] is also
/// stored on the resulting [DynamicFormLoaded] state so the bloc can
/// reuse it for the matching submit URL.
class DynamicFormLoadBundleEvent extends DynamicFormEvent {
  const DynamicFormLoadBundleEvent(this.basePath, {this.pathParams});
  final String basePath;
  final String? pathParams;
  @override
  List<Object?> get props => [basePath, pathParams];
}
