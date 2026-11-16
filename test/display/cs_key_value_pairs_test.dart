import 'package:cloudscape_flutter/src/display/display.dart';
import 'package:cloudscape_flutter/src/navigation/cs_link.dart';
import 'package:cloudscape_flutter/src/status/status.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

List<CsKeyValueItem> _items({VoidCallback? onInfo}) => [
  const CsKeyValuePair(label: 'Distribution ID', value: 'd111111abcdef8'),
  CsKeyValuePair(
    label: 'Status',
    valueWidget: const CsStatusIndicator(type: CsStatusType.success, text: 'Deployed'),
    info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: onInfo ?? () {}),
  ),
  const CsKeyValuePair(label: 'Price class', value: 'Use all edge locations'),
  const CsKeyValuePair(label: 'Domain name', value: 'd111111abcdef8.cloudfront.example', id: 'domain'),
];

void main() {
  test('column count keeps an even number when it wraps', () {
    expect(CsKeyValuePairs.columnCountFor(4, 150, 1200), 4);
    expect(CsKeyValuePairs.columnCountFor(4, 150, 500), 2);
    expect(CsKeyValuePairs.columnCountFor(4, 150, 320), 2);
    expect(CsKeyValuePairs.columnCountFor(4, 150, 200), 1);
    expect(CsKeyValuePairs.columnCountFor(3, 150, 1200), 3);
    expect(CsKeyValuePairs.columnCountFor(3, 150, 400), 2);
    expect(CsKeyValuePairs.columnCountFor(1, 150, 1200), 1);
  });

  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: CsKeyValuePairs(columns: 4, items: _items()),
          ),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Distribution ID'), findsOneWidget);
      }
    }
  });

  testWidgets('lays out four columns wide and one column at 390px', (tester) async {
    await pumpCs(tester, CsKeyValuePairs(columns: 4, items: _items()), size: csDesktopSize);
    final a = tester.getTopLeft(find.text('Distribution ID'));
    final b = tester.getTopLeft(find.text('Price class'));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));

    await pumpCs(tester, SizedBox(width: 290, child: CsKeyValuePairs(columns: 4, items: _items())));
    final c = tester.getTopLeft(find.text('Distribution ID'));
    final d = tester.getTopLeft(find.text('Price class'));
    expect(d.dy, greaterThan(c.dy));
    expect(d.dx, c.dx);
  });

  testWidgets('more than four columns uses four', (tester) async {
    await pumpCs(
      tester,
      CsKeyValuePairs(
        columns: 6,
        items: [for (var i = 0; i < 6; i++) CsKeyValuePair(label: 'Key $i', value: 'Value $i')],
      ),
      size: csDesktopSize,
    );
    expect(tester.getTopLeft(find.text('Key 3')).dy, tester.getTopLeft(find.text('Key 0')).dy);
    expect(tester.getTopLeft(find.text('Key 4')).dy, greaterThan(tester.getTopLeft(find.text('Key 0')).dy));
  });

  testWidgets('labels are bold label color, values body color', (tester) async {
    await pumpCs(tester, CsKeyValuePairs(items: _items()));
    final ctx = tester.element(find.text('Distribution ID'));
    final label = DefaultTextStyle.of(ctx).style;
    expect(label.fontWeight, FontWeight.w700);
    expect(label.color, ctx.cs.colors.textLabel);
    final value = DefaultTextStyle.of(tester.element(find.text('d111111abcdef8'))).style;
    expect(value.color, ctx.cs.colors.textKeyValuePairsValue);
  });

  testWidgets('groups show a title and their pairs', (tester) async {
    await pumpCs(
      tester,
      const CsKeyValuePairs(
        columns: 2,
        items: [
          CsKeyValueGroup(
            title: 'Origin',
            items: [
              CsKeyValuePair(label: 'Bucket', value: 'example-bucket'),
              CsKeyValuePair(label: 'Path', value: '/static'),
            ],
          ),
          CsKeyValueGroup(
            items: [CsKeyValuePair(label: 'Protocol', value: 'HTTPS only')],
          ),
        ],
      ),
      size: csDesktopSize,
    );
    expect(find.text('Origin'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Path')).dy, greaterThan(tester.getTopLeft(find.text('Bucket')).dy));
  });

  testWidgets('info links work and default to primary variant', (tester) async {
    var n = 0;
    await pumpCs(tester, CsKeyValuePairs(items: _items(onInfo: () => n++)));
    await tester.tap(find.text('Info'));
    expect(n, 1);
    expect(CsLinkDefaults.of(tester.element(find.text('Info'))), CsLinkVariant.primary);
  });

  testWidgets('exposes the aria label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsKeyValuePairs(items: _items(), ariaLabel: 'Distribution details'));
    expect(find.bySemanticsLabel('Distribution details'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('RTL, 2x text at 390px do not overflow', (tester) async {
    await pumpCs(
      tester,
      CsKeyValuePairs(columns: 3, minColumnWidth: 100, items: _items()),
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
