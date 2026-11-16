import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_board_item.dart';
import 'cs_board_layout.dart';

/// One item a palette offers (Cloudscape `ItemsPaletteProps.Item`).
@immutable
class CsItemsPaletteItem<T> {
  const CsItemsPaletteItem({required this.id, required this.data, this.definition});

  /// Unique on the page, and the id the item keeps once on the board.
  final String id;
  final T data;

  /// Size rules; `defaultColumnSpan` and `defaultRowSpan` set its size when
  /// it lands on the board.
  final CsBoardItemDefinition? definition;

  /// The board entry this item becomes when added.
  CsBoardEntry<T> toBoardEntry() => CsBoardEntry<T>(id: id, data: data, definition: definition);
}

/// What [CsItemsPalette.renderItem] receives besides the item (Cloudscape
/// `ItemsPaletteProps.ItemContext`).
@immutable
class CsItemsPaletteItemContext {
  const CsItemsPaletteItemContext({required this.showPreview});

  /// The item is being dragged over a board: render the content it will
  /// have there instead of the palette summary.
  final bool showPreview;
}

/// Live announcements of a [CsItemsPalette] (Cloudscape
/// `ItemsPaletteProps.I18nStrings`).
@immutable
class CsItemsPaletteI18nStrings {
  const CsItemsPaletteI18nStrings({
    this.liveAnnouncementDndStarted = 'Dragging',
    this.liveAnnouncementDndDiscarded = 'Insertion discarded',
  });

  final String liveAnnouncementDndStarted;
  final String liveAnnouncementDndDiscarded;
}

/// Shared state between a dragged palette item and the board under it.
/// Internal to the board components.
abstract final class CsItemsPaletteDragScope {
  /// Id of the palette item currently over a board, if any.
  static final ValueNotifier<String?> hovering = ValueNotifier<String?>(null);
  static final Map<String, Size> _sizes = {};

  /// Size of the feedback for a dragged palette item.
  static Size feedbackSize(String id) => _sizes[id] ?? Size.zero;
}

/// Builds the widget for one palette item. Return a [CsBoardItem].
typedef CsItemsPaletteItemBuilder<T> =
    Widget Function(BuildContext context, CsItemsPaletteItem<T> item, CsItemsPaletteItemContext itemContext);

/// Cloudscape's `ItemsPalette`: a catalog of items people drag onto a
/// [CsBoard].
///
/// Drag an item by its handle (immediately, with mouse or touch) or press
/// and hold anywhere on it (touch). While it is over a board, the board
/// shows where it will land and `showPreview` is true. With [onItemAdd] each
/// item also shows an add button, the keyboard and screen reader
/// alternative to dragging; Enter or Space on the drag handle adds it too.
///
/// Remove an item from [items] once it is on the board.
///
/// ```dart
/// CsItemsPalette<String>(
///   items: palette,
///   renderItem: (context, item, ctx) => CsBoardItem(
///     header: CsHeader(title: item.data),
///     child: Text(ctx.showPreview ? 'Preview' : 'Shows instance health'),
///   ),
///   onItemAdd: (item) => setState(() {
///     board = [...board, item.toBoardEntry()];
///     palette = palette.where((p) => p.id != item.id).toList();
///   }),
/// )
/// ```
class CsItemsPalette<T> extends StatefulWidget {
  const CsItemsPalette({
    super.key,
    required this.items,
    required this.renderItem,
    this.onItemAdd,
    this.i18nStrings = const CsItemsPaletteI18nStrings(),
    this.columns,
  });

  final List<CsItemsPaletteItem<T>> items;
  final CsItemsPaletteItemBuilder<T> renderItem;

  /// Adds an item without dragging. Shows an add button on every item.
  final ValueChanged<CsItemsPaletteItem<T>>? onItemAdd;
  final CsItemsPaletteI18nStrings i18nStrings;

  /// Forces a column count. By default 1 below 688px, 2 below 912px and 3
  /// from there (Cloudscape renders the palette in a 3 column layout).
  final int? columns;

