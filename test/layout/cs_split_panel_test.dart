import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  const panel = CsSplitPanel(
    header: 'i-0abc123',
    headerDescription: 'Running',
    headerActions: Text('Act'),
    child: Text('Instance details'),
  );

  testWidgets('standalone renders and collapses in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, panel, brightness: b, density: d);
        expect(find.text('i-0abc123'), findsOneWidget);
        expect(find.text('Instance details'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    await tester.tap(find.bySemanticsLabel('Close panel'));
    await tester.pumpAndSettle();
    expect(find.text('Instance details'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Open panel'));
    await tester.pumpAndSettle();
    expect(find.text('Instance details'), findsOneWidget);
  });

  Widget inLayout({
    bool open = true,
    CsSplitPanelPosition position = CsSplitPanelPosition.bottom,
    ValueChanged<bool>? onToggle,
    ValueChanged<double>? onResize,
    ValueChanged<CsSplitPanelPosition>? onPrefs,
    CsSplitPanelCloseBehavior closeBehavior = CsSplitPanelCloseBehavior.collapse,
  }) => CsAppLayout(
    navigationHide: true,
    toolsHide: true,
    content: const Text('Table'),
    splitPanelOpen: open,
    onSplitPanelToggle: onToggle,
    splitPanelSize: 300,
    onSplitPanelResize: onResize,
    splitPanelPosition: position,
    onSplitPanelPreferencesChange: onPrefs,
    splitPanel: CsSplitPanel(header: 'i-0abc123', closeBehavior: closeBehavior, child: const Text('Details')),
  );

  testWidgets('bottom panel in the app layout sits under the content', (tester) async {
    await pumpCs(tester, inLayout(), size: csDesktopSize, center: false);
    expect(tester.getTopLeft(find.text('Details')).dy, greaterThan(tester.getTopLeft(find.text('Table')).dy));
    expect(tester.getSize(find.byType(CsSplitPanel)).height, closeTo(300, 1));
  });

  testWidgets('side panel sits beside the content', (tester) async {
    await pumpCs(tester, inLayout(position: CsSplitPanelPosition.side), size: csDesktopSize, center: false);
    expect(tester.getTopLeft(find.text('Details')).dx, greaterThan(tester.getTopLeft(find.text('Table')).dx));
    expect(tester.getSize(find.byType(CsSplitPanel)).width, closeTo(300, 1));
  });

  testWidgets('close button asks the layout to toggle', (tester) async {
    bool? next;
    await pumpCs(tester, inLayout(onToggle: (v) => next = v), size: csDesktopSize, center: false);
    await tester.tap(find.bySemanticsLabel('Close panel'));
    expect(next, false);
  });

  testWidgets('collapsed panel shows the header and an open button', (tester) async {
    bool? next;
    await pumpCs(tester, inLayout(open: false, onToggle: (v) => next = v), size: csDesktopSize, center: false);
    expect(find.text('i-0abc123'), findsOneWidget);
    expect(find.text('Details'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Open panel'));
    expect(next, true);
  });

  testWidgets('hide close behavior removes the panel and adds a trigger', (tester) async {
    bool? next;
    await pumpCs(
      tester,
      inLayout(open: false, onToggle: (v) => next = v, closeBehavior: CsSplitPanelCloseBehavior.hide),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('i-0abc123'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Open split panel'));
    expect(next, true);
  });

  testWidgets('dragging the handle resizes', (tester) async {
    final sizes = <double>[];
    await pumpCs(tester, inLayout(onResize: sizes.add), size: csDesktopSize, center: false);
    await tester.drag(find.bySemanticsLabel('Resize split panel'), const Offset(0, -50));
    expect(sizes.last, greaterThan(300));
  });

  testWidgets('preferences switch the position', (tester) async {
    CsSplitPanelPosition? pos;
    await pumpCs(tester, inLayout(onPrefs: (v) => pos = v), size: csDesktopSize, center: false);
    await tester.tap(find.bySemanticsLabel('Preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Split panel preferences'), findsOneWidget);
    await tester.tap(find.text('Side'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(pos, CsSplitPanelPosition.side);
  });

  testWidgets('opens full screen on phones', (tester) async {
    await pumpCs(tester, inLayout(), center: false);
    expect(tester.getSize(find.byType(CsSplitPanel)).height, closeTo(844, 1));
    expect(find.bySemanticsLabel('Preferences'), findsNothing);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, panel, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
