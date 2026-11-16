import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_focus_ring.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_nav_reveal.dart';

/// What [CsTreeView.renderItem] returns for an item (Cloudscape
/// `TreeViewProps.TreeItem`).
@immutable
class CsTreeViewItem {
  const CsTreeViewItem({required this.content, this.icon, this.secondaryContent, this.actions, this.announcementLabel});

  /// The item's main content, usually its name.
  final Widget content;

  /// An icon before the content (a folder, a file).
  final Widget? icon;

  /// Secondary content under the main content, such as a description.
  final Widget? secondaryContent;

  /// Actions at the end of the row: inline icon or inline link buttons.
  final Widget? actions;

  /// Spoken name of the item, used for the row and its toggle. Pass it when
  /// [content] is not plain text.
  final String? announcementLabel;
}

/// Detail of [CsTreeView.onItemToggle].
@immutable
class CsTreeViewItemToggleDetail<T> {
  const CsTreeViewItemToggleDetail({required this.id, required this.item, required this.expanded});

  final String id;
  final T item;

  /// The state the item asks to be in.
  final bool expanded;
}

/// Connector lines of [CsTreeView] (Cloudscape `connectorLines`).
enum CsTreeViewConnectorLines {
  /// A vertical line under each expanded item, beside its children.
  vertical,

  /// No lines. The default.
  none,
}

/// Copy for [CsTreeView].
@immutable
class CsTreeViewI18nStrings<T> {
  const CsTreeViewI18nStrings({this.expandButtonLabel, this.collapseButtonLabel});

  /// Accessible name of the expand toggle. Defaults to "Expand".
  final String Function(T item)? expandButtonLabel;

  /// Accessible name of the collapse toggle. Defaults to "Collapse".
  final String Function(T item)? collapseButtonLabel;
}

/// Cloudscape's `TreeView`: hierarchical items, such as folders and files or
/// nested resources, that people can expand and collapse.
///
/// ```dart
/// CsTreeView<Resource>(
///   items: roots,
///   getItemId: (r, _) => r.id,
///   getItemChildren: (r, _) => r.children,
///   expandedItems: expanded,
///   onItemToggle: (d) => setState(() => d.expanded ? expanded.add(d.id) : expanded.remove(d.id)),
///   renderItem: (r, _) => CsTreeViewItem(
///     icon: CsIcon(r.children == null ? CsIcons.file : CsIcons.folder),
///     content: Text(r.name),
///   ),
/// )
/// ```
///
/// Controlled: [expandedItems] says which items are open and
/// [onItemToggle] reports the toggles.
///
/// Keyboard (ARIA tree): one item is in the Tab order. Up and Down move
/// between visible items, Home and End jump to the first and last, Right
/// expands a closed item or moves to its first child, Left collapses an
/// open item or moves to its parent, Enter and Space toggle.
class CsTreeView<T> extends StatefulWidget {
  const CsTreeView({
    super.key,
    required this.items,
    required this.renderItem,
    required this.getItemId,
    required this.getItemChildren,
    this.expandedItems = const {},
    this.onItemToggle,
    this.connectorLines = CsTreeViewConnectorLines.none,
    this.i18nStrings = const CsTreeViewI18nStrings(),
    this.renderItemToggleIcon,
    this.ariaLabel,
  });

  /// The top-level items.
  final List<T> items;

  /// Maps an item to its row content.
  final CsTreeViewItem Function(T item, int index) renderItem;

  /// A unique id per item.
  final String Function(T item, int index) getItemId;

  /// The item's children, or null for a leaf.
  final List<T>? Function(T item, int index) getItemChildren;

  /// Ids of the expanded items.
  final Set<String> expandedItems;
  final ValueChanged<CsTreeViewItemToggleDetail<T>>? onItemToggle;
  final CsTreeViewConnectorLines connectorLines;
  final CsTreeViewI18nStrings<T> i18nStrings;

  /// Replaces the caret of the expand toggle.
  final Widget Function(bool expanded)? renderItemToggleIcon;

  /// Accessible name of the tree.
  final String? ariaLabel;

