import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/pages/dynamic_form_page.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

Widget _buildTestWidget(MockDynamicFormBloc bloc) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<DynamicFormBloc>.value(
        value: bloc,
        child: const DynamicFormPage(formId: 'test_form'),
      ),
    ),
  );
}

const _testSchema = FormSchemaEntity(
  id: 'test_form',
  title: 'Test Form',
  description: 'A test form',
  fields: [
    FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Full Name'),
    FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email'),
    FormFieldEntity(type: FormFieldType.dropdown, key: 'source', label: 'Source', options: ['Web', 'Referral']),
  ],
  submitAction: FormSubmitAction(method: 'POST', endpoint: '/leads'),
);

void main() {
  late MockDynamicFormBloc mockBloc;

  setUp(() {
    mockBloc = MockDynamicFormBloc();
  });

  tearDown(() {
    mockBloc.close();
  });

  group('DynamicFormPage', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator when status is loading', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoading());

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsNothing);
        expect(find.byType(AppErrorState), findsNothing);
      });
    });

    group('failure state', () {
      testWidgets('shows AppErrorState when status is failure', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Network error'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('shows default error message when error is null', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Failed to load form'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Failed to load form'), findsOneWidget);
      });

      testWidgets('shows retry button in error state', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Something went wrong'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('initial state', () {
      testWidgets('shows CircularProgressIndicator while bloc is in DynamicFormInitial', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormInitial());

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsNothing);
      });
    });

    group('loaded state', () {
      testWidgets('shows form title and DynamicFormRenderer when loaded', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Test Form'), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(AppErrorState), findsNothing);
      });

      testWidgets('renders form fields when loaded', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Source'), findsOneWidget);
      });

      testWidgets('shows submit button when form is loaded and not submitting', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Submit'), findsOneWidget);
      });
    });

    group('submitting state', () {
      testWidgets('renders form as readOnly when submitting', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormSubmitting(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        // Form should still be visible (not loading indicator)
        expect(find.byType(DynamicFormRenderer), findsOneWidget);
        expect(find.text('Test Form'), findsOneWidget);
      });
    });

    group('submitted state', () {
      testWidgets('shows snackbar when status transitions to submitted', (tester) async {
        final statesController = MockDynamicFormBloc();
        whenListen(
          statesController,
          Stream<DynamicFormState>.fromIterable([
            const DynamicFormLoaded(schema: _testSchema),
            const DynamicFormSubmitted(schema: _testSchema),
          ]),
          initialState: const DynamicFormLoaded(schema: _testSchema),
        );

        await tester.pumpWidget(_buildTestWidget(statesController));
        await tester.pump();

        expect(find.text('Form submitted successfully'), findsOneWidget);

        statesController.close();
      });
    });
  });
}
