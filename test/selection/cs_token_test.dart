import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders normal and inline in every state', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in CsTokenVariant.values) ...[
                CsToken(
                  label: 'example-bucket',
                  variant: v,
                  icon: CsIcons.folder,
                  description: 'us-east-1',
                  onDismiss: () {},
                ),
                CsToken(label: 'read-only', variant: v, readOnly: true, onDismiss: () {}),
                CsToken(label: 'disabled', variant: v, disabled: true, onDismiss: () {}),
              ],
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('inline token is 20px tall', (tester) async {
    await pumpCs(tester, const CsToken(label: 'tag', variant: CsTokenVariant.inline));
    expect(tester.getSize(find.byType(CsToken)).height, 20);
  });

  testWidgets('dismiss fires, not when disabled or read-only', (tester) async {
    var n = 0;
    await pumpCs(tester, CsToken(label: 'a', dismissLabel: 'Remove a', onDismiss: () => n++));
    await tester.tap(find.bySemanticsLabel('Remove a'));
    expect(n, 1);
    await pumpCs(tester, CsToken(label: 'a', disabled: true, dismissLabel: 'Remove a', onDismiss: () => n++));
    await tester.tap(find.bySemanticsLabel('Remove a'), warnIfMissed: false);
    await pumpCs(tester, CsToken(label: 'a', readOnly: true, dismissLabel: 'Remove a', onDismiss: () => n++));
    await tester.tap(find.bySemanticsLabel('Remove a'), warnIfMissed: false);
    expect(n, 1);
  });

  testWidgets('shows label tag, description and tags', (tester) async {
    await pumpCs(
      tester,
      const CsToken(label: 'logs', labelTag: '12 GB', description: 'eu-west-1', tags: ['Versioned']),
    );
    expect(find.text('12 GB'), findsOneWidget);
    expect(find.text('eu-west-1'), findsOneWidget);
    expect(find.text('Versioned'), findsOneWidget);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      CsToken(label: 'a-very-long-bucket-name-that-keeps-going-and-going', description: 'us-east-1', onDismiss: () {}),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
