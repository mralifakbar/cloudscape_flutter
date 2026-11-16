import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/cs_focus_ring.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_radio_button.dart';

/// One tile of a [CsTiles] group (Cloudscape `TilesDefinition`).
@immutable
class CsTilesItem {
  const CsTilesItem({
    required this.value,
    this.label,
    this.labelWidget,
    this.description,
    this.descriptionWidget,
    this.image,
    this.disabled = false,
  }) : assert(label != null || labelWidget != null, 'Pass label or labelWidget');

  /// The value the group reports in `onChange` when this tile is picked.
  final String value;

  /// A short name for the option.
  final String? label;

  /// Custom label content in place of [label].
  final Widget? labelWidget;

  /// Further guidance on the option, under the label.
  final String? description;

  /// Custom description content in place of [description].
  final Widget? descriptionWidget;

  /// A visually distinctive image for the option, centered under the
  /// description. Shown at 30% opacity when the tile is disabled.
  final Widget? image;

  /// The user can't select a disabled tile.
  final bool disabled;
}

/// Cloudscape's `Tiles`: a single choice from options that each need more
/// room than a radio button: a description, an illustration, a spec line.
/// Each tile is a bordered card with a radio; the selected one gets the
/// selected border and background.
///
/// It is controlled: pass [value] (null for no selection) and update it in
/// [onChange].
///
/// ```dart
/// CsTiles(
///   value: engine,
///   onChange: (v) => setState(() => engine = v),
///   items: const [
///     CsTilesItem(value: 'mysql', label: 'MySQL', description: 'Open-source relational database.'),
///     CsTilesItem(value: 'postgres', label: 'PostgreSQL', description: 'Extensible relational database.'),
///   ],
/// )
/// ```
///
/// Columns respond to the width the tiles get, like Cloudscape's container
/// breakpoints: one column under 465px, at most two under 688px, then
/// [columns] (or the count picked from the number of items).
class CsTiles extends StatefulWidget {
  const CsTiles({
    super.key,
    required this.value,
    required this.items,
    this.onChange,
    this.columns,
    this.readOnly = false,
    this.ariaLabel,
    this.ariaRequired = false,
    this.autofocus = false,
  }) : assert(columns == null || (columns >= 1 && columns <= 4), 'columns must be 1 to 4');

  /// The value of the selected tile, or null for none.
  final String? value;
  final List<CsTilesItem> items;

  /// Called with the value of the newly selected tile.
  final ValueChanged<String>? onChange;

  /// Number of columns on wide layouts, 1 to 4. By default it follows the
  /// number of items, with at most 3, and 2 for 4 or 8 items.
  final int? columns;

  /// Shows the selection without letting the user change it.
  final bool readOnly;

  /// Accessible name of the group when it is not inside a labelled
  /// `CsFormField`.
  final String? ariaLabel;

  /// Announces the group as required.
  final bool ariaRequired;
  final bool autofocus;

  /// Cloudscape's default column count for [itemCount] tiles.
  static int defaultColumns(int itemCount) => switch (itemCount) {
    0 || 1 => 1,
    2 || 4 || 8 => 2,
    _ => 3,
  };

  /// Columns shown at [width] for a [columns] setting, per Cloudscape's
  /// column-layout spans (`default`, `xxs` 465px, `xs` 688px).
  static int columnsAt(double width, int columns) {
    if (width < CsBreakpoint.xxs.minWidth) return 1;
    if (width < CsBreakpoint.xs.minWidth) return columns == 1 ? 1 : 2;
    return columns;
  }

  @override
  State<CsTiles> createState() => _CsTilesState();
}

