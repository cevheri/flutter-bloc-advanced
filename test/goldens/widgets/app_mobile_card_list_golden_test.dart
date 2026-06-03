import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_mobile_card_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

// ---------------------------------------------------------------------------
// Sample data & card builder
// ---------------------------------------------------------------------------

typedef _Item = ({String name, String subtitle});

const _items = <_Item>[
  (name: 'Alice Johnson', subtitle: 'alice@example.com'),
  (name: 'Bob Smith', subtitle: 'bob@example.com'),
  (name: 'Carol White', subtitle: 'carol@example.com'),
];

Widget _cardBuilder(BuildContext context, _Item item) => Card(
  margin: const EdgeInsets.symmetric(vertical: 4),
  child: ListTile(
    leading: const CircleAvatar(child: Icon(Icons.person)),
    title: Text(item.name),
    subtitle: Text(item.subtitle),
  ),
);

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

GoldenTestGroup _grid() => GoldenTestGroup(
  columns: 1,
  children: [
    GoldenTestScenario(
      name: 'populated',
      child: SizedBox(
        width: 380,
        height: 360,
        child: AppMobileCardList<_Item>(items: _items, cardBuilder: _cardBuilder),
      ),
    ),
    GoldenTestScenario(
      name: 'empty',
      child: SizedBox(
        width: 380,
        height: 200,
        child: AppMobileCardList<_Item>(
          items: const [],
          cardBuilder: _cardBuilder,
          emptyIcon: Icons.people_outline,
          emptyText: 'No users found',
        ),
      ),
    ),
    GoldenTestScenario(
      name: 'loading',
      child: SizedBox(
        width: 380,
        height: 200,
        child: AppMobileCardList<_Item>(items: null, cardBuilder: _cardBuilder, isLoading: true),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Golden tests  (pumpBeforeTest: pumpOnce for loading scenario)
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => TestEnv.autoReset = false);

  goldenTest(
    'AppMobileCardList — light',
    fileName: 'app_mobile_card_list_light',
    pumpBeforeTest: pumpOnce,
    builder: _grid,
  );

  goldenTest(
    'AppMobileCardList — dark',
    fileName: 'app_mobile_card_list_dark',
    pumpBeforeTest: pumpOnce,
    builder: () => Theme(data: AppTheme.dark(), child: _grid()),
  );
}
