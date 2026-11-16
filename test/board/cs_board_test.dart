import 'package:cloudscape_flutter/src/board/board.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

List<CsBoardEntry<String>> _items() => const [
  CsBoardEntry(id: 'a', data: 'Alarms', columnSpan: 2),
  CsBoardEntry(id: 'b', data: 'Billing', columnSpan: 2),
  CsBoardEntry(id: 'c', data: 'Capacity', columnSpan: 4),
];

class _Host extends StatefulWidget {
  const _Host({this.initial, this.columns, this.onChange});

  final List<CsBoardEntry<String>>? initial;
  final int? columns;
  final ValueChanged<CsBoardItemsChange<String>>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<CsBoardEntry<String>> items = widget.initial ?? _items();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: CsBoard<String>(
      items: items,
      columns: widget.columns,
      onItemsChange: (c) {
        widget.onChange?.call(c);
        setState(() => items = c.items);
      },
      empty: const Text('No widgets'),
      renderItem: (context, item, actions) => CsBoardItem(
        header: Text(item.data),
        settings: GestureDetector(onTap: actions.removeItem, child: Text('remove ${item.id}')),
        i18nStrings: CsBoardItemI18nStrings(
          dragHandleAriaLabel: 'Drag ${item.data}',
          resizeHandleAriaLabel: 'Resize ${item.data}',
        ),
        child: Text('content ${item.id}'),
      ),
    ),
  );
}

Finder _handle(String label) => find.bySemanticsLabel(label);

Future<void> _focus(WidgetTester tester, String label) async {
  final focus = find.descendant(of: _handle(label), matching: find.byType(Focus)).first;
  tester.widget<Focus>(focus).focusNode!.requestFocus();
  await tester.pump();
}

void main() {
  testWidgets('renders in light, dark and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(tester, const _Host(), brightness: b, density: d, size: csDesktopSize, center: false);
        expect(tester.takeException(), isNull);
        expect(find.text('Alarms'), findsOneWidget);
      }
    }
  });

  testWidgets('columns switch with the board width', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize, center: false);
    // 4 columns at 1280: a and b sit side by side.
    expect(tester.getTopLeft(find.text('Billing')).dy, tester.getTopLeft(find.text('Alarms')).dy);
    await pumpCs(tester, const _Host(), size: csPhoneSize, center: false);
    // 1 column at 390: stacked.
    expect(tester.getTopLeft(find.text('Billing')).dy, greaterThan(tester.getTopLeft(find.text('Alarms')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows are 96px with 20px gaps, 76 and 16 in compact', (tester) async {
    await pumpCs(tester, const _Host(columns: 4), size: csDesktopSize, center: false);
    expect(tester.getSize(find.byType(CsBoardItem).first).height, 2 * 96 + 20);
    await pumpCs(tester, const _Host(columns: 4), size: csDesktopSize, center: false, density: CsDensity.compact);
    expect(tester.getSize(find.byType(CsBoardItem).first).height, 2 * 76 + 16);
  });

  testWidgets('shows the empty slot without items', (tester) async {
    await pumpCs(tester, const _Host(initial: []), center: false);
    expect(find.text('No widgets'), findsOneWidget);
  });

  testWidgets('removeItem fires onItemsChange with removedItem', (tester) async {
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(onChange: (c) => change = c), size: csDesktopSize, center: false);
    await tester.tap(find.text('remove a'));
    await tester.pumpAndSettle();
    expect(change!.removedItem!.id, 'a');
    expect(change!.items.map((i) => i.id), ['b', 'c']);
    expect(find.text('Alarms'), findsNothing);
  });

  testWidgets('dragging the handle reorders and follows the pointer', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(columns: 4, onChange: (c) => change = c), size: csDesktopSize, center: false);
    final start = tester.getCenter(_handle('Drag Billing'));
    final itemTop = tester.getTopLeft(find.text('Billing'));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(const Offset(-200, 0));
    await gesture.moveBy(const Offset(-200, 0));
    await gesture.moveBy(const Offset(-210, 0));
    await tester.pump();
    // 1:1 follow.
    expect(tester.getTopLeft(find.text('Billing')).dx, closeTo(itemTop.dx - 610, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(change!.movedItem!.id, 'b');
    expect(change!.items.first.id, 'b');
    expect(tester.getTopLeft(find.text('Billing')).dy, lessThan(tester.getTopLeft(find.text('Alarms')).dy));
    semantics.dispose();
  });

  testWidgets('dragging the resize handle resizes', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(columns: 4, onChange: (c) => change = c), size: csDesktopSize, center: false);
    final gesture = await tester.startGesture(tester.getCenter(_handle('Resize Alarms')));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 40));
    }
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(change!.resizedItem!.id, 'a');
    expect(change!.resizedItem!.rowSpan, greaterThan(2));
    semantics.dispose();
  });

  testWidgets('keyboard: Enter starts a move, arrows move, Enter commits', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(columns: 4, onChange: (c) => change = c), size: csDesktopSize, center: false);
    await _focus(tester, 'Drag Billing');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(change?.movedItem?.id, 'b');
    expect(change!.items.first.id, 'b');
    semantics.dispose();
  });

  testWidgets('keyboard: resize with arrows', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(columns: 4, onChange: (c) => change = c), size: csDesktopSize, center: false);
    await _focus(tester, 'Resize Alarms');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(change?.resizedItem?.rowSpan, 3);
    expect(change?.resizedItem?.columnSpan, 3);
    semantics.dispose();
  });

  testWidgets('keyboard: Escape discards', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(columns: 4, onChange: (c) => change = c), size: csDesktopSize, center: false);
    await _focus(tester, 'Resize Alarms');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(change, isNull);
    semantics.dispose();
  });

  testWidgets('reduced motion still works', (tester) async {
    await pumpCs(tester, const _Host(), size: csDesktopSize, center: false, disableAnimations: true);
    await tester.tap(find.text('remove a'));
    await tester.pump();
    expect(find.text('Alarms'), findsNothing);
  });

  testWidgets('2x text on a phone does not overflow', (tester) async {
    await pumpCs(tester, const _Host(), center: false, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('right to left lays items from the right', (tester) async {
    await pumpCs(tester, const _Host(columns: 4), size: csDesktopSize, center: false, textDirection: TextDirection.rtl);
    expect(tester.getTopLeft(find.text('Alarms')).dx, greaterThan(tester.getTopLeft(find.text('Billing')).dx));
  });
}
