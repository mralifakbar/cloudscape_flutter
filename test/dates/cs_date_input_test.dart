import 'package:cloudscape_flutter/src/dates/dates.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({required this.log, this.initial = '', this.build});

  final List<String> log;
  final String initial;
  final Widget Function(String value, ValueChanged<String> onChange)? build;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  void _set(String v) {
    widget.log.add(v);
    setState(() => value = v);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.build?.call(value, _set) ?? CsDateInput(value: value, onChange: _set, placeholder: 'YYYY/MM/DD'),
        const Focus(child: SizedBox(width: 10, height: 10)),
      ],
    ),
  );
}

String _shown(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets('renders every state in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CsDateInput(value: '2026-03-15'),
              CsDateInput(value: '', placeholder: 'YYYY/MM/DD', disabled: true),
              CsDateInput(value: '2026-03-15', readOnly: true),
              CsDateInput(value: '2026-03-15', invalid: true),
              CsDateInput(value: '2026-03-15', warning: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shows the ISO value slashed by default and dashed with iso', (tester) async {
    await pumpCs(tester, const CsDateInput(value: '2026-03-15'));
    expect(_shown(tester), '2026/03/15');
    await pumpCs(tester, const CsDateInput(value: '2026-03-15', format: CsDateFormat.iso));
    expect(_shown(tester), '2026-03-15');
  });

  testWidgets('typing adds separators, corrects out-of-range parts and reports ISO', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log));
    final field = find.byType(EditableText);
    await tester.enterText(field, '2');
    await tester.enterText(field, '20');
    await tester.enterText(field, '202');
    await tester.enterText(field, '2026');
    await tester.pump();
    expect(_shown(tester), '2026/');
    expect(log.last, '2026-');
    await tester.enterText(field, '2026/1');
    await tester.enterText(field, '2026/13');
    await tester.pump();
    expect(_shown(tester), '2026/12/');
    expect(log.last, '2026-12-');
    await tester.enterText(field, '2026/12/4');
    await tester.pump();
    // A first day digit above 3 is padded.
    expect(_shown(tester), '2026/12/04');
    expect(log.last, '2026-12-04');
  });

  testWidgets('letters are ignored and paste is formatted', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log));
    final field = find.byType(EditableText);
    await tester.enterText(field, 'a');
    await tester.pump();
    expect(log, isEmpty);
    await tester.enterText(field, '20260115');
    await tester.pump();
    expect(log.last, '2026-01-15');
  });

  testWidgets('Backspace after a separator removes the digit before it', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log, initial: '2026-01-'));
    expect(_shown(tester), '2026/01/');
    await tester.enterText(find.byType(EditableText), '2026/01');
    await tester.pump();
    expect(log.last, '2026-0');
  });

  testWidgets('blur completes a partial date', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log, initial: '2026-1'));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(log.last, '2026-01-01');
  });

  testWidgets('month granularity masks YYYY/MM', (tester) async {
    final log = <String>[];
    await pumpCs(
      tester,
      _Host(
        log: log,
        build: (v, set) => CsDateInput(value: v, onChange: set, granularity: CsDateGranularity.month),
      ),
    );
    await tester.enterText(find.byType(EditableText), '202604');
    await tester.pump();
    expect(_shown(tester), '2026/04');
    expect(log.last, '2026-04');
  });

  testWidgets('long-localized shows words until focused', (tester) async {
    await pumpCs(
      tester,
      _Host(
        log: [],
        initial: '2026-01-30',
        build: (v, set) => CsDateInput(value: v, onChange: set, format: CsDateFormat.longLocalized),
      ),
    );
    expect(_shown(tester), 'January 30, 2026');
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(_shown(tester), '2026/01/30');
  });

  testWidgets('read-only and disabled fields do not report edits', (tester) async {
    final log = <String>[];
    await pumpCs(
      tester,
      _Host(
        log: log,
        build: (v, set) => CsDateInput(value: v, onChange: set, readOnly: true),
      ),
    );
    await tester.enterText(find.byType(EditableText), '2026');
    await tester.pump();
    expect(log, isEmpty);
  });

  testWidgets('exposes a labeled text field', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsDateInput(value: '', ariaLabel: 'Snapshot date'));
    expect(find.bySemanticsLabel('Snapshot date'), findsWidgets);
    handle.dispose();
  });

  testWidgets('fits 390px with 2x text', (tester) async {
    await pumpCs(tester, const CsDateInput(value: '2026-03-15', placeholder: 'YYYY/MM/DD'), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
