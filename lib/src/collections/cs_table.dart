import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../feedback/cs_spinner.dart';
import '../forms/cs_form_field.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_collection_internal.dart';
import 'cs_collection_types.dart';
import 'cs_item_card.dart';
import 'cs_table_layout.dart';

/// Table styles (Cloudscape `variant`).
enum CsTableVariant {
  /// Inside a container: rounded border, the header and tools inside it.
  container,

  /// For a table inside another container (a modal, an expandable section).
  /// Cloudscape deprecated it in favor of [borderless] and [container].
  embedded,

  /// No outer border or background, for a table inside a dashboard item.
  borderless,

  /// Square corners, for a table placed next to other stacked containers.
  stacked,

  /// The table is the whole page: the header sits on the page background
  /// above the container.
  fullPage,
}

/// Vertical alignment of cell content (Cloudscape `verticalAlign`).
enum CsTableVerticalAlign { middle, top }

/// What the table shows on phones (at or below 688px).
enum CsTableMobileLayout {
  /// The table keeps its columns and scrolls sideways, with the first
  /// column stuck to the start edge.
  scroll,

  /// Each row becomes a card listing the visible columns.
  cards,
}

/// Progressive loading state of a list or an expanded row (Cloudscape
/// `LoadingStatus`).
enum CsTableLoadingStatus {
  /// More items can be loaded; nothing is in flight.
  pending,

  /// Items are being fetched.
  loading,

  /// The last fetch failed.
  error,

  /// Everything is loaded.
  finished,
}

/// The sort state of a column, handed to [CsTableColumn.ariaLabel]
/// (Cloudscape `LabelData`).
@immutable
class CsTableLabelData {
  const CsTableLabelData({required this.sorted, required this.descending, required this.disabled});

  final bool sorted;
  final bool descending;
  final bool disabled;
}

/// Data for a column [CsTableColumn.counter] (Cloudscape `ItemCounterData`).
@immutable
class CsTableItemCounterData<T> {
  const CsTableItemCounterData({required this.item, this.itemsCount, this.selectedItemsCount});

  final T item;
  final int? itemsCount;
  final int? selectedItemsCount;
}

/// What an editing cell gets to read and change its value (Cloudscape
/// `CellContext`).
@immutable
class CsTableCellContext {
  const CsTableCellContext({required this.currentValue, required this.setValue, required this.submitValue});

  /// The value typed so far, or null before the user changes anything. Fall
  /// back to the item's value: `ctx.currentValue as String? ?? item.name`.
  final Object? currentValue;

  /// Updates [currentValue] and runs validation.
  final ValueChanged<Object?> setValue;

  /// Submits [currentValue]. Call it from a text input's `onSubmit` so Enter
  /// saves.
  final VoidCallback submitValue;
}

/// Inline editing for a column (Cloudscape `EditConfig`).
///
/// ```dart
/// CsTableEditConfig<Instance>(
///   ariaLabel: 'Name',
///   validation: (item, value) => (value as String?)?.isEmpty ?? false ? 'Enter a name.' : null,
///   editingCell: (context, item, ctx) => CsInput(
///     value: ctx.currentValue as String? ?? item.name,
///     autoFocus: true,
///     onChange: ctx.setValue,
///     onSubmit: (_) => ctx.submitValue(),
///   ),
/// )
/// ```
@immutable
class CsTableEditConfig<T> {
  const CsTableEditConfig({
    required this.editingCell,
    this.ariaLabel,
    this.errorIconAriaLabel,
    this.editIconAriaLabel,
    this.constraintText,
    this.validation,
    this.disabledReason,
  });

  /// Builds the editor shown while the cell is being edited.
  final Widget Function(BuildContext context, T item, CsTableCellContext cellContext) editingCell;

  /// Label of the editor, read by screen readers.
  final String? ariaLabel;

  /// Label of the icon shown with a validation error.
  final String? errorIconAriaLabel;

  /// Label of the edit icon (announced as "editable" by default).
  final String? editIconAriaLabel;

  /// Shown below the editor.
  final String? constraintText;

  /// Returns an error message for [value], or null when it is valid.
  final String? Function(T item, Object? value)? validation;

  /// Returns why the cell cannot be edited for [item], or null when it can.
  /// A disabled cell shows a lock icon and the reason when pressed.
  final String? Function(T item)? disabledReason;
}

/// One column of a [CsTable] (Cloudscape `ColumnDefinition`).
///
/// ```dart
/// CsTableColumn<Instance>(
///   id: 'name',
///   header: 'Name',
///   cell: (context, item) => Text(item.name),
///   sortingField: 'name',
///   isRowHeader: true,
/// )
/// ```
class CsTableColumn<T> extends CsSortingColumn<T> {
  const CsTableColumn({
    required String super.id,
    required this.cell,
    this.header,
    this.headerWidget,
    this.ariaLabel,
    this.width,
    this.minWidth,
    this.maxWidth,
    super.sortingField,
    super.sortingComparator,
    this.counter,
    this.editConfig,
    this.isRowHeader = false,
    this.verticalAlign,
    this.cardLabel,
  }) : assert(header != null || headerWidget != null, 'Pass header or headerWidget');

  /// Unique column id. Matches [CsColumnDisplay.id] entries and keys the
  /// column's resized width.
  String get columnId => id!;

  /// Header text.
  final String? header;

  /// Custom header content in place of [header].
  final Widget? headerWidget;

  /// Builds the cell for an item.
  final Widget Function(BuildContext context, T item) cell;

  /// Accessible header label from the column's sort state.
  final String Function(CsTableLabelData data)? ariaLabel;

  /// Fixed width in logical pixels. Without it the column shares the free
  /// space with the other flexible columns.
  final double? width;

  /// Smallest width. Defaults to 120, Cloudscape's minimum for resizable
  /// columns.
  final double? minWidth;

  /// Largest width a flexible column grows to. Ignored with resizable
  /// columns.
  final double? maxWidth;

  /// Secondary content after the cell, such as "(12)" next to a group name.
  final Widget? Function(CsTableItemCounterData<T> data)? counter;

  /// Enables inline editing.
  final CsTableEditConfig<T>? editConfig;

  /// Cells of this column label their row for screen readers.
  final bool isRowHeader;

  /// Overrides [CsTable.cellVerticalAlign] for this column.
  final CsTableVerticalAlign? verticalAlign;

  /// Label for this column in the phone card layout; defaults to [header].
  final String? cardLabel;

  static const double defaultMinWidth = 120;
}

/// Expandable rows (Cloudscape `expandableRows`).
@immutable
class CsTableExpandableRows<T> {
  const CsTableExpandableRows({
    required this.getItemChildren,
    required this.isItemExpandable,
    required this.expandedItems,
    required this.onExpandableItemToggle,
    this.getItemsCount,
    this.totalItemsCount,
    this.getSelectedItemsCount,
    this.totalSelectedItemsCount,
  });

  /// The nested items shown when [item] is expanded.
  final List<T> Function(T item) getItemChildren;
  final bool Function(T item) isItemExpandable;

  /// Items whose children are shown.
  final List<T> expandedItems;

  /// Called with the item and its next expanded state.
  final void Function(T item, bool expanded) onExpandableItemToggle;

  /// Number of resources under an item, passed to column counters.
  final int Function(T item)? getItemsCount;
  final int? totalItemsCount;
  final int Function(T item)? getSelectedItemsCount;
  final int? totalSelectedItemsCount;
}

/// Selection data handed to selection labels (Cloudscape `SelectionState`).
@immutable
class CsTableSelectionState<T> {
  const CsTableSelectionState({required this.selectedItems, this.itemsCount, this.selectedItemsCount});

  final List<T> selectedItems;
  final int? itemsCount;
  final int? selectedItemsCount;
}

/// A row press (Cloudscape `OnRowClickDetail`).
@immutable
class CsTableRowClickDetail<T> {
  const CsTableRowClickDetail({required this.rowIndex, required this.item});

  final int rowIndex;
  final T item;
}

/// A secondary click or long press on a row (Cloudscape
/// `OnRowContextMenuDetail`).
@immutable
class CsTableRowContextMenuDetail<T> {
  const CsTableRowContextMenuDetail({required this.rowIndex, required this.item, required this.position});

  final int rowIndex;
  final T item;

  /// Global position of the pointer.
  final Offset position;
}

