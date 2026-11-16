import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/overlays/overlays.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _options = <CsOptionItem>[
  CsOption(value: 't3.micro', description: '2 vCPU, 1 GiB', labelTag: 'Free tier'),
  CsOption(value: 't3.small', description: '2 vCPU, 2 GiB', tags: ['Burstable']),
  CsOption(value: 't3.xlarge', disabled: true, disabledReason: 'Quota reached'),
  CsOptionGroup(
    label: 'Compute optimized',
    options: [
      CsOption(value: 'c6i.large'),
      CsOption(value: 'c6i.xlarge'),
    ],
  ),
];

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.filteringType = CsFilteringType.none,
    this.presentation = CsPresentation.popover,
    this.onLoad,
  });
  final CsFilteringType filteringType;
  final CsPresentation presentation;
  final ValueChanged<CsLoadItemsDetail>? onLoad;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  CsOption? value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: CsSelect(
      options: _options,
      selectedOption: value,
      placeholder: 'Choose an instance type',
      filteringType: widget.filteringType,
      filteringPlaceholder: 'Find instance type',
      noMatch: const Text('No matches'),
      presentation: widget.presentation,
      onLoadItems: widget.onLoad,
      onChange: (o) => setState(() => value = o),
    ),
  );
}

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
        await tester.tap(find.text('Choose an instance type'));
        await tester.pumpAndSettle();
        expect(find.text('t3.small'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('picks an option and closes', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Choose an instance type'));
    await tester.pumpAndSettle();
    expect(find.text('Free tier'), findsOneWidget);
    expect(find.text('Compute optimized'), findsOneWidget);
    await tester.tap(find.text('t3.small'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an instance type'), findsNothing);
    expect(find.text('t3.small'), findsOneWidget);
    expect(find.text('2 vCPU, 1 GiB'), findsNothing);
  });

  testWidgets('disabled options do not pick', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.tap(find.text('Choose an instance type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('t3.xlarge'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Choose an instance type'), findsOneWidget);
  });

  testWidgets('disabled select does not open', (tester) async {
    var changes = 0;
    await pumpCs(
      tester,
      CsSelect(
        options: _options,
        selectedOption: null,
        placeholder: 'Pick',
        disabled: true,
        onChange: (_) => changes++,
      ),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Pick'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('t3.small'), findsNothing);
    expect(changes, 0);
  });

  testWidgets('keyboard: arrows open and move, Enter picks, Escape closes', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('t3.small'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('t3.small'), findsOneWidget);
    expect(find.text('t3.micro'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('t3.micro'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('t3.micro'), findsNothing);
  });

  testWidgets('auto filtering narrows the list and shows no match', (tester) async {
    final loads = <CsLoadItemsDetail>[];
    await pumpCs(
      tester,
      _Host(filteringType: CsFilteringType.auto, onLoad: loads.add),
      size: csDesktopSize,
    );
    await tester.tap(find.text('Choose an instance type'));
    await tester.pumpAndSettle();
    expect(loads.single.firstPage, isTrue);
    await tester.enterText(find.byType(EditableText), 'c6i');
    await tester.pumpAndSettle();
    expect(find.text('t3.small'), findsNothing);
    expect(find.text('Compute optimized'), findsOneWidget);
    expect(loads.last.filteringText, 'c6i');
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('status types show loading, error and finished text', (tester) async {
    var retried = false;
    Widget select(CsDropdownStatusType t) => SizedBox(
      key: UniqueKey(),
      width: 300,
      child: CsSelect(
        options: const [CsOption(value: 'a')],
        selectedOption: null,
        placeholder: 'Pick',
        statusType: t,
        loadingText: 'Loading instances',
        errorText: 'Could not load',
        recoveryText: 'Retry',
        finishedText: 'End of results',
        onLoadItems: (d) => retried = retried || d.samePage,
        onChange: (_) {},
      ),
    );
    await pumpCs(tester, select(CsDropdownStatusType.loading), size: csDesktopSize, settle: false);
    await tester.tap(find.text('Pick'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Loading instances'), findsOneWidget);
    await pumpCs(tester, select(CsDropdownStatusType.error), size: csDesktopSize);
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
    await pumpCs(tester, select(CsDropdownStatusType.finished), size: csDesktopSize);
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('End of results'), findsOneWidget);
  });

  testWidgets('opens as a sheet on phones and closes after a pick', (tester) async {
    await pumpCs(tester, const _Host(presentation: CsPresentation.auto));
    await tester.tap(find.text('Choose an instance type'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsOneWidget);
    await tester.tap(find.text('t3.small'));
    await tester.pumpAndSettle();
    expect(find.byType(CsSheet), findsNothing);
    expect(find.text('t3.small'), findsOneWidget);
  });

  testWidgets('semantics expose label, value and expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(
      tester,
      CsSelect(
        options: _options,
        selectedOption: const CsOption(value: 't3.micro'),
        ariaLabel: 'Instance type',
        onChange: (_) {},
      ),
      size: csDesktopSize,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Instance type')),
      matchesSemantics(
        label: 'Instance type',
        value: 't3.micro',
        isButton: true,
        hasExpandedState: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('no overflow at 390px with 2x text, inline label and option trigger', (tester) async {
    await pumpCs(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: CsSelect(
          options: _options,
          selectedOption: const CsOption(
            value: 't3.micro',
            description: '2 vCPU, 1 GiB with a long description',
            tags: ['Burstable'],
          ),
          triggerVariant: CsSelectTriggerVariant.option,
          inlineLabelText: 'Instance type',
          invalid: true,
          onChange: (_) {},
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
