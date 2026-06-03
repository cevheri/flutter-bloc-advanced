import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/pages/dynamic_form_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../support/test_env.dart';
import '../support/golden_app.dart';

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  late MockDynamicFormBloc dynamicFormBloc;

  const smallSchema = FormSchemaEntity(
    id: 'golden_form',
    title: 'Contact Us',
    description: 'Send us a message',
    fields: [
      FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Full Name'),
      FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email'),
    ],
    submitAction: FormSubmitAction(method: 'POST', endpoint: '/contact'),
  );

  const loadedState = DynamicFormLoaded(schema: smallSchema);

  setUp(() {
    dynamicFormBloc = MockDynamicFormBloc();
    whenListen(dynamicFormBloc, Stream<DynamicFormState>.empty(), initialState: loadedState);
    when(() => dynamicFormBloc.state).thenReturn(loadedState);
  });

  Widget buildScreen({bool dark = false}) {
    final screen = BlocProvider<DynamicFormBloc>.value(
      value: dynamicFormBloc,
      child: const Scaffold(body: DynamicFormPage(formId: 'golden_form')),
    );
    return goldenScreen(screen, dark: dark);
  }

  goldenTest(
    'DynamicFormScreen — light',
    fileName: 'dynamic_form_screen_light',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: false)),
        ),
      ],
    ),
  );

  goldenTest(
    'DynamicFormScreen — dark',
    fileName: 'dynamic_form_screen_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'loaded',
          child: SizedBox.fromSize(size: kGoldenScreenSize, child: buildScreen(dark: true)),
        ),
      ],
    ),
  );
}
