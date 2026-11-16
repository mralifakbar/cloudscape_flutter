import 'package:cloudscape_flutter/src/actions/actions.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders both variants pressed and not, light, dark, compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          Wrap(
            children: [
              for (final v in CsToggleButtonVariant.values)
                for (final p in [true, false])
                  CsToggleButton(
                    text: 'Favorite',
                    ariaLabel: 'Favorite',
                    variant: v,
                    pressed: p,
                    icon: CsIcons.star,
                    pressedIcon: CsIcons.starFilled,
                    onChange: (_) {},
                  ),
              const CsToggleButton(text: 'Disabled', pressed: true, disabled: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('controlled: reports the next state, not when disabled', (tester) async {
    final calls = <bool>[];
    await pumpCs(tester, CsToggleButton(text: 'Bookmark', pressed: false, onChange: calls.add));
    await tester.tap(find.text('Bookmark'));
    await pumpCs(tester, CsToggleButton(text: 'Bookmark', pressed: true, onChange: calls.add));
    await tester.tap(find.text('Bookmark'));
    await pumpCs(tester, CsToggleButton(text: 'Bookmark', pressed: true, disabled: true, onChange: calls.add));
    await tester.tap(find.text('Bookmark'), warnIfMissed: false);
    expect(calls, [true, false]);
  });

  testWidgets('semantics: toggled state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsToggleButton(
        variant: CsToggleButtonVariant.icon,
        icon: CsIcons.star,
        ariaLabel: 'Favorite',
        pressed: true,
        onChange: (_) {},
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favorite').first),
      matchesSemantics(
        label: 'Favorite',
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('keyboard: Space toggles', (tester) async {
    final calls = <bool>[];
    await pumpCs(tester, CsToggleButton(text: 'Grid', pressed: false, onChange: calls.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(calls, [true]);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      CsToggleButton(text: 'Show only running instances', pressed: true, icon: CsIcons.filter, onChange: (_) {}),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
