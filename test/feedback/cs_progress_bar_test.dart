import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every variant and status in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            children: [
              for (final v in CsProgressBarVariant.values)
                for (final s in CsProgressBarStatus.values)
                  CsProgressBar(
                    variant: v,
                    status: s,
                    value: 40,
                    label: 'Creating snapshot',
                    description: 'vol-0abc123',
                    additionalInfo: 'About 3 minutes remaining',
                    resultText: 'Done',
                    resultButtonText: 'Retry',
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

  testWidgets('shows the rounded percentage and exposes it as the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsProgressBar(label: 'Uploading', value: 41.6));
    expect(find.text('42%'), findsOneWidget);
    expect(find.bySemanticsLabel('Uploading'), findsWidgets);
    expect(tester.getSemantics(find.byType(CsProgressBar)), isNotNull);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.value == '42%'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('animates value changes', (tester) async {
    await pumpCs(tester, const CsProgressBar(label: 'Uploading', value: 10));
    await tester.pumpWidget(csHarness(const CsProgressBar(label: 'Uploading', value: 90)));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester.widget<TweenAnimationBuilder<double>>(find.byType(TweenAnimationBuilder<double>));
    expect(mid.tween.end, 0.9);
    await tester.pumpAndSettle();
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('result state shows text and fires the result button', (tester) async {
    var presses = 0;
    await pumpCs(
      tester,
      CsProgressBar(
        label: 'Creating snapshot',
        status: CsProgressBarStatus.error,
        resultText: 'Snapshot failed',
        resultButtonText: 'Retry',
        onResultButtonPress: () => presses++,
      ),
    );
    expect(find.text('Snapshot failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(presses, 1);
  });

  testWidgets('flash variant hides the result button', (tester) async {
    await pumpCs(
      tester,
      const CsProgressBar(
        variant: CsProgressBarVariant.flash,
        status: CsProgressBarStatus.success,
        resultText: 'Created',
        resultButtonText: 'View',
      ),
    );
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('View'), findsNothing);
  });

  testWidgets('fits 390px at 2x text and with reduced motion', (tester) async {
    await pumpCs(
      tester,
      const CsProgressBar(
        label: 'Creating a snapshot of a very large volume',
        description: 'vol-0abc123def456',
        value: 100,
        additionalInfo: 'Finishing up',
      ),
      textScale: 2,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('100%'), findsOneWidget);
  });
}
