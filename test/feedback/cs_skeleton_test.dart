import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every variant in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(children: [for (final v in CsSkeletonVariant.values) CsSkeleton(variant: v, width: 200)]),
          brightness: b,
          density: d,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('is one line tall for its variant, or the given height', (tester) async {
    await pumpCs(tester, const CsSkeleton(variant: CsSkeletonVariant.textHeadingXl, width: 100), settle: false);
    expect(tester.getSize(find.byType(CsSkeleton)), const Size(100, 30));
    await pumpCs(tester, const CsSkeleton(height: 120, width: 80), settle: false);
    expect(tester.getSize(find.byType(CsSkeleton)), const Size(80, 120));
  });

  testWidgets('fills the available width by default', (tester) async {
    await pumpCs(tester, const SizedBox(width: 300, child: CsSkeleton()), settle: false);
    expect(tester.getSize(find.byType(CsSkeleton)).width, 300);
  });

  testWidgets('the wave runs while shown and stops under reduced motion', (tester) async {
    await pumpCs(tester, const CsSkeleton(width: 100), settle: false);
    expect(tester.hasRunningAnimations, isTrue);
    await pumpCs(tester, const CsSkeleton(width: 100), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('swaps to its child when loading ends and the wave stops', (tester) async {
    await pumpCs(tester, const CsSkeleton(loading: true, child: Text('i-0abc123')), settle: false);
    expect(find.text('i-0abc123'), findsNothing);
    await tester.pumpWidget(csHarness(const CsSkeleton(loading: false, child: Text('i-0abc123'))));
    await tester.pumpAndSettle();
    expect(find.text('i-0abc123'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('is hidden from screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsSkeleton(width: 100), settle: false);
    expect(find.byType(ExcludeSemantics), findsWidgets);
    handle.dispose();
  });

  testWidgets('lines fit a phone at 2x text', (tester) async {
    await pumpCs(tester, const CsSkeletonLines(lines: 4), textScale: 2, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byType(CsSkeleton), findsNWidgets(4));
  });
}
