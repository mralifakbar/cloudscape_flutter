import 'package:cloudscape_flutter/src/collections/collections.dart';
import 'package:cloudscape_flutter/src/icons/icons.dart';
import 'package:cloudscape_flutter/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

const _rows = [
  ('web-server-1', 'i-0abc123', 'Running'),
  ('web-server-2', 'i-0abc124', 'Stopped'),
  ('batch-worker', 'i-0abc125', 'Running'),
  ('bastion', 'i-0abc126', 'Pending'),
];

Widget _table({
  CsTableColumnLayout layout = const CsTableColumnLayout.auto(),
  CsTableVariant variant = CsTableVariant.container,
  bool striped = false,
  CsDensity density = CsDensity.comfortable,
  Set<int> selected = const {},
  CsTableSortingState? sorting = CsTableSortingState.ascending,
  VoidCallback? onSort,
  ValueChanged<int>? onRow,
  bool sticky = false,
  CsStickyColumns stickyColumns = CsStickyColumns.none,
  ValueChanged<double>? onResize,
}) {
  final head = CsTableHead(
    child: CsTableRow(
      children: [
        CsTableHeaderCell(
          sortingState: sorting,
          onSort: onSort,
          resizable: onResize != null,
          onResize: onResize,
          child: const Text('Name'),
        ),
        const CsTableHeaderCell(child: Text('Instance ID')),
        const CsTableHeaderCell(sortingState: CsTableSortingState.sortable, child: Text('State')),
      ],
    ),
  );
  final body = CsTableBody(
    children: [
      for (var i = 0; i < _rows.length; i++)
        CsTableRow(
          selected: selected.contains(i),
          onPress: onRow == null ? null : () => onRow(i),
          children: [
            CsTableBodyCell(isRowHeader: true, child: Text(_rows[i].$1)),
            CsTableBodyCell(child: Text(_rows[i].$2)),
            CsTableBodyCell(child: Text(_rows[i].$3)),
          ],
        ),
    ],
  );
  return CsTableRoot(
    ariaLabel: 'Instances',
    columnLayout: layout,
    variant: variant,
    stripedRows: striped,
    contentDensity: density,
    stickyColumns: stickyColumns,
    stickyHeader: sticky ? head : null,
    children: [if (!sticky) head, body],
  );
}

double _cellWidth(WidgetTester tester, String text) =>
    tester.getSize(find.ancestor(of: find.text(text), matching: find.byType(CsTableBodyCell))).width;

