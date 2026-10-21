import 'package:flutter_bloc_advance/infrastructure/storage/session_end_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sessionEndTimeOf', () {
    test('reads a whole number of milliseconds since the epoch as the time the other tab began to end the session', () {
      final endedAt = DateTime.utc(2026, 10, 21, 12);

      expect(sessionEndTimeOf(endedAt.millisecondsSinceEpoch), endedAt.toLocal());
      expect(sessionEndTimeOf(endedAt.millisecondsSinceEpoch.toDouble()), endedAt.toLocal());
    });

    test('takes the earliest and the latest time DateTime holds', () {
      expect(sessionEndTimeOf(8640000000000000), DateTime.fromMillisecondsSinceEpoch(8640000000000000));
      expect(sessionEndTimeOf(-8640000000000000), DateTime.fromMillisecondsSinceEpoch(-8640000000000000));
    });

    for (final (name, message) in [
      ('NaN', double.nan),
      ('Infinity', double.infinity),
      ('-Infinity', double.negativeInfinity),
      ('a fraction of a millisecond', 1.5),
      ('a time later than DateTime holds', 8640000000000001),
      ('a time earlier than DateTime holds', -8640000000000001.0),
      ('text', '1761048000000'),
      ('null', null),
      ('a map', <String, Object>{'endedAt': 1}),
    ]) {
      test('is null for $name, which no tab of the app sends', () {
        expect(sessionEndTimeOf(message), isNull);
      });
    }
  });
}
