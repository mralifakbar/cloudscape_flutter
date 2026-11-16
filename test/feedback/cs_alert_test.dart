import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/feedback/feedback.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every type in light, dark, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            children: [
              for (final t in CsAlertType.values)
                CsAlert(type: t, header: 'Header ${t.name}', content: 'Content for ${t.name}', dismissible: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Header error'), findsOneWidget);
      }
    }
  });

  testWidgets('dismiss and action buttons fire their callbacks', (tester) async {
    var dismissed = 0;
    var pressed = 0;
    await pumpCs(
      tester,
      CsAlert(
        content: 'Stop the instance first.',
        dismissible: true,
        onDismiss: () => dismissed++,
        buttonText: 'Stop instance',
        onButtonPress: () => pressed++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Dismiss alert'));
    await tester.tap(find.text('Stop instance'));
    expect(dismissed, 1);
    expect(pressed, 1);
  });

  testWidgets('custom action wins over buttonText', (tester) async {
    await pumpCs(
      tester,
      CsAlert(
        content: 'Message',
        buttonText: 'Ignored',
        action: CsButton(text: 'Custom', onPress: () {}),
      ),
    );
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Ignored'), findsNothing);
  });

  testWidgets('hidden alerts take no space', (tester) async {
    await pumpCs(tester, const CsAlert(content: 'Hidden', visible: false));
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('status icon and dismiss labels follow i18nStrings', (tester) async {
    await pumpCs(
      tester,
      const CsAlert(
        type: CsAlertType.warning,
        content: 'Message',
        dismissible: true,
        statusIconAriaLabel: 'ignored',
        i18nStrings: CsAlertI18nStrings(warningIconAriaLabel: 'Peringatan', dismissAriaLabel: 'Tutup'),
      ),
    );
    expect(find.bySemanticsLabel('Peringatan'), findsOneWidget);
    expect(find.bySemanticsLabel('Tutup'), findsOneWidget);
  });

  testWidgets('action wraps below the message at phone width and 2x text', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 358,
        child: CsAlert(
          type: CsAlertType.error,
          header: 'Could not delete bucket',
          content: 'example-bucket is not empty. Empty it and try again.',
          buttonText: 'Empty bucket',
          dismissible: true,
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final message = tester.getTopLeft(find.text('Could not delete bucket'));
    final action = tester.getTopLeft(find.text('Empty bucket'));
    expect(action.dy, greaterThan(message.dy));
  });

  testWidgets('action sits beside the message on wide layouts', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 900,
        child: CsAlert(content: 'Short message', buttonText: 'Retry'),
      ),
      size: csDesktopSize,
    );
    final message = tester.getCenter(find.text('Short message'));
    final action = tester.getCenter(find.text('Retry'));
    expect((action.dy - message.dy).abs(), lessThan(16));
    expect(action.dx, greaterThan(message.dx));
  });

  testWidgets('fades in when shown, instantly under reduced motion', (tester) async {
    await pumpCs(tester, const CsAlert(content: 'Shown'), disableAnimations: true, settle: false);
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: find.text('Shown'), matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1);
  });
}
