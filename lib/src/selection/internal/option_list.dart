import 'package:flutter/widgets.dart';

import '../../controls/cs_checkbox.dart';
import '../../icons/cs_icon.dart';
import '../../icons/cs_icons.g.dart';
import '../../navigation/cs_link.dart';
import '../../overlays/cs_anchored_overlay.dart';
import '../../overlays/cs_tooltip.dart';
import '../../status/cs_status_indicator.dart';
import '../../system/cs_pressable.dart';
import '../../theme/theme.dart';
import '../cs_option.dart';

/// Kinds of rows in a flattened option list.
enum OptionEntryType { option, parent, child, selectAll, enteredText }

/// One row of a flattened option list.
@immutable
class OptionEntry {
  const OptionEntry(this.type, this.option, {this.group, this.disabled = false});

  final OptionEntryType type;
  final CsOption option;
  final CsOptionGroup? group;
  final bool disabled;

  /// Rows a pick or highlight can land on. Group headers count only where
  /// groups select their children ([interactiveGroups]).
  bool isInteractive({bool interactiveGroups = false}) =>
      !disabled && (type != OptionEntryType.parent || interactiveGroups);
}

/// Flattens options and groups into rows, as Cloudscape's `flattenOptions`.
List<OptionEntry> flattenOptions(List<CsOptionItem> items) {
  final out = <OptionEntry>[];
  for (final item in items) {
    switch (item) {
      case CsOption():
        out.add(OptionEntry(OptionEntryType.option, item, disabled: item.disabled));
      case CsOptionGroup():
        out.add(OptionEntry(OptionEntryType.parent, item.asOption, group: item, disabled: item.disabled));
        for (final o in item.options) {
          out.add(OptionEntry(OptionEntryType.child, o, group: item, disabled: item.disabled || o.disabled));
        }
    }
  }
  return out;
}

/// Cloudscape's `filterOptions`: keeps rows whose fields contain [text]; a
/// matching group keeps all its children, and a matching child keeps its
/// group header.
List<OptionEntry> filterEntries(List<OptionEntry> entries, String text) {
  if (text.isEmpty) return entries;
  final lower = text.toLowerCase();
  final out = <OptionEntry>[];
  OptionEntry? pendingGroup;
  var parentMatched = false;
  for (final e in entries) {
    if (e.type == OptionEntryType.parent) {
      parentMatched = false;
      pendingGroup = e;
      if (e.option.matches(lower)) {
        parentMatched = true;
        out.add(e);
        pendingGroup = null;
      }
      continue;
    }
    if (e.type != OptionEntryType.child) {
      pendingGroup = null;
      parentMatched = false;
    }
    if (parentMatched) {
      out.add(e);
    } else if (e.option.matches(lower)) {
      if (pendingGroup != null) {
        out.add(pendingGroup);
        pendingGroup = null;
      }
      out.add(e);
    }
  }
  return out;
}

/// Every option (not group headers) in [items].
Iterable<CsOption> allOptions(List<CsOptionItem> items) sync* {
  for (final item in items) {
    switch (item) {
      case CsOption():
        yield item;
      case CsOptionGroup():
        yield* item.options;
    }
  }
}

/// Next interactive row from [from] in [delta] direction, wrapping around
/// as Cloudscape lists do. Returns [from] when nothing is interactive.
int stepHighlight(List<OptionEntry> entries, int from, int delta, {bool interactiveGroups = false}) {
  if (entries.isEmpty) return -1;
  var i = from;
  for (var n = 0; n < entries.length; n++) {
    i = i + delta;
    if (i >= entries.length) i = 0;
    if (i < 0) i = entries.length - 1;
    if (entries[i].isInteractive(interactiveGroups: interactiveGroups)) return i;
  }
  return from;
}

/// First (or last) interactive row.
int edgeHighlight(List<OptionEntry> entries, {required bool last, bool interactiveGroups = false}) {
  final range = last
      ? List.generate(entries.length, (i) => entries.length - 1 - i)
      : List.generate(entries.length, (i) => i);
  for (final i in range) {
    if (entries[i].isInteractive(interactiveGroups: interactiveGroups)) return i;
  }
  return -1;
}

