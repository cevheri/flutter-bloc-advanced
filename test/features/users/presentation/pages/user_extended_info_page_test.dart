@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<DynamicFormEvent, DynamicFormState> implements DynamicFormBloc {}

void main() {
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
        any(
          that: isA<DynamicFormLoadBundleEvent>()
              .having((e) => e.basePath, 'basePath', '/admin/users/extended')
              .having((e) => e.pathParams, 'pathParams', '42'),
        ),
      ),
    ).called(1);
  });

  testWidgets('on DynamicFormSubmitted shows saved snackbar and pops the route', (tester) async {
    final bloc = _MockBloc();
    const schema = FormSchemaEntity(
      id: 'user_extended_info',
      title: 'Extended Information',
      fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
    );
    const initial = DynamicFormLoaded(schema: schema);
    final submitted = DynamicFormSubmitted(schema: schema, submitResponse: '{"ok":true}');

    whenListen(bloc, Stream.fromIterable([submitted]), initialState: initial);

    // Use GoRouter so context.canPop() / context.pop() work correctly.
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (ctx, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/extended',
          builder: (ctx, state) => BlocProvider<DynamicFormBloc>.value(
            value: bloc,
            child: const UserExtendedInfoPage(userId: '42'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );

    // Push (not go) so /home stays in the stack and context.canPop() returns true.
    router.push('/extended');
    await tester.pumpAndSettle();

    // The whenListen stream has already emitted Submitted — verify snackbar.
    expect(find.text('Saved'), findsOneWidget);

    // After the snackbar and pop animation settle, the page is gone.
    await tester.pumpAndSettle();
    expect(find.byType(UserExtendedInfoPage), findsNothing);
  });

  testWidgets('on DynamicFormFailure with schema shows save_failed snackbar', (tester) async {
    final bloc = _MockBloc();
    const schema = FormSchemaEntity(
      id: 'user_extended_info',
      title: 'Extended Information',
      fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
    );
    const initial = DynamicFormLoaded(schema: schema);
    const failure = DynamicFormFailure(error: 'boom', schema: schema);

    whenListen(bloc, Stream.fromIterable([failure]), initialState: initial);

    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '42'), bloc));
    await tester.pumpAndSettle();

    expect(find.textContaining('Save failed'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    // Form is still on screen — the page is preserved, not popped.
    expect(find.byType(UserExtendedInfoPage), findsOneWidget);
  });
}