class _CsTilesState extends State<CsTiles> {
  final List<FocusNode> _nodes = [];

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode(debugLabel: 'CsTiles item ${_nodes.length}'));
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
  }

  bool _enabled(int i) => !widget.items[i].disabled && widget.onChange != null;

  int get _tabStop {
    final selected = widget.items.indexWhere((item) => item.value == widget.value);
    if (selected >= 0 && _enabled(selected)) return selected;
    for (var i = 0; i < widget.items.length; i++) {
      if (_enabled(i)) return i;
    }
    return -1;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final int delta;
    if (key == LogicalKeyboardKey.arrowDown) {
      delta = 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      delta = -1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      delta = rtl ? -1 : 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      delta = rtl ? 1 : -1;
    } else {
      return KeyEventResult.ignored;
    }
    final current = _nodes.indexWhere((n) => n.hasFocus);
    if (current < 0) return KeyEventResult.ignored;
    final n = widget.items.length;
    for (var step = 1; step <= n; step++) {
      final i = ((current + delta * step) % n + n) % n;
      if (!_enabled(i)) continue;
      _nodes[i].requestFocus();
      if (!widget.readOnly && widget.items[i].value != widget.value) widget.onChange!(widget.items[i].value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final tabStop = _tabStop;
    // Cloudscape spaces tiles by half the tile gutter (a quarter on each side).
    final gap = context.cs.space.tileGutter / 2;
    final requested = widget.columns ?? CsTiles.defaultColumns(widget.items.length);

    Widget tile(int i) {
      _nodes[i].skipTraversal = i != tabStop;
      final item = widget.items[i];
      return _Tile(
        item: item,
        selected: item.value == widget.value,
        readOnly: widget.readOnly,
        enabled: _enabled(i),
        focusNode: _nodes[i],
        autofocus: widget.autofocus && i == tabStop,
        onSelect: () => widget.onChange!(item.value),
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      hint: widget.ariaRequired ? context.csStrings.required : null,
      readOnly: widget.readOnly ? true : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cols = CsTiles.columnsAt(constraints.maxWidth, requested);
            final rows = <Widget>[];
            for (var start = 0; start < widget.items.length; start += cols) {
              final cells = <Widget>[];
              for (var c = 0; c < cols; c++) {
                final i = start + c;
                cells.add(Expanded(child: i < widget.items.length ? tile(i) : const SizedBox.shrink()));
              }
              rows.add(
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: gap, children: cells),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: rows,
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.selected,
    required this.readOnly,
    required this.enabled,
    required this.focusNode,
    required this.autofocus,
    required this.onSelect,
  });

  final CsTilesItem item;
  final bool selected;
  final bool readOnly;
  final bool enabled;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final disabled = !enabled;
    final hasMetadata = item.description != null || item.descriptionWidget != null || item.image != null;

    final Color border;
    final Color background;
    if (disabled) {
      border = c.borderTilesDisabled;
      background = c.backgroundTilesDisabled;
    } else if (readOnly) {
      border = c.borderInputDisabled;
      background = c.backgroundInputDefault;
    } else if (selected) {
      border = c.borderItemSelected;
      background = c.backgroundItemSelected;
    } else {
      border = c.borderInputDefault;
      background = c.backgroundInputDefault;
    }
    // Selected tiles add an inset 1px ring, so the border reads 2px wide.
    final borderWidth = selected && !disabled && !readOnly ? CsBorderWidth.itemSelected : CsBorderWidth.field;

    return CsPressable(
      onPress: disabled ? null : (readOnly || selected ? () {} : onSelect),
      disabled: disabled,
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      showFocusRing: false,
      // A tile is far larger than 44px; padding it would stop it stretching
      // to the height of its row.
      minTapTargetSize: 0,
      isButton: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      mouseCursor: readOnly ? SystemMouseCursors.basic : null,
      builder: (context, state) {
        Widget content = CsControlRow(
          control: CsFocusRing(
            visible: state.focused,
            offset: 2,
            borderRadius: BorderRadius.circular(CsBorderRadius.controlCircularFocusRing),
            child: CsRadioIcon(checked: selected, disabled: disabled, readOnly: readOnly),
          ),
          controlHeight: CsSize.control,
          label: item.labelWidget ?? Text(item.label!),
          description: item.descriptionWidget ?? (item.description == null ? null : Text(item.description!)),
          disabled: disabled,
        );
        content = Align(alignment: AlignmentDirectional.topStart, child: content);
        return AnimatedContainer(
          duration: CsMotion.duration(context, CsDurations.transitionQuick),
          curve: CsCurves.transitionQuick,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(CsBorderRadius.tiles),
            border: CsRing.inside(border, width: borderWidth),
          ),
          padding: EdgeInsetsDirectional.only(
            start: CsSpace.s,
            end: CsSpace.s,
            top: CsSpace.xs,
            bottom: hasMetadata ? cs.space.scaledS : CsSpace.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.image == null)
                content
              else ...[
                Expanded(child: content),
                const SizedBox(height: CsSpace.s),
                Center(
                  child: Opacity(opacity: disabled ? 0.3 : 1, child: item.image),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
