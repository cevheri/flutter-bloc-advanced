import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to wrap the widget under test in a [MaterialApp] with a [Scaffold].
Widget _buildTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// Creates a minimal [FormSchemaEntity] with the provided fields.
FormSchemaEntity _schemaWith({
  List<FormFieldEntity> fields = const [],
  String? description,
  FormSubmitAction? submitAction,
}) {
  return FormSchemaEntity(
    id: 'test_form',
    title: 'Test Form',
    description: description,
    fields: fields,
    submitAction: submitAction,
  );
}

void main() {
  group('DynamicFormRenderer', () {
    group('text field', () {
      testWidgets('renders text field with label and hint', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Full Name', hint: 'Enter your name'),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Enter your name'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });

      testWidgets('renders text field with default value', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Full Name', defaultValue: 'John Doe'),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('John Doe'), findsOneWidget);
      });
    });

    group('email field', () {
      testWidgets('renders email field with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email Address')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Email Address'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });

    group('password field', () {
      testWidgets('renders password field (obscured)', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.password, key: 'pass', label: 'Password')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Password'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });

    group('number field', () {
      testWidgets('renders number field with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.number, key: 'age', label: 'Age')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Age'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });

    group('phone field', () {
      testWidgets('renders phone field with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.phone, key: 'phone', label: 'Phone Number')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Phone Number'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });

    group('textarea field', () {
      testWidgets('renders textarea field with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.textarea, key: 'bio', label: 'Biography', maxLines: 6)],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Biography'), findsOneWidget);
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });

    group('dropdown field', () {
      testWidgets('renders dropdown with options', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(
              type: FormFieldType.dropdown,
              key: 'country',
              label: 'Country',
              options: ['USA', 'UK', 'Germany'],
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Country'), findsOneWidget);
        expect(find.byType(FormBuilderDropdown<String>), findsOneWidget);
      });
    });

    group('multi-select field', () {
      testWidgets('renders checkbox group with options', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(
              type: FormFieldType.multiSelect,
              key: 'skills',
              label: 'Skills',
              options: ['Dart', 'Flutter', 'Kotlin'],
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Skills'), findsOneWidget);
        expect(find.text('Dart'), findsOneWidget);
        expect(find.text('Flutter'), findsOneWidget);
        expect(find.text('Kotlin'), findsOneWidget);
        expect(find.byType(FormBuilderCheckboxGroup<String>), findsOneWidget);
      });
    });

    group('date field', () {
      testWidgets('renders date picker with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.date, key: 'dob', label: 'Date of Birth')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Date of Birth'), findsOneWidget);
        expect(find.byType(FormBuilderDateTimePicker), findsOneWidget);
      });
    });

    group('datetime field', () {
      testWidgets('renders datetime picker with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.datetime, key: 'meeting', label: 'Meeting Time')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Meeting Time'), findsOneWidget);
        expect(find.byType(FormBuilderDateTimePicker), findsOneWidget);
      });
    });

    group('toggle field', () {
      testWidgets('renders switch with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(type: FormFieldType.toggle, key: 'notifications', label: 'Enable Notifications'),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(find.byType(FormBuilderSwitch), findsOneWidget);
      });

      testWidgets('renders switch with default value true', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(
              type: FormFieldType.toggle,
              key: 'notifications',
              label: 'Enable Notifications',
              defaultValue: true,
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.byType(FormBuilderSwitch), findsOneWidget);
      });
    });

    group('checkbox field', () {
      testWidgets('renders checkbox with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.checkbox, key: 'terms', label: 'Accept Terms')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Accept Terms'), findsOneWidget);
        expect(find.byType(FormBuilderCheckbox), findsOneWidget);
      });
    });

    group('radio field', () {
      testWidgets('renders radio group with options', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(
              type: FormFieldType.radio,
              key: 'gender',
              label: 'Gender',
              options: ['Male', 'Female', 'Other'],
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Gender'), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
        expect(find.text('Other'), findsOneWidget);
        expect(find.byType(FormBuilderRadioGroup<String>), findsOneWidget);
      });
    });

    group('slider field', () {
      testWidgets('renders slider with label', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [
            const FormFieldEntity(
              type: FormFieldType.slider,
              key: 'rating',
              label: 'Rating',
              min: 0,
              max: 10,
              defaultValue: 5,
            ),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Rating'), findsOneWidget);
        expect(find.byType(FormBuilderSlider), findsOneWidget);
      });
    });

    group('section header field', () {
      testWidgets('renders section header text', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.sectionHeader, key: 'section', label: 'Personal Info')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Personal Info'), findsOneWidget);
      });
    });

    group('divider field', () {
      testWidgets('renders a divider', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.divider, key: 'div1', label: '')],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.byType(Divider), findsOneWidget);
      });
    });

    group('description', () {
      testWidgets('renders description when provided', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(description: 'Please fill out this form.');

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Please fill out this form.'), findsOneWidget);
      });

      testWidgets('does not render description when null', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith();

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        // No description text should appear
        expect(find.text('Please fill out this form.'), findsNothing);
      });
    });

    group('submit button', () {
      testWidgets('renders submit button when onSubmit is provided and not readOnly', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith();

        await tester.pumpWidget(
          _buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey, onSubmit: (_) {})),
        );

        expect(find.text('Submit'), findsOneWidget);
      });

      testWidgets('does not render submit button when readOnly', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith();

        await tester.pumpWidget(
          _buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey, onSubmit: (_) {}, readOnly: true)),
        );

        expect(find.text('Submit'), findsNothing);
      });

      testWidgets('does not render submit button when onSubmit is null', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith();

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('Submit'), findsNothing);
      });
    });

    group('multiple fields', () {
      testWidgets('renders multiple different field types', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          description: 'A comprehensive form',
          fields: [
            const FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name'),
            const FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email'),
            const FormFieldEntity(type: FormFieldType.dropdown, key: 'role', label: 'Role', options: ['Admin', 'User']),
            const FormFieldEntity(type: FormFieldType.toggle, key: 'active', label: 'Active'),
            const FormFieldEntity(type: FormFieldType.date, key: 'start', label: 'Start Date'),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.text('A comprehensive form'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Role'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Start Date'), findsOneWidget);
        // 2 TextFields (text + email) + 1 Dropdown + 1 Switch + 1 DateTimePicker
        expect(find.byType(FormBuilderTextField), findsNWidgets(2));
        expect(find.byType(FormBuilderDropdown<String>), findsOneWidget);
        expect(find.byType(FormBuilderSwitch), findsOneWidget);
        expect(find.byType(FormBuilderDateTimePicker), findsOneWidget);
      });
    });

    group('readOnly mode', () {
      testWidgets('text field respects readOnly flag', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name')],
        );

        await tester.pumpWidget(
          _buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey, readOnly: true)),
        );

        // The field should be present
        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });

      testWidgets('field-level readOnly is respected', (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        final schema = _schemaWith(
          fields: [const FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name', readOnly: true)],
        );

        await tester.pumpWidget(_buildTestWidget(DynamicFormRenderer(schema: schema, formKey: formKey)));

        expect(find.byType(FormBuilderTextField), findsOneWidget);
      });
    });
  });
}
