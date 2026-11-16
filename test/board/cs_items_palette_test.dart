import 'package:cloudscape_flutter/src/board/board.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _palette = [
  CsItemsPaletteItem(id: 'p1', data: 'Network traffic', definition: CsBoardItemDefinition(defaultColumnSpan: 2)),
  CsItemsPaletteItem(id: 'p2', data: 'Error rate'),
];

class _Host extends StatefulWidget {
  const _Host({this.withAdd = true, this.onChange, this.onAdd});

  final bool withAdd;
  final ValueChanged<CsBoardItemsChange<String>>? onChange;
  final ValueChanged<CsItemsPaletteItem<String>>? onAdd;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  List<CsBoardEntry<String>> board = const [CsBoardEntry(id: 'a', data: 'Alarms', columnSpan: 4)];
  List<CsItemsPaletteItem<String>> palette = _palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CsBoard<String>(
        items: board,
        columns: 4,
        onItemsChange: (c) {
          widget.onChange?.call(c);
          setState(() {
            board = c.items;
            palette = palette.where((p) => p.id != c.addedItem?.id).toList();
          });
        },
        renderItem: (context, item, actions) => CsBoardItem(header: Text(item.data)),
      ),
      const SizedBox(height: 24),
      CsItemsPalette<String>(
        items: palette,
        onItemAdd: !widget.withAdd
            ? null
            : (item) {
                widget.onAdd?.call(item);
                setState(() {
                  board = [...board, item.toBoardEntry()];
                  palette = palette.where((p) => p.id != item.id).toList();
                });
              },
        renderItem: (context, item, ctx) => CsBoardItem(
          header: Text(item.data),
          i18nStrings: CsBoardItemI18nStrings(dragHandleAriaLabel: 'Drag ${item.data}'),
          child: Text(ctx.showPreview ? 'preview ${item.id}' : 'summary ${item.id}'),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('renders in light, dark and compact, wide and narrow', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        for (final size in [csPhoneSize, csDesktopSize]) {
          await pumpCs(
            tester,
            CsItemsPalette<String>(
              items: _palette,
              renderItem: (context, item, ctx) => CsBoardItem(header: Text(item.data), child: const Text('Summary')),
            ),
            brightness: b,
            density: d,
            size: size,
            center: false,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('lays out in columns on desktop and stacks on phones', (tester) async {
    Widget palette() => CsItemsPalette<String>(
      items: _palette,
      renderItem: (context, item, ctx) => CsBoardItem(header: Text(item.data)),
    );
    await pumpCs(tester, palette(), size: csDesktopSize, center: false);
    expect(tester.getTopLeft(find.text('Error rate')).dy, tester.getTopLeft(find.text('Network traffic')).dy);
    await pumpCs(tester, palette(), size: csPhoneSize, center: false);
    expect(
      tester.getTopLeft(find.text('Error rate')).dy,
      greaterThan(tester.getTopLeft(find.text('Network traffic')).dy),
    );
  });

  testWidgets('add button inserts without dragging', (tester) async {
    final semantics = tester.ensureSemantics();
    CsItemsPaletteItem<String>? added;
    await pumpCs(tester, _Host(onAdd: (i) => added = i), size: csDesktopSize, center: false);
    await tester.tap(find.bySemanticsLabel('Add to board').first);
    await tester.pumpAndSettle();
    expect(added?.id, 'p1');
    expect(find.text('summary p1'), findsNothing);
    semantics.dispose();
  });

  testWidgets('Enter on the drag handle adds the item', (tester) async {
    final semantics = tester.ensureSemantics();
    CsItemsPaletteItem<String>? added;
    await pumpCs(tester, _Host(onAdd: (i) => added = i), size: csDesktopSize, center: false);
    final focus = find.descendant(of: find.bySemanticsLabel('Drag Error rate'), matching: find.byType(Focus)).first;
    tester.widget<Focus>(focus).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(added?.id, 'p2');
    semantics.dispose();
  });

  testWidgets('no add button without onItemAdd', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCs(tester, const _Host(withAdd: false), size: csDesktopSize, center: false);
    expect(find.bySemanticsLabel('Add to board'), findsNothing);
    semantics.dispose();
  });

  testWidgets('dragging a palette item by its handle onto the board inserts it', (tester) async {
    final semantics = tester.ensureSemantics();
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(onChange: (c) => change = c), size: csDesktopSize, center: false);
    final start = tester.getCenter(find.bySemanticsLabel('Drag Network traffic'));
    final boardTop = tester.getTopLeft(find.byType(CsBoard<String>));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(boardTop + const Offset(30, 20));
    await tester.pump();
    await gesture.moveTo(boardTop + const Offset(32, 24));
    await tester.pump();
    // Preview content while over the board.
    expect(find.text('preview p1'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(change?.addedItem?.id, 'p1');
    expect(change!.items.first.id, 'p1');
    semantics.dispose();
  });

  testWidgets('press and hold drags on touch; dropping outside discards', (tester) async {
    CsBoardItemsChange<String>? change;
    await pumpCs(tester, _Host(onChange: (c) => change = c), size: csDesktopSize, center: false);
    final gesture = await tester.startGesture(tester.getCenter(find.text('summary p2')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(change, isNull);
    expect(find.text('summary p2'), findsOneWidget);
  });
}
