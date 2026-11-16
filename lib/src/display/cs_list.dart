import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_focus_ring.dart';
import '../theme/theme.dart';

/// What [CsList.renderItem] returns for one item (Cloudscape's `renderItem`
/// result).
@immutable
class CsListItem {
  const CsListItem({
    required this.id,
    required this.content,
    this.secondaryContent,
    this.icon,
    this.actions,
    this.announcementLabel,
  });

  /// Unique, stable identifier of the item.
  final String id;

  /// Main content, in body text.
  final Widget content;

  /// Secondary content under [content], such as a description. Shown in
  /// body-s secondary text unless the widget styles itself.
  final Widget? secondaryContent;

  /// Icon at the start, aligned with the first line of [content].
  final Widget? icon;

  /// Action buttons at the end of the first line.
  final Widget? actions;

  /// What screen readers call the item while it is being reordered. Defaults
  /// to the text of [content] when it is a `Text`.
  final String? announcementLabel;
}

/// Copy for [CsList], English by default (Cloudscape `i18nStrings`).
@immutable
class CsListI18nStrings {
  const CsListI18nStrings({
    this.dragHandleAriaLabel = 'Drag handle',
    this.dragHandleAriaDescription =
        "Use Space or Enter to activate drag for an item, then use the arrow keys to move the item's position. "
        'To complete the position move, use Space or Enter, or to discard the move, use Escape.',
    this.liveAnnouncementDndStarted = _started,
    this.liveAnnouncementDndItemReordered = _reordered,
    this.liveAnnouncementDndItemCommitted = _committed,
    this.liveAnnouncementDndDiscarded = 'Reordering canceled',
  });

  /// Label of each drag handle.
  final String dragHandleAriaLabel;

  /// Hint of each drag handle, explaining the keyboard interaction.
  final String dragHandleAriaDescription;

  /// Announced when an item is picked up: `(position, total)`, 1-based.
  final String Function(int position, int total) liveAnnouncementDndStarted;

  /// Announced on each move: `(initialPosition, currentPosition, total)`.
  final String Function(int initialPosition, int currentPosition, int total) liveAnnouncementDndItemReordered;

  /// Announced on drop: `(initialPosition, finalPosition, total)`.
  final String Function(int initialPosition, int finalPosition, int total) liveAnnouncementDndItemCommitted;

  /// Announced when a move is canceled with Escape.
  final String liveAnnouncementDndDiscarded;

  static String _started(int position, int total) => 'Picked up item at position $position of $total';

  static String _reordered(int initial, int current, int total) => initial == current
      ? 'Moving item back to position $current of $total'
      : 'Moving item to position $current of $total';

  static String _committed(int initial, int finalPosition, int total) => initial == finalPosition
      ? 'Item moved back to its original position $initial of $total'
      : 'Item moved from position $initial to position $finalPosition of $total';
}

/// Cloudscape's `List`: a vertical list of structured items (icon, content,
/// secondary content, actions) separated by dividers, optionally sortable.
///
/// ```dart
/// CsList<String>(
///   items: const ['example-bucket', 'logs-bucket'],
///   renderItem: (name) => CsListItem(
///     id: name,
///     content: Text(name),
///     icon: const CsIcon(CsIcons.folder),
///   ),
/// )
/// ```
///
/// With [sortable], each item gets a drag handle. Drag the handle to move an
/// item (it lifts with the active container shadow and follows the finger),
/// or focus the handle and use Space or Enter to pick up, the arrow keys to
/// move, Space or Enter to drop and Escape to cancel. Every step is
/// announced to screen readers. The list is controlled: [onSortingChange]
/// receives the reordered items and the parent passes them back in.
class CsList<T> extends StatefulWidget {
  const CsList({
    super.key,
    required this.items,
    required this.renderItem,
    this.sortable = false,
    this.sortDisabled = false,
    this.onSortingChange,
    this.disableItemPaddings = false,
    this.disablePaddings = false,
    this.ordered,
    this.ariaLabel,
    this.i18nStrings = const CsListI18nStrings(),
  });

  final List<T> items;

  /// Describes how [items] render.
  final CsListItem Function(T item) renderItem;

  /// Adds drag handles and reordering.
  final bool sortable;

  /// Disables the drag handles, to pause reordering temporarily.
  final bool sortDisabled;

  /// Called with the reordered items after a drop.
  final ValueChanged<List<T>>? onSortingChange;

  /// Removes the vertical padding inside items (and the gap next to the drag
  /// handle).
  final bool disableItemPaddings;

  /// Removes the padding above the first and below the last item. Does not
  /// apply to sortable lists.
  final bool disablePaddings;

  /// Whether the order is meaningful (Cloudscape `tagOverride: 'ol'`).
  /// Ordered lists tell screen readers each item's position. Defaults to
  /// [sortable].
  final bool? ordered;

  /// Accessible name of the list.
  final String? ariaLabel;
  final CsListI18nStrings i18nStrings;

