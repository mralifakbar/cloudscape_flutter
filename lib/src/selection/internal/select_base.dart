import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../forms/cs_input.dart';
import '../../overlays/cs_dropdown.dart';
import '../../system/cs_strings.dart';
import '../../theme/theme.dart';
import '../cs_option.dart';
import 'option_list.dart';
import 'select_trigger.dart';

/// The search field at the top of a filtering dropdown.
class DropdownFilter extends StatelessWidget {
  const DropdownFilter({
    super.key,
    required this.value,
    required this.onChange,
    required this.focusNode,
    this.placeholder,
    this.ariaLabel,
    this.clearAriaLabel,
    this.onKey,
  });

  final String value;
  final ValueChanged<String> onChange;
  final FocusNode focusNode;
  final String? placeholder;
  final String? ariaLabel;
  final String? clearAriaLabel;
  final FocusOnKeyEventCallback? onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    return Container(
      padding: const EdgeInsets.all(CsSpace.xs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderDropdownItemDefault)),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: onKey,
        child: CsInput(
          type: CsInputType.search,
          value: value,
          onChange: onChange,
          focusNode: focusNode,
          placeholder: placeholder,
          ariaLabel: ariaLabel ?? placeholder,
          clearAriaLabel: clearAriaLabel,
        ),
      ),
    );
  }
}

/// Behavior shared by [CsSelect] and [CsMultiselect]: the trigger, the
/// dropdown (a bottom sheet on phones), filtering, keyboard highlight,
/// async loading and the status footer.
class SelectBase extends StatefulWidget {
  const SelectBase({
    super.key,
    required this.options,
    required this.triggerContent,
    required this.isSelected,
    required this.onPick,
    this.closeOnPick = true,
    this.multiple = false,
    this.groupState,
    this.selectAllText,
    this.allSelected = false,
    this.someSelected = false,
    this.onSelectAll,
    this.semanticValue,
    this.filteringType = CsFilteringType.none,
    this.filteringPlaceholder,
    this.filteringAriaLabel,
    this.filteringClearAriaLabel,
    this.filteringResultsText,
    this.noMatch,
    this.empty,
    this.statusType = CsDropdownStatusType.finished,
    this.loadingText,
    this.finishedText,
    this.errorText,
    this.recoveryText,
    this.errorIconAriaLabel,
    this.onLoadItems,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.inlineLabelText,
    this.ariaLabel,
    this.ariaRequired = false,
    this.autofocus = false,
    this.focusNode,
    this.onFocus,
    this.onBlur,
    this.presentation = CsPresentation.auto,
    this.dropdownHeader,
    this.dropdownFooter,
    this.below,
    this.optionBuilder,
  });

  final List<CsOptionItem> options;
  final Widget triggerContent;
  final bool Function(CsOption option) isSelected;
  final void Function(OptionEntry entry) onPick;
  final bool closeOnPick;
  final bool multiple;

  /// Multiselect: (all, some) children of a group selected.
  final (bool, bool) Function(CsOptionGroup group, List<OptionEntry> visible)? groupState;
  final String? selectAllText;
  final bool allSelected;
  final bool someSelected;
  final void Function(List<OptionEntry> visible)? onSelectAll;
  final String? semanticValue;
  final CsFilteringType filteringType;
  final String? filteringPlaceholder;
  final String? filteringAriaLabel;
  final String? filteringClearAriaLabel;
  final String Function(int matches, int total)? filteringResultsText;
  final Widget? noMatch;
  final Widget? empty;
  final CsDropdownStatusType statusType;
  final String? loadingText;
  final String? finishedText;
  final String? errorText;
  final String? recoveryText;
  final String? errorIconAriaLabel;
  final ValueChanged<CsLoadItemsDetail>? onLoadItems;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;
  final String? inlineLabelText;
  final String? ariaLabel;
  final bool ariaRequired;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final CsPresentation presentation;
  final Widget? dropdownHeader;
  final Widget? dropdownFooter;

