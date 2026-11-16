import 'package:cloudscape_flutter/src/forms/forms.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/selection/selection.dart';
import 'package:cloudscape_flutter/src/system/system.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _units = [CsOption(value: 'gib', label: 'GiB'), CsOption(value: 'tib', label: 'TiB')];

Widget _group({
  CsControlGroupDirection direction = CsControlGroupDirection.horizontal,
  VoidCallback? onAction,
  bool actionDisabled = false,
  bool invalid = false,
  bool warning = false,
  String? inlineLabel,
  int controls = 2,
}) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: CsControlGroup(
      direction: direction,
      invalid: invalid,
      warning: warning,
      inlineLabelText: inlineLabel,
      actionButton: onAction == null && !actionDisabled
          ? null
          : CsControlGroupActionButton(
              icon: CsIcons.remove,
              ariaLabel: 'Remove volume',
              onPress: onAction,
              disabled: actionDisabled,
              disabledReason: actionDisabled ? 'The root volume cannot be removed.' : null,
            ),
      children: [
        const CsInput(value: '100'),
        if (controls > 2) const CsInput(value: 'gp3'),
        if (controls > 1)
          const Flexible(
            flex: 0,
            child: SizedBox(
              width: 96,
              child: CsSelect(
                options: _units,
                selectedOption: CsOption(value: 'gib', label: 'GiB'),
              ),
            ),
          ),
      ],
    ),
  );
}

List<CsGroupedControl> _placements(WidgetTester tester) =>
    tester.widgetList<CsGroupedControl>(find.byType(CsGroupedControl)).toList();

