import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_option.dart';
import 'internal/option_list.dart';
import 'internal/select_base.dart' show OptionCustomRow;
import 'internal/select_trigger.dart' show Typeahead;

/// Whether a [CsOptionList] picks one option or several (Cloudscape
/// `selectionType`).
enum CsOptionListSelectionType {
  /// One option. Choosing an option selects it; the list shows a check on
  /// the selected row.
  single,

  /// Any number. Each option has a checkbox, and a group header selects or
  /// clears every enabled option in its group.
  multi,
}

/// A row handed to [CsOptionList.renderOption] (Cloudscape
/// `OptionListProps.Item`).
@immutable
class CsOptionListItem {
  const CsOptionListItem({
    required this.isGroup,
    required this.index,
    required this.option,
    required this.selected,
    required this.highlighted,
    required this.disabled,
    this.indeterminate = false,
    this.group,
    this.parent,
  });

  /// Whether this row is a group header (Cloudscape `type: 'group'`).
  final bool isGroup;

  /// Position of the row in the flattened list.
  final int index;

  /// The option, or the group header drawn as an option.
  final CsOption option;
  final bool selected;
  final bool highlighted;
  final bool disabled;

  /// For a group header in multi selection: some, not all, of its options
  /// are selected.
  final bool indeterminate;

  /// The group, when this row is a group header.
  final CsOptionGroup? group;

  /// The group this option belongs to, if any.
  final CsOptionGroup? parent;
}

/// Copy of a [CsOptionList] (Cloudscape `OptionListProps.I18nStrings`).
@immutable
class CsOptionListI18nStrings {
  const CsOptionListI18nStrings({this.selectedAriaLabel = 'Selected'});

  /// Announced with the highlighted option when it is selected.
  final String? selectedAriaLabel;
}

/// Cloudscape's `OptionList`: an always visible list of options to pick one
/// or several from, without a trigger or dropdown.
///
/// ```dart
/// CsOptionList(
///   ariaLabel: 'Instance type',
///   selectionType: CsOptionListSelectionType.single,
///   options: const [
///     CsOption(value: 't3.micro', label: 't3.micro', description: '2 vCPU, 1 GiB'),
///     CsOption(value: 't3.large', label: 't3.large', description: '2 vCPU, 8 GiB'),
///   ],
///   selectedOptions: selected,
///   onChange: (options) => setState(() => selected = options),
/// )
/// ```
///
/// Options use the [CsOption] and [CsOptionGroup] types of the selects and
/// draw the same rows: hover and keyboard highlight, selected fill and
/// outline, descriptions, label tags, tags, icons, disabled options with a
/// reason, and group headers. In [CsOptionListSelectionType.multi] each
/// option has a checkbox and a group header toggles its group.
///
/// The list is a single Tab stop. Focus highlights the first selected
/// option (or the first option); the arrow keys move the highlight, Home and
/// End jump, Enter or Space choose, and typing letters jumps to a matching
/// option. The highlighted option is announced to screen readers.
///
/// Leave [selectedOptions] null to let the list keep its own selection
/// (Cloudscape's uncontrolled mode).
class CsOptionList extends StatefulWidget {
  const CsOptionList({
    super.key,
    required this.options,
    required this.selectionType,
    this.selectedOptions,
    this.onChange,
    this.ariaLabel,
    this.renderOption,
    this.renderHighlightedAriaLive,
    this.i18nStrings = const CsOptionListI18nStrings(),
    this.empty,
    this.focusNode,
    this.autofocus = false,
    this.maxHeight,
  });

  /// Options and option groups, in display order.
  final List<CsOptionItem> options;
  final CsOptionListSelectionType selectionType;

  /// The selected options, matched by value. In single selection only the
  /// first is used. Null leaves the selection to the list.
  final List<CsOption>? selectedOptions;

  /// Called with the next selection when the user picks an option.
  final ValueChanged<List<CsOption>>? onChange;

  /// Accessible name of the list.
  final String? ariaLabel;

  /// Draws a row's content; the list keeps the highlight and selection
  /// treatment. Return null to draw the default content.
  final Widget? Function(BuildContext context, CsOptionListItem item)? renderOption;

  /// Builds the announcement for a newly highlighted option or group header
  /// (with its group, if any). Defaults to the label and, when selected,
  /// [CsOptionListI18nStrings.selectedAriaLabel].
  final String Function(CsOptionItem option, CsOptionGroup? group)? renderHighlightedAriaLive;
  final CsOptionListI18nStrings i18nStrings;

