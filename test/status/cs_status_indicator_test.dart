import 'package:cloudscape_flutter/src/feedback/cs_spinner.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/status/status.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every type and override in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in CsStatusType.values) CsStatusIndicator(type: t, text: t.name),
              for (final c in CsStatusColor.values)
                CsStatusIndicator(type: CsStatusType.info, colorOverride: c, text: c.name),
            ],
          ),
          brightness: b,
          density: d,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('colors text by type and override', (tester) async {
    await pumpCs(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsStatusIndicator(type: CsStatusType.error, text: 'Failed'),
          CsStatusIndicator(type: CsStatusType.stopped, text: 'Stopped', colorOverride: CsStatusColor.blue),
        ],
      ),
    );
    final c = tester.element(find.text('Failed')).cs.colors;
    expect(DefaultTextStyle.of(tester.element(find.text('Failed'))).style.color, c.textStatusError);
    expect(DefaultTextStyle.of(tester.element(find.text('Stopped'))).style.color, c.textStatusInfo);
  });

  testWidgets('shows the icon of each type and a spinner when loading', (tester) async {
    expect(CsStatusIndicator.iconFor(CsStatusType.success), CsIcons.statusPositive);
    expect(CsStatusIndicator.iconFor(CsStatusType.log), CsIcons.dot);
    await pumpCs(tester, const CsStatusIndicator(type: CsStatusType.loading, text: 'Deploying'), settle: false);
    expect(find.byType(CsSpinner), findsOneWidget);
    await pumpCs(tester, const CsStatusIndicator(type: CsStatusType.warning, text: 'Degraded'));
    expect(find.byType(CsIcon), findsOneWidget);
  });

  testWidgets('announces the status name before the text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsStatusIndicator(type: CsStatusType.error, text: '3 failed checks'));
    expect(find.bySemanticsLabel(RegExp(r'^Error\s+3 failed checks$')), findsOneWidget);
    await pumpCs(
      tester,
      const CsStatusIndicator(type: CsStatusType.info, text: 'Updated', iconAriaLabel: 'Information'),
    );
    expect(find.bySemanticsLabel(RegExp('^Information')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('wrapText false truncates to one line', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 120,
        child: CsStatusIndicator(
          type: CsStatusType.success,
          text: 'Available in every region of the account',
          wrapText: false,
        ),
      ),
    );
    final text = tester.widget<Text>(find.textContaining('Available'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(CsStatusIndicator)).height, 20);
  });

  testWidgets('inline display flows the icon with the text', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 120,
        child: CsStatusIndicator(
          type: CsStatusType.warning,
          display: CsStatusDisplay.inline,
          text: 'Certificate expires in 3 days',
        ),
      ),
    );
    expect(find.byType(RichText), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('animate fades in and shakes errors, instantly with reduced motion', (tester) async {
    await pumpCs(
      tester,
      const CsStatusIndicator(type: CsStatusType.error, text: 'Required', animate: true),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 40));
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: find.byType(CsStatusIndicator), matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);

    await pumpCs(
      tester,
      const CsStatusIndicator(key: ValueKey('r'), type: CsStatusType.error, text: 'Required', animate: true),
      disableAnimations: true,
      settle: false,
    );
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(of: find.byType(CsStatusIndicator), matching: find.byType(FadeTransition)),
          )
          .opacity
          .value,
      1,
    );
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpCs(
      tester,
      const CsStatusIndicator(
        type: CsStatusType.inProgress,
        text: 'Creating distribution d111111abcdef8 in the default region',
        iconSize: CsIconSize.big,
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
