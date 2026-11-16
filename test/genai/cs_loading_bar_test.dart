import 'package:cloudscape_flutter/src/genai/genai.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders both variants in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            children: [
              CsLoadingBar(),
              SizedBox(height: 8),
              CsLoadingBar(variant: CsLoadingBarVariant.genAiMasked),
            ],
          ),
          brightness: b,
          density: d,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('is 2px tall and full width', (tester) async {
    await pumpCs(tester, const Column(children: [CsLoadingBar()]), settle: false, center: false);
    expect(tester.getSize(find.byType(CsLoadingBar)), const Size(390, 2));
  });

  testWidgets('animates while mounted and stops when removed', (tester) async {
    await pumpCs(tester, const CsLoadingBar(), settle: false);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
    await pumpCs(tester, const SizedBox(), settle: false);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('is static under reduced motion', (tester) async {
    await pumpCs(tester, const CsLoadingBar(), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('right to left renders', (tester) async {
    await pumpCs(tester, const CsLoadingBar(), textDirection: TextDirection.rtl, settle: false);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional label is exposed', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsLoadingBar(semanticLabel: 'Generating response'), settle: false);
    expect(find.bySemanticsLabel('Generating response'), findsOneWidget);
    handle.dispose();
  });
}