/// Text with every case-insensitive occurrence of [highlight] drawn in
/// Cloudscape's filter match style (`color-background-dropdown-item-filter-match`,
/// bold).
class HighlightMatch extends StatelessWidget {
  const HighlightMatch(this.text, {super.key, this.highlight, this.style, this.maxLines, this.overflow});

  final String text;
  final String? highlight;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final h = highlight;
    if (h == null || h.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final c = context.cs.colors;
    final lower = text.toLowerCase();
    final needle = h.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final i = lower.indexOf(needle, start);
      if (i < 0) break;
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(
        TextSpan(
          text: text.substring(i, i + needle.length),
          style: TextStyle(
            backgroundColor: c.backgroundDropdownItemFilterMatch,
            color: c.textDropdownItemFilterMatch,
            fontWeight: CsTypography.bold,
          ),
        ),
      );
      start = i + needle.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// The content of an option: icon, label, label tag, description and tags,
/// as Cloudscape's internal `Option`. Used in option rows, in a select
/// trigger (`triggerVariant: option`) and in tokens.
class OptionContent extends StatelessWidget {
  const OptionContent({
    super.key,
    required this.option,
    this.highlightText,
    this.highlighted = false,
    this.selected = false,
    this.disabled = false,
    this.parent = false,
    this.triggerVariant = false,
    this.color,
    this.iconSize = CsIconSize.normal,
  });

  final CsOption option;
  final String? highlightText;
  final bool highlighted;
  final bool selected;
  final bool disabled;

  /// Group header: bold.
  final bool parent;

  /// Single-line rendering inside a trigger.
  final bool triggerVariant;
  final Color? color;
  final CsIconSize iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final fg = color ?? DefaultTextStyle.of(context).style.color ?? c.textBodyDefault;
    final secondary = disabled
        ? c.textDropdownItemDisabled
        : (highlighted && !selected ? c.textDropdownItemSecondaryHover : c.textDropdownItemSecondary);
    final labelStyle = cs.body.copyWith(color: fg, fontWeight: parent ? CsTypography.bold : null);
    final smallStyle = cs.text(CsTypeScale.bodyS).copyWith(color: triggerVariant ? null : secondary);
    final single = triggerVariant;
    final lead = option.iconWidget != null
        ? CsIcon.custom(option.iconWidget!, size: iconSize, semanticLabel: option.iconAriaLabel)
        : option.icon != null
        ? CsIcon(option.icon!, size: iconSize, dangerouslySetColor: fg, semanticLabel: option.iconAriaLabel)
        : null;

    final label =
        option.labelContent ??
        HighlightMatch(
          option.text,
          highlight: highlightText,
          style: labelStyle,
          maxLines: single ? 1 : null,
          overflow: single ? TextOverflow.ellipsis : null,
        );
    final labelRow = option.labelTag == null
        ? label
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: label),
              Expanded(
                child: Padding(
                  // `.label-tag { padding-inline-start: space-s }`
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: HighlightMatch(
                      option.labelTag!,
                      highlight: highlightText,
                      style: cs.body.copyWith(color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          );

    final matchingFilterTags = highlightText == null || highlightText!.isEmpty
        ? const <String>[]
        : (option.filteringTags ?? const <String>[])
              .where((t) => t.toLowerCase().contains(highlightText!.toLowerCase()))
              .toList();
    final tags = [...?option.tags, ...matchingFilterTags];
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        labelRow,
        if (option.description != null)
          HighlightMatch(
            option.description!,
            highlight: highlightText,
            style: smallStyle,
            maxLines: single ? 1 : null,
            overflow: single ? TextOverflow.ellipsis : null,
          ),
        if (tags.isNotEmpty)
          Wrap(
            // `.tag:not(:last-child) { padding-inline-end: space-m }`
            spacing: CsSpace.m,
            children: [for (final t in tags) HighlightMatch(t, highlight: highlightText, style: smallStyle)],
          ),
      ],
    );
    if (lead == null) return content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
          child: SizedBox(height: 20, child: Center(child: lead)),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// Selection mark shown at the start of a row.
enum OptionMark { none, checkbox }

/// One selectable row, drawn like Cloudscape's `selectable-item`: hover or
/// keyboard highlight fills `color-background-dropdown-item-hover` inside a
/// 2px outline; selection fills `color-background-dropdown-item-selected`
/// with a `color-border-dropdown-item-selected` outline. Rows never take
/// focus: the trigger or filter input keeps it.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.entry,
    this.highlighted = false,
    this.keyboard = false,
    this.selected = false,
    this.partial = false,
    this.mark = OptionMark.none,
    this.showSelectedIcon = false,
    this.previousSelected = false,
    this.nextSelected = false,
    this.showTopDivider = false,
    this.highlightText,
    this.interactiveGroups = false,
    this.onPress,
    this.onHover,
    this.labelPrefix,
  });

