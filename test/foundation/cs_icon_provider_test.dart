import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

CsIconData _painted(WidgetTester tester, Finder icon) {
  final paint = tester.widget<CustomPaint>(find.descendant(of: icon, matching: find.byType(CustomPaint)).first);
  return (paint.painter! as CsIconPainter).icon;
}

void main() {
  testWidgets('without a provider icons draw the built-in glyph', (tester) async {
    await pumpCs(tester, const CsIcon(CsIcons.close));
    expect(_painted(tester, find.byType(CsIcon)), CsIcons.close);
  });

  testWidgets('overrides an icon by Cloudscape name', (tester) async {
    for (final b in Brightness.values) {
      await pumpCs(
        tester,
        const CsIconProvider(icons: {'close': CsIcons.arrowLeft}, child: CsIcon(CsIcons.close)),
        brightness: b,
      );
      expect(_painted(tester, find.byType(CsIcon)), CsIcons.arrowLeft);
    }
  });

  testWidgets('leaves other icons alone', (tester) async {
    await pumpCs(tester, const CsIconProvider(icons: {'close': CsIcons.arrowLeft}, child: CsIcon(CsIcons.settings)));
    expect(_painted(tester, find.byType(CsIcon)), CsIcons.settings);
  });

  testWidgets('nested providers merge and null resets one name', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        icons: {'close': CsIcons.arrowLeft, 'settings': CsIcons.check},
        child: CsIconProvider(
          icons: {'close': null, 'search': CsIcons.filter},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsIcon(CsIcons.close, key: Key('close')),
              CsIcon(CsIcons.settings, key: Key('settings')),
              CsIcon(CsIcons.search, key: Key('search')),
            ],
          ),
        ),
      ),
    );
    expect(_painted(tester, find.byKey(const Key('close'))), CsIcons.close);
    expect(_painted(tester, find.byKey(const Key('settings'))), CsIcons.check);
    expect(_painted(tester, find.byKey(const Key('search'))), CsIcons.filter);
  });

  testWidgets('reset clears every outer override', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        icons: {'close': CsIcons.arrowLeft},
        child: CsIconProvider.reset(child: CsIcon(CsIcons.close)),
      ),
    );
    expect(_painted(tester, find.byType(CsIcon)), CsIcons.close);
  });

  testWidgets('widget overrides are sized like the icon', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        iconWidgets: {
          'settings': ColoredBox(key: Key('custom'), color: Color(0xFF0972D3), child: SizedBox(width: 40, height: 40)),
        },
        child: CsIcon(CsIcons.settings, size: CsIconSize.medium),
      ),
    );
    expect(find.byKey(const Key('custom')), findsOneWidget);
    expect(tester.getSize(find.byType(CsIcon)), const Size(20, 20));
  });

  testWidgets('an override that uses the same icon draws the built-in one without looping', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        icons: {'arrow-left': CsIcons.close},
        iconWidgets: {'close': CsIcon(CsIcons.close, variant: CsIconVariant.error)},
        child: CsIcon(CsIcons.close),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CsIcon), findsNWidgets(2));
    expect(_painted(tester, find.byType(CsIcon).last), CsIcons.close);
  });

  testWidgets('swapping two icons does not loop', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        icons: {'close': CsIcons.arrowLeft, 'arrow-left': CsIcons.close},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsIcon(CsIcons.close, key: Key('a')),
            CsIcon(CsIcons.arrowLeft, key: Key('b')),
          ],
        ),
      ),
    );
    expect(_painted(tester, find.byKey(const Key('a'))), CsIcons.arrowLeft);
    expect(_painted(tester, find.byKey(const Key('b'))), CsIcons.close);
  });

  testWidgets('changing the overrides rebuilds icons', (tester) async {
    Widget host(CsIconData icon) => CsIconProvider(icons: {'close': icon}, child: const CsIcon(CsIcons.close));
    await pumpCs(tester, host(CsIcons.arrowLeft));
    expect(_painted(tester, find.byType(CsIcon)), CsIcons.arrowLeft);
    await pumpCs(tester, host(CsIcons.check));
    expect(_painted(tester, find.byType(CsIcon)), CsIcons.check);
  });

  testWidgets('keeps the icon semantics label', (tester) async {
    await pumpCs(
      tester,
      const CsIconProvider(
        icons: {'status-positive': CsIcons.check},
        child: CsIcon(CsIcons.statusPositive, semanticLabel: 'Success'),
      ),
      density: CsDensity.compact,
    );
    expect(find.bySemanticsLabel('Success'), findsOneWidget);
  });
}
