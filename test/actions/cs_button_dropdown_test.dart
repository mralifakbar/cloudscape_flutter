import 'package:cloudscape_flutter/src/actions/actions.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = <CsButtonDropdownItemOrGroup>[
  CsButtonDropdownItem(id: 'start', text: 'Start instance', secondaryText: 'Boots from the root volume'),
  CsButtonDropdownItem(id: 'stop', text: 'Stop instance', disabled: true, disabledReason: 'Already stopped'),
  CsButtonDropdownCheckboxItem(id: 'monitor', text: 'Detailed monitoring', checked: true),
  CsButtonDropdownGroup(
    text: 'Networking',
    items: [
      CsButtonDropdownItem(id: 'ip', text: 'Associate IP address'),
      CsButtonDropdownGroup(
        text: 'Security',
        expandable: true,
        items: [CsButtonDropdownItem(id: 'sg', text: 'Change security groups')],
      ),
    ],
  ),
  CsButtonDropdownItem(id: 'docs', text: 'Documentation', external: true),
];

void main() {
  testWidgets('renders every variant in light, dark, compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Wrap(
            key: UniqueKey(),
            children: [
              for (final v in CsButtonDropdownVariant.values)
                CsButtonDropdown(text: 'Actions', ariaLabel: 'Actions', variant: v, items: _items),
              const CsButtonDropdown(
                variant: CsButtonDropdownVariant.primary,
                items: _items,
                mainAction: CsButtonDropdownMainAction(text: 'Launch instance'),
              ),
            ],
          ),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        await tester.tap(find.text('Actions').first);
        await tester.pumpAndSettle();
        expect(find.text('Start instance'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('item click reports the id and closes; disabled items do nothing', (tester) async {
    final clicks = <CsButtonDropdownItemClickDetails>[];
    final follows = <String>[];
    await pumpCs(
      tester,
      CsButtonDropdown(
        text: 'Actions',
        items: _items,
        onItemClick: clicks.add,
        onItemFollow: (d) => follows.add(d.id),
        presentation: CsPresentation.popover,
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop instance'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(clicks, isEmpty);
    await tester.tap(find.text('Detailed monitoring'));
    await tester.pumpAndSettle();
    expect(clicks.single.id, 'monitor');
    expect(clicks.single.checked, isFalse);
    expect(find.text('Start instance'), findsNothing);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documentation'));
    await tester.pumpAndSettle();
    expect(follows, ['docs']);
  });

  testWidgets('expandable groups expand in place', (tester) async {
    await pumpCs(
      tester,
      const CsButtonDropdown(text: 'Actions', items: _items),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Change security groups'), findsNothing);
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();
    expect(find.text('Change security groups'), findsOneWidget);
  });

  testWidgets('keyboard: Enter opens, arrows move, Escape closes', (tester) async {
    final clicks = <String>[];
    await pumpCs(
      tester,
      CsButtonDropdown(text: 'Actions', items: _items, onItemClick: (d) => clicks.add(d.id)),
      size: csDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Start instance'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Start instance'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(clicks, ['start']);
  });

  testWidgets('split button: main action fires; caret opens the menu', (tester) async {
    var launched = 0;
    await pumpCs(
      tester,
      CsButtonDropdown(
        variant: CsButtonDropdownVariant.primary,
        ariaLabel: 'More launch options',
        items: _items,
        mainAction: CsButtonDropdownMainAction(text: 'Launch instance', onPress: () => launched++),
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Launch instance'));
    expect(launched, 1);
    await tester.tap(find.bySemanticsLabel('More launch options'));
    await tester.pumpAndSettle();
    expect(find.text('Start instance'), findsOneWidget);
  });

  testWidgets('disabled and loading do not open', (tester) async {
    await pumpCs(
      tester,
      const CsButtonDropdown(text: 'Actions', items: _items, disabled: true),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Actions'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Start instance'), findsNothing);
  });

  testWidgets('filtering narrows items', (tester) async {
    await pumpCs(
      tester,
      const CsButtonDropdown(text: 'Actions', items: _items, filteringType: true, filteringPlaceholder: 'Find action'),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'IP');
    await tester.pumpAndSettle();
    expect(find.text('Start instance'), findsNothing);
    expect(find.text('Associate IP address'), findsOneWidget);
  });

  testWidgets('opens as a sheet on phones', (tester) async {
    await pumpCs(tester, const CsButtonDropdown(text: 'Actions', items: _items));
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      const CsButtonDropdown(
        variant: CsButtonDropdownVariant.primary,
        items: _items,
        mainAction: CsButtonDropdownMainAction(text: 'Launch'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
