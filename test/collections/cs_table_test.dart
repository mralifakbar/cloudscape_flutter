import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/forms/cs_input.dart';
import 'package:cloudscape_flutter/src/layout/cs_header.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

class _Instance {
  const _Instance(this.id, this.name, this.state, {this.cpu = 2});
  final String id;
  final String name;
  final String state;
  final int cpu;
}

const _items = [
  _Instance('i-0abc123', 'web-server-1', 'Running', cpu: 4),
  _Instance('i-0abc124', 'web-server-2', 'Stopped', cpu: 2),
  _Instance('i-0abc125', 'batch-worker', 'Running', cpu: 8),
];

List<CsTableColumn<_Instance>> _columns({bool editable = false}) => [
  CsTableColumn<_Instance>(
    id: 'id',
    header: 'Instance ID',
    cell: (context, i) => Text(i.id),
    sortingField: 'id',
    isRowHeader: true,
  ),
  CsTableColumn<_Instance>(
    id: 'name',
    header: 'Name',
    cell: (context, i) => Text(i.name),
    sortingComparator: (a, b) => a.name.compareTo(b.name),
    editConfig: editable
        ? CsTableEditConfig<_Instance>(
            ariaLabel: 'Name',
            validation: (item, value) => (value as String?)?.isEmpty ?? false ? 'Enter a name.' : null,
            editingCell: (context, item, ctx) => CsInput(
              value: ctx.currentValue as String? ?? item.name,
              autoFocus: true,
              onChange: ctx.setValue,
              onSubmit: (_) => ctx.submitValue(),
            ),
          )
        : null,
  ),
  CsTableColumn<_Instance>(id: 'state', header: 'State', cell: (context, i) => Text(i.state)),
  CsTableColumn<_Instance>(id: 'cpu', header: 'vCPU', cell: (context, i) => Text('${i.cpu}')),
];

Widget _table({
  List<_Instance> items = _items,
  CsSelectionType? selectionType,
  List<_Instance> selected = const [],
  ValueChanged<List<_Instance>>? onSelectionChange,
  CsSortingColumn<_Instance>? sortingColumn,
  bool descending = false,
  ValueChanged<CsSortingState<_Instance>>? onSortingChange,
  bool loading = false,
  Widget? empty,
  CsTableVariant variant = CsTableVariant.container,
  CsTableMobileLayout mobileLayout = CsTableMobileLayout.scroll,
  bool resizable = false,
  ValueChanged<List<double>>? onColumnWidthsChange,
  List<CsColumnDisplay>? columnDisplay,
  CsStickyColumns sticky = CsStickyColumns.none,
  bool editable = false,
  Future<void> Function(_Instance, CsTableColumn<_Instance>, Object?)? submitEdit,
  ValueChanged<CsTableRowClickDetail<_Instance>>? onRowClick,
  bool Function(_Instance)? isItemDisabled,
  CsDensity density = CsDensity.comfortable,
  bool striped = false,
  bool wrapLines = false,
  double? height,
}) {
  final table = CsTable<_Instance>(
    header: const CsHeader(title: 'Instances', counter: '(3)'),
    columnDefinitions: _columns(editable: editable),
    items: items,
    trackBy: (i) => i.id,
    selectionType: selectionType,
    selectedItems: selected,
    onSelectionChange: onSelectionChange,
    sortingColumn: sortingColumn,
    sortingDescending: descending,
    onSortingChange: onSortingChange,
    loading: loading,
    loadingText: 'Loading instances',
    empty: empty,
    variant: variant,
    mobileLayout: mobileLayout,
    resizableColumns: resizable,
    onColumnWidthsChange: onColumnWidthsChange,
    columnDisplay: columnDisplay,
    stickyColumns: sticky,
    submitEdit: submitEdit,
    onRowClick: onRowClick,
    isItemDisabled: isItemDisabled,
    contentDensity: density,
    stripedRows: striped,
    wrapLines: wrapLines,
    ariaLabels: CsTableAriaLabels<_Instance>(
      tableLabel: 'Instances',
      itemSelectionLabel: (state, item) => 'Select ${item.id}',
      allItemsSelectionLabel: (state) => 'Select all instances',
    ),
  );
  return height == null ? SingleChildScrollView(child: table) : SizedBox(height: height, child: table);
}