void main() {
  testWidgets('renders in light, dark, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _group(onAction: () {}, invalid: true),
          brightness: b,
          density: d,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(CsInput), findsOneWidget);
      }
    }
  });

  testWidgets('assigns first, middle and last positions along the axis', (tester) async {
    await pumpCs(tester, _group(controls: 3), size: csDesktopSize);
    final p = _placements(tester);
    expect(p.map((e) => e.position), [
      CsGroupedControlPosition.first,
      CsGroupedControlPosition.middle,
      CsGroupedControlPosition.last,
    ]);
    expect(p.every((e) => e.direction == Axis.horizontal), isTrue);
  });

  testWidgets('a single control is the only one and keeps all corners', (tester) async {
    await pumpCs(tester, _group(controls: 1));
    final p = _placements(tester).single;
    expect(p.position, CsGroupedControlPosition.only);
    final r = p.radius(8).resolve(TextDirection.ltr);
    expect(r, BorderRadius.circular(8));
  });

  testWidgets('only outer corners are rounded', (tester) async {
    const first = CsGroupedControl(
      position: CsGroupedControlPosition.first,
      direction: Axis.horizontal,
      child: SizedBox(),
    );
    const last = CsGroupedControl(
      position: CsGroupedControlPosition.last,
      direction: Axis.horizontal,
      hasAction: true,
      child: SizedBox(),
    );
    const top = CsGroupedControl(position: CsGroupedControlPosition.first, direction: Axis.vertical, child: SizedBox());
    final f = first.radius(8).resolve(TextDirection.ltr);
    expect(f.topLeft, const Radius.circular(8));
    expect(f.topRight, Radius.zero);
    final l = last.radius(8).resolve(TextDirection.ltr);
    expect(l.topLeft, Radius.zero);
    // The action owns the end corners.
    expect(l.topRight, Radius.zero);
    final t = top.radius(8).resolve(TextDirection.ltr);
    expect(t.topRight, const Radius.circular(8));
    expect(t.bottomLeft, Radius.zero);
    expect(first.leading, isTrue);
    expect(last.joinsPrevious, isTrue);
  });

  testWidgets('field chrome takes the control group border color', (tester) async {
    await pumpCs(tester, _group());
    final box = tester.widget<Container>(
      find.descendant(of: find.byType(CsFieldBox).first, matching: find.byType(Container)).first,
    );
    final border = (box.foregroundDecoration! as BoxDecoration).border! as Border;
    final c = CsThemeData.light().colors;
    expect(border.top.color, c.borderControlGroupDefault);
    // The second control drops its start edge; the first one's end edge is the seam.
    final second = tester.widget<Container>(
      find.descendant(of: find.byType(CsFieldBox).at(1), matching: find.byType(Container)).first,
    );
    final secondBorder = (second.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(secondBorder.left, BorderSide.none);
  });

  testWidgets('invalid group colors the borders and thickens the leading edge only', (tester) async {
    await pumpCs(tester, _group(invalid: true));
    final c = CsThemeData.light().colors;
    Border borderAt(int i) =>
        (tester
                        .widget<Container>(
                          find.descendant(of: find.byType(CsFieldBox).at(i), matching: find.byType(Container)).first,
                        )
                        .foregroundDecoration!
                    as BoxDecoration)
                .border!
            as Border;
    expect(borderAt(0).left.width, CsBorderWidth.fieldStatusInlineStart);
    expect(borderAt(0).top.color, c.textStatusError);
    expect(borderAt(1).right.color, c.textStatusError);
    expect(borderAt(1).left, BorderSide.none);
  });

  testWidgets('warning group uses the warning color', (tester) async {
    await pumpCs(tester, _group(warning: true));
    final box = tester.widget<Container>(
      find.descendant(of: find.byType(CsFieldBox).first, matching: find.byType(Container)).first,
    );
    final border = (box.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(border.top.color, CsThemeData.light().colors.textStatusWarning);
  });

  testWidgets('action button fires and matches the control height', (tester) async {
    var presses = 0;
    await pumpCs(tester, _group(onAction: () => presses++));
    final action = find.bySemanticsLabel('Remove volume');
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(presses, 1);
    final inputHeight = tester.getSize(find.byType(CsInput)).height;
    final actionBox = find.ancestor(of: find.byType(CsIcon).last, matching: find.byType(Container)).first;
    expect(tester.getSize(actionBox).height, inputHeight);
  });

  testWidgets('disabled action does not fire and explains why', (tester) async {
    await pumpCs(tester, _group(actionDisabled: true));
    final semantics = tester.getSemantics(find.bySemanticsLabel('Remove volume'));
    expect(semantics.hint, 'The root volume cannot be removed.');
    await tester.tap(find.bySemanticsLabel('Remove volume'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('action is reachable with Tab and activates with Enter', (tester) async {
    var presses = 0;
    await pumpCs(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: CsControlGroup(
          direction: CsControlGroupDirection.horizontal,
          actionButton: CsControlGroupActionButton(icon: CsIcons.close, ariaLabel: 'Clear', onPress: () => presses++),
          children: const [CsInput(value: 'example-bucket')],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('auto direction stacks at narrow widths and joins at wide ones', (tester) async {
    await pumpCs(
      tester,
      const SizedBox(
        width: 200,
        child: CsControlGroup(
          children: [
            CsInput(value: 'a'),
            CsInput(value: 'b'),
          ],
        ),
      ),
    );
    expect(_placements(tester).first.direction, Axis.vertical);
    await pumpCs(
      tester,
      const SizedBox(
        width: 360,
        child: CsControlGroup(
          children: [
            CsInput(value: 'a'),
            CsInput(value: 'b'),
          ],
        ),
      ),
    );
    expect(_placements(tester).first.direction, Axis.horizontal);
  });

  testWidgets('vertical layout stretches the action to the column height', (tester) async {
    await pumpCs(tester, _group(direction: CsControlGroupDirection.vertical, onAction: () {}, controls: 3));
    final inputs = tester.getSize(find.byType(CsInput).first).height;
    final actionBox = find.ancestor(of: find.byType(CsIcon).last, matching: find.byType(Container)).first;
    expect(tester.getSize(actionBox).height, greaterThan(inputs * 2));
    expect(_placements(tester).first.direction, Axis.vertical);
  });

  testWidgets('inline label shows and labels the group', (tester) async {
    await pumpCs(tester, _group(inlineLabel: 'Volume size'));
    expect(find.text('Volume size'), findsOneWidget);
  });

  testWidgets('survives 2x text at 390px and RTL', (tester) async {
    await pumpCs(tester, _group(onAction: () {}, controls: 3), textScale: 2);
    expect(tester.takeException(), isNull);
    await pumpCs(tester, _group(onAction: () {}), textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
