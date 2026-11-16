import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  const defs = [
    CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 8}),
    CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 4}),
  ];

  testWidgets('renders in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const CsGrid(gridDefinition: defs, children: [Text('A'), Text('B')]),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('spans follow the grid width breakpoints', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(
        disableGutters: true,
        gridDefinition: defs,
        children: [
          SizedBox(height: 10, width: double.infinity),
          SizedBox(height: 10, width: double.infinity),
        ],
      ),
      size: csDesktopSize,
      center: false,
    );
    final a = tester.getRect(find.byType(SizedBox).at(0));
    final b = tester.getRect(find.byType(SizedBox).at(1));
    expect(a.width, closeTo(1280 * 8 / 12, 0.01));
    expect(b.left, closeTo(a.right, 0.01));
    expect(a.top, b.top);

    await pumpCs(tester, const CsGrid(gridDefinition: defs, children: [Text('A'), Text('B')]), center: false);
    expect(tester.getTopLeft(find.text('B')).dy, greaterThan(tester.getTopLeft(find.text('A')).dy));
  });

  testWidgets('gutters separate columns by space-grid-gutter', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(
        gridDefinition: [CsGridDefinition.all(colspan: 6), CsGridDefinition.all(colspan: 6)],
        children: [
          SizedBox(height: 10, width: double.infinity),
          SizedBox(height: 10, width: double.infinity),
        ],
      ),
      size: csDesktopSize,
      center: false,
    );
    final a = tester.getRect(find.byType(SizedBox).at(0));
    final b = tester.getRect(find.byType(SizedBox).at(1));
    expect(b.left - a.right, closeTo(CsDensityTokens.comfortable.gridGutter, 0.01));
    expect(a.left, 0);
    expect(b.right, closeTo(1280, 0.01));
  });

  testWidgets('offset pushes an element towards the end', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(
        disableGutters: true,
        gridDefinition: [CsGridDefinition.all(colspan: 6, offset: 3)],
        children: [SizedBox(height: 10, width: double.infinity)],
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(tester.getRect(find.byType(SizedBox)).left, closeTo(320, 0.01));
  });

  testWidgets('push and pull swap visual order', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(
        disableGutters: true,
        gridDefinition: [CsGridDefinition.all(colspan: 6, push: 6), CsGridDefinition.all(colspan: 6, pull: 6)],
        children: [Text('First'), Text('Second')],
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(tester.getTopLeft(find.text('Second')).dx, lessThan(tester.getTopLeft(find.text('First')).dx));
  });

  testWidgets('mirrors in RTL', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(
        gridDefinition: [CsGridDefinition.all(colspan: 6), CsGridDefinition.all(colspan: 6)],
        children: [Text('First'), Text('Second')],
      ),
      size: csDesktopSize,
      center: false,
      textDirection: TextDirection.rtl,
    );
    expect(tester.getTopLeft(find.text('Second')).dx, lessThan(tester.getTopLeft(find.text('First')).dx));
  });

  testWidgets('resolve falls back to the nearest smaller breakpoint', (tester) async {
    const d = CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.s: 3});
    expect(d.resolve(CsBreakpoint.xs).span, 12);
    expect(d.resolve(CsBreakpoint.xl).span, 3);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const CsGrid(gridDefinition: defs, children: [Text('Alpha beta'), Text('Gamma')]),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