/// Accessible labels that depend on the items (Cloudscape `ariaLabels`).
@immutable
class CsTableAriaLabels<T> {
  const CsTableAriaLabels({
    this.allItemsSelectionLabel,
    this.itemSelectionLabel,
    this.selectionGroupLabel,
    this.tableLabel,
    this.resizerRoleDescription,
    this.resizerTooltipText,
    this.activateEditLabel,
    this.cancelEditLabel,
    this.submitEditLabel,
    this.submittingEditText,
    this.successfulEditLabel,
    this.expandButtonLabel,
    this.collapseButtonLabel,
  });

  final String Function(CsTableSelectionState<T> state)? allItemsSelectionLabel;
  final String Function(CsTableSelectionState<T> state, T item)? itemSelectionLabel;

  /// Label of the selection column header.
  final String? selectionGroupLabel;

  /// Names the table: "Instances" is announced as a table named Instances.
  final String? tableLabel;
  final String? resizerRoleDescription;
  final String? resizerTooltipText;
  final String Function(CsTableColumn<T> column, T item)? activateEditLabel;
  final String Function(CsTableColumn<T> column)? cancelEditLabel;
  final String Function(CsTableColumn<T> column)? submitEditLabel;
  final String Function(CsTableColumn<T> column)? submittingEditText;
  final String Function(CsTableColumn<T> column)? successfulEditLabel;
  final String Function(T item)? expandButtonLabel;
  final String Function(T item)? collapseButtonLabel;
}

/// Fixed copy used by [CsTable] (Cloudscape's table i18n messages).
@immutable
class CsTableI18nStrings {
  const CsTableI18nStrings({
    this.expandButtonLabel = 'Expand',
    this.collapseButtonLabel = 'Collapse',
    this.editIconAriaLabel = 'editable',
    this.errorIconAriaLabel = 'Error',
    this.submittingEditText = 'Submitting edit',
    this.successfulEditLabel = 'Edit successful',
    this.resizerRoleDescription = 'resize button',
    this.cancelEditLabel = 'Cancel',
    this.submitEditLabel = 'Submit',
    this.activateEditLabel = 'Edit',
    this.sortAscending = 'ascending',
    this.sortDescending = 'descending',
    this.notSorted = 'not sorted',
    this.selectAll = 'Select all',
    this.selectItem = 'Select item',
  });

  final String expandButtonLabel;
  final String collapseButtonLabel;
  final String editIconAriaLabel;
  final String errorIconAriaLabel;
  final String submittingEditText;
  final String successfulEditLabel;
  final String resizerRoleDescription;
  final String cancelEditLabel;
  final String submitEditLabel;
  final String activateEditLabel;
  final String sortAscending;
  final String sortDescending;
  final String notSorted;
  final String selectAll;
  final String selectItem;
}

/// Cloudscape's `Table`: rows of items in columns, with sorting, selection,
/// inline editing, expandable rows, resizable and sticky columns, and the
/// header, filter, pagination and preferences slots of a collection.
///
/// ```dart
/// CsTable<Instance>(
///   header: const CsHeader(title: 'Instances', counter: '(3)'),
///   items: instances,
///   trackBy: (i) => i.id,
///   selectionType: CsSelectionType.multi,
///   selectedItems: selected,
///   onSelectionChange: (next) => setState(() => selected = next),
///   columnDefinitions: [
///     CsTableColumn(id: 'id', header: 'Instance ID', cell: (context, i) => Text(i.id), isRowHeader: true),
///     CsTableColumn(id: 'state', header: 'State', cell: (context, i) => Text(i.state)),
///   ],
/// )
/// ```
///
/// The table is controlled: it shows [items] in the order given and reports
/// sorting, selection and expansion through callbacks. Pair it with
/// [CsCollection] to filter, sort and paginate a list in memory.
///
/// Inside a bounded height (an `Expanded`, a sized box) rows are built
/// lazily and the header can stay in place ([stickyHeader]). With an
/// unbounded height (inside a page that scrolls) every row is built.
///
/// On phones the table scrolls sideways with its first column stuck to the
/// start edge, or turns each row into a card with
/// `mobileLayout: CsTableMobileLayout.cards`.
class CsTable<T> extends StatefulWidget {
  const CsTable({
    super.key,
    required this.columnDefinitions,
    required this.items,
    this.header,
    this.footer,
    this.empty,
    this.filter,
    this.pagination,
    this.preferences,
    this.loading = false,
    this.loadingText,
    this.trackBy,
    this.cellVerticalAlign = CsTableVerticalAlign.middle,
    this.selectionType,
    this.selectedItems = const [],
    this.onSelectionChange,
    this.isItemDisabled,
    this.wrapLines = false,
    this.stripedRows = false,
    this.contentDensity = CsDensity.comfortable,
    this.resizableColumns = false,
    this.onColumnWidthsChange,
    this.ariaLabels,
    this.i18nStrings = const CsTableI18nStrings(),
    this.sortingColumn,
    this.sortingDescending = false,
    this.sortingDisabled = false,
    this.onSortingChange,
    this.stickyColumns = CsStickyColumns.none,
    this.columnDisplay,
    this.visibleColumns,
    this.onRowClick,
    this.onRowContextMenu,
    this.stickyHeader = false,
    this.stickyHeaderVerticalOffset = 0,
    this.variant = CsTableVariant.container,
    this.totalItemsCount,
    this.firstIndex,
    this.renderAriaLive,
    this.submitEdit,
    this.onEditCancel,
    this.enableKeyboardNavigation,
    this.expandableRows,
    this.getLoadingStatus,
    this.renderLoaderPending,
    this.renderLoaderLoading,
    this.renderLoaderError,
    this.renderLoaderEmpty,
    this.mobileLayout = CsTableMobileLayout.scroll,
    this.mobileStickyFirstColumn = true,
    this.scrollController,
  });

  final List<CsTableColumn<T>> columnDefinitions;

  /// The rows, in display order.
  final List<T> items;

  /// Heading of the table, usually a [CsHeader] with a counter and actions.
  final Widget? header;

  /// Content under the rows.
  final Widget? footer;

  /// Shown when [items] is empty and not [loading]: an empty or no-match
  /// state.
  final Widget? empty;

  /// Filtering controls (a text or property filter), above the columns.
  final Widget? filter;

  /// A pagination control, at the end of the tools row.
  final Widget? pagination;

  /// A [CsCollectionPreferences] trigger, after the pagination.
  final Widget? preferences;

  /// Replaces the rows with a loading indicator and [loadingText].
  final bool loading;
  final String? loadingText;

  /// Identity of an item. Without it items are compared with `==`.
  final CsTrackBy<T>? trackBy;
  final CsTableVerticalAlign cellVerticalAlign;

  /// Adds a selection column: checkboxes for multi, radios for single.
  final CsSelectionType? selectionType;
  final List<T> selectedItems;
  final ValueChanged<List<T>>? onSelectionChange;

  /// Disabled items cannot be selected.
  final bool Function(T item)? isItemDisabled;

  /// Wrap long cell text instead of truncating it with an ellipsis.
  final bool wrapLines;

  /// Shade every other row.
  final bool stripedRows;

  /// Compact tightens the rows (Cloudscape `contentDensity`).
  final CsDensity contentDensity;

  /// Columns get drag handles in the header to change their width.
  final bool resizableColumns;

  /// Called after a resize with the widths of all columns, in
  /// [columnDefinitions] order. Persist them and pass them back as
  /// [CsTableColumn.width].
  final ValueChanged<List<double>>? onColumnWidthsChange;
  final CsTableAriaLabels<T>? ariaLabels;
  final CsTableI18nStrings i18nStrings;

  /// The sorted column; one of [columnDefinitions] or a column with the same
  /// id or sorting field.
  final CsSortingColumn<T>? sortingColumn;
  final bool sortingDescending;

  /// Disables the sort buttons, for example while items load.
  final bool sortingDisabled;
  final ValueChanged<CsSortingState<T>>? onSortingChange;

  /// Columns that stay in place while scrolling sideways. They are released
  /// when fewer than 148px would be left to scroll, as in Cloudscape.
  final CsStickyColumns stickyColumns;

  /// Order and visibility of columns, usually from collection preferences.
  final List<CsColumnDisplay>? columnDisplay;

  /// Ids of visible columns. Cloudscape deprecated it in favor of
  /// [columnDisplay].
  final List<String>? visibleColumns;

  /// Called when a row is pressed. Cloudscape keeps this for backwards
  /// compatibility; prefer links or buttons inside cells.
  final ValueChanged<CsTableRowClickDetail<T>>? onRowClick;

  /// Called on a secondary click or a long press on a row.
  final ValueChanged<CsTableRowContextMenuDetail<T>>? onRowContextMenu;

  /// Keeps the header, tools and column headers in place while rows scroll.
  /// Needs a bounded height.
  final bool stickyHeader;

