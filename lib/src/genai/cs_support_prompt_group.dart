import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// Layout of a [CsSupportPromptGroup] (Cloudscape
/// `SupportPromptGroupProps.Alignment`).
enum CsSupportPromptAlignment { vertical, horizontal }

/// Which side of the text a prompt's icon sits on.
enum CsSupportPromptIconPosition { left, right }

/// Vertical alignment of a prompt's icon against multi-line text.
enum CsSupportPromptIconVerticalAlignment { start, center, end }

/// One support prompt (Cloudscape `SupportPromptGroupProps.Item`).
@immutable
class CsSupportPrompt {
  const CsSupportPrompt({
    required this.id,
    required this.text,
    this.textWidget,
    this.icon,
    this.iconWidget,
    this.iconPosition = CsSupportPromptIconPosition.left,
    this.iconVerticalAlignment = CsSupportPromptIconVerticalAlignment.start,
    this.ariaLabel,
  });

  /// Identifier passed to [CsSupportPromptGroup.onItemClick].
  final String id;

  /// The prompt text.
  final String text;

  /// Rich content shown instead of [text] (Cloudscape takes a ReactNode).
  final Widget? textWidget;

  /// A built-in icon (Cloudscape `iconName`).
  final CsIconData? icon;

  /// A custom icon (Cloudscape `iconSvg`). Takes precedence over [icon].
  final Widget? iconWidget;
  final CsSupportPromptIconPosition iconPosition;
  final CsSupportPromptIconVerticalAlignment iconVerticalAlignment;

  /// Accessible name that replaces [text].
  final String? ariaLabel;
}

/// Cloudscape's `SupportPromptGroup`: suggested prompts a user can send to a
/// generative AI assistant with one tap.
///
/// The group is a single Tab stop. Arrow keys move between prompts and wrap
/// around, Home and End jump to the first and last, and Enter or Space sends
/// the focused prompt.
///
/// ```dart
/// CsSupportPromptGroup(
///   ariaLabel: 'Suggested prompts',
///   items: const [
///     CsSupportPrompt(id: 'cost', text: 'Why did my bill go up this month?'),
///     CsSupportPrompt(id: 'scale', text: 'How do I scale my instances?'),
///   ],
///   onItemClick: (id) => send(id),
/// )
/// ```
class CsSupportPromptGroup extends StatefulWidget {
  const CsSupportPromptGroup({
    super.key,
    required this.items,
    required this.onItemClick,
    required this.ariaLabel,
    this.alignment = CsSupportPromptAlignment.vertical,
  });

  final List<CsSupportPrompt> items;

  /// Called with the [CsSupportPrompt.id] of the prompt that was chosen.
  final ValueChanged<String> onItemClick;

  /// Accessible name of the group, unique on the page.
  final String ariaLabel;

  /// Stack the prompts ([CsSupportPromptAlignment.vertical], the default) or
  /// let them flow in wrapping rows.
  final CsSupportPromptAlignment alignment;

  @override
  State<CsSupportPromptGroup> createState() => CsSupportPromptGroupState();
}

/// State of a [CsSupportPromptGroup]. Reach it with a `GlobalKey` to move
/// focus to a prompt (Cloudscape `ref.focus(itemId)`).
class CsSupportPromptGroupState extends State<CsSupportPromptGroup> {
  final Map<String, FocusNode> _nodes = {};

  /// Id of the prompt that holds the group's single Tab stop.
  String? _active;

