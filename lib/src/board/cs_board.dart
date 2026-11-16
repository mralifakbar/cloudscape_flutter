import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_board_item.dart';
import 'cs_board_layout.dart';
import 'cs_items_palette.dart';

/// What a drag on the board does (Cloudscape `BoardProps.DndOperationType`).
enum CsBoardOperation { reorder, resize, insert }

/// The state of a move, resize or insert, handed to the live announcement
/// strings (Cloudscape `DndReorderState`, `DndResizeState`,
/// `DndInsertState`).
@immutable
class CsBoardDndState<T> {
  const CsBoardDndState({
    required this.operation,
    required this.item,
    required this.placement,
    this.direction,
    this.isMinimalColumnsReached = false,
    this.isMinimalRowsReached = false,
    this.conflicts = const [],
    this.disturbed = const [],
  });

  final CsBoardOperation operation;
  final CsBoardEntry<T> item;

  /// Where the item would land.
  final CsBoardPlacement placement;

  /// Axis of the last keyboard step (reorder and resize), null for pointers.
  final Axis? direction;

  /// The item is at its minimum width (resize).
  final bool isMinimalColumnsReached;

  /// The item is at its minimum height (resize).
  final bool isMinimalRowsReached;

  /// Items the target cells overlapped before they moved out of the way.
  final List<CsBoardEntry<T>> conflicts;

  /// Items that change position as a result.
  final List<CsBoardEntry<T>> disturbed;
}

/// The state handed to [CsBoardI18nStrings.liveAnnouncementItemRemoved].
@immutable
class CsBoardItemRemovedState<T> {
  const CsBoardItemRemovedState({required this.item, this.disturbed = const []});

  final CsBoardEntry<T> item;
  final List<CsBoardEntry<T>> disturbed;
}

/// What changed in [CsBoard.onItemsChange] (Cloudscape
/// `BoardProps.ItemsChangeDetail`). [items] is the new list to store; at
/// most one of the other fields is set.
@immutable
class CsBoardItemsChange<T> {
  const CsBoardItemsChange({required this.items, this.movedItem, this.resizedItem, this.addedItem, this.removedItem});

  final List<CsBoardEntry<T>> items;
  final CsBoardEntry<T>? movedItem;
  final CsBoardEntry<T>? resizedItem;
  final CsBoardEntry<T>? addedItem;
  final CsBoardEntry<T>? removedItem;
}

/// Actions an item can take on its board (Cloudscape
/// `BoardProps.ItemActions`).
@immutable
class CsBoardItemActions {
  const CsBoardItemActions({required this.removeItem});

  /// Removes the item; [CsBoard.onItemsChange] fires with `removedItem`.
  final VoidCallback removeItem;
}

/// Live announcements of a [CsBoard] (Cloudscape `BoardProps.I18nStrings`).
/// Every field is optional and falls back to English.
@immutable
class CsBoardI18nStrings<T> {
  const CsBoardI18nStrings({
    this.liveAnnouncementDndStarted,
    this.liveAnnouncementDndItemReordered,
    this.liveAnnouncementDndItemResized,
    this.liveAnnouncementDndItemInserted,
    this.liveAnnouncementDndCommitted,
    this.liveAnnouncementDndDiscarded,
    this.liveAnnouncementItemRemoved,
  });

  final String Function(CsBoardOperation operation)? liveAnnouncementDndStarted;
  final String Function(CsBoardDndState<T> state)? liveAnnouncementDndItemReordered;
  final String Function(CsBoardDndState<T> state)? liveAnnouncementDndItemResized;
  final String Function(CsBoardDndState<T> state)? liveAnnouncementDndItemInserted;
  final String Function(CsBoardOperation operation)? liveAnnouncementDndCommitted;
  final String Function(CsBoardOperation operation)? liveAnnouncementDndDiscarded;
  final String Function(CsBoardItemRemovedState<T> state)? liveAnnouncementItemRemoved;

  String started(CsBoardOperation op) =>
      liveAnnouncementDndStarted?.call(op) ??
      switch (op) {
        CsBoardOperation.reorder => 'Dragging',
        CsBoardOperation.resize => 'Resizing',
        CsBoardOperation.insert => 'Inserting',
      };

