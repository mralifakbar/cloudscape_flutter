import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  List<Widget> items(int n) => [for (var i = 0; i < n; i++) Text('Item $i')];

  testWidgets('renders every variant and border in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in CsColumnLayoutVariant.values)
                for (final br in CsColumnLayoutBorders.values)
                  CsColumnLayout(columns: 3, variant: v, borders: br, children: items(4)),
            ],
          ),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('four columns show on one row when wide', (tester) async {
    await pumpCs(tester, CsColumnLayout(columns: 4, children: items(4)), size: csDesktopSize, center: false);
    final ys = [for (var i = 0; i < 4; i++) tester.getTopLeft(find.text('Item $i')).dy];
    expect(ys.toSet().length, 1);
    expect(tester.getTopLeft(find.text('Item 1')).dx, greaterThan(tester.getTopLeft(find.text('Item 0')).dx));
  });

  testWidgets('collapses to two per row between 465 and 688px and one under 465px', (tester) async {
    await pumpCs(
      tester,
      SizedBox(width: 600, child: CsColumnLayout(columns: 4, children: items(4))),
      size: csDesktopSize,
    );
    expect(tester.getTopLeft(find.text('Item 0')).dy, tester.getTopLeft(find.text('Item 1')).dy);
    expect(tester.getTopLeft(find.text('Item 2')).dy, greaterThan(tester.getTopLeft(find.text('Item 0')).dy));
    await pumpCs(tester, CsColumnLayout(columns: 4, children: items(4)));
    expect(tester.getTopLeft(find.text('Item 1')).dy, greaterThan(tester.getTopLeft(find.text('Item 0')).dy));
  });

  testWidgets('column count helpers match Cloudscape', (tester) async {
    expect(CsColumnLayout.fixedColumnCount(3, 400), 1);
    expect(CsColumnLayout.fixedColumnCount(3, 500), 2);
    expect(CsColumnLayout.fixedColumnCount(1, 500), 1);
    expect(CsColumnLayout.fixedColumnCount(3, 900), 3);
    expect(CsColumnLayout.flexibleColumnCount(6, 200, 1000), 4);
    expect(CsColumnLayout.flexibleColumnCount(6, 200, 1300), 6);
    expect(CsColumnLayout.flexibleColumnCount(6, 200, 100), 1);
  });

  testWidgets('minColumnWidth allows more than four columns', (tester) async {
    await pumpCs(
      tester,
      CsColumnLayout(columns: 6, minColumnWidth: 150, children: items(6)),
      size: csDesktopSize,
      center: false,
    );
    expect(tester.getTopLeft(find.text('Item 5')).dy, tester.getTopLeft(find.text('Item 0')).dy);
  });

  testWidgets('disableGutters packs columns edge to edge', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 800,
        child: CsColumnLayout(
          columns: 2,
          disableGutters: true,
          children: [
            SizedBox(height: 20, width: double.infinity, child: Text('A')),
            SizedBox(height: 20, width: double.infinity, child: Text('B')),
          ],
        ),
      ),
      size: csDesktopSize,
    );
    expect(tester.getTopLeft(find.text('B')).dx - tester.getTopLeft(find.text('A')).dx, 400);
  });

  testWidgets('cells in a row stretch to the tallest', (tester) async {
    await pumpCs(
      tester,
      const CsColumnLayout(
        columns: 2,
        children: [
          SizedBox(height: 100, child: Text('Tall')),
          ColoredBox(color: Color(0xFF00FF00)),
        ],
      ),
      size: csDesktopSize,
    );
    expect(tester.getSize(find.byType(ColoredBox).last).height, 100);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      CsColumnLayout(columns: 3, variant: CsColumnLayoutVariant.textGrid, children: items(3)),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
