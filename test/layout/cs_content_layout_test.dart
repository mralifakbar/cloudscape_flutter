import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget page({
    CsContentLayoutHeaderVariant variant = CsContentLayoutHeaderVariant.defaultVariant,
    bool disableOverlap = false,
    double? maxContentWidth,
    VoidCallback? onTap,
  }) => SingleChildScrollView(
    child: CsContentLayout(
      headerVariant: variant,
      disableOverlap: disableOverlap,
      maxContentWidth: maxContentWidth,
      defaultPadding: true,
      notifications: const Text('Notice'),
      breadcrumbs: const Text('Crumbs'),
      header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Distributions'),
      secondaryHeader: const Text('Summary'),
      child: GestureDetector(
        onTap: onTap,
        child: const SizedBox(height: 200, child: Text('Content')),
      ),
    ),
  );

  testWidgets('renders every header variant in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final v in CsContentLayoutHeaderVariant.values) {
          await pumpCs(
            tester,
            page(variant: v),
            brightness: b,
            density: d,
            center: false,
          );
          expect(find.text('Distributions'), findsOneWidget);
          expect(find.text('Notice'), findsOneWidget);
          expect(find.text('Crumbs'), findsOneWidget);
          expect(find.text('Summary'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('high contrast content overlaps the header band', (tester) async {
    await pumpCs(tester, page(variant: CsContentLayoutHeaderVariant.highContrast), center: false);
    final headerBottom = tester.getBottomLeft(find.text('Distributions')).dy;
    final band = tester.getRect(
      find.descendant(of: find.byType(CsContentLayout), matching: find.byType(DecoratedBox)).first,
    );
    final contentTop = tester.getTopLeft(find.text('Content')).dy;
    expect(contentTop, greaterThan(headerBottom));
    expect(contentTop, lessThan(band.bottom));
  });

  testWidgets('disableOverlap starts content under the band', (tester) async {
    await pumpCs(tester, page(variant: CsContentLayoutHeaderVariant.highContrast, disableOverlap: true), center: false);
    final band = tester.getRect(
      find.descendant(of: find.byType(CsContentLayout), matching: find.byType(DecoratedBox)).first,
    );
    expect(tester.getTopLeft(find.text('Content')).dy, greaterThanOrEqualTo(band.bottom));
  });

  testWidgets('overlapping content still receives taps', (tester) async {
    var n = 0;
    await pumpCs(tester, page(variant: CsContentLayoutHeaderVariant.highContrast, onTap: () => n++), center: false);
    await tester.tap(find.text('Content'));
    expect(n, 1);
  });

  testWidgets('high contrast header uses the dark header context', (tester) async {
    await pumpCs(tester, page(variant: CsContentLayoutHeaderVariant.highContrast), center: false);
    final theme = CsTheme.of(tester.element(find.text('Distributions')));
    expect(theme.visualContext, CsVisualContextName.header);
  });

  testWidgets('custom header background builder is used', (tester) async {
    await pumpCs(
      tester,
      CsContentLayout(
        headerBackgroundStyle: (_) => const BoxDecoration(color: Color(0xFF112233)),
        header: const Text('H'),
        child: const Text('C'),
      ),
      center: false,
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(CsContentLayout), matching: find.byType(DecoratedBox)).first,
    );
    expect((box.decoration as BoxDecoration).color, const Color(0xFF112233));
  });

  testWidgets('maxContentWidth caps the content', (tester) async {
    await pumpCs(tester, page(maxContentWidth: 600), size: csDesktopSize, center: false);
    expect(tester.getSize(find.byType(CsHeader)).width, lessThanOrEqualTo(600));
  });

  testWidgets('secondary header moves under the header on phones', (tester) async {
    await pumpCs(tester, page(), center: false);
    expect(tester.getTopLeft(find.text('Summary')).dy, greaterThan(tester.getTopLeft(find.text('Distributions')).dy));
    await pumpCs(tester, page(), size: csDesktopSize, center: false);
    expect(tester.getTopLeft(find.text('Summary')).dx, greaterThan(tester.getTopLeft(find.text('Distributions')).dx));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(tester, page(variant: CsContentLayoutHeaderVariant.highContrast), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
