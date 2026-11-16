import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.initial = false, this.onChange});

  final bool initial;
  final ValueChanged<bool>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool checked = widget.initial;

  @override
  Widget build(BuildContext context) => CsToggle(
    checked: checked,
    label: 'Detailed monitoring',
    description: 'Collects metrics every minute.',
    onChange: (v) {
      widget.onChange?.call(v);
      setState(() => checked = v);
    },
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Host(),
              const _Host(initial: true),
              CsToggle(checked: true, disabled: true, label: 'Disabled', onChange: (_) {}),
              CsToggle(checked: true, readOnly: true, label: 'Read-only', onChange: (_) {}),
            ],
          ),
          brightness: brightness,
          density: density,
        );
        expect(find.text('Disabled'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tap on the label toggles', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Detailed monitoring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detailed monitoring'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('disabled and read-only do not fire', (tester) async {
    var calls = 0;
    await pumpCs(tester, CsToggle(checked: false, disabled: true, label: 'Off', onChange: (_) => calls++));
    await tester.tap(find.text('Off'));
    await pumpCs(tester, CsToggle(checked: false, readOnly: true, label: 'Off', onChange: (_) => calls++));
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('semantics expose the toggled state and label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Host(initial: true));
    expect(
      tester.getSemantics(find.text('Detailed monitoring')),
      matchesSemantics(
        label: 'Detailed monitoring\nCollects metrics every minute.',
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

  testWidgets('Space toggles when focused', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(changes, [true]);
  });

  testWidgets('dragging the handle past the middle turns it on', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    final track = tester.getTopLeft(find.byType(CsToggle)) + const Offset(16, 22);
    final gesture = await tester.startGesture(track);
    await gesture.moveBy(const Offset(4, 0));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [true]);
  });

  testWidgets('a short drag back keeps it off', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    final track = tester.getTopLeft(find.byType(CsToggle)) + const Offset(16, 22);
    final gesture = await tester.startGesture(track);
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('reduced motion and 2x text at 390px', (tester) async {
    await pumpCs(tester, const _Host(), disableAnimations: true, textScale: 2);
    await tester.tap(find.text('Detailed monitoring'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
