import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_responsive_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

typedef _Row = ({String name, String email, String role});

const _rows = <_Row>[
  (name: 'Alice Johnson', email: 'alice@example.com', role: 'Admin'),
  (name: 'Bob Smith', email: 'bob@example.com', role: 'Editor'),
  (name: 'Carol White', email: 'carol@example.com', role: 'Viewer'),
];

List<AppTableColumn<_Row>> _columns() => [
  AppTableColumn<_Row>(label: 'Name', flex: 3, builder: (_, row) => Text(row.name)),
  AppTableColumn<_Row>(label: 'Email', flex: 4, builder: (_, row) => Text(row.email)),
  AppTableColumn<_Row>(label: 'Role', flex: 2, builder: (_, row) => Text(row.role)),
];

Widget _mobileCardBuilder(BuildContext context, _Row row) => Card(
  margin: const EdgeInsets.symmetric(vertical: 4),
  child: ListTile(
    leading: const CircleAvatar(child: Icon(Icons.person)),
    title: Text(row.name),
    subtitle: Text(row.email),
  ),
);

// ---------------------------------------------------------------------------
// AppResponsiveListView uses LayoutBuilder internally.  Alchemist's Table
// uses IntrinsicColumnWidth by default, which triggers intrinsic dimension
// calculations that LayoutBuilder does not support.  We supply a
// FixedColumnWidth so the Table never needs to ask LayoutBuilder for its
// intrinsic size, and we also give each scenario a tight outer SizedBox so
// LayoutBuilder always receives a bounded constraint.
// ---------------------------------------------------------------------------

const _desktopWidth = 800.0;
const _mobileWidth = 380.0;
const _mobileHeight = 420.0;

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  // FixedColumnWidth prevents the Table from asking for intrinsic dimensions.
  columnWidthBuilder: (_) => const FixedColumnWidth(_desktopWidth),
  children: [
    // Desktop — populated (width 800 >= 768 → desktop branch)
    GoldenTestScenario(
      name: 'desktop-populated',
      child: SizedBox(
        width: _desktopWidth,
        child: AppResponsiveListView<_Row>(
          title: 'Users',
          subtitle: '3 users found',
          items: _rows,
          columns: _columns(),
          mobileCardBuilder: _mobileCardBuilder,
          onCreateNew: () {},
          createLabel: 'New User',
          onPrevious: () {},
          onNext: () {},
        ),
      ),
    ),
    // Desktop — empty state
    GoldenTestScenario(
      name: 'desktop-empty',
      child: SizedBox(
        width: _desktopWidth,
        child: AppResponsiveListView<_Row>(
          title: 'Users',
          items: const [],
          columns: _columns(),
          mobileCardBuilder: _mobileCardBuilder,
          emptyIcon: Icons.people_outline,
          emptyText: 'No users found',
          onCreateNew: () {},
          onPrevious: () {},
          onNext: () {},
        ),
      ),
    ),
    // Mobile — populated (width 380 < 768 → mobile branch)
    GoldenTestScenario(
      name: 'mobile-populated',
      child: SizedBox(
        width: _mobileWidth,
        height: _mobileHeight,
        child: AppResponsiveListView<_Row>(
          title: 'Users',
          items: _rows,
          columns: _columns(),
          mobileCardBuilder: _mobileCardBuilder,
          onCreateNew: () {},
          createLabel: 'New',
        ),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest('AppResponsiveListView — light', fileName: 'app_responsive_list_view_light', builder: _grid);

  goldenTest(
    'AppResponsiveListView — dark',
    fileName: 'app_responsive_list_view_dark',
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
