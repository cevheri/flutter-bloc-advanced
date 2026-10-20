import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that every message in `lib/l10n/intl_en.arb` has a Turkish translation in `intl_tr.arb` that uses the same
/// placeholders.
///
/// intl_utils generates `S` from the English file and looks each message up by name in the Turkish one, so a message
/// missing from `intl_tr.arb` still compiles and the Turkish app shows it in English without any error. A Turkish
/// message that leaves out a placeholder drops that value from the text.
void main() {
  Map<String, dynamic> read(String locale) =>
      jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
  Set<String> messages(Map<String, dynamic> arb) => {
    for (final key in arb.keys)
      if (!key.startsWith('@')) key,
  };

  final en = read('en');
  final tr = read('tr');

  test('intl_en.arb and intl_tr.arb have the same messages', () {
    expect(messages(en).difference(messages(tr)), isEmpty, reason: 'these English messages have no Turkish one');
    expect(messages(tr).difference(messages(en)), isEmpty, reason: 'these Turkish messages have no English one');
  });

  test('each Turkish message uses every placeholder that its English message declares', () {
    final missing = [
      for (final key in messages(en).intersection(messages(tr)))
        for (final name
            in ((en['@$key'] as Map<String, dynamic>?)?['placeholders'] as Map<String, dynamic>?)?.keys ??
                const <String>[])
          if (!RegExp('\\{$name[,}]').hasMatch(tr[key] as String)) '$key: {$name}',
    ];
    expect(missing, isEmpty, reason: 'these Turkish messages leave out a placeholder');
  });
}