  final OptionEntry entry;
  final bool highlighted;
  final bool keyboard;
  final bool selected;

  /// Indeterminate checkbox (a group with some children selected).
  final bool partial;
  final OptionMark mark;

  /// The check icon at the end of the selected row (select).
  final bool showSelectedIcon;
  final bool previousSelected;
  final bool nextSelected;
  final bool showTopDivider;
  final String? highlightText;
  final bool interactiveGroups;
  final VoidCallback? onPress;
  final VoidCallback? onHover;

  /// Bold text before the label (autosuggest's "Use: ").
  final String? labelPrefix;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final e = entry;
    final isParent = e.type == OptionEntryType.parent;
    final staticParent = isParent && !interactiveGroups;
    final disabled = e.disabled;
    final lit = highlighted && !staticParent;
    final sel = selected && !staticParent;

    final Color fg;
    if (disabled) {
      fg = lit ? c.textDropdownItemDimmed : c.textDropdownItemDisabled;
    } else if (lit || sel) {
      fg = c.textDropdownItemHighlighted;
    } else if (isParent) {
      fg = c.textDropdownGroupLabel;
    } else {
      fg = c.textDropdownItemDefault;
    }

    Color? background;
    final borders = <Color>[];
    if (sel) {
      background = c.backgroundDropdownItemSelected;
      borders.add(c.borderDropdownItemSelected);
    }
    if (lit) {
      if (disabled) {
        background = c.backgroundDropdownItemDimmed;
        borders.add(c.borderDropdownItemDimmedHover);
      } else {
        background ??= c.backgroundDropdownItemHover;
        borders.add(keyboard ? c.borderDropdownItemFocused : c.borderDropdownItemHover);
      }
    }

    final radius = lit ? CsBorderRadius.dropdown : CsBorderRadius.item;
    final top = sel && previousSelected && !lit ? Radius.zero : Radius.circular(radius);
    final bottom = sel && nextSelected && !lit ? Radius.zero : Radius.circular(radius);
    final shape = BorderRadius.vertical(top: top, bottom: bottom);

