import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardSummaryEntity', () {
    test('supports value equality', () {
      const a = DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5);
      const b = DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5);
      expect(a, b);
    });

    test('different values are not equal', () {
      const a = DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5);
      const b = DashboardSummaryEntity(id: '2', label: 'Users', value: 100, trend: 5);
      expect(a, isNot(b));
    });
  });

  group('DashboardActivityEntity', () {
    final time = DateTime(2024, 1, 1);

    test('supports value equality', () {
      final a = DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: time, type: 'auth');
      final b = DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: time, type: 'auth');
      expect(a, b);
    });

    test('props are correct', () {
      final entity = DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: time, type: 'auth');
      expect(entity.props, ['1', 'Login', 'admin', time, 'auth']);
    });
  });

  group('DashboardQuickActionEntity', () {
    test('supports value equality', () {
      const a = DashboardQuickActionEntity(id: '1', label: 'Add User', icon: 'person_add');
      const b = DashboardQuickActionEntity(id: '1', label: 'Add User', icon: 'person_add');
      expect(a, b);
    });
  });

  group('DashboardEntity', () {
    test('supports value equality', () {
      final entity = DashboardEntity(
        summary: const [DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5)],
        activities: [
          DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: DateTime(2024), type: 'auth'),
        ],
        quickActions: const [DashboardQuickActionEntity(id: '1', label: 'Add User', icon: 'person_add')],
      );

      final entity2 = DashboardEntity(
        summary: const [DashboardSummaryEntity(id: '1', label: 'Users', value: 100, trend: 5)],
        activities: [
          DashboardActivityEntity(id: '1', title: 'Login', subtitle: 'admin', time: DateTime(2024), type: 'auth'),
        ],
        quickActions: const [DashboardQuickActionEntity(id: '1', label: 'Add User', icon: 'person_add')],
      );

      expect(entity, entity2);
    });
  });
}
