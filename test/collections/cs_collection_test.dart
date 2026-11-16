import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

typedef _M = Map<String, Object?>;

final _items = <Map<String, Object?>>[
  for (var i = 1; i <= 25; i++)
    {'id': 'i-${i.toString().padLeft(3, '0')}', 'name': i.isEven ? 'web-$i' : 'batch-$i', 'cpu': i % 4 + 1},
];

void main() {
  test('paginates and counts', () {
    final c = CsCollection<_M>(_items, pagination: const CsCollectionPagination(pageSize: 10));
    expect(c.items.length, 10);
    expect(c.pagesCount, 3);
    expect(c.firstIndex, 1);
    c.setCurrentPage(3);
    expect(c.items.length, 5);
    expect(c.firstIndex, 21);
    c.setCurrentPage(9);
    expect(c.currentPageIndex, 3);
  });

  test('text filtering is case-insensitive, resets page and selection', () {
    final c = CsCollection<_M>(
      _items,
      filtering: const CsCollectionFiltering(fields: ['name']),
      pagination: const CsCollectionPagination(pageSize: 5),
    );
    c.setCurrentPage(2);
    c.setSelectedItems([_items.first]);
    c.setFiltering('WEB');
    expect(c.filteredItemsCount, 12);
    expect(c.currentPageIndex, 1);
    expect(c.selectedItems, isEmpty);
    expect(c.isFiltered, isTrue);
  });

  test('keepSelection keeps the selection', () {
    final c = CsCollection<_M>(
      _items,
      filtering: const CsCollectionFiltering(),
      selection: const CsCollectionSelection(keepSelection: true),
    );
    c.setSelectedItems([_items.first]);
    c.setFiltering('batch');
    expect(c.selectedItems.length, 1);
  });

  test('sorts by field and comparator, descending inverts, stable', () {
    final c = CsCollection<_M>(_items, sorting: const CsCollectionSorting());
    c.setSorting(const CsSortingState(sortingColumn: CsSortingColumn(sortingField: 'cpu'), isDescending: true));
    expect(c.items.first['cpu'], 4);
    expect(c.items.first['id'], 'i-003');
    c.setSorting(
      CsSortingState(
        sortingColumn: CsSortingColumn(
          id: 'name',
          sortingComparator: (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        ),
      ),
    );
    expect(c.items.first['name'], 'batch-1');
    expect(c.sortingColumn!.id, 'name');
    expect(c.sortingDescending, isFalse);
  });

  test('property filter operators and operations', () {
    final c = CsCollection<_M>(
      _items,
      propertyFiltering: const CsCollectionPropertyFiltering(
        filteringProperties: [
          CsCollectionFilterProperty(key: 'name', propertyLabel: 'Name'),
          CsCollectionFilterProperty(key: 'cpu', propertyLabel: 'vCPU'),
        ],
      ),
    );
    c.setPropertyFiltering(
      const CsCollectionFilterQuery(
        tokens: [
          CsCollectionFilterToken(propertyKey: 'cpu', operator: '>=', value: '3'),
          CsCollectionFilterToken(propertyKey: 'name', operator: '^', value: 'WEB'),
        ],
      ),
    );
    expect(c.allPageItems.every((i) => (i['cpu'] as int) >= 3 && (i['name'] as String).startsWith('web')), isTrue);
    expect(c.filteredItemsCount, greaterThan(0));
    c.setPropertyFiltering(
      const CsCollectionFilterQuery(
        operation: CsCollectionFilterOperation.or,
        tokens: [
          CsCollectionFilterToken(propertyKey: 'cpu', operator: '=', value: 1),
          CsCollectionFilterToken(value: 'batch-25'),
        ],
      ),
    );
    expect(c.allPageItems.map((i) => i['id']), containsAll(['i-025', 'i-004']));
    c.setPropertyFiltering(
      const CsCollectionFilterQuery(
        tokens: [CsCollectionFilterToken(operator: '!:', value: 'web')],
      ),
    );
    expect(c.filteredItemsCount, 13);
  });

  test('operator matching', () {
    expect(csCollectionMatchOperator(5, '=', '5'), isTrue);
    expect(csCollectionMatchOperator('Running', ':', 'run'), isTrue);
    expect(csCollectionMatchOperator('Running', '!^', 'run'), isFalse);
    expect(csCollectionMatchOperator(10, '<', 9), isFalse);
    expect(csCollectionMatchOperator('b', '>', 'a'), isTrue);
  });

  test('empty state picks empty or no match', () {
    final empty = CsCollection<Map<String, Object?>>(
      const [],
      filtering: const CsCollectionFiltering(empty: Text('No instances'), noMatch: Text('No matches')),
    );
    expect((empty.emptyState as Text).data, 'No instances');
    final c = CsCollection<_M>(
      _items,
      filtering: const CsCollectionFiltering(empty: Text('No instances'), noMatch: Text('No matches')),
    );
    expect(c.emptyState, isNull);
    c.setFiltering('zzz');
    expect((c.emptyState as Text).data, 'No matches');
  });

  test('notifies listeners and replaces items', () {
    final c = CsCollection<_M>(_items, pagination: const CsCollectionPagination(pageSize: 10));
    var n = 0;
    c.addListener(() => n++);
    c.setCurrentPage(2);
    c.allItems = _items.take(3).toList();
    expect(n, 2);
    expect(c.currentPageIndex, 1);
    c.dispose();
  });

  testWidgets('drives a table', (tester) async {
    final c = CsCollection<_M>(
      _items,
      sorting: const CsCollectionSorting(),
      pagination: const CsCollectionPagination(pageSize: 5),
    );
    addTearDown(c.dispose);
    final columns = [
      CsTableColumn<Map<String, Object?>>(
        id: 'id',
        header: 'ID',
        cell: (context, i) => Text(i['id'] as String),
        sortingField: 'id',
      ),
    ];
    await pumpCs(
      tester,
      SingleChildScrollView(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => CsTable<Map<String, Object?>>(
            items: c.items,
            columnDefinitions: columns,
            sortingColumn: c.sortingColumn,
            sortingDescending: c.sortingDescending,
            onSortingChange: c.setSorting,
          ),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('i-001'), findsOneWidget);
    await tester.tap(find.text('ID'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ID'));
    await tester.pumpAndSettle();
    expect(find.text('i-025'), findsOneWidget);
  });
}