  /// Moves keyboard focus to the prompt with [itemId]. Does nothing when no
  /// prompt has that id.
  void focus(String itemId) => _nodes[itemId]?.requestFocus();

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    final ids = {for (final i in widget.items) i.id};
    for (final id in _nodes.keys.toList()) {
      if (!ids.contains(id)) _nodes.remove(id)!.dispose();
    }
    for (final id in ids) {
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'CsSupportPrompt $id'));
    }
    if (_active == null || !ids.contains(_active)) _active = widget.items.isEmpty ? null : widget.items.first.id;
    for (final e in _nodes.entries) {
      e.value.skipTraversal = e.key != _active;
    }
  }

  void _move(int delta, {int? to}) {
    final ids = [for (final i in widget.items) i.id];
    if (ids.isEmpty) return;
    final current = ids.indexWhere((id) => _nodes[id]!.hasFocus);
    if (current < 0) return;
    final next = to ?? (current + delta) % ids.length;
    _nodes[ids[next]]!.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isShiftPressed || keys.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final k = event.logicalKey;
    final last = widget.items.length - 1;
    if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowRight && !rtl ||
        k == LogicalKeyboardKey.arrowLeft && rtl) {
      _move(1);
    } else if (k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.arrowLeft && !rtl ||
        k == LogicalKeyboardKey.arrowRight && rtl) {
      _move(-1);
    } else if (k == LogicalKeyboardKey.home || k == LogicalKeyboardKey.pageUp) {
      _move(0, to: 0);
    } else if (k == LogicalKeyboardKey.end || k == LogicalKeyboardKey.pageDown) {
      _move(0, to: last);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final cs = context.cs;
    final prompts = [
      for (final item in widget.items)
        _Prompt(
          item: item,
          focusNode: _nodes[item.id]!,
          onFocus: () {
            if (_active != item.id) setState(() => _active = item.id);
          },
          onPress: () => widget.onItemClick(item.id),
        ),
    ];
    final gap = cs.space.scaledXs;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: widget.alignment == CsSupportPromptAlignment.horizontal
            ? Wrap(spacing: gap, runSpacing: gap, children: prompts)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: gap,
                children: prompts,
              ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.item, required this.focusNode, required this.onFocus, required this.onPress});

  final CsSupportPrompt item;
  final FocusNode focusNode;
  final VoidCallback onFocus;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.supportPrompt));
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) {
        if (v) onFocus();
      },
      child: CsPressable(
        focusNode: focusNode,
        onPress: onPress,
        borderRadius: radius,
        // `focus-highlight($gutter: 6px)` in the support prompt SCSS.
        focusRingOffset: 6 - CsBorderWidth.button,
        semanticLabel: item.ariaLabel,
        excludeChildSemantics: item.ariaLabel != null,
        builder: (context, state) {
          final fg = state.pressed
              ? c.textButtonNormalActive
              : state.hovered
              ? c.textButtonNormalHover
              : c.textButtonNormalDefault;
          final bg = state.pressed
              ? c.backgroundButtonNormalActive
              : state.hovered
              ? c.backgroundButtonNormalHover
              : c.backgroundButtonNormalDefault;
          final border = state.pressed
              ? c.borderButtonNormalActive
              : state.hovered
              ? c.borderButtonNormalHover
              : c.borderButtonNormalDefault;
          final iconAlign = switch (item.iconVerticalAlignment) {
            CsSupportPromptIconVerticalAlignment.start => CrossAxisAlignment.start,
            CsSupportPromptIconVerticalAlignment.center => CrossAxisAlignment.center,
            CsSupportPromptIconVerticalAlignment.end => CrossAxisAlignment.end,
          };
          final hasIcon = item.icon != null || item.iconWidget != null;
          final icon = hasIcon
              ? Align(
                  alignment: switch (item.iconVerticalAlignment) {
                    CsSupportPromptIconVerticalAlignment.start => Alignment.topCenter,
                    CsSupportPromptIconVerticalAlignment.center => Alignment.center,
                    CsSupportPromptIconVerticalAlignment.end => Alignment.bottomCenter,
                  },
                  widthFactor: 1,
                  child: SizedBox(
                    height: CsFontTokens.lineHeightHeadingM,
                    child: Center(
                      widthFactor: 1,
                      child: item.iconWidget ?? CsIcon(item.icon!, dangerouslySetColor: fg),
                    ),
                  ),
                )
              : null;
          final text = Flexible(
            child:
                item.textWidget ??
                Text(
                  item.text,
                  style: cs.body.copyWith(
                    color: fg,
                    height: CsFontTokens.lineHeightHeadingM / CsFontTokens.fontSizeBodyM,
                  ),
                ),
          );
          final left = item.iconPosition == CsSupportPromptIconPosition.left;
          return Container(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledXs, horizontal: CsSpace.staticS),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(color: border, width: CsBorderWidth.field),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: hasIcon ? CrossAxisAlignment.stretch : iconAlign,
                    spacing: cs.space.scaledXs,
                    children: left ? [?icon, text] : [text, ?icon],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