  String moved(CsBoardDndState<T> s) => switch (s.operation) {
    CsBoardOperation.reorder =>
      liveAnnouncementDndItemReordered?.call(s) ??
          'Item moved to column ${s.placement.x + 1}, row ${s.placement.y + 1}.${_disturbed(s)}',
    CsBoardOperation.resize =>
      liveAnnouncementDndItemResized?.call(s) ??
          'Item resized to ${s.placement.width} ${s.placement.width == 1 ? 'column' : 'columns'}, '
              '${s.placement.height} rows.${s.isMinimalColumnsReached || s.isMinimalRowsReached ? ' Minimum size reached.' : ''}${_disturbed(s)}',
    CsBoardOperation.insert =>
      liveAnnouncementDndItemInserted?.call(s) ??
          'Item inserted to column ${s.placement.x + 1}, row ${s.placement.y + 1}.${_disturbed(s)}',
  };

  String committed(CsBoardOperation op) =>
      liveAnnouncementDndCommitted?.call(op) ??
      switch (op) {
        CsBoardOperation.reorder => 'Reorder committed',
        CsBoardOperation.resize => 'Resize committed',
        CsBoardOperation.insert => 'Insertion committed',
      };

  String discarded(CsBoardOperation op) =>
      liveAnnouncementDndDiscarded?.call(op) ??
      switch (op) {
        CsBoardOperation.reorder => 'Reorder discarded',
        CsBoardOperation.resize => 'Resize discarded',
        CsBoardOperation.insert => 'Insertion discarded',
      };

  String removed(CsBoardItemRemovedState<T> s) => liveAnnouncementItemRemoved?.call(s) ?? 'Removed item.';

  static String _disturbed(CsBoardDndState<Object?> s) =>
      s.disturbed.isEmpty ? '' : ' ${s.disturbed.length} ${s.disturbed.length == 1 ? 'item' : 'items'} moved.';
}

/// Builds the widget for one board item. Return a [CsBoardItem].
typedef CsBoardItemBuilder<T> = Widget Function(BuildContext context, CsBoardEntry<T> item, CsBoardItemActions actions);

/// Cloudscape's `Board`: a configurable dashboard grid whose items people
/// rearrange by dragging, resize from the corner, add from a
/// [CsItemsPalette] and remove.
///
/// The board is controlled: it never changes [items] itself. Every commit
/// calls [onItemsChange] with the new list, which you store and pass back.
///
/// Columns follow the board's own width (1 below 688px, 2 below 912px, 4
/// below 2100px, else 6), each layout keeping its own arrangement. Rows are
/// 96px apart from a 20px gap (76px and 16px in compact density).
///
/// Pointer: drag an item by its handle; it follows the finger 1:1, the
/// others make room, and on release it settles into its slot. Drag the
/// corner handle to resize. Keyboard: focus a handle, press Enter or Space,
/// use the arrow keys, then Enter or Space to commit or Escape to discard.
///
/// ```dart
/// CsBoard<String>(
///   items: items,
///   onItemsChange: (change) => setState(() => items = change.items),
///   renderItem: (context, item, actions) => CsBoardItem(
///     header: CsHeader(title: item.data),
///     child: const Text('No alarms'),
///   ),
///   empty: const Text('No widgets'),
/// )
/// ```
class CsBoard<T> extends StatefulWidget {
  const CsBoard({
    super.key,
    required this.items,
    required this.renderItem,
    required this.onItemsChange,
    this.empty,
    this.i18nStrings,
    this.columns,
  });

  final List<CsBoardEntry<T>> items;
  final CsBoardItemBuilder<T> renderItem;
  final ValueChanged<CsBoardItemsChange<T>> onItemsChange;

  /// Shown when [items] is empty (and as the loading slot while items load).
  final Widget? empty;
  final CsBoardI18nStrings<T>? i18nStrings;

  /// Forces a column count (1, 2, 4 or 6) instead of following the width.
  final int? columns;

  /// Row height and gap for comfortable density (`grid-auto-rows: 96px;
  /// gap: 20px` in the grid SCSS).
  static const double rowHeight = 96;
  static const double gap = 20;