  /// Shown when there are no options.
  final Widget? empty;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Scrolls the list when it would be taller. Unbounded by default.
  final double? maxHeight;

  @override
  State<CsOptionList> createState() => _CsOptionListState();
}

class _CsOptionListState extends State<CsOptionList> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'CsOptionList'));
  final Typeahead _typeahead = Typeahead();
  final GlobalKey _highlightKey = GlobalKey();

  List<CsOption> _internal = const [];
  int _highlight = -1;
  bool _keyboard = false;
  bool _focused = false;

  bool get _multi => widget.selectionType == CsOptionListSelectionType.multi;
  List<CsOption> get _selected => widget.selectedOptions ?? _internal;

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  bool _isSelected(CsOption o) {
    final s = _selected;
    if (!_multi) return s.isNotEmpty && s.first.value == o.value;
    return s.any((x) => x.value == o.value);
  }

  (bool, bool) _groupState(CsOptionGroup group) {
    final enabled = group.options.where((o) => !o.disabled && !group.disabled).toList();
    final n = enabled.where(_isSelected).length;
    return (enabled.isNotEmpty && n == enabled.length, n > 0);
  }

  void _pick(List<OptionEntry> entries, int index) {
    if (index < 0 || index >= entries.length) return;
    final e = entries[index];
    if (!e.isInteractive(interactiveGroups: _multi)) return;
    final current = _selected;
    List<CsOption> next;
    if (!_multi) {
      next = [e.option];
    } else if (e.type == OptionEntryType.parent) {
      final group = e.group!;
      final enabled = group.options.where((o) => !o.disabled).toList();
      if (enabled.every(_isSelected)) {
        next = current.where((s) => !enabled.any((o) => o.value == s.value)).toList();
      } else {
        next = [...current, ...enabled.where((o) => !_isSelected(o))];
      }
    } else if (_isSelected(e.option)) {
      next = current.where((s) => s.value != e.option.value).toList();
    } else {
      next = [...current, e.option];
    }
    setState(() {
      _highlight = index;
      if (widget.selectedOptions == null) _internal = next;
    });
    widget.onChange?.call(next);
  }

  void _move(List<OptionEntry> entries, int to) {
    if (to < 0) return;
    setState(() {
      _keyboard = true;
      _highlight = to;
    });
    _announce(entries[to]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _highlightKey.currentContext;
      if (ctx != null && mounted && Scrollable.maybeOf(ctx) != null) Scrollable.ensureVisible(ctx);
    });
  }

  void _announce(OptionEntry e) {
    final view = View.maybeOf(context);
    if (view == null) return;
    final String message;
    final custom = widget.renderHighlightedAriaLive;
    if (custom != null) {
      message = custom(e.type == OptionEntryType.parent ? e.group! : e.option, e.group);
    } else {
      final selected = e.type == OptionEntryType.parent ? _groupState(e.group!).$1 : _isSelected(e.option);
      final parts = <String>[
        if (e.type == OptionEntryType.child && e.group != null) e.group!.label,
        e.option.text,
        ?e.option.labelTag,
        ?e.option.description,
        ...?e.option.tags,
        if (selected && widget.i18nStrings.selectedAriaLabel != null) widget.i18nStrings.selectedAriaLabel!,
      ];
      message = parts.join(', ');
    }
    if (message.isEmpty) return;
    SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
  }

  void _onFocusChange(bool focused, List<OptionEntry> entries) {
    _focused = focused;
    if (!focused) {
      setState(() => _highlight = -1);
      return;
    }
    if (_highlight >= 0) return;
    var start = -1;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.type != OptionEntryType.parent && _isSelected(e.option)) {
        start = i;
        break;
      }
    }
    if (start < 0) start = edgeHighlight(entries, last: false, interactiveGroups: _multi);
    if (start >= 0) _move(entries, start);
  }

  KeyEventResult _onKey(KeyEvent event, List<OptionEntry> entries) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final groups = _multi;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(
        entries,
        _highlight < 0
            ? edgeHighlight(entries, last: false, interactiveGroups: groups)
            : stepHighlight(entries, _highlight, 1, interactiveGroups: groups),
      );
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(
        entries,
        _highlight < 0
            ? edgeHighlight(entries, last: true, interactiveGroups: groups)
            : stepHighlight(entries, _highlight, -1, interactiveGroups: groups),
      );
    } else if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.pageUp) {
      _move(entries, edgeHighlight(entries, last: false, interactiveGroups: groups));
    } else if (key == LogicalKeyboardKey.end || key == LogicalKeyboardKey.pageDown) {
      _move(entries, edgeHighlight(entries, last: true, interactiveGroups: groups));
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _pick(entries, _highlight);
    } else if (key == LogicalKeyboardKey.space && !_typeahead.active) {
      // Cloudscape `spaceSelects: 'always'`.
      _pick(entries, _highlight);
    } else {
      final ch = _typeahead.characterOf(event);
      if (ch == null) return KeyEventResult.ignored;
      _move(entries, _typeahead.search(entries, ch, _highlight));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final entries = flattenOptions(widget.options);
    if (_highlight >= entries.length) _highlight = -1;

    bool selectedAt(int i) {
      if (i < 0 || i >= entries.length) return false;
      final e = entries[i];
      if (e.type == OptionEntryType.parent) return false;
      return _isSelected(e.option);
    }

    Widget rowAt(int i) {
      final e = entries[i];
      var selected = false;
      var partial = false;
      if (e.type == OptionEntryType.parent) {
        if (_multi) (selected, partial) = _groupState(e.group!);
      } else {
        selected = _isSelected(e.option);
      }
      final highlighted = i == _highlight;
      void hover() {
        if (_highlight != i || _keyboard) {
          setState(() {
            _keyboard = false;
            _highlight = i;
          });
        }
      }

      void press() {
        if (!_focus.hasFocus) _focus.requestFocus();
        _pick(entries, i);
      }

      final custom = widget.renderOption?.call(
        context,
        CsOptionListItem(
          isGroup: e.type == OptionEntryType.parent,
          index: i,
          option: e.option,
          selected: selected,
          highlighted: highlighted,
          disabled: e.disabled,
          indeterminate: partial && !selected,
          group: e.type == OptionEntryType.parent ? e.group : null,
          parent: e.type == OptionEntryType.child ? e.group : null,
        ),
      );
      Widget row;
      if (custom != null && (e.type != OptionEntryType.parent || _multi)) {
        row = OptionCustomRow(
          entry: e,
          highlighted: highlighted,
          keyboard: _keyboard,
          selected: selected,
          onPress: press,
          onHover: hover,
          child: custom,
        );
      } else {
        row = OptionRow(
          entry: custom != null
              ? OptionEntry(
                  e.type,
                  CsOption(value: e.option.value, labelContent: custom),
                  group: e.group,
                  disabled: e.disabled,
                )
              : e,
          highlighted: highlighted,
          keyboard: _keyboard,
          selected: selected,
          partial: partial,
          mark: _multi ? OptionMark.checkbox : OptionMark.none,
          showSelectedIcon: !_multi,
          previousSelected: selectedAt(i - 1),
          nextSelected: selectedAt(i + 1),
          // The list has no dropdown border above it, so the first row has no divider.
          showTopDivider: i > 0 && !selectedAt(i - 1) && i - 1 != _highlight,
          interactiveGroups: _multi,
          onPress: press,
          onHover: hover,
        );
      }
      return KeyedSubtree(key: highlighted ? _highlightKey : null, child: row);
    }

    Widget list;
    if (entries.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CsSpace.fieldHorizontal,
          vertical: CsSpace.optionPaddingVertical,
        ),
        child: DefaultTextStyle.merge(
          style: cs.body.copyWith(color: cs.colors.textDropdownFooter),
          child: widget.empty ?? const SizedBox.shrink(),
        ),
      );
    } else {
      list = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < entries.length; i++) rowAt(i)],
      );
      if (widget.maxHeight != null) {
        list = ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight!),
          child: SingleChildScrollView(child: list),
        );
      }
    }

    list = MouseRegion(
      // Leaving the list clears a hover highlight unless the keyboard is in it.
      onExit: (_) {
        if (!_focused && _highlight >= 0) setState(() => _highlight = -1);
      },
      child: list,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel,
      child: Focus(
        focusNode: _focus,
        autofocus: widget.autofocus,
        onFocusChange: (f) => _onFocusChange(f, entries),
        onKeyEvent: (node, event) => _onKey(event, entries),
        child: list,
      ),
    );
  }
}