  @override
  State<CsItemsPalette<T>> createState() => _CsItemsPaletteState<T>();
}

class _CsItemsPaletteState<T> extends State<CsItemsPalette<T>> {
  String? _dragging;

  void _announce(String message) {
    final view = View.maybeOf(context);
    if (view == null || message.isEmpty) return;
    SemanticsService.sendAnnouncement(view, message, Directionality.of(context));
  }

  void _dragStarted(CsItemsPaletteItem<T> item, Size size) {
    CsItemsPaletteDragScope._sizes[item.id] = size;
    setState(() => _dragging = item.id);
    _announce(widget.i18nStrings.liveAnnouncementDndStarted);
  }

  void _dragEnded(CsItemsPaletteItem<T> item, bool accepted) {
    CsItemsPaletteDragScope._sizes.remove(item.id);
    CsItemsPaletteDragScope.hovering.value = null;
    if (mounted) setState(() => _dragging = null);
    if (!accepted) _announce(widget.i18nStrings.liveAnnouncementDndDiscarded);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = widget.columns ?? (width < 688 ? 1 : (width < 912 ? 2 : 3));
        final gap = cs.space.gridGutter;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in widget.items)
              SizedBox(width: itemWidth, child: _buildItem(context, item, Size(itemWidth, 0))),
          ],
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, CsItemsPaletteItem<T> item, Size slot) {
    final theme = context.cs;
    final direction = Directionality.of(context);
    final textStyle = DefaultTextStyle.of(context).style;

    Widget feedback(BuildContext ctx) => CsTheme(
      data: theme,
      child: Directionality(
        textDirection: direction,
        child: DefaultTextStyle(
          style: textStyle,
          child: SizedBox(
            width: slot.width,
            child: ValueListenableBuilder<String?>(
              valueListenable: CsItemsPaletteDragScope.hovering,
              builder: (context, hovering, _) => CsBoardItemScope(
                active: true,
                showResizeHandle: false,
                wrapDragHandle: (h) => h,
                child: widget.renderItem(context, item, CsItemsPaletteItemContext(showPreview: hovering == item.id)),
              ),
            ),
          ),
        ),
      ),
    );

    Size measure(BuildContext ctx) {
      final box = ctx.findRenderObject() as RenderBox?;
      return box?.hasSize == true ? box!.size : slot;
    }

    return Builder(
      builder: (itemContext) {
        Widget draggable(Widget child, {required bool longPress}) {
          if (longPress) {
            return LongPressDraggable<CsItemsPaletteItem<T>>(
              data: item,
              feedback: Builder(builder: feedback),
              dragAnchorStrategy: childDragAnchorStrategy,
              hapticFeedbackOnStart: true,
              onDragStarted: () => _dragStarted(item, measure(itemContext)),
              onDragEnd: (d) => _dragEnded(item, d.wasAccepted),
              child: child,
            );
          }
          return Draggable<CsItemsPaletteItem<T>>(
            data: item,
            feedback: Builder(builder: feedback),
            dragAnchorStrategy: (draggable, context, position) {
              // Keep the item's top start corner where it was relative to
              // the finger, measured from the whole item, not the handle.
              final box = itemContext.findRenderObject() as RenderBox;
              return box.globalToLocal(position);
            },
            onDragStarted: () => _dragStarted(item, measure(itemContext)),
            onDragEnd: (d) => _dragEnded(item, d.wasAccepted),
            child: child,
          );
        }

        final content = CsBoardItemScope(
          showResizeHandle: false,
          active: false,
          wrapDragHandle: (handle) => draggable(handle, longPress: false),
          onActivate: widget.onItemAdd == null ? null : (_) => widget.onItemAdd!(item),
          onAdd: widget.onItemAdd == null ? null : () => widget.onItemAdd!(item),
          child: widget.renderItem(itemContext, item, const CsItemsPaletteItemContext(showPreview: false)),
        );
        return Opacity(opacity: _dragging == item.id ? 0.5 : 1, child: draggable(content, longPress: true));
      },
    );
  }
}