  @override
  State<CsList<T>> createState() => _CsListState<T>();
}

class _CsListState<T> extends State<CsList<T>> {
  final Map<String, FocusNode> _handleNodes = {};

  /// Keyboard reordering: the order shown while an item is picked up.
  List<T>? _preview;
  String? _activeId;
  int _initialIndex = 0;

  /// Pointer reordering: the item being dragged.
  int? _dragStartIndex;

  @override
  void dispose() {
    for (final n in _handleNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CsList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = {for (final i in widget.items) widget.renderItem(i).id};
    _handleNodes.removeWhere((id, node) {
      if (ids.contains(id)) return false;
      node.dispose();
      return true;
    });
    if (_preview != null && (widget.sortDisabled || !widget.sortable)) _discard(announce: false);
  }

  FocusNode _nodeFor(String id) => _handleNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'CsList handle $id'));

  void _announce(String message) {
    if (message.isEmpty) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
  }

  int _indexOf(List<T> list, String id) => list.indexWhere((i) => widget.renderItem(i).id == id);

  void _pickUp(String id) {
    final index = _indexOf(widget.items, id);
    if (index < 0) return;
    setState(() {
      _preview = List<T>.of(widget.items);
      _activeId = id;
      _initialIndex = index;
    });
    _announce(widget.i18nStrings.liveAnnouncementDndStarted(index + 1, widget.items.length));
  }

  void _move(int delta) {
    final preview = _preview;
    final id = _activeId;
    if (preview == null || id == null) return;
    final from = _indexOf(preview, id);
    final to = (from + delta).clamp(0, preview.length - 1);
    if (to == from) return;
    setState(() => preview.insert(to, preview.removeAt(from)));
    _announce(widget.i18nStrings.liveAnnouncementDndItemReordered(_initialIndex + 1, to + 1, preview.length));
    _keepFocus(id);
  }

  void _commit() {
    final preview = _preview;
    final id = _activeId;
    if (preview == null || id == null) return;
    final to = _indexOf(preview, id);
    setState(() {
      _preview = null;
      _activeId = null;
    });
    _announce(widget.i18nStrings.liveAnnouncementDndItemCommitted(_initialIndex + 1, to + 1, preview.length));
    if (to != _initialIndex) widget.onSortingChange?.call(preview);
    _keepFocus(id);
  }

  void _discard({bool announce = true}) {
    final id = _activeId;
    setState(() {
      _preview = null;
      _activeId = null;
    });
    if (announce) _announce(widget.i18nStrings.liveAnnouncementDndDiscarded);
    if (id != null) _keepFocus(id);
  }

  void _keepFocus(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _handleNodes[id];
      if (mounted && node != null && !node.hasFocus) node.requestFocus();
    });
  }

  KeyEventResult _onHandleKey(String id, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final active = _activeId == id;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      active ? _commit() : _pickUp(id);
      return KeyEventResult.handled;
    }
    if (!active) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowRight) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _discard();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _labelOf(CsListItem item) {
    if (item.announcementLabel != null) return item.announcementLabel!;
    final c = item.content;
    if (c is Text) return c.data ?? c.textSpan?.toPlainText() ?? '';
    return '';
  }

  Widget _row(BuildContext context, T value, int index, int count, {required bool sortable, bool lifted = false}) {
    final cs = context.cs;
    final item = widget.renderItem(value);
    final last = index == count - 1;
    final pad = widget.disableItemPaddings ? 0.0 : cs.space.scaledXs;
    final top = !sortable && widget.disablePaddings && index == 0 ? 0.0 : pad;
    final bottom = !sortable && widget.disablePaddings && last ? 0.0 : pad;
    Widget body = _StructuredItem(item: item, disablePaddings: widget.disableItemPaddings);
    if (sortable) {
      final id = item.id;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(
            index: index,
            focusNode: _nodeFor(id),
            disabled: widget.sortDisabled,
            active: _activeId == id,
            label: widget.i18nStrings.dragHandleAriaLabel,
            hint: widget.i18nStrings.dragHandleAriaDescription,
            itemLabel: _labelOf(item),
            onKey: (e) => _onHandleKey(id, e),
            onFocusLost: () {
              if (_activeId == id) _discard();
            },
          ),
          if (!widget.disableItemPaddings) const SizedBox(width: CsSpace.xxs),
          Expanded(child: body),
        ],
      );
    }
    final highlighted = lifted || (_activeId != null && _activeId == item.id);
    return Semantics(
      container: true,
      sortKey: OrdinalSortKey(index.toDouble()),
      value: (widget.ordered ?? widget.sortable) ? '${index + 1} of $count' : null,
      child: Container(
        key: ValueKey(item.id),
        decoration: highlighted
            ? BoxDecoration(
                color: cs.colors.backgroundContainerContent,
                borderRadius: BorderRadius.circular(CsBorderRadius.item),
                boxShadow: cs.shadows.containerActive,
              )
            : (last
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cs.colors.borderDividerSecondary,
                          width: CsBorderLine.dividerListWidth,
                        ),
                      ),
                    )),
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final shown = _preview ?? widget.items;
    Widget list;
    if (!widget.sortable) {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < shown.length; i++) _row(context, shown[i], i, shown.length, sortable: false)],
      );
    } else {
      final reduce = CsMotion.reduceMotion(context);
      list = ReorderableList(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown.length,
        onReorderStart: (index) {
          _dragStartIndex = index;
          _announce(widget.i18nStrings.liveAnnouncementDndStarted(index + 1, shown.length));
        },
        onReorderEnd: (_) => _dragStartIndex = null,
        onReorder: (from, to) {
          // ReorderableList reports the slot before removal.
          final target = to > from ? to - 1 : to;
          final start = _dragStartIndex ?? from;
          _announce(widget.i18nStrings.liveAnnouncementDndItemCommitted(start + 1, target + 1, shown.length));
          if (target == from) return;
          final next = List<T>.of(widget.items);
          next.insert(target, next.removeAt(from));
          widget.onSortingChange?.call(next);
        },
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: cs.colors.backgroundContainerContent,
              borderRadius: BorderRadius.circular(CsBorderRadius.item),
              boxShadow: reduce || animation.value > 0.5 ? cs.shadows.containerActive : const [],
            ),
            child: _row(context, shown[index], index, shown.length, sortable: true, lifted: true),
          ),
        ),
        itemBuilder: (context, i) => KeyedSubtree(
          key: ValueKey(widget.renderItem(shown[i]).id),
          child: _row(context, shown[i], i, shown.length, sortable: true),
        ),
      );
    }
    return Semantics(container: true, explicitChildNodes: true, label: widget.ariaLabel, child: list);
  }
}

