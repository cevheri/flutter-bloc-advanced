import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfigEntity', () {
    group('creation', () {
      test('should create with default values', () {
        const entity = AppConfigEntity();
        expect(entity.minimumVersion, isNull);
        expect(entity.latestVersion, isNull);
        expect(entity.maintenanceMode, isFalse);
        expect(entity.maintenanceMessage, isNull);
        expect(entity.maintenanceEstimatedEnd, isNull);
        expect(entity.storeUrl, isNull);
        expect(entity.featureFlags, isEmpty);
      });

      test('should create with all fields', () {
        const entity = AppConfigEntity(
          minimumVersion: '1.0.0',
          latestVersion: '2.0.0',
          maintenanceMode: true,
          maintenanceMessage: 'System under maintenance',
          maintenanceEstimatedEnd: '2026-03-14T18:00:00Z',
          storeUrl: 'https://store.example.com/app',
          featureFlags: {'dark_mode': true, 'beta': false},
        );

        expect(entity.minimumVersion, '1.0.0');
        expect(entity.latestVersion, '2.0.0');
        expect(entity.maintenanceMode, isTrue);
        expect(entity.maintenanceMessage, 'System under maintenance');
        expect(entity.maintenanceEstimatedEnd, '2026-03-14T18:00:00Z');
        expect(entity.storeUrl, 'https://store.example.com/app');
        expect(entity.featureFlags, {'dark_mode': true, 'beta': false});
      });

      test('should create with partial fields', () {
        const entity = AppConfigEntity(minimumVersion: '1.0.0', maintenanceMode: false);

        expect(entity.minimumVersion, '1.0.0');
        expect(entity.maintenanceMode, isFalse);
        expect(entity.latestVersion, isNull);
        expect(entity.featureFlags, isEmpty);
      });
    });

    group('Equatable equality', () {
      test('should be equal when all fields match', () {
        const a = AppConfigEntity(
          minimumVersion: '1.0.0',
          latestVersion: '2.0.0',
          maintenanceMode: false,
          featureFlags: {'flag': true},
        );
        const b = AppConfigEntity(
          minimumVersion: '1.0.0',
          latestVersion: '2.0.0',
          maintenanceMode: false,
          featureFlags: {'flag': true},
        );

        expect(a, equals(b));
      });

      test('should not be equal when minimumVersion differs', () {
        const a = AppConfigEntity(minimumVersion: '1.0.0');
        const b = AppConfigEntity(minimumVersion: '2.0.0');
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when latestVersion differs', () {
        const a = AppConfigEntity(latestVersion: '1.0.0');
        const b = AppConfigEntity(latestVersion: '2.0.0');
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when maintenanceMode differs', () {
        const a = AppConfigEntity(maintenanceMode: false);
        const b = AppConfigEntity(maintenanceMode: true);
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when maintenanceMessage differs', () {
        const a = AppConfigEntity(maintenanceMessage: 'msg1');
        const b = AppConfigEntity(maintenanceMessage: 'msg2');
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when maintenanceEstimatedEnd differs', () {
        const a = AppConfigEntity(maintenanceEstimatedEnd: '2026-01-01');
        const b = AppConfigEntity(maintenanceEstimatedEnd: '2026-12-31');
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when storeUrl differs', () {
        const a = AppConfigEntity(storeUrl: 'https://a.com');
        const b = AppConfigEntity(storeUrl: 'https://b.com');
        expect(a, isNot(equals(b)));
      });

      test('should not be equal when featureFlags differ', () {
        const a = AppConfigEntity(featureFlags: {'x': true});
        const b = AppConfigEntity(featureFlags: {'x': false});
        expect(a, isNot(equals(b)));
      });

      test('two default entities should be equal', () {
        const a = AppConfigEntity();
        const b = AppConfigEntity();
        expect(a, equals(b));
      });
    });

    group('props', () {
      test('should contain all fields', () {
        const entity = AppConfigEntity(
          minimumVersion: '1.0.0',
          latestVersion: '2.0.0',
          maintenanceMode: true,
          maintenanceMessage: 'msg',
          maintenanceEstimatedEnd: 'end',
          storeUrl: 'url',
          featureFlags: {'a': true},
        );

        expect(entity.props, [
          '1.0.0',
          '2.0.0',
          true,
          'msg',
          'end',
          'url',
          {'a': true},
        ]);
      });

      test('should have 7 props', () {
        const entity = AppConfigEntity();
        expect(entity.props.length, 7);
      });
    });
  });
}
