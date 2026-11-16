import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.type = CsInputType.text, this.onChange, this.initial = ''});

  final CsInputType type;
  final ValueChanged<String>? onChange;
  final String initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsInput(
      value: value,
      type: widget.type,
      placeholder: 'example-bucket',
      ariaLabel: 'Bucket name',
      onChange: (v) {
        widget.onChange?.call(v);
        setState(() => value = v);
      },
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
                CsInput(value: 'x', invalid: true, onChange: (_) {}),
                CsInput(value: 'x', warning: true, onChange: (_) {}),
                CsInput(value: 'x', disabled: true, onChange: (_) {}),
                CsInput(value: 'x', readOnly: true, onChange: (_) {}),
                const CsInput(value: '50', prefix: Text(r'$'), suffix: Text('GiB'), invalid: true),
                CsInput(value: '', inlineLabelText: 'Region', placeholder: 'us-east-1', onChange: (_) {}),
              ],
            ),
          ),
          brightness: brightness,
          density: density,
        );
        expect(find.text('GiB'), findsOneWidget);
        expect(find.text('Region'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('typing calls onChange and the field reflects the value', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.enterText(find.byType(TextField), 'logs');
    await tester.pump();
    expect(changes.last, 'logs');
    expect(find.text('logs'), findsOneWidget);
  });

  testWidgets('controlled value from outside replaces the text', (tester) async {
    await pumpCs(tester, CsInput(value: 'first', onChange: (_) {}));
    await pumpCs(tester, CsInput(value: 'second', onChange: (_) {}));
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('search shows a clear button once it has text', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(type: CsInputType.search, initial: 'i-0abc', onChange: changes.add));
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pump();
    expect(changes, ['']);
    expect(find.bySemanticsLabel('Clear'), findsNothing);
  });

  testWidgets('disabled does not accept focus or text', (tester) async {
    await pumpCs(tester, CsInput(value: '', disabled: true, onChange: (_) => fail('called')));
    await tester.tap(find.byType(CsInput));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('focus and blur callbacks and key events', (tester) async {
    final events = <String>[];
    await pumpCs(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsInput(
            value: '',
            onChange: (_) {},
            onFocus: () => events.add('focus'),
            onBlur: () => events.add('blur'),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) events.add('escape');
              return KeyEventResult.ignored;
            },
          ),
          CsInput(value: '', onChange: (_) {}),
        ],
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(events, ['focus', 'escape', 'blur']);
  });

  testWidgets('semantics: text field with label and required hint', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, CsInput(value: '', ariaLabel: 'Bucket name', ariaRequired: true, onChange: (_) {}));
    final node = tester.getSemantics(find.byType(TextField));
    expect(node.flagsCollection.isTextField, isTrue);
    expect(find.bySemanticsLabel(RegExp('Bucket name')), findsWidgets);
    handle.dispose();
  });

  testWidgets('2x text at 390px with adornments does not overflow', (tester) async {
    await pumpCs(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: CsInput(
          value: 'logs',
          prefix: Text('https://'),
          suffix: Text('.example.com'),
          inlineLabelText: 'Domain',
        ),
      ),
      textScale: 2,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
  });
}
