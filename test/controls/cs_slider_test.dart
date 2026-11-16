import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.onChange, this.onChangeEnd});

  final ValueChanged<double>? onChange;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double value = 50;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: CsSlider(
      min: 0,
      max: 100,
      step: 10,
      tickMarks: true,
      value: value,
      referenceValues: const [25, 50, 75],
      valueFormatter: (v) => '${v.round()}%',
      ariaLabel: 'Capacity',
      onChangeEnd: widget.onChangeEnd,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Host(),
              CsSlider(min: 0, max: 10, value: 3, invalid: true, onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 3, warning: true, onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 3, readOnly: true, onChange: (_) {}),
              CsSlider(min: 0, max: 10, value: 3, disabled: true, hideFillLine: true, onChange: (_) {}),
            ],
          ),
          brightness: brightness,
          density: density,
          size: csDesktopSize,
        );
        expect(find.text('0%'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('snap rounds to the step grid', () {
    expect(CsSlider.snap(47, min: 0, max: 100, step: 10), 50);
    expect(CsSlider.snap(0.34, min: 0, max: 1, step: 0.1), 0.3);
    expect(CsSlider.snap(130, min: 0, max: 100), 100);
    expect(CsSlider.visibleReferenceValues([5, 25, 26, 50, 99.5], 0, 100, narrow: false), [25, 50]);
    expect(CsSlider.visibleReferenceValues([10, 25, 50, 75], 0, 100, narrow: true), [25, 50, 75]);
  });

  testWidgets('dragging follows the finger and reports the end', (tester) async {
    final changes = <double>[];
    final ends = <double>[];
    await pumpCs(tester, _Host(onChange: changes.add, onChangeEnd: ends.add), center: false);
    final rect = tester.getRect(find.byType(CsSlider));
    final gesture = await tester.startGesture(Offset(rect.center.dx, rect.top + 22));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(Offset(rect.width / 2, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes.last, 100);
    expect(ends.single, 100);
  });

  testWidgets('tapping the track jumps there', (tester) async {
    final changes = <double>[];
    await pumpCs(tester, _Host(onChange: changes.add), center: false);
    final rect = tester.getRect(find.byType(CsSlider));
    await tester.tapAt(Offset(rect.left + 8, rect.top + 22));
    await tester.pumpAndSettle();
    expect(changes, [0]);
  });

  testWidgets('keyboard steps and semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <double>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(changes, [60, 50, 100, 0]);
    final node = tester.getSemantics(find.byWidgetPredicate((w) => w is Semantics && (w.properties.slider ?? false)));
    expect(node.label, 'Capacity');
    expect(node.flagsCollection.isSlider, isTrue);
    expect(node.value, '0%');
    expect(node.increasedValue, '10%');
    handle.dispose();
  });

  testWidgets('disabled and read-only ignore input', (tester) async {
    var calls = 0;
    await pumpCs(tester, CsSlider(min: 0, max: 10, value: 5, disabled: true, onChange: (_) => calls++));
    await tester.tap(find.byType(CsSlider));
    await pumpCs(tester, CsSlider(min: 0, max: 10, value: 5, readOnly: true, onChange: (_) => calls++));
    await tester.tap(find.byType(CsSlider));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('reduced motion, 2x text and 390px', (tester) async {
    await pumpCs(tester, const _Host(), disableAnimations: true, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