    Widget content = OptionContent(
      option: e.option,
      highlightText: isParent && !interactiveGroups ? null : highlightText,
      highlighted: lit,
      selected: sel,
      disabled: disabled,
      parent: isParent,
      color: fg,
    );
    if (labelPrefix != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$labelPrefix ',
            style: cs.body.copyWith(color: fg, fontWeight: CsTypography.bold),
          ),
          Expanded(child: content),
        ],
      );
    }
    final rowChildren = <Widget>[
      if (mark == OptionMark.checkbox)
        Padding(
          // `.item > .checkbox { margin-inline-end: control-padding-horizontal }`
          padding: const EdgeInsetsDirectional.only(end: CsSpace.fieldHorizontal, top: 2),
          child: CsCheckboxIcon(checked: selected, indeterminate: partial && !selected, disabled: disabled),
        ),
      Expanded(child: content),
      if (showSelectedIcon && selected)
        Padding(
          padding: EdgeInsetsDirectional.only(start: e.option.labelTag != null ? CsSpace.s : CsSpace.xs),
          child: SizedBox(
            height: 20,
            child: Center(child: CsIcon(CsIcons.check, dangerouslySetColor: c.itemSelected)),
          ),
        ),
    ];

    final EdgeInsetsDirectional padding;
    if (staticParent) {
      padding = const EdgeInsetsDirectional.all(CsSpace.xs + CsBorderWidth.itemSelected);
    } else {
      const h = CsSpace.fieldHorizontal + CsBorderWidth.itemSelected;
      padding = EdgeInsetsDirectional.only(
        start: e.type == OptionEntryType.child ? CsSpace.xxl + CsBorderWidth.itemSelected : h,
        end: h,
        top: CsSpace.optionPaddingVertical + CsBorderWidth.itemSelected,
        bottom: CsSpace.optionPaddingVertical + CsBorderWidth.itemSelected,
      );
    }

    final Widget box = Container(
      constraints: BoxConstraints(minHeight: cs.minTapTarget > 0 && !staticParent ? 44 : 0),
      padding: padding,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: background,
        borderRadius: shape,
        border: showTopDivider && background == null
            ? Border(top: BorderSide(color: isParent ? c.borderDropdownGroup : c.borderDropdownItemDefault))
            : null,
      ),
      foregroundDecoration: borders.isEmpty
          ? null
          : _NestedOutlines(colors: borders, radius: shape, width: CsBorderWidth.itemSelected),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren),
      ),
    );

    if (staticParent) {
      return Semantics(header: true, child: box);
    }

    final interactive = !disabled && onPress != null;
    Widget row = CsPressable(
      onPress: interactive ? onPress : null,
      disabled: disabled,
      canRequestFocus: false,
      showFocusRing: false,
      scaleOnPress: false,
      minTapTargetSize: 0,
      selected: mark == OptionMark.none ? selected : null,
      checked: mark == OptionMark.checkbox ? (partial && !selected ? null : selected) : null,
      mixed: mark == OptionMark.checkbox && partial && !selected ? true : null,
      semanticHint: disabled ? e.option.disabledReason : null,
      child: box,
    );
    row = MouseRegion(onEnter: onHover == null ? null : (_) => onHover!(), child: row);
    if (disabled && e.option.disabledReason != null) {
      row = CsTooltip(content: e.option.disabledReason!, side: CsSide.right, child: row);
    }
    return row;
  }
}

/// Stacked inset outlines, outermost first (Cloudscape draws a selected row
/// that is also highlighted with two inset box shadows).
class _NestedOutlines extends Decoration {
  const _NestedOutlines({required this.colors, required this.radius, required this.width});

  final List<Color> colors;
  final BorderRadius radius;
  final double width;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _NestedOutlinesPainter(this);
}

class _NestedOutlinesPainter extends BoxPainter {
  _NestedOutlinesPainter(this.d);

  final _NestedOutlines d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    var rect = offset & size;
    for (final color in d.colors) {
      final rrect = d.radius.toRRect(rect).deflate(d.width / 2);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = d.width
          ..color = color,
      );
      rect = rect.deflate(d.width);
    }
  }
}

/// Status content at the end of a list: loading, error with a recovery
/// link, empty, no match, results count, or finished (Cloudscape
/// `useDropdownStatus`).
class DropdownStatusConfig {
  const DropdownStatusConfig({
    this.statusType = CsDropdownStatusType.finished,
    this.empty,
    this.noMatch,
    this.loadingText,
    this.finishedText,
    this.errorText,
    this.recoveryText,
    this.errorIconAriaLabel,
    this.filteringResultsText,
    this.onRecoveryClick,
  });

  final CsDropdownStatusType statusType;
  final Widget? empty;
  final Widget? noMatch;
  final String? loadingText;
  final String? finishedText;
  final String? errorText;
  final String? recoveryText;
  final String? errorIconAriaLabel;
  final String? filteringResultsText;
  final VoidCallback? onRecoveryClick;

