import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/presentation/pages/dynamic_form_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class DynamicFormsFeatureRoutes {
  static Widget _withBloc(Widget child) {
    return BlocProvider(create: (_) => DynamicFormBloc(), child: child);
  }

  static final List<GoRoute> routes = <GoRoute>[
    GoRoute(
      name: 'dynamicForm',
      path: '/dynamic-forms/:formId',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.fade,
        child: _withBloc(DynamicFormPage(formId: state.pathParameters['formId']!)),
      ),
    ),
  ];
}