/// Cloudscape's internal structured item: icon, content and actions on the
/// first line, secondary content below.
class _StructuredItem extends StatelessWidget {
  const _StructuredItem({required this.item, required this.disablePaddings});

  final CsListItem item;
  final bool disablePaddings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gap = disablePaddings ? 0.0 : CsSpace.xs;
    final firstLine = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DefaultTextStyle(style: cs.body, child: item.content),
        ),
        if (item.actions != null) ...[SizedBox(width: gap), item.actions!],
      ],
    );
    final main = item.secondaryContent == null
        ? firstLine
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              firstLine,
              DefaultTextStyle(
                style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                child: item.secondaryContent!,
              ),
            ],
          );
    if (item.icon == null) return main;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: CsTypeScale.bodyM.lineHeight),
          child: Center(widthFactor: 1, heightFactor: 1, child: item.icon),
        ),
        SizedBox(width: gap),
        Expanded(child: main),
      ],
    );
  }
}

class _DragHandle extends StatefulWidget {
  const _DragHandle({
    required this.index,
    required this.focusNode,
    required this.disabled,
    required this.active,
    required this.label,
    required this.hint,
    required this.itemLabel,
    required this.onKey,
    required this.onFocusLost,
  });

  final int index;
  final FocusNode focusNode;
  final bool disabled;
  final bool active;
  final String label;
  final String hint;
  final String itemLabel;
  final KeyEventResult Function(KeyEvent event) onKey;
  final VoidCallback onFocusLost;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _hovered = false;
  bool _focusVisible = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = widget.disabled
        ? cs.colors.textInteractiveDisabled
        : (_hovered || widget.active ? cs.colors.textInteractiveHover : cs.colors.textInteractiveDefault);
    Widget handle = Container(
      height: CsTypeScale.bodyM.lineHeight,
      padding: EdgeInsets.symmetric(horizontal: cs.space.scaledXxxs),
      alignment: Alignment.center,
      child: CsIcon(CsIcons.dragIndicator, dangerouslySetColor: color),
    );
    handle = CsFocusRing(
      visible: _focusVisible,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      child: handle,
    );
    final min = cs.minTapTarget;
    if (min > 0) {
      handle = ConstrainedBox(
        constraints: BoxConstraints(minWidth: min, minHeight: CsTypeScale.bodyM.lineHeight),
        child: Center(widthFactor: 1, heightFactor: 1, child: handle),
      );
    }
    handle = MouseRegion(
      cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: handle,
    );
    if (!widget.disabled) {
      handle = ReorderableDragStartListener(index: widget.index, child: handle);
    }
    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: !widget.disabled,
      skipTraversal: widget.disabled,
      onKeyEvent: (_, e) => widget.disabled ? KeyEventResult.ignored : widget.onKey(e),
      onFocusChange: (focused) {
        final visible = focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
        if (visible != _focusVisible) setState(() => _focusVisible = visible);
        if (!focused) widget.onFocusLost();
      },
      child: Semantics(
        button: true,
        enabled: !widget.disabled,
        label: widget.itemLabel.isEmpty ? widget.label : '${widget.label}, ${widget.itemLabel}',
        hint: widget.hint,
        child: handle,
      ),
    );
  }
}
