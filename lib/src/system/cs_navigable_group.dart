import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Which arrow keys move focus within a [CsNavigableGroup] (Cloudscape
/// `navigationDirection`).
enum CsNavigationDirection {
  /// Left and right.
  horizontal,

  /// Up and down.
  vertical,

  /// All four arrows.
  both,
}

/// Cloudscape's `NavigableGroup`: a set of focusable controls (buttons,
/// toggle buttons, button dropdowns, links) that is a single Tab stop, with
/// the arrow keys moving focus between them (a roving tab index).
///
/// ```dart
/// CsNavigableGroup(
///   child: Row(
///     children: [
///       CsButton(text: 'Start', onPress: start),
///       CsButton(text: 'Stop', onPress: stop),
///       CsButton(text: 'Reboot', onPress: reboot),
///     ],
///   ),
/// )
/// ```
///
/// The controls do not need to be direct children. Tab enters the group on
/// the control that had focus last (the first one at first) and leaves it
/// after one stop. Arrow keys along [navigationDirection] move to the
/// previous or next control in reading order, Home and End to the first and
/// last; disabled controls are skipped. With [loop] the arrows wrap from the
/// last control to the first and back, as Cloudscape does; without it they
/// stop at the ends.
///
/// Reach the state with a `GlobalKey<CsNavigableGroupState>` to [CsNavigableGroupState.focus]
/// the group (Cloudscape `ref.focus()`).
class CsNavigableGroup extends StatefulWidget {
  const CsNavigableGroup({
    super.key,
    required this.child,
    this.navigationDirection = CsNavigationDirection.horizontal,
    this.loop = false,
    this.semanticLabel,
  });

  final Widget child;
  final CsNavigationDirection navigationDirection;

  /// Wrap from the last control to the first and back.
  final bool loop;

  /// Accessible name of the group, such as "Instance actions".
  final String? semanticLabel;

  @override
  State<CsNavigableGroup> createState() => CsNavigableGroupState();
}

/// State of a [CsNavigableGroup].
class CsNavigableGroupState extends State<CsNavigableGroup> {
  final FocusNode _group = FocusNode(debugLabel: 'CsNavigableGroup', skipTraversal: true);
  FocusNode? _active;
  late final _SingleStopPolicy _policy = _SingleStopPolicy(this);

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    _group.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary != _group && _isMember(primary)) _active = primary;
  }

  bool _isMember(FocusNode node) => node.ancestors.contains(_group);

  /// The group's focusable controls in reading order.
  List<FocusNode> get items {
    final nodes = _group.descendants.where((n) => n.canRequestFocus && !n.skipTraversal && n.context != null).toList();
    if (nodes.isEmpty) return nodes;
    return ReadingOrderTraversalPolicy().sortDescendants(nodes, nodes.first).toList();
  }

  /// The control Tab lands on: the last focused one, or the first.
  FocusNode? get tabStop {
    final list = items;
    if (list.isEmpty) return null;
    final active = _active;
    if (active != null && list.contains(active)) return active;
    return list.first;
  }

  /// Focuses the control that had focus last, or the first one.
  void focus() => tabStop?.requestFocus();

  void _focusItem(FocusNode node) {
    node.requestFocus();
    final ctx = node.context;
    if (ctx != null && Scrollable.maybeOf(ctx) != null) Scrollable.ensureVisible(ctx);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed || keyboard.isControlPressed || keyboard.isMetaPressed || keyboard.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final primary = FocusManager.instance.primaryFocus;
    final list = items;
    if (primary == null || !list.contains(primary)) return KeyEventResult.ignored;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final horizontal = widget.navigationDirection != CsNavigationDirection.vertical;
    final vertical = widget.navigationDirection != CsNavigationDirection.horizontal;
    int? delta;
    if (horizontal && key == LogicalKeyboardKey.arrowRight) delta = rtl ? -1 : 1;
    if (horizontal && key == LogicalKeyboardKey.arrowLeft) delta = rtl ? 1 : -1;
    if (vertical && key == LogicalKeyboardKey.arrowDown) delta = 1;
    if (vertical && key == LogicalKeyboardKey.arrowUp) delta = -1;
    final index = list.indexOf(primary);
    int? target;
    if (delta != null) {
      target = index + delta;
      if (target < 0) target = widget.loop ? list.length - 1 : 0;
      if (target >= list.length) target = widget.loop ? 0 : list.length - 1;
    } else if (key == LogicalKeyboardKey.home) {
      target = 0;
    } else if (key == LogicalKeyboardKey.end) {
      target = list.length - 1;
    } else if (key == LogicalKeyboardKey.pageUp || key == LogicalKeyboardKey.pageDown) {
      // Cloudscape claims Page Up and Page Down without moving focus.
      return KeyEventResult.handled;
    }
    if (target == null) return KeyEventResult.ignored;
    if (target != index) _focusItem(list[target]);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = FocusTraversalGroup(
      policy: _policy,
      child: Focus(focusNode: _group, canRequestFocus: false, onKeyEvent: _onKey, child: widget.child),
    );
    if (widget.semanticLabel != null) {
      child = Semantics(container: true, explicitChildNodes: true, label: widget.semanticLabel, child: child);
    }
    return child;
  }
}

/// Reading order, with every control but the group's tab stop dropped from
/// Tab traversal.
class _SingleStopPolicy extends ReadingOrderTraversalPolicy {
  _SingleStopPolicy(this.state);

  final CsNavigableGroupState state;

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    final sorted = super.sortDescendants(descendants, currentNode).toList();
    final stop = state.tabStop;
    if (stop == null) return sorted;
    // Keep the member that is, or contains, the tab stop (a member can be a
    // nested traversal group).
    return sorted.where((n) => n == stop || stop.ancestors.contains(n) || !state._isMember(n)).toList();
  }
}