  /// Space kept above the stuck header.
  final double stickyHeaderVerticalOffset;
  final CsTableVariant variant;

  /// Total number of items across all pages, for screen readers.
  final int? totalItemsCount;

  /// One-based index of the first item shown, for screen readers.
  final int? firstIndex;

  /// Builds the message announced when the page of items changes.
  final String Function(CsLiveAnnouncement data)? renderAriaLive;

  /// Saves an inline edit. Return a future to keep the submit button busy
  /// until it completes; throw to keep the editor open.
  final FutureOr<void> Function(T item, CsTableColumn<T> column, Object? newValue)? submitEdit;

  /// Called when an inline edit is canceled.
  final VoidCallback? onEditCancel;

  /// Arrow keys move focus between cells. On by default for expandable
  /// rows.
  final bool? enableKeyboardNavigation;
  final CsTableExpandableRows<T>? expandableRows;

  /// Progressive loading state of the whole list (item null) and of each
  /// expanded item.
  final CsTableLoadingStatus Function(T? item)? getLoadingStatus;

  /// Content of the loader row while more items can be loaded, such as a
  /// "Load more" button.
  final Widget Function(T? item)? renderLoaderPending;
  final Widget Function(T? item)? renderLoaderLoading;
  final Widget Function(T? item)? renderLoaderError;

  /// Content shown under an expanded item that has no children.
  final Widget Function(T item)? renderLoaderEmpty;

  /// Layout on phones. Not part of Cloudscape, which has no phone layout.
  final CsTableMobileLayout mobileLayout;

  /// On phones with the scroll layout, stick the first column even when
  /// [stickyColumns] does not.
  final bool mobileStickyFirstColumn;

  /// Vertical scroll controller for the rows when the height is bounded.
  final ScrollController? scrollController;

  @override
  State<CsTable<T>> createState() => CsTableState<T>();
}

class _RowEntry<T> {
  const _RowEntry.data(this.item, {required this.level, required this.dataIndex, required this.topIndex})
    : loader = false,
      status = null,
      emptyParent = false;

  const _RowEntry.loader(this.item, {required this.level, required this.status, this.emptyParent = false})
    : loader = true,
      dataIndex = -1,
      topIndex = -1;

  final T? item;
  final int level;
  final bool loader;
  final CsTableLoadingStatus? status;
  final bool emptyParent;

  /// Position among data rows, for striping and neighbors.
  final int dataIndex;

  /// Index in [CsTable.items] for top-level rows; -1 for nested ones.
  final int topIndex;
}

typedef _CellKey = (Object?, String);

/// State of a [CsTable]. Reach it with a `GlobalKey<CsTableState<T>>` to
/// call [scrollToTop] or [cancelEdit] (Cloudscape `Table.Ref`).
class CsTableState<T> extends State<CsTable<T>> {
  final ScrollController _horizontal = ScrollController();
  ScrollController? _ownVertical;
  final Map<String, double> _resized = {};
  T? _anchor;
  bool _stuck = false;

  _CellKey? _editing;
  T? _editingItem;
  Object? _editValue;
  String? _editError;
  bool _submitting = false;
  _CellKey? _success;
  _CellKey? _reasonOpen;

  ScrollController get _vertical => widget.scrollController ?? (_ownVertical ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _vertical.addListener(_onVerticalScroll);
  }

