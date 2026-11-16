import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _properties = [
  CsPropertyFilterProperty(key: 'type', propertyLabel: 'Instance type', groupValuesLabel: 'Instance type values'),
  CsPropertyFilterProperty(
    key: 'state',
    propertyLabel: 'State',
    groupValuesLabel: 'State values',
    operators: [CsPropertyFilterOperator.equals, CsPropertyFilterOperator.notEquals],
  ),
];

const _options = [
  CsPropertyFilterOption(propertyKey: 'type', value: 't3.micro'),
  CsPropertyFilterOption(propertyKey: 'type', value: 'm5.large'),
  CsPropertyFilterOption(propertyKey: 'state', value: 'Running'),
  CsPropertyFilterOption(propertyKey: 'state', value: 'Stopped'),
];

class _Host extends StatefulWidget {
  const _Host({super.key, this.initial = const CsPropertyFilterQuery(), this.tokenLimit, this.disableFreeText = false});
  final CsPropertyFilterQuery initial;
  final int? tokenLimit;
  final bool disableFreeText;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late CsPropertyFilterQuery query = widget.initial;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsPropertyFilter(
      query: query,
      filteringProperties: _properties,
      filteringOptions: _options,
      countText: '3 matches',
      tokenLimit: widget.tokenLimit,
      disableFreeTextFiltering: widget.disableFreeText,
      onChange: (q) => setState(() => query = q),
    ),
  );
}

CsPropertyFilterQuery _query(WidgetTester t) => t.state<_HostState>(find.byType(_Host)).query;

const _twoTokens = CsPropertyFilterQuery(
  tokens: [
    CsPropertyFilterToken(propertyKey: 'state', operator: CsPropertyFilterOperator.equals, value: 'Running'),
    CsPropertyFilterToken(operator: CsPropertyFilterOperator.contains, value: 'web'),
  ],
);

void main() {
  testWidgets('renders tokens in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _Host(key: UniqueKey(), initial: _twoTokens),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        expect(find.text('State = Running'), findsOneWidget);
        expect(find.text('web'), findsOneWidget);
        expect(find.text('and'), findsOneWidget);
        expect(find.text('3 matches'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('property, operator, value flow adds a token', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Values'), findsOneWidget);
    await tester.tap(find.text('State').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Operators'), findsOneWidget);
    await tester.tap(find.text('State !='));
    await tester.pumpAndSettle();
    expect(find.text('State values'), findsOneWidget);
    await tester.tap(find.text('State != Stopped'));
    await tester.pumpAndSettle();
    expect(
      _query(tester).tokens.single,
      const CsPropertyFilterToken(propertyKey: 'state', operator: CsPropertyFilterOperator.notEquals, value: 'Stopped'),
    );
    expect(find.text('State != Stopped'), findsOneWidget);
  });

  testWidgets('picking a value suggestion adds it with the default operator', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 't3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instance type = t3.micro'));
    await tester.pumpAndSettle();
    expect(_query(tester).tokens.single.value, 't3.micro');
  });

  testWidgets('Enter on a typed query and on free text', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'State = Pending');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      _query(tester).tokens.single,
      const CsPropertyFilterToken(propertyKey: 'state', operator: CsPropertyFilterOperator.equals, value: 'Pending'),
    );
    await tester.enterText(find.byType(EditableText), 'web');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use: "web"'));
    await tester.pumpAndSettle();
    expect(
      _query(tester).tokens.last,
      const CsPropertyFilterToken(operator: CsPropertyFilterOperator.contains, value: 'web'),
    );
  });

  testWidgets('free text is ignored when disabled', (tester) async {
    await pumpCs(tester, const _Host(disableFreeText: true), size: csDesktopSize);
    await tester.enterText(find.byType(EditableText), 'web');
    await tester.pumpAndSettle();
    expect(find.text('Use: "web"'), findsNothing);
  });

  testWidgets('remove, clear filters and operation', (tester) async {
    await pumpCs(tester, const _Host(initial: _twoTokens), size: csDesktopSize);
    await tester.tap(find.text('and'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('or').last);
    await tester.pumpAndSettle();
    expect(_query(tester).operation, CsPropertyFilterOperation.or);
    await tester.tap(find.bySemanticsLabel(RegExp('^Remove filter, State')));
    await tester.pumpAndSettle();
    expect(_query(tester).tokens.length, 1);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(_query(tester).tokens, isEmpty);
  });

  testWidgets('token editor edits a token on Apply only', (tester) async {
    await pumpCs(tester, const _Host(initial: _twoTokens), size: csDesktopSize);
    await tester.tap(find.text('State = Running'));
    await tester.pumpAndSettle();
    expect(find.text('Edit filter'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, 'Stopped');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_query(tester).tokens.first.value, 'Running');
    await tester.tap(find.text('State = Running'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Stopped');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(_query(tester).tokens.first.value, 'Stopped');
  });

  testWidgets('token limit', (tester) async {
    await pumpCs(tester, const _Host(initial: _twoTokens, tokenLimit: 1), size: csDesktopSize);
    expect(find.text('web'), findsNothing);
    await tester.tap(find.text('Show more (+1)'));
    await tester.pumpAndSettle();
    expect(find.text('web'), findsOneWidget);
  });

  testWidgets('390px and 2x text without overflow, editor as a sheet', (tester) async {
    await pumpCs(tester, const _Host(initial: _twoTokens), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('State = Running'));
    await tester.pumpAndSettle();
    expect(find.text('Edit filter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
