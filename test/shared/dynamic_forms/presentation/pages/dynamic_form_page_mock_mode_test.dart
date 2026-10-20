@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/pages/dynamic_form_page.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';
import '../../../../support/unsaved_changes_host.dart';

/// Drives the sample form that the dashboard opens at `/dynamic-forms/sample` with the real bloc and repository on
/// the mock-backed [TestEnv.apiClient], so `MockInterceptor` serves both the schema and the submission from
/// `assets/mock`, as it does in `main_local` and the web demo.
///
/// Regression: the form submits `POST /leads`, which had no mock file, so the mock answered "OK" and the demo reported
/// success for a submission it could not answer.
void main() {
  testWidgets('submits the sample lead form in mock mode and gets the created lead back', (tester) async {
    TestEnv.authenticate();
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      withUnsavedChangesRegistry(
        MaterialApp.router(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          routerConfig: singlePageRouter(
            Scaffold(
              body: RepositoryProvider<IDynamicFormRepository>(
                create: (_) => DynamicFormRepository(TestEnv.apiClient()),
                child: Builder(
                  builder: (context) =>
                      DynamicFormsFeatureRoutes.withBloc(context, const DynamicFormPage(formId: 'sample')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New Lead'), findsOneWidget);

    await tester.enterText(find.widgetWithText(FormBuilderTextField, 'Full Name'), 'Jane Doe');
    await tester.enterText(find.widgetWithText(FormBuilderTextField, 'Email Address'), 'jane.doe@example.com');
    await tester.tap(find.byType(FormBuilderDropdown<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Referral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Form submitted successfully'), findsOneWidget);
    expect(
      tester.element(find.byType(DynamicFormPage)).read<DynamicFormBloc>().state,
      isA<DynamicFormSubmitted>().having(
        (state) => jsonDecode(state.submitResponse!),
        'created lead',
        containsPair('id', 'lead-1'),
      ),
    );
  });
}
