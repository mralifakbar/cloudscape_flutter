import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget full() => const CsContainer(
    header: CsHeader(title: 'Distribution settings', description: 'Origin and behaviors'),
    footer: Text('Footer'),
    child: Text('Body'),
  );

  testWidgets('renders header, content and footer in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, full(), brightness: b, density: d);
        expect(find.text('Distribution settings'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Footer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('pads content 20px on the sides', (tester) async {
    await pumpCs(tester, const CsContainer(child: Text('Body')), center: false);
    final box = tester.getTopLeft(find.byType(CsContainer));
    final text = tester.getTopLeft(find.text('Body'));
    expect(text.dx - box.dx, CsSpace.containerHorizontal);
  });

  testWidgets('disableContentPaddings removes the padding', (tester) async {
    await pumpCs(tester, const CsContainer(disableContentPaddings: true, child: Text('Body')), center: false);
    expect(tester.getTopLeft(find.text('Body')), tester.getTopLeft(find.byType(CsContainer)));
  });

  testWidgets('disableFooterPaddings removes the footer padding', (tester) async {
    await pumpCs(
      tester,
      const CsContainer(disableFooterPaddings: true, footerDivider: false, footer: Text('F')),
      center: false,
    );
    expect(tester.getTopLeft(find.text('F')).dx, tester.getTopLeft(find.byType(CsContainer)).dx);
  });

  testWidgets('stacked containers render in every position', (tester) async {
    await pumpCs(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsContainer(variant: CsContainerVariant.stacked, stackPosition: CsStackPosition.first, child: Text('A')),
          CsContainer(variant: CsContainerVariant.stacked, stackPosition: CsStackPosition.middle, child: Text('B')),
          CsContainer(variant: CsContainerVariant.stacked, stackPosition: CsStackPosition.last, child: Text('C')),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('top media shows above the header', (tester) async {
    await pumpCs(
      tester,
      const CsContainer(
        media: CsContainerMedia(
          content: ColoredBox(key: Key('media'), color: Color(0xFF0000FF)),
          height: 100,
        ),
        header: CsHeader(title: 'Media'),
        child: Text('Body'),
      ),
    );
    final media = tester.getRect(find.byKey(const Key('media')));
    expect(media.height, 100);
    expect(tester.getTopLeft(find.text('Media')).dy, greaterThan(media.bottom));
  });

  testWidgets('side media sits beside content on desktop and on top on phones', (tester) async {
    Widget build() => const SizedBox(
      width: 600,
      child: CsContainer(
        media: CsContainerMedia(
          content: ColoredBox(key: Key('media'), color: Color(0xFF0000FF)),
          position: CsContainerMediaPosition.side,
          width: 200,
          height: 80,
        ),
        child: Text('Body'),
      ),
    );
    await pumpCs(tester, build(), size: csDesktopSize);
    final media = tester.getRect(find.byKey(const Key('media')));
    expect(media.width, 200);
    expect(tester.getTopLeft(find.text('Body')).dx, greaterThan(media.right));
    await pumpCs(tester, build());
    final m2 = tester.getRect(find.byKey(const Key('media')));
    expect(tester.getTopLeft(find.text('Body')).dy, greaterThan(m2.bottom - 1));
  });

  testWidgets('fitHeight fills the parent height', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        height: 300,
        child: CsContainer(
          fitHeight: true,
          header: CsHeader(title: 'T'),
          child: Text('B'),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CsContainer)).height, 300);
  });

  testWidgets('style overrides background and radius', (tester) async {
    await pumpCs(
      tester,
      const CsContainer(
        style: CsContainerStyle(background: Color(0xFF123456), borderRadius: 4),
        child: Text('B'),
      ),
    );
    final c = tester.widget<Container>(find.descendant(of: find.byType(CsContainer), matching: find.byType(Container)));
    final d = c.decoration! as BoxDecoration;
    expect(d.color, const Color(0xFF123456));
    expect(d.borderRadius, BorderRadius.circular(4));
  });

  testWidgets('exposes a labelled region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsContainer(semanticLabel: 'Settings', child: Text('B')));
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, full(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
