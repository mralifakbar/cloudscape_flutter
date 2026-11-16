import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget layout({
    CsPanelPosition position = CsPanelPosition.sideStart,
    CsPanelLayoutDisplay display = CsPanelLayoutDisplay.all,
    double? panelSize,
    ValueChanged<CsPanelResizeDetail>? onResize,
    double? min,
    double? max,
  }) => SizedBox(
    width: 800,
    height: 400,
    child: CsPanelLayout(
      panelPosition: position,
      display: display,
      panelSize: panelSize,
      minPanelSize: min,
      maxPanelSize: max,
      resizable: true,
      onPanelResize: onResize,
      panelContent: const SizedBox.expand(child: Text('Panel')),
      mainContent: const SizedBox.expand(child: Text('Main')),
    ),
  );

  Finder panel() => find.ancestor(of: find.text('Panel'), matching: find.byType(SizedBox)).first;

  testWidgets('renders in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, layout(), brightness: b, density: d, size: csDesktopSize);
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Main'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('panel starts at 200px on the start side', (tester) async {
    await pumpCs(tester, layout(), size: csDesktopSize);
    expect(tester.getTopLeft(find.text('Panel')).dx, lessThan(tester.getTopLeft(find.text('Main')).dx));
    final mainLeft = tester.getTopLeft(find.text('Main')).dx;
    final start = tester.getTopLeft(find.byType(CsPanelLayout)).dx;
    expect(mainLeft - start, closeTo(200, 0.5));
  });

  testWidgets('side end puts the panel after the main content', (tester) async {
    await pumpCs(tester, layout(position: CsPanelPosition.sideEnd), size: csDesktopSize);
    expect(tester.getTopLeft(find.text('Panel')).dx, greaterThan(tester.getTopLeft(find.text('Main')).dx));
  });

  testWidgets('dragging the handle resizes and reports', (tester) async {
    final sizes = <CsPanelResizeDetail>[];
    await pumpCs(tester, layout(onResize: sizes.add), size: csDesktopSize);
    final handle = find.bySemanticsLabel('Resize panel');
    await tester.drag(handle, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(sizes.last.panelSize, greaterThan(250));
    expect(sizes.last.totalSize, 800);
    final start = tester.getTopLeft(find.byType(CsPanelLayout)).dx;
    expect(tester.getTopLeft(find.text('Main')).dx - start, greaterThan(250));
  });

  testWidgets('clamps to min and max', (tester) async {
    final sizes = <CsPanelResizeDetail>[];
    await pumpCs(tester, layout(onResize: sizes.add, min: 150, max: 300), size: csDesktopSize);
    await tester.drag(find.bySemanticsLabel('Resize panel'), const Offset(400, 0));
    expect(sizes.last.panelSize, 300);
    await tester.drag(find.bySemanticsLabel('Resize panel'), const Offset(-400, 0));
    expect(sizes.last.panelSize, 150);
  });

  testWidgets('arrow keys resize in 10px steps', (tester) async {
    final sizes = <CsPanelResizeDetail>[];
    await pumpCs(tester, layout(onResize: sizes.add), size: csDesktopSize);
    await tester.tap(find.bySemanticsLabel('Resize panel'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(sizes.last.panelSize, 210);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    expect(sizes.last.panelSize, 150);
  });

  testWidgets('controlled size is respected', (tester) async {
    await pumpCs(tester, layout(panelSize: 320), size: csDesktopSize);
    final start = tester.getTopLeft(find.byType(CsPanelLayout)).dx;
    expect(tester.getTopLeft(find.text('Main')).dx - start, closeTo(320, 0.5));
  });

  testWidgets('display panel only and main only', (tester) async {
    await pumpCs(tester, layout(display: CsPanelLayoutDisplay.panelOnly));
    expect(find.text('Main'), findsNothing);
    await pumpCs(tester, layout(display: CsPanelLayoutDisplay.mainOnly));
    expect(find.text('Panel'), findsNothing);
    expect(panel, isNotNull);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        height: 300,
        child: CsPanelLayout(
          scrollable: true,
          panelContent: Text('Filters for distributions'),
          mainContent: Text('Results'),
          defaultPanelSize: 150,
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
