import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({super.key, this.maxRows, this.onChange});

  final int? maxRows;
  final ValueChanged<String>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = '';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsFormField(
      label: 'Description',
      characterCountText: '${value.length}/200',
      child: CsTextarea(
        value: value,
        rows: 2,
        maxRows: widget.maxRows,
        placeholder: 'Describe what this bucket stores',
        onChange: (v) {
          widget.onChange?.call(v);
          setState(() => value = v);
        },
      ),
    ),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders every state in $brightness $density', (tester) async {
        await pumpCs(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                const _Host(),
                CsTextarea(value: 'x', invalid: true, onChange: (_) {}),
                CsTextarea(value: 'x', warning: true, onChange: (_) {}),
                CsTextarea(value: 'x', disabled: true, onChange: (_) {}),
                CsTextarea(value: 'x', readOnly: true, mono: true, onChange: (_) {}),
              ],
            ),
          ),
          brightness: brightness,
          density: density,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('typing updates the value and the character count', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.enterText(find.byType(TextField), 'Access logs\nfor the example distribution');
    await tester.pump();
    expect(changes.single, startsWith('Access logs'));
    expect(find.text('40/200'), findsOneWidget);
  });

  testWidgets('rows sets the height; maxRows lets it grow', (tester) async {
    await pumpCs(tester, const _Host());
    final fixed = tester.getSize(find.byType(CsTextarea)).height;
    await tester.enterText(find.byType(TextField), 'a\nb\nc\nd\ne');
    await tester.pump();
    expect(tester.getSize(find.byType(CsTextarea)).height, fixed);

    await pumpCs(tester, const _Host(key: ValueKey('grow'), maxRows: 6));
    final start = tester.getSize(find.byType(CsTextarea)).height;
    expect(start, fixed);
    await tester.enterText(find.byType(TextField), 'a\nb\nc\nd\ne');
    await tester.pump();
    expect(tester.getSize(find.byType(CsTextarea)).height, greaterThan(start));
  });

  testWidgets('disabled is not editable; semantics are multiline', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsTextarea(value: '', disabled: true, ariaLabel: 'Notes', onChange: (_) {}));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await pumpCs(tester, CsTextarea(value: '', ariaLabel: 'Notes', onChange: (_) {}));
    final node = tester.getSemantics(find.byType(TextField));
    expect(node.flagsCollection.isTextField, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 3);
    handle.dispose();
  });

  testWidgets('key events reach onKeyEvent', (tester) async {
    var submits = 0;
    await pumpCs(
      tester,
      CsTextarea(
        value: '',
        onChange: (_) {},
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isMetaPressed) {
            submits++;
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(submits, 1);
  });

  testWidgets('2x text at 390px', (tester) async {
    await pumpCs(tester, const _Host(maxRows: 4), textScale: 2, disableAnimations: true);
    expect(tester.takeException(), isNull);
  });
}
