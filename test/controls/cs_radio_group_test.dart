import 'dart:ui' show CheckedState;

import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _items = [
  CsRadioGroupItem(value: 'standard', label: 'Standard', description: 'Frequently accessed data.'),
  CsRadioGroupItem(value: 'ia', label: 'Infrequent access'),
  CsRadioGroupItem(value: 'glacier', label: 'Archive', disabled: true),
  CsRadioGroupItem(value: 'onezone', label: 'One zone'),
];

class _Host extends StatefulWidget {
  const _Host({this.initial, this.readOnly = false, this.onChange});

  final String? initial;
  final bool readOnly;
  final ValueChanged<String>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => CsRadioGroup(
    value: value,
    items: _items,
    readOnly: widget.readOnly,
    ariaLabel: 'Storage class',
    onChange: (v) {
      widget.onChange?.call(v);
      setState(() => value = v);
    },
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          const _Host(initial: 'ia'),
          brightness: brightness,
          density: density,
        );
        expect(find.text('Standard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tap selects and reports the value', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Infrequent access'));
    await tester.pumpAndSettle();
    expect(changes, ['ia']);
    // Tapping the selected radio again does not fire.
    await tester.tap(find.text('Infrequent access'));
    await tester.pumpAndSettle();
    expect(changes, ['ia']);
  });

  testWidgets('disabled item and read-only group do not change', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await pumpCs(tester, _Host(initial: 'standard', readOnly: true, onChange: changes.add));
    await tester.tap(find.text('One zone'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('reflects the controlled value in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Host(initial: 'ia'));
    expect(
      tester.getSemantics(find.text('Infrequent access')),
      matchesSemantics(
        label: 'Infrequent access',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    final standard = tester.getSemantics(find.text('Standard'));
    expect(standard.flagsCollection.isChecked, CheckedState.isFalse);
    handle.dispose();
  });

  testWidgets('one tab stop, arrows move and select skipping disabled', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(initial: 'ia', onChange: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // Archive is disabled, so focus moves to One zone.
    expect(changes, ['onezone']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes, ['onezone', 'standard']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(changes.last, 'onezone');
  });

  testWidgets('horizontal direction wraps at 390px and 2x text', (tester) async {
    await pumpCs(
      tester,
      CsRadioGroup(value: 'a', direction: CsRadioGroupDirection.horizontal, onChange: (_) {}, items: _items),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion renders the selection without animating', (tester) async {
    await pumpCs(tester, const _Host(initial: 'standard'), disableAnimations: true);
    await tester.tap(find.text('One zone'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('CsRadioButton fires onSelect only when unchecked', (tester) async {
    var selects = 0;
    await pumpCs(tester, CsRadioButton(checked: false, label: 'Standard', onSelect: () => selects++));
    await tester.tap(find.text('Standard'));
    expect(selects, 1);
    await pumpCs(tester, CsRadioButton(checked: true, label: 'Standard', onSelect: () => selects++));
    await tester.tap(find.text('Standard'));
    expect(selects, 1);
    await pumpCs(tester, CsRadioButton(checked: false, disabled: true, label: 'Standard', onSelect: () => selects++));
    await tester.tap(find.text('Standard'));
    expect(selects, 1);
  });
}
