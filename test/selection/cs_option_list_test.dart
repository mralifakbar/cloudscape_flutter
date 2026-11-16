import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _micro = CsOption(value: 't3.micro', label: 't3.micro', description: '2 vCPU, 1 GiB', tags: ['Free tier']);
const _small = CsOption(value: 't3.small', label: 't3.small', labelTag: 'Popular', icon: CsIcons.settings);
const _large = CsOption(value: 't3.large', label: 't3.large', disabled: true, disabledReason: 'Quota reached');
const _m5 = CsOption(value: 'm5.large', label: 'm5.large');
const _m6 = CsOption(value: 'm6i.large', label: 'm6i.large');

const _options = <CsOptionItem>[
  _micro,
  _small,
  _large,
  CsOptionGroup(label: 'General purpose', options: [_m5, _m6]),
];

class _Host extends StatefulWidget {
  const _Host({this.type = CsOptionListSelectionType.single, this.initial = const [], this.onChange});

  final CsOptionListSelectionType type;
  final List<CsOption> initial;
  final ValueChanged<List<CsOption>>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<CsOption> selected = widget.initial;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsOptionList(
      ariaLabel: 'Instance type',
      selectionType: widget.type,
      options: _options,
      selectedOptions: selected,
      onChange: (v) {
        setState(() => selected = v);
        widget.onChange?.call(v);
      },
    ),
  );
}

void main() {
  testWidgets('renders options, descriptions, tags and groups in every theme', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, const _Host(), brightness: b, density: d);
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.text('t3.micro'), findsOneWidget);
    expect(find.text('2 vCPU, 1 GiB'), findsOneWidget);
    expect(find.text('Free tier'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('General purpose'), findsOneWidget);
    expect(find.bySemanticsLabel('Instance type'), findsOneWidget);
  });

  testWidgets('single selection picks one option on tap', (tester) async {
    List<CsOption>? last;
    await pumpCs(tester, _Host(onChange: (v) => last = v));
    await tester.tap(find.text('t3.small'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.small']);
    await tester.tap(find.text('m5.large'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['m5.large']);
    // The selected row shows a check.
    expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.check), findsOneWidget);
  });

  testWidgets('disabled options do not select', (tester) async {
    List<CsOption>? last;
    await pumpCs(tester, _Host(onChange: (v) => last = v));
    await tester.tap(find.text('t3.large'));
    await tester.pumpAndSettle();
    expect(last, isNull);
  });

  testWidgets('multi selection toggles options and whole groups', (tester) async {
    List<CsOption>? last;
    await pumpCs(tester, _Host(type: CsOptionListSelectionType.multi, onChange: (v) => last = v));
    expect(find.byType(CsCheckboxIcon), findsNWidgets(6));
    await tester.tap(find.text('t3.micro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('t3.small'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.micro', 't3.small']);
    await tester.tap(find.text('t3.micro'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.small']);
    await tester.tap(find.text('General purpose'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.small', 'm5.large', 'm6i.large']);
    await tester.tap(find.text('General purpose'));
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.small']);
  });

  testWidgets('reflects the selection it is given', (tester) async {
    await pumpCs(tester, const _Host(type: CsOptionListSelectionType.multi, initial: [_m5]));
    final checks = tester.widgetList<CsCheckboxIcon>(find.byType(CsCheckboxIcon)).toList();
    // micro, small, large, group header (partial), m5 (checked), m6.
    expect(checks[3].indeterminate, isTrue);
    expect(checks[4].checked, isTrue);
    expect(checks[5].checked, isFalse);
  });

  testWidgets('without selectedOptions the list keeps its own selection', (tester) async {
    final changes = <List<CsOption>>[];
    await pumpCs(
      tester,
      CsOptionList(options: _options, selectionType: CsOptionListSelectionType.single, onChange: changes.add),
    );
    await tester.tap(find.text('t3.micro'));
    await tester.pumpAndSettle();
    expect(changes.single.single.value, 't3.micro');
    expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.check), findsOneWidget);
  });

  testWidgets('keyboard: Tab focuses, arrows skip disabled, Enter and Space choose', (tester) async {
    List<CsOption>? last;
    await pumpCs(tester, _Host(type: CsOptionListSelectionType.multi, onChange: (v) => last = v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    // Focus highlights the first option; Enter picks it.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.micro']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // t3.large is disabled, so the second step lands on the group header.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.micro', 'm5.large', 'm6i.large']);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['t3.micro', 'm5.large']);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(last!.map((o) => o.value), ['m5.large']);
  });

  testWidgets('focus starts on the selected option and typing jumps', (tester) async {
    List<CsOption>? last;
    await pumpCs(tester, _Host(initial: const [_m5], onChange: (v) => last = v));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(last!.single.value, 'm6i.large');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(last!.single.value, 't3.micro');
  });

  testWidgets('renderOption draws custom content and keeps selection', (tester) async {
    List<CsOption>? last;
    await pumpCs(
      tester,
      CsOptionList(
        options: _options,
        selectionType: CsOptionListSelectionType.single,
        selectedOptions: const [],
        onChange: (v) => last = v,
        renderOption: (context, item) => item.isGroup ? null : Text('Type ${item.option.value}'),
      ),
    );
    expect(find.text('Type t3.micro'), findsOneWidget);
    expect(find.text('General purpose'), findsOneWidget);
    await tester.tap(find.text('Type m5.large'));
    await tester.pumpAndSettle();
    expect(last!.single.value, 'm5.large');
  });

  testWidgets('shows the empty state without options', (tester) async {
    await pumpCs(
      tester,
      const CsOptionList(
        options: [],
        selectionType: CsOptionListSelectionType.single,
        empty: Text('No instance types'),
      ),
    );
    expect(find.text('No instance types'), findsOneWidget);
  });

  testWidgets('rows expose selected and checked semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Host(initial: [_small]));
    final node = tester.getSemantics(find.text('t3.small'));
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.getSemantics(find.text('t3.micro')).flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('scrolls within maxHeight and survives 2x text at 390px', (tester) async {
    await pumpCs(
      tester,
      const CsOptionList(options: _options, selectionType: CsOptionListSelectionType.multi, maxHeight: 160),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