  /// The status widget, or null when there is nothing to show.
  Widget? build(BuildContext context, {required bool isEmpty, required bool isNoMatch}) {
    Widget? content;
    switch (statusType) {
      case CsDropdownStatusType.loading:
        content = CsStatusIndicator(type: CsStatusType.loading, text: loadingText);
      case CsDropdownStatusType.error:
        content = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: CsSpace.xxs,
          children: [
            CsStatusIndicator(type: CsStatusType.error, text: errorText, iconAriaLabel: errorIconAriaLabel),
            if (recoveryText != null && onRecoveryClick != null) CsLink(text: recoveryText!, onFollow: onRecoveryClick),
          ],
        );
      case CsDropdownStatusType.pending:
      case CsDropdownStatusType.finished:
        if (isEmpty && empty != null) {
          content = empty;
        } else if (isNoMatch && noMatch != null) {
          content = noMatch;
        } else if (filteringResultsText != null) {
          content = Text(filteringResultsText!);
        } else if (statusType == CsDropdownStatusType.finished && finishedText != null) {
          content = Text(finishedText!);
        }
    }
    if (content == null) return null;
    final cs = context.cs;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isEmpty ? cs.colors.borderDropdownItemTop : cs.colors.borderDropdownItemDefault),
          ),
        ),
        padding: const EdgeInsetsDirectional.only(
          start: CsSpace.fieldHorizontal,
          end: CsSpace.fieldHorizontal,
          top: CsSpace.optionPaddingVertical,
          bottom: CsSpace.optionPaddingVertical + CsSpace.xxxs,
        ),
        child: DefaultTextStyle.merge(
          style: cs.body.copyWith(color: cs.colors.textDropdownFooter),
          child: content,
        ),
      ),
    );
  }
}

/// The dropdown surface of option lists (`color-background-dropdown-item-default`,
/// 2px `color-border-dropdown-container`, 8px radius, `shadow-dropdown`). In
/// a sheet it is bare.
class DropdownSurface extends StatelessWidget {
  const DropdownSurface({super.key, required this.child, this.inSheet = false, this.maxHeight = 400});

  final Widget child;
  final bool inSheet;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (inSheet) return child;
    final cs = context.cs;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.dropdown));
    // At least as wide as the trigger (the overlay's minimum width), growing
    // to the widest option, as Cloudscape dropdowns do.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: cs.colors.backgroundDropdownItemDefault,
            borderRadius: radius,
            boxShadow: cs.shadows.dropdown,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: cs.colors.borderDropdownContainer, width: CsBorderWidth.dropdown),
          ),
          padding: const EdgeInsets.all(CsBorderWidth.dropdown),
          child: ClipRRect(borderRadius: radius, child: child),
        ),
      ),
    );
  }
}

/// A scrolling list of [OptionRow]s with an optional sticky header (a
/// filter) and a status footer. It keeps the highlighted row in view and
/// reports when the user scrolls near the end (to load more).
class OptionListView extends StatefulWidget {
  const OptionListView({
    super.key,
    required this.entries,
    required this.rowBuilder,
    this.highlighted = -1,
    this.header,
    this.footer,
    this.onScrollEnd,
    this.semanticLabel,
    this.inSheet = false,
    this.maxHeight = 400,
  });

  final List<OptionEntry> entries;

  /// Builds row [index]; the list adds keys and dividers.
  final Widget Function(BuildContext context, int index) rowBuilder;
  final int highlighted;
  final Widget? header;
  final Widget? footer;
  final VoidCallback? onScrollEnd;
  final String? semanticLabel;
  final bool inSheet;
  final double maxHeight;

  @override
  State<OptionListView> createState() => _OptionListViewState();
}

class _OptionListViewState extends State<OptionListView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _highlightKey = GlobalKey();

  @override
  void didUpdateWidget(OptionListView old) {
    super.didUpdateWidget(old);
    if (old.highlighted != widget.highlighted && widget.highlighted >= 0) {
      final down = widget.highlighted > old.highlighted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _highlightKey.currentContext;
        if (ctx == null || !mounted) return;
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: down
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (var i = 0; i < widget.entries.length; i++)
        KeyedSubtree(key: i == widget.highlighted ? _highlightKey : null, child: widget.rowBuilder(context, i)),
    ];
    Widget list = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (widget.onScrollEnd != null && n.metrics.extentAfter < 80 && n is ScrollUpdateNotification) {
          widget.onScrollEnd!();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scroll,
        padding: widget.inSheet ? const EdgeInsets.symmetric(horizontal: CsSpace.xs) : EdgeInsets.zero,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      ),
    );
    list = Semantics(container: true, explicitChildNodes: true, label: widget.semanticLabel, child: list);
    return DropdownSurface(
      inSheet: widget.inSheet,
      maxHeight: widget.maxHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?widget.header,
          if (widget.entries.isNotEmpty) Flexible(child: list),
          ?widget.footer,
        ],
      ),
    );
  }
}