  /// Row height and gap for compact density (`.grid-compact`).
  static const double compactRowHeight = 76;
  static const double compactGap = 16;

  /// Cloudscape `TRANSITION_DURATION_MS`.
  static const Duration transitionDuration = Duration(milliseconds: 200);

  @override
  State<CsBoard<T>> createState() => _CsBoardState<T>();
}

class _Transition<T> {
  _Transition({
    required this.operation,
    required this.entry,
    required this.origin,
    required this.keyboard,
    required this.preview,
    required this.originRect,
  });

  final CsBoardOperation operation;
  final CsBoardEntry<T> entry;
  final List<CsBoardEntry<T>> origin;
  final bool keyboard;
  List<CsBoardEntry<T>> preview;

  /// Item rectangle at the start of a pointer drag, in board pixels.
  final Rect originRect;
  Offset delta = Offset.zero;

  /// Pointer in board coordinates for an insert from the palette.
  Rect? insertRect;
  Axis? direction;

  /// Target cell of a keyboard move.
  (int, int)? cell;
}

class _BoardDrag implements Drag {
  _BoardDrag(this.onUpdate, this.onEnd);

  final ValueChanged<Offset> onUpdate;
  final ValueChanged<bool> onEnd;

  @override
  void update(DragUpdateDetails details) => onUpdate(details.delta);

  @override
  void end(DragEndDetails details) => onEnd(true);

  @override
  void cancel() => onEnd(false);
}

class _Metrics {
  _Metrics({required this.width, required this.columns, required this.rowHeight, required this.gap, required this.rtl})
    : columnWidth = (width - gap * (columns - 1)) / columns;

  final double width;
  final int columns;
  final double rowHeight;
  final double gap;
  final bool rtl;
  final double columnWidth;

  double spanWidth(int w) => w * columnWidth + (w - 1) * gap;
  double spanHeight(int h) => h * rowHeight + (h - 1) * gap;
  double height(int rows) => rows <= 0 ? 0 : spanHeight(rows);

  Rect rect(int x, int y, int w, int h) {
    final left = x * (columnWidth + gap);
    final width = spanWidth(w);
    return Rect.fromLTWH(rtl ? this.width - left - width : left, y * (rowHeight + gap), width, spanHeight(h));
  }

  Rect rectOf(CsBoardPlacement p) => rect(p.x, p.y, p.width, p.height);

  /// The cell whose top start corner is nearest to [r]'s.
  (int, int) cellOf(Rect r) {
    final start = rtl ? width - r.right : r.left;
    return ((start / (columnWidth + gap)).round(), (r.top / (rowHeight + gap)).round());
  }

  int columnsFor(double px) => ((px + gap) / (columnWidth + gap)).round();
  int rowsFor(double px) => ((px + gap) / (rowHeight + gap)).round();
}

class _CsBoardState<T> extends State<CsBoard<T>> {
  final GlobalKey _stackKey = GlobalKey();
  _Transition<T>? _t;
  _Metrics? _m;

  CsBoardI18nStrings<T> get _strings => widget.i18nStrings ?? CsBoardI18nStrings<T>();

  void _announce(String message) {
    if (message.isEmpty) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(view, message, Directionality.of(context));
  }

