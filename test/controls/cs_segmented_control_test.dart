import 'dart:ui' show Tristate;

import 'package:cloudscape_flutter/src/controls/controls.dart';
import 'package:cloudscape_flutter/src/icons/cs_icons.g.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _options = [
  CsSegmentedControlOption(id: '1h', text: '1h'),
  CsSegmentedControlOption(id: '3h', text: '3h'),
  CsSegmentedControlOption(id: '12h', text: '12h', disabled: true, disabledReason: 'Needs detailed monitoring'),
  CsSegmentedControlOption(id: '1d', text: '1d', icon: CsIcons.calendar),
  CsSegmentedControlOption(id: 'grid', icon: CsIcons.gridView, iconAlt: 'Grid view'),
];

class _Host extends StatefulWidget {
  const _Host({this.onChange, this.presentation = CsSegmentedControlPresentation.auto});

  final ValueChanged<String>? onChange;
  final CsSegmentedControlPresentation presentation;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String id = '1h';

  @override
  Widget build(BuildContext context) => CsSegmentedControl(
    label: 'Time range',
    selectedId: id,
    options: _options,
    presentation: widget.presentation,
    onChange: (v) {
      widget.onChange?.call(v);
      setState(() => id = v);
    },
  );
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in CsDensity.values) {
      testWidgets('renders segments in $brightness $density', (tester) async {
        await pumpCs(tester, const _Host(), brightness: brightness, density: density, size: csDesktopSize);
        expect(find.text('3h'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tap picks a segment; disabled and active do not fire', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add), size: csDesktopSize);
    await tester.tap(find.text('3h'));
    await tester.pump();
    await tester.tap(find.text('3h'));
    await tester.tap(find.text('12h'));
    await tester.pumpAndSettle();
    expect(changes, ['3h']);
  });

  testWidgets('semantics: selected segment and icon-only label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCs(tester, const _Host(), size: csDesktopSize);
    expect(tester.getSemantics(find.text('1h')).flagsCollection.isSelected, Tristate.isTrue);
    expect(find.bySemanticsLabel('Grid view'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('arrows move focus, Enter picks, disabled with reason is focusable', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add), size: csDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, ['3h']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // 12h is disabled: focus lands there but Enter does nothing.
    expect(changes, ['3h']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    // Wrapped from 1h to the last segment.
    expect(changes.last, 'grid');
  });

  testWidgets('phone shows a select that opens a sheet', (tester) async {
    final changes = <String>[];
    await pumpCs(tester, _Host(onChange: changes.add));
    expect(find.text('Time range'), findsOneWidget);
    expect(find.text('3h'), findsNothing);
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3h'));
    await tester.pumpAndSettle();
    expect(changes, ['3h']);
    expect(find.text('1h'), findsNothing);
  });

  testWidgets('presentation override keeps segments on a phone', (tester) async {
    await pumpCs(tester, const _Host(presentation: CsSegmentedControlPresentation.segments), textScale: 2);
    expect(find.text('3h'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select form on desktop opens a dropdown', (tester) async {
    await pumpCs(tester, const _Host(presentation: CsSegmentedControlPresentation.select), size: csDesktopSize);
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    expect(find.text('1d'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('1d'), findsNothing);
  });
}