  @override
  void didUpdateWidget(CsTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      (oldWidget.scrollController ?? _ownVertical)?.removeListener(_onVerticalScroll);
      _vertical.addListener(_onVerticalScroll);
    }
    final pageChanged =
        oldWidget.firstIndex != widget.firstIndex ||
        oldWidget.totalItemsCount != widget.totalItemsCount ||
        oldWidget.items.length != widget.items.length;
    if (pageChanged && widget.renderAriaLive != null && !widget.loading) {
      final first = widget.firstIndex ?? 1;
      final message = widget.renderAriaLive!(
        CsLiveAnnouncement(
          firstIndex: first,
          lastIndex: first + widget.items.length - 1,
          visibleItemsCount: widget.items.length,
          totalItemsCount: widget.totalItemsCount,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) csCollectionAnnounce(context, message);
      });
    }
  }

  @override
  void dispose() {
    _vertical.removeListener(_onVerticalScroll);
    _horizontal.dispose();
    _ownVertical?.dispose();
    super.dispose();
  }

  void _onVerticalScroll() {
    final stuck = _vertical.hasClients && _vertical.offset > 0;
    if (stuck != _stuck) setState(() => _stuck = stuck);
  }

  /// Scrolls the rows back to the first one.
  void scrollToTop() {
    if (_vertical.hasClients) {
      _vertical.animateTo(0, duration: CsMotion.duration(context, CsDurations.complex), curve: CsCurves.expressive);
    }
  }

  /// Closes the inline editor without saving, if one is open.
  void cancelEdit() {
    if (_editing == null) return;
    setState(_clearEdit);
    widget.onEditCancel?.call();
  }

  Object? _key(T item) => widget.trackBy == null ? item : widget.trackBy!(item);

  CsTableAriaLabels<T> get _labels => widget.ariaLabels ?? CsTableAriaLabels<T>();

  bool get _keyboardNav => widget.enableKeyboardNavigation ?? widget.expandableRows != null;

  List<CsTableColumn<T>> get _visibleColumns {
    final defs = widget.columnDefinitions;
    final display = widget.columnDisplay;
    if (display != null) {
      final byId = {for (final c in defs) c.columnId: c};
      return [
        for (final d in display)
          if (d.visible && byId[d.id] != null) byId[d.id]!,
      ];
    }
    final visible = widget.visibleColumns;
    if (visible != null) {
      return [
        for (final c in defs)
          if (visible.contains(c.columnId)) c,
      ];
    }
    return defs;
  }

  CsCollectionSelectionModel<T> get _selection => CsCollectionSelectionModel<T>(
    items: widget.items,
    selectedItems: widget.selectedItems,
    trackBy: widget.trackBy,
    isItemDisabled: widget.isItemDisabled,
  );

  bool _isExpanded(T item) {
    final rows = widget.expandableRows;
    if (rows == null) return false;
    final k = _key(item);
    return rows.expandedItems.any((e) => _key(e) == k);
  }

  List<_RowEntry<T>> _flatten() {
    final out = <_RowEntry<T>>[];
    var dataIndex = 0;
    final rows = widget.expandableRows;
    final status = widget.getLoadingStatus;

    void addLoader(T? parent, int level, {bool emptyParent = false}) {
      if (status == null && !emptyParent) return;
      final s = status?.call(parent) ?? CsTableLoadingStatus.finished;
      if (s != CsTableLoadingStatus.finished) {
        out.add(_RowEntry<T>.loader(parent, level: level, status: s));
      } else if (emptyParent && widget.renderLoaderEmpty != null) {
        out.add(_RowEntry<T>.loader(parent, level: level, status: s, emptyParent: true));
      }
    }

    void visit(T item, int level, int topIndex) {
      out.add(_RowEntry<T>.data(item, level: level, dataIndex: dataIndex++, topIndex: topIndex));
      if (rows != null && rows.isItemExpandable(item) && _isExpanded(item)) {
        final children = rows.getItemChildren(item);
        for (final child in children) {
          visit(child, level + 1, -1);
        }
        addLoader(item, level + 1, emptyParent: children.isEmpty);
      }
    }

    for (var i = 0; i < widget.items.length; i++) {
      visit(widget.items[i], 1, i);
    }
    addLoader(null, 1);
    return out;
  }

  void _toggleItem(T item, bool shift) {
    final type = widget.selectionType;
    if (type == null || widget.onSelectionChange == null) return;
    final next = _selection.toggle(item, type: type, shift: shift, anchor: _anchor);
    _anchor = item;
    widget.onSelectionChange!(next);
  }

  void _toggleAll() {
    widget.onSelectionChange?.call(_selection.toggleAll());
  }

  void _sortBy(CsTableColumn<T> column) {
    final sorted = column.sameSortAs(widget.sortingColumn);
    widget.onSortingChange?.call(
      CsSortingState<T>(sortingColumn: column, isDescending: sorted ? !widget.sortingDescending : false),
    );
  }

  void _clearEdit() {
    _editing = null;
    _editingItem = null;
    _editValue = null;
    _editError = null;
    _submitting = false;
  }

  void _startEdit(T item, CsTableColumn<T> column) {
    setState(() {
      _clearEdit();
      _success = null;
      _reasonOpen = null;
      _editing = (_key(item), column.columnId);
      _editingItem = item;
    });
  }

  void _cancelEditFromUser() {
    if (_editing == null) return;
    setState(_clearEdit);
    widget.onEditCancel?.call();
  }

  Future<void> _submitEdit(CsTableColumn<T> column) async {
    final item = _editingItem as T;
    final key = _editing;
    if (key == null || _submitting) return;
    final value = _editValue;
    if (value == null) {
      setState(_clearEdit);
      return;
    }
    final error = column.editConfig?.validation?.call(item, value);
    if (error != null) {
      setState(() => _editError = error);
      return;
    }
    final submit = widget.submitEdit;
    if (submit == null) {
      setState(_clearEdit);
      return;
    }
    setState(() => _submitting = true);
    csCollectionAnnounce(context, _labels.submittingEditText?.call(column) ?? widget.i18nStrings.submittingEditText);
    try {
      await submit(item, column, value);
      if (!mounted) return;
      setState(() {
        _clearEdit();
        _success = key;
      });
      csCollectionAnnounce(
        context,
        _labels.successfulEditLabel?.call(column) ?? widget.i18nStrings.successfulEditLabel,
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.cs;
    Widget table = Builder(builder: _buildBody);
    if (widget.contentDensity == CsDensity.compact) {
      table = CsTheme(
        data: theme.copyWith(density: CsDensity.compact, densityTokens: CsDensityTokens.compactTable),
        child: table,
      );
    }
    if (_keyboardNav) {
      table = Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
          SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
          SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
          SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
        },
        child: table,
      );
    }
    final total = widget.totalItemsCount;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: _labels.tableLabel,
      value: total == null ? null : '$total',
      child: FocusTraversalGroup(child: table),
    );
  }

  bool get _framed =>
      widget.variant == CsTableVariant.container ||
      widget.variant == CsTableVariant.stacked ||
      widget.variant == CsTableVariant.fullPage;

  Widget _buildBody(BuildContext context) {
    final narrow = context.csIsNarrow;
    if (narrow && widget.mobileLayout == CsTableMobileLayout.cards) return _buildCards(context);
    return _buildGrid(context);
  }

  Widget? _headerBlock(BuildContext context, {required bool inside}) {
    final cs = context.cs;
    final tools = _tools(context);
    if (widget.header == null && tools == null) return null;
    final fullPage = widget.variant == CsTableVariant.fullPage;
    final horizontal = inside && _framed
        ? CsSpace.tableHorizontal + CsSpace.tableHeaderHorizontal
        : CsSpace.tableHeaderHorizontal;
    final EdgeInsets padding;
    if (fullPage && !inside) {
      padding = EdgeInsets.only(bottom: cs.space.containerHeaderBottom + CsSpace.tableHeaderToolsFullPageBottom);
    } else if (_framed) {
      padding = EdgeInsets.fromLTRB(horizontal, CsSpace.containerHeaderTop, horizontal, cs.space.containerHeaderBottom);
    } else {
      padding = EdgeInsets.only(top: CsSpace.tableEmbeddedHeaderTop, bottom: cs.space.containerHeaderBottom);
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [?widget.header, ?tools],
      ),
    );
  }

  /// Cloudscape's tools row: the filter grows, pagination and preferences
  /// sit at the end separated by a divider. Below 600px the filter takes
  /// its own line.
  Widget? _tools(BuildContext context) {
    final filter = widget.filter;
    final pagination = widget.pagination;
    final preferences = widget.preferences;
    if (filter == null && pagination == null && preferences == null) return null;
    final c = context.cs.colors;
    final end = <Widget>[];
    if (pagination != null) end.add(pagination);
    if (preferences != null) {
      if (end.isNotEmpty) {
        end.add(
          Container(
            margin: const EdgeInsetsDirectional.only(start: CsSpace.xs, end: CsSpace.xs),
            width: CsBorderLine.dividerSectionWidth,
            height: CsFontTokens.lineHeightBodyM,
            color: c.borderDividerDefault,
          ),
        );
      }
      end.add(preferences);
    }
    return Padding(
      padding: EdgeInsets.only(
        top: widget.header != null ? context.cs.space.scaledXs : 0,
        bottom: CsSpace.tableHeaderToolsBottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final small = constraints.maxWidth < 600;
          final endRow = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: end,
          );
          if (filter == null) return Align(alignment: AlignmentDirectional.centerEnd, child: endRow);
          if (end.isEmpty) return filter;
          if (small) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: context.cs.space.scaledXs,
              children: [
                filter,
                Align(alignment: AlignmentDirectional.centerEnd, child: endRow),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: CsSpace.l,
            children: [
              Expanded(child: filter),
              endRow,
            ],
          );
        },
      ),
    );
  }

  Widget _frame(BuildContext context, Widget inner, {Widget? outsideHeader}) {
    final cs = context.cs;
    final c = cs.colors;
    Widget framed = inner;
    if (_framed) {
      final rounded = widget.variant != CsTableVariant.stacked;
      final radius = rounded ? BorderRadius.circular(CsBorderRadius.container) : BorderRadius.zero;
      framed = Container(
        decoration: BoxDecoration(color: c.backgroundContainerContent, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: c.borderDividerDefault, strokeAlign: BorderSide.strokeAlignInside),
        ),
        clipBehavior: Clip.antiAlias,
        child: inner,
      );
    }
    if (outsideHeader == null) return framed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            outsideHeader,
            if (bounded) Expanded(child: framed) else framed,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Grid layout

  Widget _buildGrid(BuildContext context) {
    final fullPage = widget.variant == CsTableVariant.fullPage;
    final outside = fullPage ? _headerBlock(context, inside: false) : null;
    final grid = LayoutBuilder(builder: (context, constraints) => _grid(context, constraints, fullPage));
    return _frame(context, grid, outsideHeader: outside);
  }

  Widget _grid(BuildContext context, BoxConstraints constraints, bool fullPage) {
    final cs = context.cs;
    final c = cs.colors;
    final columns = _visibleColumns;
    final selectable = widget.selectionType != null;
    final selW = selectable ? CsSize.tableSelectionHorizontal : 0.0;
    final pad = _framed ? CsSpace.tableHorizontal : 0.0;
    final mins = [for (final col in columns) col.minWidth ?? CsTableColumn.defaultMinWidth];
    final fixed = <double?>[];
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final last = i == columns.length - 1;
      if (widget.resizableColumns) {
        fixed.add(last ? null : (_resized[col.columnId] ?? col.width));
      } else {
        fixed.add(col.width);
      }
    }
    final maxes = [for (final col in columns) widget.resizableColumns ? null : col.maxWidth];
    final minTotal =
        selW + 2 * pad + [for (var i = 0; i < columns.length; i++) fixed[i] ?? mins[i]].fold(0.0, (a, b) => a + b);
    final viewport = constraints.hasBoundedWidth ? constraints.maxWidth : minTotal;
    final widths = csTableColumnWidths(
      fixed: fixed,
      min: [for (var i = 0; i < columns.length; i++) fixed[i] != null ? fixed[i]! : mins[i]],
      max: maxes,
      available: viewport - 2 * pad - selW,
    );
    final contentWidth = selW + widths.fold(0.0, (a, b) => a + b);
    final tableWidth = math.max(viewport, contentWidth + 2 * pad);
    final scrolls = tableWidth > viewport + 0.5;
    final controller = scrolls ? _horizontal : null;

    // Sticky columns.
    var first = widget.stickyColumns.first;
    if (context.csIsNarrow && widget.mobileStickyFirstColumn && first == 0) first = 1;
    first = math.min(first, columns.length);
    final last = math.min(widget.stickyColumns.last, columns.length - first);
    var stickyWidth = (first > 0 ? selW : 0.0);
    for (var i = 0; i < first; i++) {
      stickyWidth += widths[i];
    }
    for (var i = columns.length - last; i < columns.length; i++) {
      stickyWidth += widths[i];
    }
    final stickyOn = scrolls && stickyWidth + 148 <= viewport;
    final pins = <CsTablePin?>[
      if (selectable) stickyOn && first > 0 ? CsTablePin.start : null,
      for (var i = 0; i < columns.length; i++)
        !stickyOn
            ? null
            : i < first
            ? CsTablePin.start
            : i >= columns.length - last
            ? CsTablePin.end
            : null,
    ];
    final cellWidths = [if (selectable) selW, ...widths];

    final geometry = _Geometry<T>(
      columns: columns,
      widths: cellWidths,
      pins: pins,
      controller: controller,
      pad: pad,
      viewport: viewport,
      tableWidth: tableWidth,
    );

    final headerBlock = fullPage ? null : _headerBlock(context, inside: true);
    Widget pin(Widget child) =>
        CsTableViewportPin(controller: controller, viewportWidth: viewport, contentWidth: tableWidth, child: child);

    final columnHeader = _columnHeader(context, geometry);
    final rows = (widget.loading || widget.items.isEmpty) ? <_RowEntry<T>>[] : _flatten();
    final hasFooter = widget.footer != null;
    final footer = hasFooter
        ? pin(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: pad + CsSpace.tableFooterHorizontal,
                vertical: cs.space.scaledS,
              ),
              child: widget.footer,
            ),
          )
        : null;
    Widget? state;
    if (widget.loading) {
      state = _mergedCell(
        context,
        CsStatusIndicator(type: CsStatusType.loading, text: widget.loadingText ?? context.csStrings.loading),
        hasFooter,
      );
    } else if (widget.items.isEmpty) {
      state = _mergedCell(context, widget.empty ?? const SizedBox.shrink(), hasFooter);
    }

    final bottomPad = !hasFooter && _framed ? CsSpace.tableContentBottom : 0.0;
    final bounded = constraints.hasBoundedHeight;

    Widget rowAt(int i) => _bodyRow(context, geometry, rows, i, hasFooter);

    final header = DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: widget.stickyHeader && _stuck ? cs.shadows.stickyEmbedded : null,
        color: _framed ? c.backgroundContainerContent : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [if (headerBlock != null) pin(headerBlock), columnHeader],
      ),
    );

    Widget body;
    if (state != null) {
      body = Column(
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (bounded) Expanded(child: SingleChildScrollView(child: pin(state))) else pin(state),
          ?footer,
          SizedBox(height: bottomPad),
        ],
      );
    } else if (bounded) {
      final sticky = widget.stickyHeader;
      final extra = (sticky ? 0 : 1) + 1;
      final list = ListView.builder(
        controller: _vertical,
        padding: EdgeInsets.zero,
        itemCount: rows.length + extra,
        itemBuilder: (context, i) {
          if (!sticky && i == 0) return header;
          final index = sticky ? i : i - 1;
          if (index >= rows.length) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?footer,
                SizedBox(height: bottomPad),
              ],
            );
          }
          return rowAt(index);
        },
      );
      body = sticky
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: widget.stickyHeaderVerticalOffset),
                header,
                Expanded(child: list),
              ],
            )
          : list;
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          for (var i = 0; i < rows.length; i++) rowAt(i),
          ?footer,
          SizedBox(height: bottomPad),
        ],
      );
    }
    body = SizedBox(width: tableWidth, height: bounded ? constraints.maxHeight : null, child: body);
    if (!scrolls) return body;
    return SingleChildScrollView(controller: _horizontal, scrollDirection: Axis.horizontal, child: body);
  }

  /// The loading and empty states: one cell across the table, centered in
  /// the viewport (Cloudscape `cell-merged`).
  Widget _mergedCell(BuildContext context, Widget child, bool hasFooter) {
    final cs = context.cs;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: hasFooter ? Border(bottom: BorderSide(color: cs.colors.borderDividerDefault)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(CsSpace.l, cs.space.scaledM, CsSpace.l, cs.space.scaledL),
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: cs.colors.textEmpty),
            textAlign: TextAlign.center,
            child: child,
          ),
        ),
      ),
    );
  }

  EdgeInsetsDirectional _cellPadding(BuildContext context, int columnIndex, int columnCount, {required bool header}) {
    final cs = context.cs;
    final h = CsSpace.s + cs.space.scaledXs;
    final first = columnIndex == 0 && widget.selectionType == null;
    final start = first ? (widget.stripedRows ? CsSpace.xxs : CsSpace.xxxs) + CsBorderWidth.itemSelected : h;
    return EdgeInsetsDirectional.only(start: start, end: h);
  }

  Widget _columnHeader(BuildContext context, _Geometry<T> g) {
    final cs = context.cs;
    final c = cs.colors;
    final transparent = widget.variant == CsTableVariant.embedded || widget.variant == CsTableVariant.borderless;
    final background = transparent ? null : c.backgroundTableHeader;
    final cells = <Widget>[];
    final model = _selection;
    if (widget.selectionType != null) {
      if (widget.selectionType == CsSelectionType.multi) {
        final all = model.allSelected;
        final some = model.someSelected;
        final state = CsTableSelectionState<T>(
          selectedItems: widget.selectedItems,
          itemsCount: widget.expandableRows?.totalItemsCount ?? widget.totalItemsCount,
          selectedItemsCount: widget.expandableRows?.totalSelectedItemsCount ?? widget.selectedItems.length,
        );
        cells.add(
          CsCollectionSelectionControl(
            selectionType: CsSelectionType.multi,
            checked: all,
            indeterminate: some && !all,
            disabled: widget.items.isEmpty || widget.loading,
            semanticLabel: _labels.allItemsSelectionLabel?.call(state) ?? widget.i18nStrings.selectAll,
            width: CsSize.tableSelectionHorizontal,
            onChange: widget.onSelectionChange == null ? null : (_) => _toggleAll(),
          ),
        );
      } else {
        cells.add(
          Semantics(
            label: _labels.selectionGroupLabel,
            child: const SizedBox(width: CsSize.tableSelectionHorizontal),
          ),
        );
      }
    }
    for (var i = 0; i < g.columns.length; i++) {
      final col = g.columns[i];
      final cellIndex = i + (widget.selectionType != null ? 1 : 0);
      cells.add(
        _HeaderCell<T>(
          column: col,
          padding: _cellPadding(context, i, g.columns.length, header: true),
          sorted: col.sameSortAs(widget.sortingColumn),
          descending: widget.sortingDescending,
          sortingDisabled: widget.sortingDisabled || widget.onSortingChange == null,
          onSort: () => _sortBy(col),
          showDivider: i < g.columns.length - 1,
          resizable: widget.resizableColumns && i < g.columns.length - 1,
          width: g.widths[cellIndex],
          wrapLines: widget.wrapLines,
          i18n: widget.i18nStrings,
          resizerRoleDescription: _labels.resizerRoleDescription ?? widget.i18nStrings.resizerRoleDescription,
          resizerTooltip: _labels.resizerTooltipText,
          onResize: (w) =>
              setState(() => _resized[col.columnId] = math.max(w, col.minWidth ?? CsTableColumn.defaultMinWidth)),
          onResizeEnd: () => _reportWidths(g),
          editable: col.editConfig != null,
          expandableOffset: i == 0 && widget.expandableRows != null,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: g.pad),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(color: c.borderDividerDefault, width: CsBorderLine.dividerListWidth),
          ),
        ),
        child: CsTableRowLayout(
          widths: g.widths,
          pins: g.pins,
          controller: g.controller,
          background: background ?? c.backgroundContainerContent,
          textDirection: Directionality.of(context),
          padStart: g.pad,
          shadowFirst: cs.shadows.stickyColumnFirst,
          shadowLast: cs.shadows.stickyColumnLast,
          children: cells,
        ),
      ),
    );
  }

  void _reportWidths(_Geometry<T> g) {
    final cb = widget.onColumnWidthsChange;
    if (cb == null) return;
    final offset = widget.selectionType != null ? 1 : 0;
    final current = <String, double>{};
    for (var i = 0; i < g.columns.length; i++) {
      current[g.columns[i].columnId] = g.widths[i + offset];
    }
    cb([
      for (final col in widget.columnDefinitions)
        _resized[col.columnId] ?? current[col.columnId] ?? col.width ?? col.minWidth ?? CsTableColumn.defaultMinWidth,
    ]);
  }

  Widget _bodyRow(BuildContext context, _Geometry<T> g, List<_RowEntry<T>> rows, int index, bool hasFooter) {
    final entry = rows[index];
    if (entry.loader) return _loaderRow(context, g, entry);
    final cs = context.cs;
    final c = cs.colors;
    final item = entry.item as T;
    final model = _selection;
    final selected = widget.selectionType != null && model.isSelected(item);
    bool selectedAt(int j) {
      if (widget.selectionType == null || j < 0 || j >= rows.length || rows[j].loader) return false;
      return model.isSelected(rows[j].item as T);
    }

    final prevSelected = selected && selectedAt(index - 1);
    final nextSelected = selected && selectedAt(index + 1);
    final shaded = widget.stripedRows && entry.dataIndex.isOdd;
    final isLast = index == rows.length - 1;
    final background = selected ? c.backgroundItemSelected : (shaded ? c.backgroundCellShaded : null);
    final Color? divider = isLast
        ? (hasFooter ? c.borderDividerDefault : null)
        : (widget.stripedRows ? c.borderCellShaded : c.borderDividerSecondary);

    final cells = <Widget>[];
    if (widget.selectionType != null) {
      final disabled = model.isDisabled(item);
      final state = CsTableSelectionState<T>(
        selectedItems: widget.selectedItems,
        itemsCount: widget.expandableRows?.getItemsCount?.call(item),
        selectedItemsCount: widget.expandableRows?.getSelectedItemsCount?.call(item),
      );
      cells.add(
        CsCollectionSelectionControl(
          selectionType: widget.selectionType!,
          checked: selected,
          disabled: disabled,
          semanticLabel: _labels.itemSelectionLabel?.call(state, item) ?? widget.i18nStrings.selectItem,
          width: CsSize.tableSelectionHorizontal,
          alignment: (widget.cellVerticalAlign == CsTableVerticalAlign.top) ? const Alignment(0, -1) : Alignment.center,
          onChange: widget.onSelectionChange == null ? null : (shift) => _toggleItem(item, shift),
        ),
      );
    }
    for (var i = 0; i < g.columns.length; i++) {
      cells.add(_bodyCell(context, g, entry, item, i));
    }

    const radius = Radius.circular(CsBorderRadius.item);
    Widget row = CsTableRowLayout(
      widths: g.widths,
      pins: g.pins,
      controller: g.controller,
      background: background ?? c.backgroundContainerContent,
      textDirection: Directionality.of(context),
      padStart: g.pad,
      shadowFirst: cs.shadows.stickyColumnFirst,
      shadowLast: cs.shadows.stickyColumnLast,
      children: cells,
    );
    row = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: selected
            ? BorderRadius.only(
                topLeft: prevSelected ? Radius.zero : radius,
                topRight: prevSelected ? Radius.zero : radius,
                bottomLeft: nextSelected ? Radius.zero : radius,
                bottomRight: nextSelected ? Radius.zero : radius,
              )
            : null,
      ),
      child: CustomPaint(
        foregroundPainter: CsTableRowDecorationPainter(
          divider: divider,
          dividerWidth: CsBorderLine.dividerListWidth,
          selected: selected,
          prevSelected: prevSelected,
          nextSelected: nextSelected,
          selectedColor: c.borderItemSelected,
          placeholderColor: c.borderItemPlaceholder,
          radius: CsBorderRadius.item,
          selectedWidth: CsBorderWidth.itemSelected,
        ),
        child: row,
      ),
    );

    final rowClick = widget.onRowClick;
    if (rowClick != null) {
      final rowIndex = entry.topIndex >= 0 ? entry.topIndex : entry.dataIndex;
      final inner = row;
      row = CsPressable(
        onPress: () => rowClick(CsTableRowClickDetail(rowIndex: rowIndex, item: item)),
        scaleOnPress: false,
        isButton: false,
        mergeChildSemantics: false,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        borderRadius: const BorderRadius.all(radius),
        child: inner,
      );
    }
    final contextMenu = widget.onRowContextMenu;
    if (contextMenu != null) {
      final rowIndex = entry.topIndex >= 0 ? entry.topIndex : entry.dataIndex;
      row = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapUp: (d) =>
            contextMenu(CsTableRowContextMenuDetail(rowIndex: rowIndex, item: item, position: d.globalPosition)),
        onLongPressStart: (d) =>
            contextMenu(CsTableRowContextMenuDetail(rowIndex: rowIndex, item: item, position: d.globalPosition)),
        child: row,
      );
    }
    return Semantics(
      key: ValueKey<Object?>(('row', _key(item), entry.level)),
      container: true,
      selected: widget.selectionType != null ? selected : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: g.pad),
        child: row,
      ),
    );
  }

  Widget _loaderRow(BuildContext context, _Geometry<T> g, _RowEntry<T> entry) {
    final cs = context.cs;
    final item = entry.item;
    Widget? content;
    if (entry.emptyParent) {
      content = widget.renderLoaderEmpty?.call(item as T);
    } else {
      content = switch (entry.status) {
        CsTableLoadingStatus.pending => widget.renderLoaderPending?.call(item),
        CsTableLoadingStatus.loading =>
          widget.renderLoaderLoading?.call(item) ??
              CsStatusIndicator(type: CsStatusType.loading, text: widget.loadingText ?? context.csStrings.loading),
        CsTableLoadingStatus.error => widget.renderLoaderError?.call(item),
        _ => null,
      };
    }
    if (content == null) return const SizedBox.shrink();
    final selOffset = widget.selectionType != null ? CsSize.tableSelectionHorizontal : 0.0;
    final indent = widget.expandableRows != null ? entry.level * _levelIndent : 0.0;
    final start = selOffset + _cellPadding(context, 0, 1, header: false).start + indent;
    return CsTableViewportPin(
      controller: g.controller,
      viewportWidth: g.viewport,
      contentWidth: g.tableWidth,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: g.pad + start,
          end: g.pad,
          top: cs.space.tableCellVertical,
          bottom: cs.space.tableCellVertical,
        ),
        child: Align(alignment: AlignmentDirectional.centerStart, child: content),
      ),
    );
  }

  /// Cloudscape `$cell-offset`: one nesting level of expandable rows.
  static const double _levelIndent = CsSpace.m + CsSpace.xs;

  Widget _bodyCell(BuildContext context, _Geometry<T> g, _RowEntry<T> entry, T item, int columnIndex) {
    final cs = context.cs;
    final col = g.columns[columnIndex];
    final align = col.verticalAlign ?? widget.cellVerticalAlign;
    final padding = _cellPadding(context, columnIndex, g.columns.length, header: false);
    final vertical = cs.space.tableCellVertical + CsBorderLine.dividerListWidth;
    final key = (_key(item), col.columnId);
    final editing = _editing == key;
    final alignment = align == CsTableVerticalAlign.top
        ? AlignmentDirectional.topStart
        : AlignmentDirectional.centerStart;

    Widget content;
    if (editing) {
      content = _editingCell(context, col, item);
    } else {
      Widget cell = Builder(builder: (context) => col.cell(context, item));
      final counter = col.counter?.call(
        CsTableItemCounterData<T>(
          item: item,
          itemsCount: widget.expandableRows?.getItemsCount?.call(item),
          selectedItemsCount: widget.expandableRows?.getSelectedItemsCount?.call(item),
        ),
      );
      if (counter != null) {
        cell = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CsSpace.xxs,
          children: [
            Flexible(child: cell),
            DefaultTextStyle.merge(
              style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
              child: counter,
            ),
          ],
        );
      }
      cell = DefaultTextStyle.merge(
        style: cs.body,
        maxLines: widget.wrapLines ? null : 1,
        overflow: widget.wrapLines ? null : TextOverflow.ellipsis,
        softWrap: widget.wrapLines,
        child: cell,
      );
      if (col.isRowHeader) cell = Semantics(header: true, child: cell);
      content = Padding(
        padding: EdgeInsets.only(top: vertical, bottom: vertical),
        child: Align(alignment: alignment, widthFactor: 1, heightFactor: 1, child: cell),
      );
    }

    // Expand toggle and indentation in the first column.
    final rows = widget.expandableRows;
    if (columnIndex == 0 && rows != null) {
      final expandable = rows.isItemExpandable(item);
      final indent = (entry.level - 1) * _levelIndent;
      Widget toggle = const SizedBox(width: _levelIndent);
      if (expandable) {
        final expanded = _isExpanded(item);
        toggle = _ExpandToggle(
          expanded: expanded,
          label: expanded
              ? (_labels.collapseButtonLabel?.call(item) ?? widget.i18nStrings.collapseButtonLabel)
              : (_labels.expandButtonLabel?.call(item) ?? widget.i18nStrings.expandButtonLabel),
          onPress: () => rows.onExpandableItemToggle(item, !expanded),
        );
      }
      content = Row(
        crossAxisAlignment: align == CsTableVerticalAlign.top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: indent),
          Padding(
            padding: EdgeInsets.only(top: align == CsTableVerticalAlign.top ? vertical : 0),
            child: toggle,
          ),
          Expanded(child: content),
        ],
      );
    }

    final edit = col.editConfig;
    if (edit != null && !editing) {
      return _editableCell(context, col, item, edit, content, padding, key, columnIndex == g.columns.length - 1);
    }
    return Padding(
      padding: editing ? const EdgeInsetsDirectional.symmetric(horizontal: CsSpace.xxs) : padding,
      child: content,
    );
  }

  Widget _editableCell(
    BuildContext context,
    CsTableColumn<T> col,
    T item,
    CsTableEditConfig<T> edit,
    Widget content,
    EdgeInsetsDirectional padding,
    _CellKey key,
    bool lastColumn,
  ) {
    final cs = context.cs;
    final c = cs.colors;
    final reason = edit.disabledReason?.call(item);
    final success = _success == key;
    final editLabel =
        _labels.activateEditLabel?.call(col, item) ??
        '${widget.i18nStrings.activateEditLabel} ${col.header ?? ''}'.trim();
    return CsPressable(
      onPress: () {
        if (reason != null) {
          setState(() => _reasonOpen = _reasonOpen == key ? null : key);
        } else {
          _startEdit(item, col);
        }
      },
      scaleOnPress: false,
      minTapTargetSize: 0,
      focusRingOffset: -2,
      borderRadius: BorderRadius.circular(CsBorderRadius.item),
      semanticLabel: editLabel,
      semanticHint: reason,
      mergeChildSemantics: false,
      builder: (context, state) {
        final active = state.hovered || state.focused || _reasonOpen == key;
        final iconColor = reason != null
            ? c.textDisabledInlineEdit
            : state.pressed
            ? c.textButtonNormalActive
            : state.hovered
            ? c.textButtonNormalHover
            : c.textButtonNormalDefault;
        Widget icon = CsIcon(
          reason != null ? CsIcons.lockPrivate : CsIcons.edit,
          dangerouslySetColor: iconColor,
          semanticLabel: edit.editIconAriaLabel ?? widget.i18nStrings.editIconAriaLabel,
        );
        if (reason != null) {
          icon = CsTooltip(
            content: reason,
            open: _reasonOpen == key ? true : null,
            onOpenChange: (open) {
              if (!open && _reasonOpen == key) setState(() => _reasonOpen = null);
            },
            child: icon,
          );
        }
        return Container(
          decoration: active && reason == null
              ? BoxDecoration(
                  color: c.backgroundDropdownItemHover,
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                )
              : null,
          foregroundDecoration: active && reason == null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                  border: Border.all(color: c.borderEditableCellHover, strokeAlign: BorderSide.strokeAlignInside),
                )
              : null,
          child: Stack(
            children: [
              Padding(
                padding: padding.copyWith(end: widget.resizableColumns ? padding.end : padding.end + CsSpace.l),
                child: content,
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: CsSpace.xs + CsSpace.xxs - CsSpace.xxs,
                child: Center(
                  child: success
                      ? CsIcon(
                          CsIcons.statusPositive,
                          variant: CsIconVariant.success,
                          semanticLabel:
                              _labels.successfulEditLabel?.call(col) ?? widget.i18nStrings.successfulEditLabel,
                        )
                      : Opacity(opacity: active || _reasonOpen == key ? 1 : 0, child: icon),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _editingCell(BuildContext context, CsTableColumn<T> col, T item) {
    final cs = context.cs;
    final edit = col.editConfig!;
    final ctx = CsTableCellContext(
      currentValue: _editValue,
      setValue: (v) => setState(() {
        _editValue = v;
        _editError = edit.validation?.call(item, v);
      }),
      submitValue: () => _submitEdit(col),
    );
    final editor = CsFormField(
      label: edit.ariaLabel ?? col.header,
      labelHidden: true,
      stretch: true,
      errorText: _editError,
      constraintText: edit.constraintText,
      errorIconAriaLabel: edit.errorIconAriaLabel ?? widget.i18nStrings.errorIconAriaLabel,
      child: Builder(builder: (context) => edit.editingCell(context, item, ctx)),
    );
    return TapRegion(
      onTapOutside: (_) => _cancelEditFromUser(),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _cancelEditFromUser,
          const SingleActivator(LogicalKeyboardKey.enter): () => _submitEdit(col),
        },
        child: FocusTraversalGroup(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxxs + CsSpace.xxxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CsSpace.xxs,
              children: [
                Expanded(child: editor),
                SizedBox(
                  height: cs.space.sizeVerticalInput,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_submitting)
                        CsButton(
                          icon: CsIcons.close,
                          variant: CsButtonVariant.inlineIcon,
                          semanticLabel: _labels.cancelEditLabel?.call(col) ?? widget.i18nStrings.cancelEditLabel,
                          onPress: _cancelEditFromUser,
                        ),
                      const SizedBox(width: CsSpace.xxs),
                      if (_submitting)
                        CsSpinner(semanticLabel: widget.i18nStrings.submittingEditText)
                      else
                        CsButton(
                          icon: CsIcons.check,
                          variant: CsButtonVariant.inlineIcon,
                          semanticLabel: _labels.submitEditLabel?.call(col) ?? widget.i18nStrings.submitEditLabel,
                          onPress: () => _submitEdit(col),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Phone card layout

  Widget _buildCards(BuildContext context) {
    final cs = context.cs;
    final columns = _visibleColumns;
    final headerColumn = columns.where((c) => c.isRowHeader).firstOrNull ?? columns.firstOrNull;
    final model = _selection;
    final headerBlock = _headerBlock(context, inside: true);

    Widget card(T item, int index) {
      final selected = widget.selectionType != null && model.isSelected(item);
      final disabled = model.isDisabled(item);
      Widget? selection;
      if (widget.selectionType != null) {
        final state = CsTableSelectionState<T>(selectedItems: widget.selectedItems);
        selection = CsCollectionSelectionControl(
          selectionType: widget.selectionType!,
          checked: selected,
          disabled: disabled,
          semanticLabel: _labels.itemSelectionLabel?.call(state, item) ?? widget.i18nStrings.selectItem,
          onChange: widget.onSelectionChange == null ? null : (shift) => _toggleItem(item, shift),
        );
        selection = Padding(padding: const EdgeInsets.all(CsSpace.xxs), child: selection);
      }
      final rest = [
        for (final col in columns)
          if (col != headerColumn) col,
      ];
      return CsItemCard(
        key: ValueKey<Object?>(('card', _key(item))),
        highlighted: selected,
        header: headerColumn == null ? null : Builder(builder: (context) => headerColumn.cell(context, item)),
        actions: selection,
        onPress: widget.onRowClick == null
            ? null
            : () => widget.onRowClick!(CsTableRowClickDetail(rowIndex: index, item: item)),
        child: rest.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xs,
                children: [
                  for (final col in rest)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (col.cardLabel != null || col.header != null)
                          Text(
                            col.cardLabel ?? col.header!,
                            style: cs.text(CsTypeScale.bodyM, weight: FontWeight.w700, color: CsColor.textLabel),
                          )
                        else if (col.headerWidget != null)
                          DefaultTextStyle.merge(
                            style: cs.text(CsTypeScale.bodyM, weight: FontWeight.w700, color: CsColor.textLabel),
                            child: col.headerWidget!,
                          ),
                        DefaultTextStyle.merge(
                          style: cs.body,
                          child: Builder(builder: (context) => col.cell(context, item)),
                        ),
                      ],
                    ),
                ],
              ),
      );
    }

    Widget? state;
    if (widget.loading) {
      state = _mergedCell(
        context,
        CsStatusIndicator(type: CsStatusType.loading, text: widget.loadingText ?? context.csStrings.loading),
        false,
      );
    } else if (widget.items.isEmpty) {
      state = _mergedCell(context, widget.empty ?? const SizedBox.shrink(), false);
    }

    Widget? selectAll;
    if (widget.selectionType == CsSelectionType.multi && widget.items.isNotEmpty && !widget.loading) {
      final all = model.allSelected;
      selectAll = Padding(
        padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs, bottom: CsSpace.xs),
        child: Row(
          spacing: CsSpace.xs,
          children: [
            CsCollectionSelectionControl(
              selectionType: CsSelectionType.multi,
              checked: all,
              indeterminate: model.someSelected && !all,
              semanticLabel: widget.i18nStrings.selectAll,
              onChange: widget.onSelectionChange == null ? null : (_) => _toggleAll(),
            ),
            ExcludeSemantics(
              child: Text(
                widget.i18nStrings.selectAll,
                style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
              ),
            ),
          ],
        ),
      );
    }

    final pad = _framed ? CsSpace.tableHorizontal : 0.0;
    return _frame(
      context,
      LayoutBuilder(
        builder: (context, constraints) {
          final children = <Widget>[
            ?headerBlock,
            ?state,
            if (state == null) ...[
              if (selectAll != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: selectAll,
                ),
              for (var i = 0; i < widget.items.length; i++)
                Padding(padding: EdgeInsets.fromLTRB(pad, 0, pad, CsSpace.s), child: card(widget.items[i], i)),
            ],
            if (widget.footer != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: cs.space.scaledS),
                child: widget.footer,
              ),
          ];
          if (constraints.hasBoundedHeight) {
            return ListView(controller: _vertical, padding: EdgeInsets.zero, children: children);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      ),
      outsideHeader: null,
    );
  }
}

class _Geometry<T> {
  const _Geometry({
    required this.columns,
    required this.widths,
    required this.pins,
    required this.controller,
    required this.pad,
    required this.viewport,
    required this.tableWidth,
  });

  final List<CsTableColumn<T>> columns;
  final List<double> widths;
  final List<CsTablePin?> pins;
  final ScrollController? controller;
  final double pad;
  final double viewport;
  final double tableWidth;
}

/// The expand toggle of an expandable row: a filled caret that turns from
/// pointing sideways to pointing down.
class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({required this.expanded, required this.label, required this.onPress});

  final bool expanded;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CsPressable(
      onPress: onPress,
      expanded: expanded,
      semanticLabel: label,
      scaleOnPress: false,
      minTapTargetSize: 0,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) => SizedBox(
        width: CsTableState._levelIndent,
        height: CsFontTokens.lineHeightBodyM,
        child: Center(
          child: AnimatedRotation(
            turns: expanded ? 0 : (rtl ? 0.25 : -0.25),
            duration: CsMotion.duration(context, CsDurations.rotate90),
            curve: CsCurves.rotate90,
            child: CsIcon(
              CsIcons.caretDownFilled,
              size: CsIconSize.small,
              dangerouslySetColor: state.hovered
                  ? context.cs.colors.textInteractiveHover
                  : context.cs.colors.textInteractiveDefault,
            ),
          ),
        ),
      ),
    );
  }
}

/// A column header: the label, the sort button and icon, the divider and
/// the resize handle.
class _HeaderCell<T> extends StatefulWidget {
  const _HeaderCell({
    required this.column,
    required this.padding,
    required this.sorted,
    required this.descending,
    required this.sortingDisabled,
    required this.onSort,
    required this.showDivider,
    required this.resizable,
    required this.width,
    required this.wrapLines,
    required this.i18n,
    required this.resizerRoleDescription,
    required this.resizerTooltip,
    required this.onResize,
    required this.onResizeEnd,
    required this.editable,
    required this.expandableOffset,
  });

  final CsTableColumn<T> column;
  final EdgeInsetsDirectional padding;
  final bool sorted;
  final bool descending;
  final bool sortingDisabled;
  final VoidCallback onSort;
  final bool showDivider;
  final bool resizable;
  final double width;
  final bool wrapLines;
  final CsTableI18nStrings i18n;
  final String resizerRoleDescription;
  final String? resizerTooltip;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;
  final bool editable;
  final bool expandableOffset;

  @override
  State<_HeaderCell<T>> createState() => _HeaderCellState<T>();
}

class _HeaderCellState<T> extends State<_HeaderCell<T>> {
  bool _resizerActive = false;
  bool _resizerHover = false;
  bool _resizerFocused = false;
  double _dragStartWidth = 0;
  double _dragDistance = 0;

  /// Cloudscape moves a focused resizer by 10px per arrow key press.
  static const double _keyboardStep = 10;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final col = widget.column;
    final sortable = col.isSortable;
    final interactive = sortable && !widget.sortingDisabled;
    final sortIcon = widget.sorted
        ? (widget.descending ? CsIcons.caretDownFilled : CsIcons.caretUpFilled)
        : (interactive ? CsIcons.caretDown : null);
    final labelData = CsTableLabelData(sorted: widget.sorted, descending: widget.descending, disabled: !interactive);
    final semanticLabel = col.ariaLabel?.call(labelData) ?? col.header;

    Widget build(CsPressState? state) {
      final hot = interactive && (widget.sorted || (state?.hovered ?? false));
      final color = hot ? CsColor.textInteractiveActive : CsColor.textColumnHeader;
      final style = cs.text(CsTypeScale.headingXs, color: color);
      Widget label =
          col.headerWidget ??
          Text(
            col.header!,
            maxLines: widget.wrapLines ? null : 1,
            overflow: widget.wrapLines ? null : TextOverflow.ellipsis,
            softWrap: widget.wrapLines,
          );
      label = DefaultTextStyle.merge(style: style, child: label);
      if (widget.editable) {
        label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: label),
            Padding(
              padding: EdgeInsetsDirectional.only(start: CsSpace.xxs, top: cs.space.scaledXxs),
              child: CsIcon(CsIcons.edit, size: CsIconSize.small, dangerouslySetColor: cs.color(color)),
            ),
          ],
        );
      }
      final iconColor = widget.sorted
          ? (interactive ? c.textInteractiveActive : c.textInteractiveDisabled)
          : (hot ? c.textInteractiveActive : c.textColumnSortingIcon);
      final vertical = cs.space.scaledXxs * 2 + CsSpace.xxxs / 2;
      return Padding(
        padding: EdgeInsetsDirectional.only(
          start: widget.padding.start + (widget.expandableOffset ? CsSpace.m + CsSpace.xs : 0),
          end: sortIcon != null ? CsSpace.xs + CsSpace.xxs : widget.padding.end,
          top: vertical,
          bottom: vertical,
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: AlignmentDirectional.centerStart, child: label),
            ),
            if (sortIcon != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                child: CsIcon(sortIcon, dangerouslySetColor: iconColor),
              ),
          ],
        ),
      );
    }

    Widget cell;
    if (interactive) {
      cell = CsPressable(
        onPress: widget.onSort,
        scaleOnPress: false,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        semanticLabel: semanticLabel,
        semanticValue: widget.sorted
            ? (widget.descending ? widget.i18n.sortDescending : widget.i18n.sortAscending)
            : widget.i18n.notSorted,
        excludeChildSemantics: semanticLabel != null,
        builder: (context, state) => build(state),
      );
    } else {
      cell = Semantics(header: true, label: col.ariaLabel?.call(labelData), child: build(null));
    }

    final showActive = _resizerActive || _resizerHover || _resizerFocused;
    final children = <Widget>[cell];
    if (widget.showDivider || widget.resizable) {
      // Cloudscape `$divider-block-gap`: the divider stops short of the
      // cell edges by 2 x 8px + 2px.
      const gap = 2 * CsSpace.xs + CsSpace.xxxs;
      children.add(
        PositionedDirectional(
          end: 0,
          top: gap / 2,
          bottom: gap / 2,
          child: IgnorePointer(
            child: Container(
              width: showActive ? 2 : CsBorderLine.dividerListWidth,
              color: showActive
                  ? c.borderDividerActive
                  : (widget.resizable ? c.borderDividerInteractiveDefault : c.borderDividerDefault),
            ),
          ),
        ),
      );
    }
    if (widget.resizable) {
      children.add(PositionedDirectional(end: 0, top: 0, bottom: 0, width: CsSpace.m, child: _resizer(context)));
    }
    return Stack(children: children);
  }

  Widget _resizer(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final col = widget.column;
    Widget handle = MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _resizerHover = true),
      onExit: (_) => setState(() => _resizerHover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => setState(() {
          _resizerActive = true;
          _dragStartWidth = widget.width;
          _dragDistance = 0;
        }),
        onHorizontalDragUpdate: (d) {
          _dragDistance += rtl ? -d.delta.dx : d.delta.dx;
          widget.onResize(_dragStartWidth + _dragDistance);
        },
        onHorizontalDragEnd: (_) {
          setState(() => _resizerActive = false);
          widget.onResizeEnd();
        },
        onHorizontalDragCancel: () => setState(() => _resizerActive = false),
        child: const SizedBox.expand(),
      ),
    );
    handle = Focus(
      onFocusChange: (f) => setState(() => _resizerFocused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final grow = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
        final shrink = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
        if (key == grow || key == shrink) {
          widget.onResize(widget.width + (key == grow ? _keyboardStep : -_keyboardStep));
          widget.onResizeEnd();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: handle,
    );
    final value = '${widget.width.round()}';
    handle = Semantics(
      label: col.header,
      hint: widget.resizerRoleDescription,
      value: value,
      increasedValue: '${(widget.width + _keyboardStep).round()}',
      decreasedValue: '${(widget.width - _keyboardStep).round()}',
      onIncrease: () {
        widget.onResize(widget.width + _keyboardStep);
        widget.onResizeEnd();
      },
      onDecrease: () {
        widget.onResize(widget.width - _keyboardStep);
        widget.onResizeEnd();
      },
      child: handle,
    );
    final tooltip = widget.resizerTooltip;
    if (tooltip != null) handle = CsTooltip(content: tooltip, child: handle);
    return handle;
  }
}
