import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_radio_button.dart';

/// One choice in a [CsRadioGroup] (Cloudscape `RadioButtonDefinition`).
@immutable
class CsRadioGroupItem {
  const CsRadioGroupItem({
    required this.value,
    this.label,
    this.labelWidget,
    this.description,
    this.descriptionWidget,
    this.disabled = false,
  }) : assert(label != null || labelWidget != null, 'Pass label or labelWidget');

  /// The value the group reports in `onChange` when this item is picked.
  final String value;
  final String? label;

  /// Custom label content in place of [label].
  final Widget? labelWidget;
  final String? description;

  /// Custom description content in place of [description].
  final Widget? descriptionWidget;

  /// The user can't select a disabled item; it is skipped by arrow keys.
  final bool disabled;
}

/// How the radios of a [CsRadioGroup] are laid out (Cloudscape `direction`).
enum CsRadioGroupDirection {
  /// One radio per line (default).
  vertical,

  /// Radios side by side, wrapping to the next line when they run out of
  /// room, 20px apart (`space-scaled-l`).
  horizontal,
}

/// Cloudscape's `RadioGroup`: a list of mutually exclusive options. Use it
/// for 2 to 7 choices that should all stay visible; use a select for longer
/// lists and `CsTiles` when each option needs more room.
///
/// It is controlled: pass [value] (null for no selection) and update it in
/// [onChange].
///
/// ```dart
/// CsRadioGroup(
///   value: storageClass,
///   onChange: (v) => setState(() => storageClass = v),
///   items: const [
///     CsRadioGroupItem(value: 'standard', label: 'Standard'),
///     CsRadioGroupItem(value: 'ia', label: 'Infrequent access', description: 'Lower cost, retrieval fee.'),
///   ],
/// )
/// ```
///
/// Keyboard: the group is a single Tab stop (the selected radio, or the
/// first enabled one); arrow keys move to the next or previous enabled radio
/// and select it, wrapping at the ends, like native radio inputs.
class CsRadioGroup extends StatefulWidget {
  const CsRadioGroup({
    super.key,
    required this.value,
    required this.items,
    this.onChange,
    this.direction = CsRadioGroupDirection.vertical,
    this.readOnly = false,
    this.disabled = false,
    this.ariaLabel,
    this.ariaRequired = false,
    this.autofocus = false,
  });

  /// The value of the selected item, or null for none.
  final String? value;
  final List<CsRadioGroupItem> items;

  /// Called with the value of the newly selected item.
  final ValueChanged<String>? onChange;
  final CsRadioGroupDirection direction;

  /// Shows the selection without letting the user change it. Radios stay
  /// focusable.
  final bool readOnly;

  /// Disables every item (a Flutter addition; Cloudscape disables per item).
  final bool disabled;

  /// Accessible name of the group when it is not inside a labelled
  /// `CsFormField`.
  final String? ariaLabel;

  /// Announces the group as required.
  final bool ariaRequired;

  /// Focus the tab-stop radio on mount.
  final bool autofocus;

  @override
  State<CsRadioGroup> createState() => _CsRadioGroupState();
}

class _CsRadioGroupState extends State<CsRadioGroup> {
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
      _nodes.add(FocusNode(debugLabel: 'CsRadioGroup item ${_nodes.length}'));
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
  }

  bool _enabled(int i) => !widget.disabled && !widget.items[i].disabled && widget.onChange != null;

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
    int delta;
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
      if (!widget.readOnly && widget.items[i].value != widget.value) {
        widget.onChange!(widget.items[i].value);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _syncNodes();
    final space = context.cs.space;
    final tabStop = _tabStop;
    final radios = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final enabled = _enabled(i);
      _nodes[i].skipTraversal = i != tabStop;
      Widget radio = CsRadioButton(
        checked: item.value == widget.value,
        onSelect: enabled ? () => widget.onChange!(item.value) : null,
        label: item.label,
        description: item.description,
        descriptionWidget: item.descriptionWidget,
        readOnly: widget.readOnly,
        disabled: !enabled,
        focusNode: _nodes[i],
        autofocus: widget.autofocus && i == tabStop,
        child: item.labelWidget,
      );
      if (widget.direction == CsRadioGroupDirection.horizontal) {
        // Leaves about 80 characters for a description before wrapping.
        radio = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 16 * space.scaledXxl),
          child: radio,
        );
      } else if (i > 0) {
        final prevHasDescription =
            widget.items[i - 1].description != null || widget.items[i - 1].descriptionWidget != null;
        radio = Padding(
          padding: EdgeInsets.only(top: prevHasDescription ? space.scaledXs : space.scaledXxs),
          child: radio,
        );
      }
      radios.add(Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: radio));
    }

    final Widget layout = widget.direction == CsRadioGroupDirection.horizontal
        ? Wrap(spacing: space.scaledL, runSpacing: space.scaledL, children: radios)
        : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: radios);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      hint: widget.ariaRequired ? context.csStrings.required : null,
      readOnly: widget.readOnly ? true : null,
      child: Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: _onKey, child: layout),
    );
  }
}
