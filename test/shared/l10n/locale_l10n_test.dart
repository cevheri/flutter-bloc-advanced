@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/l10n/locale_l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The names of the supported languages, in the language [shown].
  Future<List<String>> languageNames(WidgetTester tester, Locale shown) async {
    late BuildContext context;
    await tester.pumpWidget(
      Localizations(
        locale: shown,
        delegates: const [S.delegate, GlobalWidgetsLocalizations.delegate],
        child: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return [for (final locale in S.delegate.supportedLocales) locale.displayName(context)];
  }

  testWidgets('names every supported language in English', (tester) async {
    expect(await languageNames(tester, const Locale('en')), ['English', 'Turkish']);
  });

  testWidgets('names every supported language in Turkish', (tester) async {
    expect(await languageNames(tester, const Locale('tr')), ['İngilizce', 'Türkçe']);
  });

  test('names every supported language in its own language', () {
    expect([for (final locale in S.delegate.supportedLocales) locale.endonym], ['English', 'Türkçe']);
  });
}
