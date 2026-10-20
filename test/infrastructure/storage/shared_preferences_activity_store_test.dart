import 'package:flutter_bloc_advance/infrastructure/storage/shared_preferences_activity_store.dart';
import 'package:flutter_test/flutter_test.dart';

// TestEnv backs SharedPreferencesAsync with one in-memory store, as window.localStorage backs it for every tab on web.
void main() {
  group('SharedPreferencesActivityStore', () {
    test('reads the activity that another tab recorded', () async {
      final otherTab = SharedPreferencesActivityStore();
      final thisTab = SharedPreferencesActivityStore();
      final activity = DateTime(2026, 10, 20, 12, 30, 15, 250);

      await otherTab.writeLastActivity(activity);

      expect(await thisTab.readLastActivity(), activity);
    });

    test('reads null before any tab has recorded activity', () async {
      expect(await SharedPreferencesActivityStore().readLastActivity(), isNull);
    });
  });
}