  @override
  State<CsTreeView<T>> createState() => _CsTreeViewState<T>();
}

class _Entry<T> {
  _Entry(this.item, this.index, this.id, this.parent, this.level, this.children);

  final T item;
  final int index;
  final String id;
  final _Entry<T>? parent;
  final int level;
  final List<T>? children;

  bool get expandable => children != null && children!.isNotEmpty;
}

// Cloudscape's $item-toggle-column-width (tree-view/tree-item/styles.scss).
const double _toggleColumn = 28;

class _CsTreeViewState<T> extends State<CsTreeView<T>> {
  final Map<String, FocusNode> _focus = {};
  String? _tabStop;
  List<_Entry<T>> _visible = const [];

  @override
  void dispose() {
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeFor(String id) => _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'CsTreeView $id'));

  bool _expanded(_Entry<T> e) => e.expandable && widget.expandedItems.contains(e.id);

  void _toggle(_Entry<T> e, bool expanded) {
    if (!e.expandable) return;
    if (!expanded) {
      // Collapsing hides the focused descendant: focus moves to the item.
      for (final v in _visible) {
        if (!(_focus[v.id]?.hasPrimaryFocus ?? false)) continue;
        for (var p = v.parent; p != null; p = p.parent) {
          if (p.id == e.id) {
            _moveFocus(e.id);
            break;
          }
        }
      }
    }
    widget.onItemToggle?.call(CsTreeViewItemToggleDetail<T>(id: e.id, item: e.item, expanded: expanded));
  }

  void _collect(List<T> items, _Entry<T>? parent, int level, List<_Entry<T>> out) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final entry = _Entry<T>(item, i, widget.getItemId(item, i), parent, level, widget.getItemChildren(item, i));
      out.add(entry);
      if (_expanded(entry)) _collect(entry.children!, entry, level + 1, out);
    }
  }

  void _moveFocus(String id) {
    setState(() => _tabStop = id);
    _nodeFor(id).requestFocus();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final index = _visible.indexWhere((e) => _focus[e.id]?.hasPrimaryFocus ?? false);
    if (index < 0) return KeyEventResult.ignored;
    final entry = _visible[index];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final back = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (index + 1 < _visible.length) _moveFocus(_visible[index + 1].id);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) _moveFocus(_visible[index - 1].id);
    } else if (key == LogicalKeyboardKey.home) {
      _moveFocus(_visible.first.id);
    } else if (key == LogicalKeyboardKey.end) {
      _moveFocus(_visible.last.id);
    } else if (key == forward) {
      if (!entry.expandable) return KeyEventResult.handled;
      if (!_expanded(entry)) {
        _toggle(entry, true);
      } else if (index + 1 < _visible.length && _visible[index + 1].parent?.id == entry.id) {
        _moveFocus(_visible[index + 1].id);
      }
    } else if (key == back) {
      if (_expanded(entry)) {
        _toggle(entry, false);
      } else if (entry.parent != null) {
        _moveFocus(entry.parent!.id);
      }
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _toggle(entry, !_expanded(entry));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final visible = <_Entry<T>>[];
    _collect(widget.items, null, 1, visible);
    _visible = visible;
    final ids = {for (final e in visible) e.id};
    if (_tabStop == null || !ids.contains(_tabStop)) {
      // The previous stop was collapsed away or removed.
      _tabStop = visible.isEmpty ? null : visible.first.id;
    }
    final cs = context.cs;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Padding(
          padding: EdgeInsets.all(cs.space.scaledXxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _branch(context, widget.items, null, 1),
          ),
        ),
      ),
    );
  }

  List<Widget> _branch(BuildContext context, List<T> items, _Entry<T>? parent, int level) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final entry = _Entry<T>(item, i, widget.getItemId(item, i), parent, level, widget.getItemChildren(item, i));
      final expanded = _expanded(entry);
      final row = _row(context, entry, expanded, siblings: items.length, position: i + 1);
      if (!entry.expandable) {
        out.add(KeyedSubtree(key: ValueKey(entry.id), child: row));
        continue;
      }
      final lines = widget.connectorLines == CsTreeViewConnectorLines.vertical;
      out.add(
        Column(
          key: ValueKey(entry.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            row,
            CsNavReveal(
              expanded: expanded,
              child: Stack(
                children: [
                  if (lines)
                    PositionedDirectional(
                      start: (_toggleColumn - CsBorderLine.dividerListWidth) / 2 - 2,
                      top: 0,
                      bottom: context.cs.space.scaledXs,
                      width: CsBorderLine.dividerListWidth,
                      child: ColoredBox(color: context.cs.colors.treeViewConnectorLine),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: CsSpace.treeViewIndentation),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: _branch(context, entry.children!, entry, level + 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return out;
  }

  Widget _row(BuildContext context, _Entry<T> entry, bool expanded, {required int siblings, required int position}) {
    final cs = context.cs;
    final c = cs.colors;
    final rendered = widget.renderItem(entry.item, entry.index);
    final strings = widget.i18nStrings;
    final toggleLabel = expanded
        ? (strings.collapseButtonLabel?.call(entry.item) ?? 'Collapse')
        : (strings.expandButtonLabel?.call(entry.item) ?? 'Expand');
    const lineHeight = CsFontTokens.lineHeightHeadingM;
    final node = _nodeFor(entry.id);
    final isStop = entry.id == _tabStop;
    node
      ..skipTraversal = !isStop
      ..canRequestFocus = true;

    Widget toggle = const SizedBox(width: CsSpace.m, height: CsSpace.m);
    if (entry.expandable) {
      toggle = CsPressable(
        onPress: () {
          _moveFocus(entry.id);
          _toggle(entry, !expanded);
        },
        canRequestFocus: false,
        semanticLabel: toggleLabel,
        expanded: expanded,
        scaleOnPress: false,
        minTapTargetSize: cs.minTapTarget > 0 ? 32 : 0,
        builder: (context, state) {
          final color = state.pressed
              ? c.textInteractiveActive
              : state.hovered
              ? c.textInteractiveHover
              : c.textInteractiveDefault;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return SizedBox(
            width: CsSpace.m,
            height: CsSpace.m,
            child: Center(
              child:
                  widget.renderItemToggleIcon?.call(expanded) ??
                  AnimatedRotation(
                    turns: expanded ? 0 : (rtl ? 0.25 : -0.25),
                    duration: CsMotion.duration(context, CsDurations.rotate90),
                    curve: CsCurves.rotate90,
                    child: CsIcon(CsIcons.caretDownFilled, size: CsIconSize.small, dangerouslySetColor: color),
                  ),
            ),
          );
        },
      );
    }

    final label = rendered.announcementLabel;
    return Focus(
      focusNode: node,
      onFocusChange: (focused) => setState(() {
        if (focused) _tabStop = entry.id;
      }),
      child: Builder(
        builder: (context) {
          final focused = node.hasPrimaryFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
          return Semantics(
            label: label,
            expanded: entry.expandable ? expanded : null,
            value: 'level ${entry.level}, $position of $siblings',
            onTap: entry.expandable ? () => _toggle(entry, !expanded) : null,
            child: CsFocusRing(
              visible: focused,
              borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _moveFocus(entry.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _toggleColumn,
                      height: lineHeight + 2 * cs.space.scaledXxxs,
                      child: Align(
                        // The toggle sits 2px down and 2px toward the start.
                        alignment: AlignmentDirectional.center,
                        child: Transform.translate(offset: const Offset(-2, 1), child: toggle),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxxs),
                        child: DefaultTextStyle.merge(
                          style: cs.body.copyWith(height: lineHeight / CsTypeScale.bodyM.fontSize),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: CsSpace.xs,
                            children: [
                              if (rendered.icon != null)
                                SizedBox(
                                  height: lineHeight,
                                  child: Center(widthFactor: 1, child: rendered.icon),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    rendered.content,
                                    if (rendered.secondaryContent != null)
                                      DefaultTextStyle.merge(
                                        style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                                        child: rendered.secondaryContent!,
                                      ),
                                  ],
                                ),
                              ),
                              ?rendered.actions,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
