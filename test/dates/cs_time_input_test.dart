import 'package:cloudscape_flutter/src/dates/dates.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({required this.log, this.initial = '', this.format = CsTimeInputFormat.hhMmSs, this.use24Hour = true});

  final List<String> log;
  final String initial;
  final CsTimeInputFormat format;
  final bool use24Hour;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: CsTimeInput(
      value: value,
      format: widget.format,
      use24Hour: widget.use24Hour,
      onChange: (v) {
        widget.log.add(v);
        setState(() => value = v);
      },
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
              CsTimeInput(value: '13:45:00'),
              CsTimeInput(value: '', placeholder: 'hh:mm:ss', disabled: true),
              CsTimeInput(value: '13:45', format: CsTimeInputFormat.hhMm, readOnly: true),
              CsTimeInput(value: '13', format: CsTimeInputFormat.hh, invalid: true),
              CsTimeInput(value: '13:45:00', warning: true),
            ],
          ),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('a high first digit is padded and colons are added', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log));
    await tester.enterText(find.byType(EditableText), '7');
    await tester.pump();
    expect(_shown(tester), '07:');
    expect(log.last, '07:');
  });

  testWidgets('hours above 23 are capped in 24-hour mode, above 12 otherwise', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log));
    final field = find.byType(EditableText);
    await tester.enterText(field, '2');
    await tester.enterText(field, '25');
    await tester.pump();
    expect(log.last, '23:');

    final log12 = <String>[];
    await pumpCs(tester, _Host(log: log12, use24Hour: false));
    await tester.enterText(field, '1');
    await tester.enterText(field, '13');
    await tester.pump();
    expect(log12.last, '12:');
  });

  testWidgets('format limits the parts', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log, format: CsTimeInputFormat.hhMm));
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    expect(log.last, '12:34');
  });

  testWidgets('blur completes a partial time', (tester) async {
    final log = <String>[];
    await pumpCs(tester, _Host(log: log, initial: '10:1'));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(log.last, '10:01:00');
  });

  testWidgets('exposes a labeled text field and fits 390px with 2x text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const CsTimeInput(value: '09:30:00', ariaLabel: 'Start time'), textScale: 2);
    expect(find.bySemanticsLabel('Start time'), findsWidgets);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