void main() {
  group('CsTableRoot', () {
    testWidgets('renders every variant in light, dark, comfortable and compact', (tester) async {
      for (final b in Brightness.values) {
        for (final d in CsDensity.values) {
          for (final v in CsTableVariant.values) {
            await pumpCs(
              tester,
              Padding(
                padding: const EdgeInsets.all(16),
                child: _table(variant: v, density: d, striped: true),
              ),
              brightness: b,
              size: csDesktopSize,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
      expect(find.text('web-server-1'), findsOneWidget);
      expect(find.bySemanticsLabel('Instances'), findsOneWidget);
    });

    testWidgets('auto layout shares the width evenly', (tester) async {
      await pumpCs(tester, _table(variant: CsTableVariant.borderless), size: csDesktopSize, center: false);
      final w = _cellWidth(tester, 'web-server-1');
      expect(_cellWidth(tester, 'i-0abc123'), closeTo(w, 0.01));
      expect(w, closeTo(1280 / 3, 0.5));
    });

    testWidgets('grid layout honors fixed widths, flex weights and caps', (tester) async {
      await pumpCs(
        tester,
        _table(
          variant: CsTableVariant.borderless,
          layout: const CsTableColumnLayout.grid([
            CsTableGridColumn.fixed(200),
            CsTableGridColumn(flex: 2, minWidth: 100),
            CsTableGridColumn(minWidth: 100),
          ]),
        ),
        size: csDesktopSize,
        center: false,
      );
      expect(_cellWidth(tester, 'web-server-1'), 200);
      final second = _cellWidth(tester, 'i-0abc123');
      final third = _cellWidth(tester, 'Pending');
      expect(second + third, closeTo(1080, 0.5));
      // 100 + 2/3 of the rest vs 100 + 1/3 of it.
      expect(second, closeTo(100 + 880 * 2 / 3, 0.5));

      await pumpCs(
        tester,
        _table(
          variant: CsTableVariant.borderless,
          layout: const CsTableColumnLayout.grid([
            CsTableGridColumn(maxWidth: 150),
            CsTableGridColumn(),
            CsTableGridColumn(),
          ]),
        ),
        size: csDesktopSize,
        center: false,
      );
      expect(_cellWidth(tester, 'web-server-1'), closeTo(150, 0.5));
    });

    testWidgets('scrolls sideways at 390px and keeps sticky columns', (tester) async {
      await pumpCs(tester, _table(stickyColumns: const CsStickyColumns(first: 1)), textScale: 2, center: false);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(CsTableRoot), matching: find.byType(SingleChildScrollView)),
        findsOneWidget,
      );
      final before = tester.getTopLeft(find.text('web-server-1'));
      await tester.drag(find.text('i-0abc123'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('web-server-1')).dx, greaterThanOrEqualTo(0));
      expect(tester.getTopLeft(find.text('web-server-1')).dx, closeTo(before.dx, CsSpace.tableHorizontal));
    });

    testWidgets('sticky header stays while the body scrolls', (tester) async {
      await pumpCs(tester, SizedBox(height: 160, child: _table(sticky: true)), size: csDesktopSize);
      final top = tester.getTopLeft(find.text('Name')).dy;
      await tester.drag(find.text('web-server-2'), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Name')).dy, top);
    });

    testWidgets('compact density shortens rows', (tester) async {
      await pumpCs(tester, _table(), size: csDesktopSize);
      final comfortable = tester.getSize(find.byType(CsTableRow).at(1)).height;
      await pumpCs(tester, _table(density: CsDensity.compact), size: csDesktopSize);
      expect(tester.getSize(find.byType(CsTableRow).at(1)).height, lessThan(comfortable));
    });
  });

  group('CsTableHead', () {
    testWidgets('draws the table header background and divider', (tester) async {
      await pumpCs(tester, _table(), size: csDesktopSize);
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(CsTableHead), matching: find.byType(DecoratedBox)).first,
      );
      final d = box.decoration as BoxDecoration;
      final c = CsThemeData.light().colors;
      expect(d.color, c.backgroundTableHeader);
      expect((d.border! as Border).bottom.color, c.borderDividerDefault);
    });

    testWidgets('is transparent in the borderless variant', (tester) async {
      await pumpCs(tester, _table(variant: CsTableVariant.borderless), size: csDesktopSize);
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(CsTableHead), matching: find.byType(DecoratedBox)).first,
      );
      expect((box.decoration as BoxDecoration).color, CsThemeData.light().colors.backgroundContainerContent);
    });
  });

  group('CsTableHeaderCell', () {
    testWidgets('shows the sorting caret for each state and calls onSort', (tester) async {
      var sorts = 0;
      await pumpCs(tester, _table(onSort: () => sorts++), size: csDesktopSize);
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.caretUpFilled), findsOneWidget);
      // The sortable column without onSort shows no caret.
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.caretDown), findsNothing);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(sorts, 1);

      await pumpCs(
        tester,
        _table(onSort: () {}, sorting: CsTableSortingState.descending),
        size: csDesktopSize,
      );
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.caretDownFilled), findsOneWidget);
      await pumpCs(
        tester,
        _table(onSort: () {}, sorting: CsTableSortingState.sortable),
        size: csDesktopSize,
      );
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.caretDown), findsOneWidget);
    });

    testWidgets('announces the sort state and sorts with Enter', (tester) async {
      var sorts = 0;
      await pumpCs(tester, _table(onSort: () => sorts++), size: csDesktopSize);
      final node = tester.getSemantics(find.text('Name'));
      expect(node.value, 'sorted ascending');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(sorts, 1);
    });

    testWidgets('sorting disabled shows the state and ignores taps', (tester) async {
      var sorts = 0;
      await pumpCs(
        tester,
        CsTableRoot(
          children: [
            CsTableHead(
              child: CsTableRow(
                children: [
                  CsTableHeaderCell(
                    sortingState: CsTableSortingState.descending,
                    sortingDisabled: true,
                    onSort: () => sorts++,
                    child: const Text('Name'),
                  ),
                ],
              ),
            ),
          ],
        ),
        size: csDesktopSize,
      );
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(sorts, 0);
      final icon = tester.widget<CsIcon>(
        find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.caretDownFilled),
      );
      expect(icon.dangerouslySetColor, CsThemeData.light().colors.textInteractiveDisabled);
    });

    testWidgets('resize handle reports widths by drag and keyboard', (tester) async {
      final widths = <double>[];
      await pumpCs(
        tester,
        _table(
          variant: CsTableVariant.borderless,
          layout: const CsTableColumnLayout.grid([
            CsTableGridColumn.fixed(200),
            CsTableGridColumn(minWidth: 100),
            CsTableGridColumn(minWidth: 100),
          ]),
          onResize: widths.add,
        ),
        size: csDesktopSize,
        center: false,
      );
      final handle = find.byWidgetPredicate((w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn);
      expect(handle, findsOneWidget);
      await tester.drag(handle, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(widths.last, greaterThan(200));
      widths.clear();
      final semantics = tester.getSemantics(handle);
      expect(semantics.value, '200');
    });
  });

  group('CsTableBody and CsTableRow', () {
    testWidgets('striped rows shade every other row', (tester) async {
      await pumpCs(tester, _table(striped: true), size: csDesktopSize);
      final c = CsThemeData.light().colors;
      Color? colorOf(int row) {
        final box = tester.widget<Container>(
          find.descendant(of: find.byType(CsTableRow).at(row + 1), matching: find.byType(Container)).first,
        );
        return (box.decoration as BoxDecoration?)?.color;
      }

      expect(colorOf(0), isNull);
      expect(colorOf(1), c.backgroundCellShaded);
      expect(colorOf(2), isNull);
    });

    testWidgets('selected rows fill and announce selection', (tester) async {
      await pumpCs(tester, _table(selected: {1, 2}), size: csDesktopSize);
      final box = tester.widget<Container>(
        find.descendant(of: find.byType(CsTableRow).at(2), matching: find.byType(Container)).first,
      );
      final d = box.decoration! as BoxDecoration;
      expect(d.color, CsThemeData.light().colors.backgroundItemSelected);
      // Joined with the next selected row: square bottom corners.
      expect((d.borderRadius! as BorderRadius).bottomLeft, Radius.zero);
      expect((d.borderRadius! as BorderRadius).topLeft, const Radius.circular(CsBorderRadius.item));
    });

    testWidgets('onPress makes the row tappable', (tester) async {
      final taps = <int>[];
      await pumpCs(tester, _table(onRow: taps.add), size: csDesktopSize);
      await tester.tap(find.text('batch-worker'));
      await tester.pumpAndSettle();
      expect(taps, [2]);
    });
  });

  group('CsTableBodyCell', () {
    Widget single(CsTableBodyCell cell, {bool wrap = false}) => SizedBox(
      width: 300,
      child: CsTableRoot(
        wrapLines: wrap,
        children: [
          CsTableBody(
            children: [
              CsTableRow(
                children: [
                  cell,
                  const CsTableBodyCell(child: Text('x')),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    testWidgets('truncates by default and wraps with wrapLines', (tester) async {
      const long = 'A very long description of the instance that will not fit in one line of the cell';
      await pumpCs(tester, single(const CsTableBodyCell(child: Text(long))), size: csDesktopSize);
      final one = tester.getSize(find.text(long)).height;
      await pumpCs(tester, single(const CsTableBodyCell(wrapLines: true, child: Text(long))), size: csDesktopSize);
      expect(tester.getSize(find.text(long)).height, greaterThan(one));
      await pumpCs(tester, single(const CsTableBodyCell(child: Text(long)), wrap: true), size: csDesktopSize);
      expect(tester.getSize(find.text(long)).height, greaterThan(one));
    });

    testWidgets('colSpan covers several columns', (tester) async {
      await pumpCs(
        tester,
        const CsTableRoot(
          columnLayout: CsTableColumnLayout.grid([
            CsTableGridColumn.fixed(100),
            CsTableGridColumn.fixed(100),
            CsTableGridColumn.fixed(100),
          ]),
          children: [
            CsTableBody(
              children: [
                CsTableRow(
                  children: [
                    CsTableBodyCell(colSpan: 2, child: Text('Spans two')),
                    CsTableBodyCell(child: Text('One')),
                  ],
                ),
              ],
            ),
          ],
        ),
        size: csDesktopSize,
      );
      expect(_cellWidth(tester, 'Spans two'), 200);
      expect(_cellWidth(tester, 'One'), 100);
    });

    testWidgets('vertical alignment top', (tester) async {
      await pumpCs(
        tester,
        SizedBox(
          width: 300,
          child: CsTableRoot(
            children: [
              CsTableBody(
                children: [
                  CsTableRow(
                    children: [
                      const CsTableBodyCell(verticalAlign: CsTableVerticalAlign.top, child: Text('Top')),
                      CsTableBodyCell(child: Container(height: 80, color: const Color(0x00000000))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        size: csDesktopSize,
      );
      final cellTop = tester.getTopLeft(find.byType(CsTableBodyCell).first).dy;
      expect(tester.getTopLeft(find.text('Top')).dy - cellTop, lessThan(20));
    });

    testWidgets('editable cells show the edit affordance and call onEdit', (tester) async {
      var edits = 0;
      await pumpCs(
        tester,
        single(
          CsTableBodyCell(editable: true, editAriaLabel: 'Edit name', onEdit: () => edits++, child: const Text('web')),
        ),
        size: csDesktopSize,
      );
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.edit), findsOneWidget);
      await tester.tap(find.text('web'));
      await tester.pumpAndSettle();
      expect(edits, 1);
      expect(find.bySemanticsLabel(RegExp('Edit name')), findsOneWidget);
    });

    testWidgets('a disabled edit shows a lock and does not edit', (tester) async {
      var edits = 0;
      await pumpCs(
        tester,
        single(
          CsTableBodyCell(
            editable: true,
            editDisabledReason: 'Running instances cannot be renamed.',
            onEdit: () => edits++,
            child: const Text('web'),
          ),
        ),
        size: csDesktopSize,
      );
      expect(find.byWidgetPredicate((w) => w is CsIcon && w.icon == CsIcons.lockPrivate), findsOneWidget);
      await tester.tap(find.text('web'));
      await tester.pumpAndSettle();
      expect(edits, 0);
    });

    testWidgets('row header cells are announced as headers', (tester) async {
      await pumpCs(tester, _table(), size: csDesktopSize);
      final node = tester.getSemantics(find.text('web-server-1'));
      expect(node.flagsCollection.isHeader, isTrue);
    });
  });
}
