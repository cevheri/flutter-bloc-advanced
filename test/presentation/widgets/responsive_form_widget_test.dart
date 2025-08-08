import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/responsive_form_widget.dart';

void main() {
  group('ResponsiveFormBuilder Widget Tests', () {
    late GlobalKey<FormBuilderState> formKey;

    setUp(() {
      formKey = GlobalKey<FormBuilderState>();
    });

    testWidgets('should render with minimal required props', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveFormBuilder(formKey: formKey, children: const [Text('Test Child')]),
          ),
        ),
      );

      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsAtLeast(1));
      expect(find.byType(Padding), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should apply correct alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveFormBuilder(
              formKey: formKey,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [Text('Test Child')],
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('should handle onChanged callback', (tester) async {
      bool wasCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveFormBuilder(
              formKey: formKey,
              onChanged: () => wasCallbackCalled = true,
              children: [FormBuilderTextField(name: 'test_field')],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(FormBuilderTextField), 'test');
      await tester.pump();

      expect(wasCallbackCalled, true);
    });

    testWidgets('should apply autovalidateMode correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveFormBuilder(formKey: formKey, autoValidateMode: true, children: const [Text('Test Child')]),
          ),
        ),
      );

      final formBuilder = tester.widget<FormBuilder>(find.byType(FormBuilder));
      expect(formBuilder.autovalidateMode, AutovalidateMode.onUserInteraction);
    });
  });
}
