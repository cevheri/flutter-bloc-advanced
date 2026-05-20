import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils.dart';

class _MockBloc extends MockBloc<DynamicFormEvent, DynamicFormState> implements DynamicFormBloc {}

class _FakeEvent extends Fake implements DynamicFormEvent {}

void main() {
  late TestUtils testUtils;

  setUpAll(() {
    registerFallbackValue(_FakeEvent());
  });

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  Widget host(Widget child, DynamicFormBloc bloc) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: BlocProvider<DynamicFormBloc>.value(value: bloc, child: child),
  );

  testWidgets('renders loading indicator while bloc is Loading', (tester) async {
    final bloc = _MockBloc();
    whenListen(bloc, const Stream<DynamicFormState>.empty(), initialState: const DynamicFormLoading());
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders form fields when bloc is Loaded', (tester) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<DynamicFormState>.empty(),
      initialState: const DynamicFormLoaded(
        schema: FormSchemaEntity(
          id: 'user_extended_info',
          title: 'Extended Information',
          fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
        ),
        initialValues: {'firstName': 'Alice'},
      ),
    );
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
  });

  testWidgets('dispatches DynamicFormLoadBundleEvent on init with correct endpoint', (tester) async {
    final bloc = _MockBloc();
    whenListen(bloc, const Stream<DynamicFormState>.empty(), initialState: const DynamicFormInitial());
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '42'), bloc));
    await tester.pump();
    verify(
      () => bloc.add(
        any(that: isA<DynamicFormLoadBundleEvent>().having((e) => e.endpoint, 'endpoint', '/admin/users/42/extended')),
      ),
    ).called(1);
  });
}
