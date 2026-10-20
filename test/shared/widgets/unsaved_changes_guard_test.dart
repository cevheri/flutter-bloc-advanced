@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A page with one form field, guarded the way the app's form pages are.
class _FormPage extends StatefulWidget {
  const _FormPage({required this.onBack});

  final void Function(BuildContext context) onBack;

  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      hasUnsavedChanges: () => _formKey.currentState?.isDirty ?? false,
      onBack: () => widget.onBack(context),
      child: Scaffold(
        body: Builder(
          builder: (context) => FormBuilder(
            key: _formKey,
            onChanged: () => UnsavedChangesScope.formChanged(context),
            child: Column(
              children: [
                FormBuilderTextField(key: const Key('name'), name: 'name'),
                TextButton(onPressed: () => _formKey.currentState!.reset(), child: const Text('reset')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Harness {
  bool sessionEnded = false;
  int backs = 0;

  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/other',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: const Scaffold(body: Text('other')),
        ),
      ),
      GoRoute(
        path: '/form',
        onExit: confirmLeavingUnsavedChanges,
        // A page with a transition, so a page that is left stays mounted while it animates out.
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: _FormPage(
            onBack: (context) {
              backs++;
              context.canPop() ? context.pop() : context.go('/');
            },
          ),
        ),
      ),
    ],
  );

  Widget app() => RepositoryProvider<UnsavedChangesRegistry>(
    create: (_) => UnsavedChangesRegistry(isExitForced: (_) => sessionEnded),
    child: MaterialApp.router(
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
}

Future<_Harness> _pumpDirtyForm(WidgetTester tester, {bool push = false, bool dirty = true}) async {
  final harness = _Harness();
  addTearDown(harness.router.dispose);
  await tester.pumpWidget(harness.app());
  if (push) {
    harness.router.push('/form');
  } else {
    harness.router.go('/form');
  }
  await tester.pumpAndSettle();
  if (dirty) {
    await tester.enterText(find.byKey(const Key('name')), 'changed');
    await tester.pumpAndSettle();
  }
  return harness;
}

Future<void> _androidBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

Finder get _dialog => find.text(S.current.unsaved_changes);

void main() {
  testWidgets('a clean form leaves without asking', (tester) async {
    final harness = await _pumpDirtyForm(tester, dirty: false);
    harness.router.go('/other');
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('a dirty form asks, stays on No and leaves on Yes', (tester) async {
    final harness = await _pumpDirtyForm(tester);
    harness.router.go('/other');
    await tester.pumpAndSettle();
    expect(_dialog, findsOneWidget);
    await tester.tap(find.text(S.current.no));
    await tester.pumpAndSettle();
    expect(find.text('changed'), findsOneWidget);

    harness.router.go('/other');
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.yes));
    await tester.pumpAndSettle();
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('a second navigation while the dialog is open waits for the same answer', (tester) async {
    final harness = await _pumpDirtyForm(tester);
    harness.router.go('/other');
    await tester.pump();
    harness.router.go('/');
    await tester.pumpAndSettle();
    expect(_dialog, findsOneWidget);
    await tester.tap(find.text(S.current.yes));
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a forced exit leaves a dirty form without asking', (tester) async {
    final harness = await _pumpDirtyForm(tester);
    harness.sessionEnded = true;
    harness.router.go('/other');
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('holds the system back while the form is dirty and answers it with onBack', (tester) async {
    final harness = await _pumpDirtyForm(tester);
    final route = ModalRoute.of(tester.element(find.byType(FormBuilder)))!;
    expect(route.popDisposition, RoutePopDisposition.doNotPop);

    await _androidBack(tester);
    expect(harness.backs, 1);
    expect(_dialog, findsOneWidget);
  });

  testWidgets('releases the system back once the form is reset', (tester) async {
    await _pumpDirtyForm(tester, push: true);
    await tester.tap(find.text('reset'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(FormBuilder)))!;
    expect(route.popDisposition, RoutePopDisposition.pop);
  });

  testWidgets('asks once when a pushed dirty form is popped by Android back', (tester) async {
    final harness = await _pumpDirtyForm(tester, push: true);
    await _androidBack(tester);
    expect(_dialog, findsOneWidget);
    await tester.tap(find.text(S.current.yes));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(harness.backs, 1);
  });

  testWidgets('asks about the page the route shows when the page is entered again while it still animates out', (
    tester,
  ) async {
    final harness = await _pumpDirtyForm(tester);
    harness.router.go('/other');
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.yes));
    await tester.pump();
    harness.router.go('/form');
    await tester.pump();
    expect(find.byType(_FormPage, skipOffstage: false), findsNWidgets(2));

    harness.router.go('/other');
    await tester.pumpAndSettle();
    expect(_dialog, findsNothing);
    expect(find.text('other'), findsOneWidget);
  });

  testWidgets('formChanged without a scope above the context is an error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              TextButton(onPressed: () => UnsavedChangesScope.formChanged(context), child: const Text('change')),
        ),
      ),
    );
    await tester.tap(find.text('change'));
    expect(tester.takeException(), isA<FlutterError>());
  });
}
