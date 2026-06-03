import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
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

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  children: [
    GoldenTestScenario(
      name: 'populated',
      child: SizedBox(
        width: 600,
        child: AppDataTable<_Row>(columns: _columns(), items: _rows, onPrevious: () {}, onNext: () {}),
      ),
    ),
    GoldenTestScenario(
      name: 'empty',
      child: SizedBox(
        width: 600,
        child: AppDataTable<_Row>(columns: _columns(), items: const [], onPrevious: () {}, onNext: () {}),
      ),
    ),
    GoldenTestScenario(
      name: 'with-checkbox',
      child: SizedBox(
        width: 600,
        child: AppDataTable<_Row>(
          columns: _columns(),
          items: _rows,
          showCheckbox: true,
          onPrevious: () {},
          onNext: () {},
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

  goldenTest('AppDataTable — light', fileName: 'app_data_table_light', builder: _grid);

  goldenTest(
    'AppDataTable — dark',
    fileName: 'app_data_table_dark',
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
