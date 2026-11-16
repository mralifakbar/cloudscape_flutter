import 'dart:ui';

import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  List<CsTab> tabs({VoidCallback? onDismiss}) => [
    const CsTab(id: 'details', label: 'Details', content: Text('Details panel')),
    const CsTab(id: 'monitoring', label: 'Monitoring', content: Text('Monitoring panel')),
    const CsTab(id: 'tags', label: 'Tags', disabled: true, disabledReason: 'No tags yet.', content: Text('Tags panel')),
    CsTab(id: 'logs', label: 'Logs', dismissible: true, onDismiss: onDismiss, content: const Text('Logs panel')),
  ];

  testWidgets('renders every variant in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final v in CsTabsVariant.values) {
          await pumpCs(
            tester,
            CsTabs(variant: v, tabs: tabs(), actions: const Text('Act')),
            brightness: b,
            density: d,
          );
          expect(find.text('Details panel'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('uncontrolled: tap selects a tab and reports onChange', (tester) async {
    final ids = <String>[];
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(), onChange: ids.add),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Monitoring'));
    await tester.pumpAndSettle();
    expect(find.text('Monitoring panel'), findsOneWidget);
    expect(find.text('Details panel'), findsNothing);
    expect(ids, ['monitoring']);
  });

  testWidgets('controlled: shows the given tab', (tester) async {
    String? next;
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(), activeTabId: 'monitoring', onChange: (v) => next = v),
      size: csDesktopSize,
    );
    expect(find.text('Monitoring panel'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(next, 'details');
    expect(find.text('Monitoring panel'), findsOneWidget);
  });

  testWidgets('disabled tabs do not select', (tester) async {
    final ids = <String>[];
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(), onChange: ids.add),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(ids, isEmpty);
    expect(find.text('Details panel'), findsOneWidget);
  });

  testWidgets('dismiss button calls onDismiss', (tester) async {
    var n = 0;
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(onDismiss: () => n++)),
      size: csDesktopSize,
    );
    await tester.tap(find.bySemanticsLabel('Close Logs'));
    expect(n, 1);
  });

  testWidgets('arrow keys move and activate tabs, skipping disabled ones without reason', (tester) async {
    final ids = <String>[];
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(), onChange: ids.add),
      size: csDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(ids.last, 'monitoring');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(ids.last, 'logs');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(ids.last, 'details');
  });

  testWidgets('manual activation waits for Enter', (tester) async {
    final ids = <String>[];
    await pumpCs(
      tester,
      CsTabs(tabs: tabs(), onChange: ids.add, keyboardActivationMode: CsTabsKeyboardActivation.manual),
      size: csDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(ids, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ids, ['monitoring']);
  });

  testWidgets('active indicator slides to the selected tab', (tester) async {
    await pumpCs(tester, CsTabs(tabs: tabs()), size: csDesktopSize);
    final pos = find.byType(AnimatedPositioned);
    final before = tester.getTopLeft(pos).dx;
    await tester.tap(find.text('Monitoring'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pos).dx, greaterThan(before));
  });

  testWidgets('tabs expose selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsTabs(tabs: tabs()), size: csDesktopSize);
    expect(tester.getSemantics(find.bySemanticsLabel('Details').first).flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('overflowing tabs show scroll arrows on phones', (tester) async {
    await pumpCs(
      tester,
      CsTabs(
        tabs: [for (var i = 0; i < 10; i++) CsTab(id: '$i', label: 'Distribution $i', content: Text('P$i'))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Scroll')), findsNWidgets(2));
    await tester.tap(find.bySemanticsLabel('Scroll tabs right'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe changes tabs when swipeable', (tester) async {
    final ids = <String>[];
    await pumpCs(
      tester,
      SizedBox(
        height: 300,
        child: CsTabs(
          tabs: const [
            CsTab(
              id: 'a',
              label: 'A',
              content: SizedBox(height: 200, width: 300, child: Text('Panel A')),
            ),
            CsTab(id: 'b', label: 'B', content: Text('Panel B')),
          ],
          swipeable: true,
          onChange: ids.add,
        ),
      ),
    );
    await tester.fling(find.text('Panel A'), const Offset(-200, 0), 1000);
    await tester.pumpAndSettle();
    expect(ids, ['b']);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, CsTabs(tabs: tabs(), variant: CsTabsVariant.container), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