void main() {
  testWidgets('renders in light, dark, comfortable and compact', (tester) async {
    for (final b in Brightness.values) {
      for (final d in CsDensity.values) {
        await pumpCs(
          tester,
          _table(density: d, striped: true),
          brightness: b,
          size: csDesktopSize,
          center: false,
        );
        expect(find.text('web-server-1'), findsOneWidget);
        expect(find.text('Instance ID'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('every variant renders', (tester) async {
    for (final v in CsTableVariant.values) {
      await pumpCs(tester, _table(variant: v), size: csDesktopSize, center: false);
      expect(find.text('batch-worker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('sorting header calls onSortingChange and flips direction', (tester) async {
    CsSortingState<_Instance>? last;
    final cols = _columns();
    await pumpCs(
      tester,
      _table(onSortingChange: (s) => last = s, sortingColumn: cols[0]),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.text('Instance ID'));
    expect(last!.isDescending, isTrue);
    expect(last!.sortingColumn.id, 'id');
    await tester.tap(find.text('Name'));
    expect(last!.isDescending, isFalse);
    expect(last!.sortingColumn.id, 'name');
  });

  testWidgets('sorted header exposes its sort state', (tester) async {
    final cols = _columns();
    await pumpCs(
      tester,
      _table(onSortingChange: (_) {}, sortingColumn: cols[0], descending: true),
      size: csDesktopSize,
      center: false,
    );
    expect(find.bySemanticsLabel('Instance ID'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('Instance ID'));
    expect(node.value, 'descending');
  });

  testWidgets('multi selection toggles rows and select all', (tester) async {
    var selected = <_Instance>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _table(
          selectionType: CsSelectionType.multi,
          selected: selected,
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Select i-0abc124'));
    await tester.pumpAndSettle();
    expect(selected.map((i) => i.id), ['i-0abc124']);
    await tester.tap(find.bySemanticsLabel('Select all instances'));
    await tester.pumpAndSettle();
    expect(selected.length, 3);
    await tester.tap(find.bySemanticsLabel('Select all instances'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });

  testWidgets('shift extends a multi selection range', (tester) async {
    var selected = <_Instance>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _table(
          selectionType: CsSelectionType.multi,
          selected: selected,
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Select i-0abc123'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.bySemanticsLabel('Select i-0abc125'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(selected.length, 3);
  });

  testWidgets('single selection keeps one item and skips disabled ones', (tester) async {
    var selected = <_Instance>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _table(
          selectionType: CsSelectionType.single,
          selected: selected,
          isItemDisabled: (i) => i.state == 'Stopped',
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Select i-0abc123'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select i-0abc125'));
    await tester.pumpAndSettle();
    expect(selected.map((i) => i.id), ['i-0abc125']);
    await tester.tap(find.bySemanticsLabel('Select i-0abc124'));
    await tester.pumpAndSettle();
    expect(selected.map((i) => i.id), ['i-0abc125']);
  });

  testWidgets('loading and empty states', (tester) async {
    await pumpCs(tester, _table(loading: true), size: csDesktopSize, center: false, settle: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Loading instances'), findsOneWidget);
    expect(find.text('web-server-1'), findsNothing);
    await pumpCs(
      tester,
      _table(items: const [], empty: const Text('No instances')),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('No instances'), findsOneWidget);
  });

  testWidgets('column display hides and reorders columns', (tester) async {
    await pumpCs(
      tester,
      _table(
        columnDisplay: const [
          CsColumnDisplay(id: 'state'),
          CsColumnDisplay(id: 'id'),
          CsColumnDisplay(id: 'name', visible: false),
          CsColumnDisplay(id: 'cpu', visible: false),
        ],
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('Name'), findsNothing);
    final state = tester.getTopLeft(find.text('State'));
    final id = tester.getTopLeft(find.text('Instance ID'));
    expect(state.dx, lessThan(id.dx));
  });

  testWidgets('row click reports the row', (tester) async {
    CsTableRowClickDetail<_Instance>? detail;
    await pumpCs(tester, _table(onRowClick: (d) => detail = d), size: csDesktopSize, center: false);
    await tester.tap(find.text('Stopped'));
    expect(detail!.rowIndex, 1);
    expect(detail!.item.id, 'i-0abc124');
  });

  testWidgets('resizing a column reports widths', (tester) async {
    List<double>? widths;
    await pumpCs(
      tester,
      _table(resizable: true, onColumnWidthsChange: (w) => widths = w),
      size: csDesktopSize,
      center: false,
    );
    final before = tester.getTopLeft(find.text('Name')).dx;
    final handle = find.byWidgetPredicate((w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn).first;
    await tester.drag(handle, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(widths, isNotNull);
    expect(widths!.length, 4);
    expect(tester.getTopLeft(find.text('Name')).dx, greaterThan(before + 40));
  });

  testWidgets('inline edit validates, submits and cancels', (tester) async {
    Object? saved;
    await pumpCs(
      tester,
      _table(editable: true, submitEdit: (item, column, value) async => saved = value),
      size: csDesktopSize,
      center: false,
    );
    await tester.tap(find.text('web-server-1'));
    await tester.pumpAndSettle();
    expect(find.byType(CsInput), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '');
    await tester.pumpAndSettle();
    expect(find.text('Enter a name.'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'web-server-9');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Submit'));
    await tester.pumpAndSettle();
    expect(saved, 'web-server-9');
    expect(find.byType(CsInput), findsNothing);

    await tester.tap(find.text('web-server-2'));
    await tester.pumpAndSettle();
    expect(find.byType(CsInput), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CsInput), findsNothing);
  });

  testWidgets('expandable rows show children and toggle', (tester) async {
    const parent = _Instance('g-1', 'web-tier', 'Group');
    var expanded = <_Instance>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: CsTable<_Instance>(
            columnDefinitions: _columns(),
            items: const [parent],
            trackBy: (i) => i.id,
            expandableRows: CsTableExpandableRows<_Instance>(
              getItemChildren: (i) => i.id == 'g-1' ? _items : const [],
              isItemExpandable: (i) => i.id == 'g-1',
              expandedItems: expanded,
              onExpandableItemToggle: (item, open) =>
                  setState(() => expanded = open ? [...expanded, item] : expanded.where((e) => e != item).toList()),
            ),
          ),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('web-server-1'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Expand'));
    await tester.pumpAndSettle();
    expect(find.text('web-server-1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Collapse'));
    await tester.pumpAndSettle();
    expect(find.text('web-server-1'), findsNothing);
  });

  testWidgets('progressive loading renders a loader row', (tester) async {
    await pumpCs(
      tester,
      SingleChildScrollView(
        child: CsTable<_Instance>(
          columnDefinitions: _columns(),
          items: _items,
          getLoadingStatus: (item) => CsTableLoadingStatus.pending,
          renderLoaderPending: (item) => const Text('Load more'),
        ),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('Load more'), findsOneWidget);
  });

  testWidgets('phone: scroll layout fits 390px with sticky first column and 2x text', (tester) async {
    await pumpCs(tester, _table(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    expect(find.text('web-server-1'), findsOneWidget);
    await tester.drag(find.text('Running').first, const Offset(-300, 0));
    await tester.pumpAndSettle();
    // The sticky first column stays at the start edge.
    expect(tester.getTopLeft(find.text('i-0abc123')).dx, lessThan(40));
  });

  testWidgets('phone: card layout shows one card per row', (tester) async {
    var selected = <_Instance>[];
    await pumpCs(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _table(
          mobileLayout: CsTableMobileLayout.cards,
          selectionType: CsSelectionType.multi,
          selected: selected,
          onSelectionChange: (next) => setState(() => selected = next),
        ),
      ),
      textScale: 2,
      center: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CsItemCard), findsNWidgets(3));
    await tester.tap(find.bySemanticsLabel('Select i-0abc125'));
    await tester.pumpAndSettle();
    expect(selected.single.id, 'i-0abc125');
  });

  testWidgets('desktop: card layout setting keeps the grid', (tester) async {
    await pumpCs(tester, _table(mobileLayout: CsTableMobileLayout.cards), size: csDesktopSize, center: false);
    expect(find.byType(CsItemCard), findsNothing);
  });

  testWidgets('bounded height builds rows lazily with a sticky header', (tester) async {
    final many = [for (var i = 0; i < 200; i++) _Instance('i-$i', 'server-$i', 'Running')];
    await pumpCs(
      tester,
      CsTable<_Instance>(
        columnDefinitions: _columns(),
        items: many,
        stickyHeader: true,
        header: const CsHeader(title: 'Instances'),
      ),
      size: csDesktopSize,
      center: false,
    );
    expect(find.text('server-0'), findsOneWidget);
    expect(find.text('server-199'), findsNothing);
    await tester.drag(find.text('server-3'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Instances'), findsOneWidget);
  });

  testWidgets('reduced motion and wrap lines render', (tester) async {
    await pumpCs(
      tester,
      _table(wrapLines: true, sticky: const CsStickyColumns(first: 1, last: 1)),
      disableAnimations: true,
      size: csDesktopSize,
      center: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('table label is exposed', (tester) async {
    await pumpCs(tester, _table(), size: csDesktopSize, center: false);
    expect(find.bySemanticsLabel('Instances'), findsWidgets);
  });
}
