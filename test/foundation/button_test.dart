import 'package:cloudscape_flutter/src/buttons/buttons.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
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
          Wrap(
            children: [
              for (final v in CsButtonVariant.values)
                CsButton(
                  text: v.name,
                  icon: CsIcons.settings,
                  semanticLabel: v.name,
                  variant: v,
                  onPress: () {},
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

  testWidgets('fires onPress, not when disabled or loading', (tester) async {
    var n = 0;
    await pumpCs(tester, CsButton(text: 'Save', onPress: () => n++));
    await tester.tap(find.text('Save'));
    expect(n, 1);
    await pumpCs(tester, CsButton(text: 'Save', disabled: true, onPress: () => n++));
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await pumpCs(tester, CsButton(text: 'Save', loading: true, onPress: () => n++), settle: false);
    await tester.tap(find.text('Save'), warnIfMissed: false);
    expect(n, 1);
  });

  testWidgets('is 32px tall comfortable and 28px compact', (tester) async {
    await pumpCs(tester, CsButton(text: 'Go', onPress: () {}), tapTargetSize: CsTapTargetSize.shrinkWrap);
    expect(tester.getSize(find.byType(Container).first).height, 32);
    await pumpCs(
      tester,
      CsButton(text: 'Go', onPress: () {}),
      tapTargetSize: CsTapTargetSize.shrinkWrap,
      density: CsDensity.compact,
    );
    expect(tester.getSize(find.byType(Container).first).height, 28);
  });

  testWidgets('icon buttons expose their label', (tester) async {
    await pumpCs(
      tester,
      CsButton(icon: CsIcons.refresh, variant: CsButtonVariant.icon, semanticLabel: 'Refresh', onPress: () {}),
    );
    expect(find.bySemanticsLabel('Refresh'), findsOneWidget);
  });
}
