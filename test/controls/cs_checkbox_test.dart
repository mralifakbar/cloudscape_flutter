import 'dart:ui' show CheckedState;

import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.onChange});

  final ValueChanged<bool>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool checked = false;

  @override
  Widget build(BuildContext context) => CsCheckbox(
    checked: checked,
    label: 'Enable versioning',
    description: 'Keeps every version of each object.',
    onChange: (v) {
      widget.onChange?.call(v);
      setState(() => checked = v);
    },
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders every state in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Host(),
              CsCheckbox(checked: true, label: 'Checked', onChange: (_) {}),
              CsCheckbox(checked: false, indeterminate: true, label: 'Some', onChange: (_) {}),
              CsCheckbox(checked: true, disabled: true, label: 'Disabled', onChange: (_) {}),
              CsCheckbox(checked: true, readOnly: true, label: 'Read-only', onChange: (_) {}),
              const CsCheckboxIcon(checked: true),
            ],
          ),
          brightness: brightness,
          density: density,
        );
        expect(find.text('Some'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tap toggles; indeterminate becomes checked', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Enable versioning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keeps every version of each object.'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);

    bool? next;
    await pumpCs(tester, CsCheckbox(checked: false, indeterminate: true, label: 'All', onChange: (v) => next = v));
    await tester.tap(find.text('All'));
    expect(next, isTrue);
  });

  testWidgets('disabled, read-only and null onChange do not fire', (tester) async {
    var calls = 0;
    await pumpCs(tester, CsCheckbox(checked: false, disabled: true, label: 'A', onChange: (_) => calls++));
    await tester.tap(find.text('A'));
    await pumpCs(tester, CsCheckbox(checked: false, readOnly: true, label: 'A', onChange: (_) => calls++));
    await tester.tap(find.text('A'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpCs(tester, const CsCheckbox(checked: false, label: 'A'));
    await tester.tap(find.text('A'));
    expect(calls, 0);
  });

  testWidgets('semantics: checked, mixed, required', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsCheckbox(checked: true, label: 'On', ariaRequired: true, onChange: (_) {}),
          CsCheckbox(checked: false, indeterminate: true, label: 'Mixed', onChange: (_) {}),
          CsCheckbox(checked: false, ariaLabel: 'Select row', onChange: (_) {}),
        ],
      ),
    );
    final on = tester.getSemantics(find.text('On'));
    expect(on.flagsCollection.isChecked, CheckedState.isTrue);
    expect(on.hint, 'Required');
    expect(tester.getSemantics(find.text('Mixed')).flagsCollection.isChecked, CheckedState.mixed);
    expect(find.bySemanticsLabel('Select row'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Space toggles from the keyboard', (tester) async {
    final changes = <bool>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(changes, [true]);
  });

  testWidgets('reduced motion skips the check draw-in; 2x text fits', (tester) async {
    await pumpCs(tester, const _Host(), disableAnimations: true, textScale: 2);
    await tester.tap(find.text('Enable versioning'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