  /// Content under the trigger (multiselect tokens).
  final Widget? below;

  /// Custom row content (Cloudscape `renderOption`).
  final Widget Function(BuildContext context, CsOption option, bool highlighted, bool selected)? optionBuilder;

  @override
  State<SelectBase> createState() => _SelectBaseState();
}

class _SelectBaseState extends State<SelectBase> {
  FocusNode? _ownFocus;
  final FocusNode _filterFocus = FocusNode(debugLabel: 'Select filter');
  final Typeahead _typeahead = Typeahead();
  bool _open = false;
  bool _keyboard = false;
  int _highlight = -1;
  String _filter = '';
  bool _hadFocus = false;
  int _requestedFor = -1;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'Select'));

  bool get _filtering => widget.filteringType != CsFilteringType.none;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(SelectBase old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    if ((widget.disabled || widget.readOnly) && _open) _open = false;
    if (old.options != widget.options) _requestedFor = -1;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _filterFocus.dispose();
    super.dispose();
  }

  void _onFocus() {
    final has = _focus.hasFocus;
    if (has == _hadFocus) return;
    _hadFocus = has;
    if (has) {
      widget.onFocus?.call();
    } else if (!_open) {
      widget.onBlur?.call();
    }
  }

  List<OptionEntry> get _entries {
    final flat = flattenOptions(widget.options);
    final filtered = widget.filteringType == CsFilteringType.auto ? filterEntries(flat, _filter) : flat;
    if (widget.selectAllText != null && filtered.isNotEmpty) {
      return [
        OptionEntry(OptionEntryType.selectAll, CsOption(value: '\u0000select-all', label: widget.selectAllText)),
        ...filtered,
      ];
    }
    return filtered;
  }

  void _load({bool firstPage = true, bool samePage = false}) {
    widget.onLoadItems?.call(CsLoadItemsDetail(filteringText: _filter, firstPage: firstPage, samePage: samePage));
  }

  void _openList({bool keyboard = false}) {
    if (widget.disabled || widget.readOnly || _open) return;
    final entries = _entries;
    var start = -1;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.type != OptionEntryType.parent && e.type != OptionEntryType.selectAll && widget.isSelected(e.option)) {
        start = i;
        break;
      }
    }
    if (start < 0 && keyboard) start = edgeHighlight(entries, last: false, interactiveGroups: widget.multiple);
    setState(() {
      _open = true;
      _keyboard = keyboard;
      _highlight = start;
      _requestedFor = -1;
    });
    _load();
    if (_filtering && !widget.presentation.usesSheet(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _filterFocus.requestFocus();
      });
    }
  }

  void _close({bool refocus = true}) {
    if (!_open) return;
    final filterHadFocus = _filterFocus.hasFocus;
    setState(() {
      _open = false;
      _highlight = -1;
      _filter = '';
    });
    if (refocus && filterHadFocus) _focus.requestFocus();
  }

  void _pickAt(int index, List<OptionEntry> entries) {
    if (index < 0 || index >= entries.length) return;
    final e = entries[index];
    if (!e.isInteractive(interactiveGroups: widget.multiple)) return;
    if (e.type == OptionEntryType.selectAll) {
      widget.onSelectAll?.call(entries.where((x) => x.type != OptionEntryType.selectAll).toList());
    } else {
      widget.onPick(e);
    }
    setState(() => _highlight = index);
    if (widget.closeOnPick) {
      _close();
      _focus.requestFocus();
    }
  }

  void _move(int to) {
    if (to < 0) return;
    setState(() {
      _keyboard = true;
      _highlight = to;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event, {required bool fromFilter}) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.disabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (!_open) {
      if (widget.readOnly) return KeyEventResult.ignored;
      if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
        _openList(keyboard: true);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        _openList(keyboard: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final entries = _entries;
    final groups = widget.multiple;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(
        _highlight < 0
            ? edgeHighlight(entries, last: false, interactiveGroups: groups)
            : stepHighlight(entries, _highlight, 1, interactiveGroups: groups),
      );
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(
        _highlight < 0
            ? edgeHighlight(entries, last: true, interactiveGroups: groups)
            : stepHighlight(entries, _highlight, -1, interactiveGroups: groups),
      );
    } else if (!fromFilter && (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.pageUp)) {
      _move(edgeHighlight(entries, last: false, interactiveGroups: groups));
    } else if (!fromFilter && (key == LogicalKeyboardKey.end || key == LogicalKeyboardKey.pageDown)) {
      _move(edgeHighlight(entries, last: true, interactiveGroups: groups));
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlight >= 0) {
        _pickAt(_highlight, entries);
      } else if (!widget.multiple) {
        _close();
      }
    } else if (key == LogicalKeyboardKey.space && !fromFilter && !_typeahead.active) {
      _pickAt(_highlight, entries);
    } else if (key == LogicalKeyboardKey.escape) {
      _close();
      _focus.requestFocus();
    } else if (key == LogicalKeyboardKey.tab) {
      _close(refocus: false);
      return KeyEventResult.ignored;
    } else if (!fromFilter) {
      final ch = _typeahead.characterOf(event);
      if (ch == null) return KeyEventResult.ignored;
      _move(_typeahead.search(entries, ch, _highlight));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onFilter(String v) {
    setState(() {
      _filter = v;
      _requestedFor = -1;
      final entries = _entries;
      _highlight = v.isEmpty ? -1 : edgeHighlight(entries, last: false, interactiveGroups: widget.multiple);
    });
    _load();
  }

  Widget _buildList(BuildContext context, bool inSheet) {
    final entries = _entries;
    final total = allOptions(widget.options).length;
    final matches = entries.where((e) => e.type == OptionEntryType.option || e.type == OptionEntryType.child).length;
    final status = DropdownStatusConfig(
      statusType: widget.statusType,
      empty: widget.empty,
      noMatch: widget.noMatch,
      loadingText: widget.loadingText,
      finishedText: widget.finishedText,
      errorText: widget.errorText,
      recoveryText: widget.recoveryText,
      errorIconAriaLabel: widget.errorIconAriaLabel,
      filteringResultsText: _filter.isNotEmpty && widget.filteringResultsText != null
          ? widget.filteringResultsText!(matches, total)
          : null,
      onRecoveryClick: widget.onLoadItems == null ? null : () => _load(firstPage: false, samePage: true),
    ).build(context, isEmpty: total == 0, isNoMatch: total > 0 && entries.isEmpty);

    final header = <Widget>[
      ?widget.dropdownHeader,
      if (_filtering)
        DropdownFilter(
          value: _filter,
          onChange: _onFilter,
          focusNode: _filterFocus,
          placeholder: widget.filteringPlaceholder,
          ariaLabel: widget.filteringAriaLabel,
          clearAriaLabel: widget.filteringClearAriaLabel,
          onKey: (node, event) => _onKey(node, event, fromFilter: true),
        ),
    ];
    final footer = <Widget>[?status, ?widget.dropdownFooter];

    bool selectedAt(int i) {
      if (i < 0 || i >= entries.length) return false;
      final e = entries[i];
      if (e.type == OptionEntryType.parent || e.type == OptionEntryType.selectAll) return false;
      return widget.isSelected(e.option);
    }

    Widget list = OptionListView(
      entries: entries,
      highlighted: _highlight,
      inSheet: inSheet,
      semanticLabel: widget.ariaLabel ?? widget.inlineLabelText,
      header: header.isEmpty
          ? null
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: header),
      footer: footer.isEmpty
          ? null
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: footer),
      onScrollEnd: widget.statusType == CsDropdownStatusType.pending && widget.onLoadItems != null
          ? () {
              if (_requestedFor == entries.length) return;
              _requestedFor = entries.length;
              _load(firstPage: false);
            }
          : null,
      rowBuilder: (context, i) {
        final e = entries[i];
        var selected = false;
        var partial = false;
        if (e.type == OptionEntryType.selectAll) {
          selected = widget.allSelected;
          partial = widget.someSelected;
        } else if (e.type == OptionEntryType.parent) {
          if (widget.multiple && widget.groupState != null) {
            final (all, some) = widget.groupState!(e.group!, entries);
            selected = all;
            partial = some;
          }
        } else {
          selected = widget.isSelected(e.option);
        }
        final highlighted = i == _highlight;
        if (widget.optionBuilder != null && e.type != OptionEntryType.parent && e.type != OptionEntryType.selectAll) {
          return OptionCustomRow(
            entry: e,
            highlighted: highlighted,
            keyboard: _keyboard,
            selected: selected,
            onPress: () => _pickAt(i, entries),
            onHover: () => setState(() {
              _keyboard = false;
              _highlight = i;
            }),
            child: widget.optionBuilder!(context, e.option, highlighted, selected),
          );
        }
        return OptionRow(
          entry: e,
          highlighted: highlighted,
          keyboard: _keyboard,
          selected: selected,
          partial: partial,
          mark: widget.multiple ? OptionMark.checkbox : OptionMark.none,
          showSelectedIcon: !widget.multiple,
          previousSelected: selectedAt(i - 1),
          nextSelected: selectedAt(i + 1),
          showTopDivider: i > 0 && !selectedAt(i - 1) && i - 1 != _highlight,
          highlightText: widget.filteringType == CsFilteringType.auto ? _filter : null,
          interactiveGroups: widget.multiple,
          onPress: () => _pickAt(i, entries),
          onHover: () {
            if (_highlight != i || _keyboard) {
              setState(() {
                _keyboard = false;
                _highlight = i;
              });
            }
          },
        );
      },
    );
    if (inSheet && _filtering) {
      list = Focus(skipTraversal: true, canRequestFocus: false, child: list);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final trigger = SelectTrigger(
      focusNode: _focus,
      autofocus: widget.autofocus,
      open: _open,
      onPress: () => _open ? _close() : _openList(),
      onKey: (node, event) => _onKey(node, event, fromFilter: false),
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      warning: widget.warning,
      inlineLabelText: widget.inlineLabelText,
      semanticLabel: widget.ariaLabel ?? widget.inlineLabelText,
      semanticValue: widget.semanticValue,
      semanticHint: widget.ariaRequired ? context.csStrings.required : null,
      child: widget.triggerContent,
    );
    final dropdown = CsDropdown(
      open: _open,
      onDismiss: () => _close(refocus: false),
      presentation: widget.presentation,
      sheetLabel: widget.ariaLabel ?? widget.inlineLabelText,
      contentBuilder: _buildList,
      child: trigger,
    );
    // Always a column, so tokens appearing below never remount the dropdown.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [dropdown, ?widget.below],
    );
  }
}

/// A row with caller-drawn content (Cloudscape `renderOption`), keeping the
/// highlight and selection treatment.
class OptionCustomRow extends StatelessWidget {
  const OptionCustomRow({
    super.key,
    required this.entry,
    required this.child,
    required this.highlighted,
    required this.keyboard,
    required this.selected,
    this.onPress,
    this.onHover,
  });

  final OptionEntry entry;
  final Widget child;
  final bool highlighted;
  final bool keyboard;
  final bool selected;
  final VoidCallback? onPress;
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    return OptionRow(
      entry: OptionEntry(
        entry.type,
        CsOption(value: entry.option.value, labelContent: child),
        disabled: entry.disabled,
      ),
      highlighted: highlighted,
      keyboard: keyboard,
      selected: selected,
      onPress: onPress,
      onHover: onHover,
    );
  }
}
