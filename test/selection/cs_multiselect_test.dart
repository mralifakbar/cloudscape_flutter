import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _options = <CsOptionItem>[
  CsOption(value: 'us-east-1a', description: 'N. Virginia'),
  CsOption(value: 'us-east-1b'),
  CsOption(value: 'us-east-1c', disabled: true),
  CsOptionGroup(
    label: 'Europe',
    options: [
      CsOption(value: 'eu-west-1a'),
      CsOption(value: 'eu-west-1b'),
    ],
  ),
];

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.initial = const [],
    this.enableSelectAll = false,
    this.tokenLimit,
    this.keepOpen = true,
    this.inlineTokens = false,
    this.hideTokens = false,
    this.presentation = CsPresentation.popover,
    this.filteringType = CsFilteringType.none,
  });
  final List<CsOption> initial;
  final bool enableSelectAll;
  final int? tokenLimit;
  final bool keepOpen;
  final bool inlineTokens;
  final bool hideTokens;
  final CsPresentation presentation;
  final CsFilteringType filteringType;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<CsOption> value = widget.initial;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 340,
    child: CsMultiselect(
      options: _options,
      selectedOptions: value,
      placeholder: 'Choose zones',
      enableSelectAll: widget.enableSelectAll,
      tokenLimit: widget.tokenLimit,
      keepOpen: widget.keepOpen,
      inlineTokens: widget.inlineTokens,
      hideTokens: widget.hideTokens,
      presentation: widget.presentation,
      filteringType: widget.filteringType,
      onChange: (v) => setState(() => value = v),
    ),
  );
}

List<String> _values(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host)).value.map((o) => o.value).toList();

void main() {
  testWidgets('renders in light, dark and compact with tokens', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _Host(
            key: UniqueKey(),
            initial: const [CsOption(value: 'us-east-1a', description: 'N. Virginia')],
          ),
          brightness: b,
          density: d,
          size: csDesktopSize,
        );
        await tester.tap(find.text('Choose zones'));
        await tester.pumpAndSettle();
        expect(find.byType(CsToken), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('toggles options and keeps the list open', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('us-east-1b'));
    await tester.pumpAndSettle();
    expect(_values(tester), ['us-east-1b']);
    expect(find.text('Europe'), findsOneWidget);
    await tester.tap(find.text('us-east-1b').hitTestable().first);
    await tester.pumpAndSettle();
    expect(_values(tester), isEmpty);
  });

  testWidgets('a group label selects and clears its group', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();
    expect(_values(tester), ['eu-west-1a', 'eu-west-1b']);
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();
    expect(_values(tester), isEmpty);
  });

  testWidgets('select all skips disabled options', (tester) async {
    await pumpCs(tester, const _Host(enableSelectAll: true), size: csDesktopSize);
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(_values(tester), ['us-east-1a', 'us-east-1b', 'eu-west-1a', 'eu-west-1b']);
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(_values(tester), isEmpty);
  });

  testWidgets('dismissing a token removes the option', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        initial: [
          CsOption(value: 'us-east-1a'),
          CsOption(value: 'us-east-1b'),
        ],
      ),
    );
    await tester.tap(find.bySemanticsLabel('Remove us-east-1a'));
    await tester.pumpAndSettle();
    expect(_values(tester), ['us-east-1b']);
  });

  testWidgets('token limit shows more and fewer', (tester) async {
    await pumpCs(
      tester,
      const _Host(
        tokenLimit: 1,
        initial: [
          CsOption(value: 'us-east-1a'),
          CsOption(value: 'us-east-1b'),
          CsOption(value: 'eu-west-1a'),
        ],
      ),
    );
    expect(find.byType(CsToken), findsOneWidget);
    expect(find.text('Show more (+2)'), findsOneWidget);
    await tester.tap(find.text('Show more (+2)'));
    await tester.pumpAndSettle();
    expect(find.byType(CsToken), findsNWidgets(3));
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('hideTokens and inlineTokens', (tester) async {
    await pumpCs(
      tester,
      _Host(
        key: UniqueKey(),
        hideTokens: true,
        initial: const [CsOption(value: 'us-east-1a')],
      ),
    );
    expect(find.byType(CsToken), findsNothing);
    await pumpCs(
      tester,
      _Host(
        key: UniqueKey(),
        inlineTokens: true,
        initial: const [CsOption(value: 'us-east-1a')],
      ),
    );
    expect(find.byType(CsToken), findsOneWidget);
    expect(find.text('Choose zones'), findsNothing);
  });

  testWidgets('keyboard: Space toggles, Escape closes', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_values(tester), ['us-east-1a']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Europe'), findsNothing);
  });

  testWidgets('sheet on phones keeps toggling', (tester) async {
    await pumpCs(tester, const _Host(presentation: CsPresentation.auto));
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsOneWidget);
    await tester.tap(find.text('us-east-1a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('us-east-1b').hitTestable().first);
    await tester.pumpAndSettle();
    expect(_values(tester), ['us-east-1a', 'us-east-1b']);
    expect(find.byType(CsSheet), findsOneWidget);
  });

  testWidgets('checkbox rows expose checked state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      const _Host(initial: [CsOption(value: 'us-east-1a')]),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.text('N. Virginia'));
    expect(node.flagsCollection.isChecked.name, 'isTrue');
    handle.dispose();
  });

  testWidgets('keepOpen false closes after a pick; filtering narrows', (tester) async {
    await pumpCs(tester, const _Host(keepOpen: false, filteringType: CsFilteringType.auto), size: csDesktopSize);
    await tester.tap(find.text('Choose zones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'eu');
    await tester.pumpAndSettle();
    expect(find.text('us-east-1a'), findsNothing);
    await tester.tap(find.text('eu-west-1b'));
    await tester.pumpAndSettle();
    expect(_values(tester), ['eu-west-1b']);
    expect(find.text('eu-west-1a'), findsNothing);
  });

  testWidgets('390px and 2x text without overflow', (tester) async {
    await pumpCs(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: _Host(
          initial: [
            CsOption(value: 'us-east-1a', description: 'N. Virginia'),
            CsOption(value: 'eu-west-1a'),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
