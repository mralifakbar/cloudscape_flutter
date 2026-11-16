import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _options = <CsOptionItem>[
  CsOption(value: 'example-bucket', description: 'us-east-1'),
  CsOption(value: 'logs-bucket', description: 'eu-west-1'),
  CsOption(value: 'archive-bucket', disabled: true),
];

class _Host extends StatefulWidget {
  const _Host({super.key, this.onSelect, this.onLoad, this.statusType = CsDropdownStatusType.finished});
  final ValueChanged<CsAutosuggestSelectDetail>? onSelect;
  final ValueChanged<CsLoadItemsDetail>? onLoad;
  final CsDropdownStatusType statusType;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = '';
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: CsAutosuggest(
      value: value,
      options: _options,
      placeholder: 'Enter a bucket name',
      enteredTextLabel: (v) => 'Use: "$v"',
      statusType: widget.statusType,
      loadingText: 'Loading buckets',
      onLoadItems: widget.onLoad,
      onSelect: widget.onSelect,
      onChange: (v) => setState(() => value = v),
    ),
  );
}

String _value(WidgetTester t) => t.state<_HostState>(find.byType(_Host)).value;

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _Host(key: UniqueKey()),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        await tester.enterText(find.byType(EditableText), 'log');
        await tester.pumpAndSettle();
        expect(find.text('Use: "log"'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('typing filters, clicking picks', (tester) async {
    CsAutosuggestSelectDetail? picked;
    await pumpCs(tester, _Host(onSelect: (d) => picked = d), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'logs');
    await tester.pumpAndSettle();
    expect(find.text('example-bucket'), findsNothing);
    await tester.tap(find.text('eu-west-1'));
    await tester.pumpAndSettle();
    expect(_value(tester), 'logs-bucket');
    expect(picked!.selectedOption!.value, 'logs-bucket');
    expect(find.text('eu-west-1'), findsNothing);
  });

  testWidgets('keyboard: arrows highlight, Enter picks, Escape closes then clears', (tester) async {
    CsAutosuggestSelectDetail? picked;
    await pumpCs(tester, _Host(onSelect: (d) => picked = d), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'bucket');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked!.selectedOption, isNull);
    expect(_value(tester), 'bucket');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('us-east-1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('us-east-1'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_value(tester), '');
  });

  testWidgets('disabled options are skipped', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'archive');
    await tester.pumpAndSettle();
    await tester.tap(find.text('archive-bucket'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_value(tester), 'archive');
  });

  testWidgets('clear button empties the value', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'x');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pumpAndSettle();
    expect(_value(tester), '');
  });

  testWidgets('loads items and shows the loading status', (tester) async {
    final loads = <CsLoadItemsDetail>[];
    await pumpCs(
      tester,
      _Host(onLoad: loads.add, statusType: CsDropdownStatusType.loading),
      size: csDesktopSize,
      settle: false,
    );
    await tester.enterText(find.byType(EditableText), 'l');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(loads.first.firstPage, isTrue);
    expect(find.text('Loading buckets'), findsOneWidget);
  });

  testWidgets('disabled input does not open', (tester) async {
    await pumpCs(
      tester,
      CsAutosuggest(value: '', options: _options, disabled: true, placeholder: 'Bucket', onChange: (_) {}),
      size: csDesktopSize,
    );
    await tester.tap(find.byType(EditableText), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('example-bucket'), findsNothing);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(tester, const Padding(padding: EdgeInsets.all(16), child: _Host()), textScale: 2);
    await tester.enterText(find.byType(EditableText), 'bucket');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
