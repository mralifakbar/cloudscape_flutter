import 'package:cloudscape_flutter/src/layout/layout.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget actions() => const SizedBox(width: 160, height: 32, child: Text('Actions'));

  testWidgets('renders every variant in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in CsHeaderVariant.values)
                CsHeader(
                  variant: v,
                  title: v.name,
                  counter: '(3)',
                  description: 'Description',
                  info: const Text('Info'),
                  actions: actions(),
                ),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('uses the type scale of each variant', (tester) async {
    await pumpCs(tester, const CsHeader(variant: CsHeaderVariant.h1, title: 'Page'));
    final dts = tester.widget<DefaultTextStyle>(
      find.ancestor(of: find.text('Page'), matching: find.byType(DefaultTextStyle)).first,
    );
    expect(dts.style.fontSize, CsTypeScale.headingXl.fontSize);
  });

  testWidgets('actions share the row when they fit and wrap when not', (tester) async {
    await pumpCs(
      tester,
      SizedBox(
        width: 600,
        child: CsHeader(title: 'Buckets', actions: actions()),
      ),
      size: csDesktopSize,
    );
    final t = tester.getTopLeft(find.text('Buckets'));
    final a = tester.getTopLeft(find.text('Actions'));
    expect((a.dy - t.dy).abs(), lessThan(10));
    expect(a.dx, greaterThan(t.dx));

    await pumpCs(
      tester,
      SizedBox(
        width: 250,
        child: CsHeader(title: 'A very long bucket title here', actions: actions()),
      ),
    );
    final t2 = tester.getBottomLeft(find.text('A very long bucket title here'));
    final a2 = tester.getTopLeft(find.text('Actions'));
    expect(a2.dy, greaterThanOrEqualTo(t2.dy));
  });

  testWidgets('actions sit at the end in RTL', (tester) async {
    await pumpCs(
      tester,
      SizedBox(
        width: 600,
        child: CsHeader(title: 'Buckets', actions: actions()),
      ),
      textDirection: TextDirection.rtl,
      size: csDesktopSize,
    );
    expect(tester.getTopLeft(find.text('Actions')).dx, lessThan(tester.getTopLeft(find.text('Buckets')).dx));
  });

  testWidgets('secondary content renders between title and actions', (tester) async {
    await pumpCs(
      tester,
      SizedBox(
        width: 700,
        child: CsHeader(title: 'T', secondaryContent: const Text('Secondary'), actions: actions()),
      ),
      size: csDesktopSize,
    );
    expect(find.text('Secondary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is a heading with the overridden level', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsHeader(title: 'Instances', headingTagOverride: 3));
    final node = tester.getSemantics(find.text('Instances'));
    expect(node.flagsCollection.isHeader, isTrue);
    expect(node.headingLevel, 3);
    handle.dispose();
  });

  testWidgets('sticky h1 shrinks and hides the description while stuck', (tester) async {
    Widget build(bool stuck) => CsHeaderStickyScope(
      stuck: stuck,
      child: const CsHeader(variant: CsHeaderVariant.awsuiH1Sticky, title: 'Instances', description: 'Desc'),
    );
    await pumpCs(tester, build(false));
    expect(find.text('Desc'), findsOneWidget);
    final h1 = tester.getSize(find.text('Instances')).height;
    await pumpCs(tester, build(true));
    expect(find.text('Desc'), findsNothing);
    expect(tester.getSize(find.text('Instances')).height, lessThan(h1));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      CsHeader(
        variant: CsHeaderVariant.h1,
        title: 'Distributions',
        counter: '(24)',
        description: 'All',
        actions: actions(),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
