import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  setUp(() {
    // Clear flags before each test to start fresh
    FeatureFlagService.instance.clear();
  });

  group('FeatureFlagService', () {
    group('singleton pattern', () {
      test('should return the same instance', () {
        final a = FeatureFlagService.instance;
        final b = FeatureFlagService.instance;
        expect(identical(a, b), isTrue);
      });
    });

    group('isEnabled', () {
      test('should return false for unknown flag', () {
        expect(FeatureFlagService.instance.isEnabled('unknown_flag'), isFalse);
      });

      test('should return true for enabled flag', () {
        FeatureFlagService.instance.setFlag('feature_x', true);
        expect(FeatureFlagService.instance.isEnabled('feature_x'), isTrue);
      });

      test('should return false for explicitly disabled flag', () {
        FeatureFlagService.instance.setFlag('feature_y', false);
        expect(FeatureFlagService.instance.isEnabled('feature_y'), isFalse);
      });
    });

    group('allFlags', () {
      test('should return empty map initially', () {
        expect(FeatureFlagService.instance.allFlags, isEmpty);
      });

      test('should return unmodifiable map', () {
        FeatureFlagService.instance.setFlag('a', true);
        final flags = FeatureFlagService.instance.allFlags;
        expect(() => flags['b'] = false, throwsUnsupportedError);
      });

      test('should reflect current flags', () {
        FeatureFlagService.instance.setFlag('a', true);
        FeatureFlagService.instance.setFlag('b', false);
        expect(FeatureFlagService.instance.allFlags, {'a': true, 'b': false});
      });
    });

    group('updateFlags', () {
      test('should replace all existing flags', () {
        FeatureFlagService.instance.setFlag('old_flag', true);
        FeatureFlagService.instance.updateFlags({'new_flag': true});

        expect(FeatureFlagService.instance.isEnabled('old_flag'), isFalse);
        expect(FeatureFlagService.instance.isEnabled('new_flag'), isTrue);
      });

      test('should set lastFetched', () {
        expect(FeatureFlagService.instance.lastFetched, isNull);

        final before = DateTime.now();
        FeatureFlagService.instance.updateFlags({'flag': true});
        final after = DateTime.now();

        expect(FeatureFlagService.instance.lastFetched, isNotNull);
        expect(FeatureFlagService.instance.lastFetched!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(FeatureFlagService.instance.lastFetched!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('should accept empty map', () {
        FeatureFlagService.instance.setFlag('existing', true);
        FeatureFlagService.instance.updateFlags({});

        expect(FeatureFlagService.instance.allFlags, isEmpty);
        expect(FeatureFlagService.instance.lastFetched, isNotNull);
      });

      test('should notify listeners', () {
        int notifyCount = 0;
        FeatureFlagService.instance.addListener(() => notifyCount++);

        FeatureFlagService.instance.updateFlags({'a': true});
        expect(notifyCount, 1);

        // Clean up listener
        FeatureFlagService.instance.removeListener(() => notifyCount++);
      });
    });

    group('setFlag', () {
      test('should add a new flag', () {
        FeatureFlagService.instance.setFlag('new_feature', true);
        expect(FeatureFlagService.instance.isEnabled('new_feature'), isTrue);
      });

      test('should overwrite an existing flag', () {
        FeatureFlagService.instance.setFlag('toggle', true);
        expect(FeatureFlagService.instance.isEnabled('toggle'), isTrue);

        FeatureFlagService.instance.setFlag('toggle', false);
        expect(FeatureFlagService.instance.isEnabled('toggle'), isFalse);
      });

      test('should notify listeners', () {
        int notifyCount = 0;
        void listener() => notifyCount++;
        FeatureFlagService.instance.addListener(listener);

        FeatureFlagService.instance.setFlag('flag', true);
        expect(notifyCount, 1);

        FeatureFlagService.instance.setFlag('flag', false);
        expect(notifyCount, 2);

        FeatureFlagService.instance.removeListener(listener);
      });
    });

    group('clear', () {
      test('should remove all flags', () {
        FeatureFlagService.instance.setFlag('a', true);
        FeatureFlagService.instance.setFlag('b', false);

        FeatureFlagService.instance.clear();

        expect(FeatureFlagService.instance.allFlags, isEmpty);
      });

      test('should reset lastFetched to null', () {
        FeatureFlagService.instance.updateFlags({'flag': true});
        expect(FeatureFlagService.instance.lastFetched, isNotNull);

        FeatureFlagService.instance.clear();
        expect(FeatureFlagService.instance.lastFetched, isNull);
      });

      test('should notify listeners', () {
        int notifyCount = 0;
        void listener() => notifyCount++;
        FeatureFlagService.instance.addListener(listener);

        FeatureFlagService.instance.clear();
        expect(notifyCount, 1);

        FeatureFlagService.instance.removeListener(listener);
      });
    });

    group('lastFetched', () {
      test('should be null initially', () {
        expect(FeatureFlagService.instance.lastFetched, isNull);
      });

      test('should be updated after updateFlags', () {
        FeatureFlagService.instance.updateFlags({'flag': true});
        expect(FeatureFlagService.instance.lastFetched, isA<DateTime>());
      });

      test('should be null after clear', () {
        FeatureFlagService.instance.updateFlags({'flag': true});
        FeatureFlagService.instance.clear();
        expect(FeatureFlagService.instance.lastFetched, isNull);
      });
    });

    group('ChangeNotifier', () {
      test('should support multiple listeners', () {
        int count1 = 0;
        int count2 = 0;
        void listener1() => count1++;
        void listener2() => count2++;

        FeatureFlagService.instance.addListener(listener1);
        FeatureFlagService.instance.addListener(listener2);

        FeatureFlagService.instance.setFlag('x', true);

        expect(count1, 1);
        expect(count2, 1);

        FeatureFlagService.instance.removeListener(listener1);
        FeatureFlagService.instance.removeListener(listener2);
      });

      test('should not notify removed listeners', () {
        int count = 0;
        void listener() => count++;

        FeatureFlagService.instance.addListener(listener);
        FeatureFlagService.instance.setFlag('x', true);
        expect(count, 1);

        FeatureFlagService.instance.removeListener(listener);
        FeatureFlagService.instance.setFlag('y', true);
        expect(count, 1); // Should not have incremented
      });
    });
  });
}