  CsBoardEntry<T>? _entry(String id) {
    for (final i in widget.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _start(CsBoardOperation op, CsBoardEntry<T> entry, {required bool keyboard}) {
    final m = _m!;
    final p = CsBoardLayout.interpret(widget.items, m.columns)[entry.id];
    setState(() {
      _t = _Transition<T>(
        operation: op,
        entry: entry,
        origin: widget.items,
        keyboard: keyboard,
        preview: widget.items,
        originRect: p == null ? Rect.zero : m.rectOf(p),
      );
    });
    _announce(_strings.started(op));
  }

  void _update(List<CsBoardEntry<T>> preview) {
    final t = _t!;
    final m = _m!;
    final changed = !listEquals(preview, t.preview);
    setState(() => t.preview = preview);
    if (!changed) return;
    final before = CsBoardLayout.interpret(t.origin, m.columns);
    final after = CsBoardLayout.interpret(preview, m.columns);
    final p = after[t.entry.id];
    if (p == null) return;
    final disturbed = CsBoardLayout.disturbed(before, after, except: t.entry.id);
    final conflicts = [
      for (final o in before.items)
        if (o.id != t.entry.id && o.overlaps(p)) o.id,
    ];
    final item = preview.firstWhere((i) => i.id == t.entry.id);
    _announce(
      _strings.moved(
        CsBoardDndState<T>(
          operation: t.operation,
          item: item,
          placement: p,
          direction: t.direction,
          isMinimalColumnsReached: p.width <= CsBoardLayout.minColumns(item.definition, m.columns),
          isMinimalRowsReached: p.height <= CsBoardLayout.minRows(item.definition),
          conflicts: [for (final id in conflicts) t.origin.firstWhere((i) => i.id == id)],
          disturbed: [for (final id in disturbed) preview.firstWhere((i) => i.id == id)],
        ),
      ),
    );
  }

  void _finish({required bool commit}) {
    final t = _t;
    if (t == null) return;
    setState(() => _t = null);
    final changed = !listEquals(t.preview, t.origin);
    if (commit && changed) {
      final item = t.preview.firstWhere((i) => i.id == t.entry.id);
      widget.onItemsChange(
        CsBoardItemsChange<T>(
          items: t.preview,
          movedItem: t.operation == CsBoardOperation.reorder ? item : null,
          resizedItem: t.operation == CsBoardOperation.resize ? item : null,
          addedItem: t.operation == CsBoardOperation.insert ? item : null,
        ),
      );
      _announce(_strings.committed(t.operation));
    } else {
      _announce(_strings.discarded(t.operation));
    }
  }

  // Pointer drags.

  Drag? _onDragStart(String id, CsBoardHandle handle, Offset position) {
    if (_t != null || _m == null) return null;
    final entry = _entry(id);
    if (entry == null) return null;
    final op = handle == CsBoardHandle.drag ? CsBoardOperation.reorder : CsBoardOperation.resize;
    _start(op, entry, keyboard: false);
    return _BoardDrag(_onDragUpdate, (ok) => _finish(commit: ok));
  }

  void _onDragUpdate(Offset delta) {
    final t = _t;
    final m = _m;
    if (t == null || m == null) return;
    t.delta += delta;
    if (t.operation == CsBoardOperation.reorder) {
      final (x, y) = m.cellOf(t.originRect.shift(t.delta));
      _update(CsBoardLayout.place(t.origin, t.entry, x, y, m.columns));
    } else {
      final dx = m.rtl ? -t.delta.dx : t.delta.dx;
      final w = m.columnsFor(t.originRect.width + dx);
      final h = m.rowsFor(t.originRect.height + t.delta.dy);
      _update(CsBoardLayout.resize(t.origin, t.entry.id, math.max(1, w), math.max(1, h), m.columns));
    }
  }

  // Keyboard.

  void _onActivate(String id, CsBoardHandle handle) {
    final t = _t;
    if (t == null) {
      final entry = _entry(id);
      if (entry == null) return;
      _start(handle == CsBoardHandle.drag ? CsBoardOperation.reorder : CsBoardOperation.resize, entry, keyboard: true);
    } else if (t.keyboard && t.entry.id == id) {
      _finish(commit: true);
    }
  }

  KeyEventResult _onKey(String id, CsBoardHandle handle, KeyEvent event) {
    final t = _t;
    final m = _m;
    if (t == null || m == null || !t.keyboard || t.entry.id != id) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.handled;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.escape) {
      _finish(commit: false);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.numpadEnter) {
      _finish(commit: true);
      return KeyEventResult.handled;
    }
    var dx = 0;
    var dy = 0;
    if (k == LogicalKeyboardKey.arrowLeft) dx = m.rtl ? 1 : -1;
    if (k == LogicalKeyboardKey.arrowRight) dx = m.rtl ? -1 : 1;
    if (k == LogicalKeyboardKey.arrowUp) dy = -1;
    if (k == LogicalKeyboardKey.arrowDown) dy = 1;
    if (dx == 0 && dy == 0) return KeyEventResult.ignored;
    t.direction = dx != 0 ? Axis.horizontal : Axis.vertical;
    final p = CsBoardLayout.interpret(t.preview, m.columns)[id]!;
    if (t.operation == CsBoardOperation.reorder) {
      final (cx, cy) = t.cell ?? (p.x, p.y);
      final x = (cx + dx).clamp(0, m.columns - p.width);
      final y = math.max(0, cy + dy);
      t.cell = (x, y);
      _update(CsBoardLayout.place(t.origin, t.entry, x, y, m.columns));
    } else {
      _update(CsBoardLayout.resize(t.origin, id, p.width + dx, p.height + dy, m.columns));
    }
    return KeyEventResult.handled;
  }

  void _onBlur(String id) {
    final t = _t;
    if (t != null && t.keyboard && t.entry.id == id) _finish(commit: true);
  }

  // Insert from a palette.

  void _onPaletteMove(CsItemsPaletteItem<T> item, Offset globalTopLeft, Size size) {
    final m = _m;
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (m == null || box == null) return;
    final local = box.globalToLocal(globalTopLeft);
    var t = _t;
    if (t == null || t.operation != CsBoardOperation.insert || t.entry.id != item.id) {
      if (t != null) return;
      _start(CsBoardOperation.insert, item.toBoardEntry(), keyboard: false);
      t = _t!;
    }
    t.insertRect = local & size;
    final (x, y) = m.cellOf(local & size);
    _update(CsBoardLayout.place(t.origin, t.entry, x, y, m.columns));
  }

  void _onPaletteLeave(CsItemsPaletteItem<T>? item) {
    final t = _t;
    if (t != null && t.operation == CsBoardOperation.insert) _finish(commit: false);
  }

  void _remove(String id) {
    final m = _m;
    final entry = _entry(id);
    if (m == null || entry == null) return;
    final before = CsBoardLayout.interpret(widget.items, m.columns);
    final next = CsBoardLayout.remove(widget.items, id, m.columns);
    final after = CsBoardLayout.interpret(next, m.columns);
    widget.onItemsChange(CsBoardItemsChange<T>(items: next, removedItem: entry));
    final disturbed = CsBoardLayout.disturbed(before, after);
    _announce(
      _strings.removed(
        CsBoardItemRemovedState<T>(
          item: entry,
          disturbed: [for (final id in disturbed) next.firstWhere((i) => i.id == id)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final compact = cs.density == CsDensity.compact;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DragTarget<CsItemsPaletteItem<T>>(
      onWillAcceptWithDetails: (details) => _t == null || _t!.operation == CsBoardOperation.insert,
      onMove: (details) {
        final size = CsItemsPaletteDragScope.feedbackSize(details.data.id);
        _onPaletteMove(details.data, details.offset, size);
        CsItemsPaletteDragScope.hovering.value = details.data.id;
      },
      onLeave: (item) {
        _onPaletteLeave(item);
        CsItemsPaletteDragScope.hovering.value = null;
      },
      onAcceptWithDetails: (details) {
        CsItemsPaletteDragScope.hovering.value = null;
        _finish(commit: true);
      },
      builder: (context, candidates, rejected) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = widget.columns ?? CsBoardLayout.columnsForWidth(width);
          final m = _m = _Metrics(
            width: width,
            columns: columns,
            rowHeight: compact ? CsBoard.compactRowHeight : CsBoard.rowHeight,
            gap: compact ? CsBoard.compactGap : CsBoard.gap,
            rtl: rtl,
          );
          return _buildGrid(context, m);
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, _Metrics m) {
    final cs = context.cs;
    final t = _t;
    final shown = t?.preview ?? widget.items;
    if (shown.isEmpty && t == null) {
      return KeyedSubtree(
        key: _stackKey,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: cs.space.scaledM,
            bottom: cs.space.scaledL,
            left: cs.space.scaledL,
            right: cs.space.scaledL,
          ),
          alignment: Alignment.topCenter,
          child: DefaultTextStyle.merge(
            style: cs.body.copyWith(color: cs.colors.textEmpty),
            child: widget.empty ?? const SizedBox.shrink(),
          ),
        ),
      );
    }
    final grid = CsBoardLayout.interpret(shown, m.columns);
    var rows = grid.rows;
    if (t != null) {
      final p = grid[t.entry.id];
      final originRows = CsBoardLayout.interpret(t.origin, m.columns).rows;
      if (t.operation == CsBoardOperation.resize && p != null) {
        rows = math.max(rows, p.y + p.height + 1);
      } else {
        rows = math.max(rows, originRows + (p?.height ?? CsBoardLayout.defaultRows(t.entry.definition)));
      }
    }
    final duration = CsMotion.duration(context, CsBoard.transitionDuration);
    final byId = {for (final i in shown) i.id: i};
    final target = t == null ? null : grid[t.entry.id];

    final children = <Widget>[];
    if (t != null) {
      const radius = BorderRadius.all(Radius.circular(CsBorderRadius.container));
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < m.columns; x++) {
          final hover =
              target != null &&
              x >= target.x &&
              x < target.x + target.width &&
              y >= target.y &&
              y < target.y + target.height;
          children.add(
            Positioned.fromRect(
              rect: m.rect(x, y, 1, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hover ? cs.colors.boardPlaceholderHover : cs.colors.boardPlaceholderActive,
                  borderRadius: radius,
                ),
              ),
            ),
          );
        }
      }
    }

    Widget itemWidget(CsBoardPlacement p, {required Rect rect, required Duration duration, bool active = false}) {
      final entry = byId[p.id]!;
      return AnimatedPositioned.fromRect(
        key: ValueKey('cs-board-item-${p.id}'),
        rect: rect,
        duration: duration,
        curve: CsCurves.responsive,
        child: CsBoardItemScope(
          active: active,
          keyboardHandle: t != null && t.keyboard && t.entry.id == p.id
              ? (t.operation == CsBoardOperation.resize ? CsBoardHandle.resize : CsBoardHandle.drag)
              : null,
          onDragStart: (handle, position) => _onDragStart(p.id, handle, position),
          onActivate: (handle) => _onActivate(p.id, handle),
          onKey: (handle, event) => _onKey(p.id, handle, event),
          onBlur: (handle) => _onBlur(p.id),
          child: Builder(
            builder: (context) =>
                widget.renderItem(context, entry, CsBoardItemActions(removeItem: () => _remove(p.id))),
          ),
        ),
      );
    }

    CsBoardPlacement? lifted;
    for (final p in grid.items) {
      final isMoving = t != null && t.entry.id == p.id && t.operation != CsBoardOperation.insert;
      if (isMoving) {
        lifted = p;
        continue;
      }
      if (t != null && t.operation == CsBoardOperation.insert && t.entry.id == p.id) continue;
      children.add(itemWidget(p, rect: m.rectOf(p), duration: duration));
    }
    if (lifted != null) {
      // The moving item is painted last so it rides above the others.
      Rect rect;
      if (t!.keyboard) {
        rect = m.rectOf(lifted);
      } else if (t.operation == CsBoardOperation.reorder) {
        rect = t.originRect.shift(t.delta);
      } else {
        final minW = m.spanWidth(CsBoardLayout.minColumns(t.entry.definition, m.columns));
        final minH = m.spanHeight(CsBoardLayout.minRows(t.entry.definition));
        final dx = m.rtl ? -t.delta.dx : t.delta.dx;
        final maxW = math.max(minW, m.rtl ? t.originRect.right : m.width - t.originRect.left);
        final w = (t.originRect.width + dx).clamp(minW, maxW).toDouble();
        final h = math.max(minH, t.originRect.height + t.delta.dy);
        rect = m.rtl
            ? Rect.fromLTWH(t.originRect.right - w, t.originRect.top, w, h)
            : Rect.fromLTWH(t.originRect.left, t.originRect.top, w, h);
      }
      children.add(itemWidget(lifted, rect: rect, duration: t.keyboard ? duration : Duration.zero, active: true));
    }

    final height = math.max(m.height(rows), t?.originRect.shift(t.delta).bottom ?? 0);
    return SizedBox(
      key: _stackKey,
      width: m.width,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}
