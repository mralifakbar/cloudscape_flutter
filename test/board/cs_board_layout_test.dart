import 'package:cloudscape_flutter/src/board/board.dart';
import 'package:flutter_test/flutter_test.dart';

CsBoardEntry<String> e(String id, {int? w, int? h, Map<int, int>? at, CsBoardItemDefinition? def}) =>
    CsBoardEntry<String>(id: id, data: id, columnSpan: w, rowSpan: h, columnOffset: at, definition: def);

void main() {
  test('columns follow the width breakpoints', () {
    expect(CsBoardLayout.columnsForWidth(390), 1);
    expect(CsBoardLayout.columnsForWidth(700), 2);
    expect(CsBoardLayout.columnsForWidth(1200), 4);
    expect(CsBoardLayout.columnsForWidth(2200), 6);
  });

  test('interpret packs items in reading order without overlaps', () {
    final grid = CsBoardLayout.interpret([e('a', w: 2), e('b', w: 1), e('c', w: 1), e('d', w: 4)], 4);
    expect(grid['a'], const CsBoardPlacement(id: 'a', x: 0, y: 0, width: 2, height: 2));
    expect(grid['b']!.x, 2);
    expect(grid['c']!.x, 3);
    expect(grid['d']!.y, 2);
    expect(grid.rows, 4);
    for (final p in grid.items) {
      for (final q in grid.items) {
        if (p != q) expect(p.overlaps(q), isFalse);
      }
    }
  });

  test('spans respect minimums and the column count', () {
    final grid = CsBoardLayout.interpret([
      e('a', w: 9, h: 1),
      e('b', def: const CsBoardItemDefinition(defaultColumnSpan: 2, defaultRowSpan: 3)),
    ], 4);
    expect(grid['a']!.width, 4);
    expect(grid['a']!.height, 2);
    expect(grid['b']!.width, 2);
    expect(grid['b']!.height, 3);
  });

  test('place moves an item and stores its column', () {
    final items = [e('a'), e('b'), e('c')];
    final next = CsBoardLayout.place(items, items[2], 0, 0, 4);
    expect(next.first.id, 'c');
    expect(next.first.columnOffset![4], 0);
    final grid = CsBoardLayout.interpret(next, 4);
    expect(grid['c']!.y, 0);
    expect(grid['a']!.y, 2);
  });

  test('place inserts a new item and pushes others', () {
    final items = [e('a', w: 4)];
    final next = CsBoardLayout.place(items, e('n', w: 4), 0, 0, 4);
    final grid = CsBoardLayout.interpret(next, 4);
    expect(grid['n']!.y, 0);
    expect(grid['a']!.y, 2);
  });

  test('resize clamps to minimums and the space left', () {
    final items = [e('a', def: const CsBoardItemDefinition(minColumnSpan: 2, minRowSpan: 3))];
    var next = CsBoardLayout.resize(items, 'a', 1, 1, 4);
    expect(next.single.columnSpan, 2);
    expect(next.single.rowSpan, 3);
    next = CsBoardLayout.resize(items, 'a', 9, 5, 4);
    expect(next.single.columnSpan, 4);
    expect(next.single.rowSpan, 5);
  });

  test('remove floats the items below up', () {
    final items = [e('a', w: 4), e('b', w: 4)];
    final next = CsBoardLayout.remove(items, 'a', 4);
    expect(next.single.id, 'b');
    expect(CsBoardLayout.interpret(next, 4)['b']!.y, 0);
  });

  test('apply keeps offsets for other column counts until the first change', () {
    final items = [
      e('a', at: {1: 0, 4: 0}),
      e('b', at: {1: 0, 4: 1}),
    ];
    final next = CsBoardLayout.place(items, items[1], 0, 0, 4);
    expect(next.first.id, 'b');
    expect(next.first.columnOffset!.containsKey(1), isFalse);
  });
}
