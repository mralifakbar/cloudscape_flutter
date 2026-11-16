import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_option.dart';
import 'internal/autosuggest_hooks.dart';
import 'internal/option_list.dart';

/// What [CsAutosuggest.onSelect] reports (Cloudscape `SelectDetail`).
@immutable
class CsAutosuggestSelectDetail {
  const CsAutosuggestSelectDetail({required this.value, this.selectedOption});

  /// The picked option's value, or the typed text for the entered-text option.
  final String value;

  /// The picked option, or null when the typed text was used.
  final CsOption? selectedOption;
}

/// Cloudscape's `Autosuggest`: a text input that suggests options as the
/// user types. Unlike a select, any text is a valid value; the suggestions
/// only help.
///
/// ```dart
/// CsAutosuggest(
///   value: bucket,
///   placeholder: 'Enter a bucket name',
///   enteredTextLabel: (value) => 'Use: "$value"',
///   options: const [
///     CsOption(value: 'example-bucket'),
///     CsOption(value: 'logs-bucket'),
///   ],
///   onChange: (v) => setState(() => bucket = v),
/// )
/// ```
///
/// * Typing opens the suggestions, filtered by the text and with matches
///   highlighted ([CsFilteringType.auto]); with [CsFilteringType.manual] the
///   app filters in [onLoadItems]. The first row offers the typed text
///   itself ([enteredTextLabel]) unless [hideEnteredTextOption].
/// * Arrow keys move the highlight while focus stays in the input, Enter
///   picks, Escape closes the list and a second Escape clears the text.
/// * Picking an option sets the text to its value and calls [onSelect].
///
/// The list stays anchored under the input on every screen size, so the
/// keyboard and the text stay in view.
class CsAutosuggest extends StatefulWidget {
  const CsAutosuggest({
    super.key,
    required this.value,
    required this.options,
    this.onChange,
    this.onSelect,
    this.enteredTextLabel,
    this.hideEnteredTextOption = false,
    this.filteringType = CsFilteringType.auto,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.empty,
    this.filteringResultsText,
    this.statusType = CsDropdownStatusType.finished,
    this.loadingText,
    this.finishedText,
    this.errorText,
    this.recoveryText,
    this.errorIconAriaLabel,
    this.onLoadItems,
    this.ariaLabel,
    this.clearAriaLabel,
    this.selectedAriaLabel,
    this.autoFocus = false,
    this.focusNode,
    this.onFocus,
    this.onBlur,
    this.onSubmit,
    this.presentation = CsPresentation.popover,
    this.renderOption,
  });

  /// The text in the input.
  final String value;

  /// Suggestions and suggestion groups.
  final List<CsOptionItem> options;

  /// Called with the new text on every edit and when an option is picked.
  final ValueChanged<String>? onChange;

  /// Called when a suggestion or the entered-text option is picked.
  final ValueChanged<CsAutosuggestSelectDetail>? onSelect;

  /// Label of the option that uses the typed text, such as `Use: "abc"`.
  /// Defaults to `Use: "<value>"`.
  final String Function(String value)? enteredTextLabel;
  final bool hideEnteredTextOption;

  /// [CsFilteringType.auto] filters here; [CsFilteringType.manual] leaves
  /// filtering to the app ([onLoadItems]); [CsFilteringType.none] shows
  /// every option.
  final CsFilteringType filteringType;
  final String? placeholder;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;

  /// Shown when there are no options at all.
  final Widget? empty;

  /// Text at the end of the list while filtering, such as "3 matches".
  final String Function(int matches, int total)? filteringResultsText;

  /// See [CsDropdownStatusType].
  final CsDropdownStatusType statusType;
  final String? loadingText;
  final String? finishedText;
  final String? errorText;
  final String? recoveryText;
  final String? errorIconAriaLabel;

  /// Called when the list opens, when the text changes, when the list
  /// scrolls to its end while pending, and on retry.
  final ValueChanged<CsLoadItemsDetail>? onLoadItems;
  final String? ariaLabel;

  /// Accessible name of the clear button.
  final String? clearAriaLabel;

  /// Announced with the highlighted option when it is the current value.
  final String? selectedAriaLabel;
  final bool autoFocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  /// Enter with no highlighted suggestion (the list closed).
  final ValueChanged<String>? onSubmit;

  /// Defaults to an anchored list on every screen size.
  final CsPresentation presentation;

  /// Custom suggestion rows: (context, option, highlighted, selected).
  final Widget Function(BuildContext context, CsOption option, bool highlighted, bool selected)? renderOption;

  @override
  State<CsAutosuggest> createState() => _CsAutosuggestState();
}

class _CsAutosuggestState extends State<CsAutosuggest> {
  FocusNode? _ownFocus;
  bool _open = false;
  bool _keyboard = false;
  int _highlight = -1;
  int _requestedFor = -1;
  bool _hadFocus = false;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'Autosuggest'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CsAutosuggest old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    if (widget.disabled || widget.readOnly) _open = false;
    if (old.options != widget.options) _requestedFor = -1;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    final has = _focus.hasFocus;
    if (has == _hadFocus) return;
    _hadFocus = has;
    if (has) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }

  List<OptionEntry> get _entries {
    final flat = flattenOptions(widget.options);
    final filtered = widget.filteringType == CsFilteringType.auto ? filterEntries(flat, widget.value) : flat;
    if (widget.value.isEmpty || widget.hideEnteredTextOption) return filtered;
    return [OptionEntry(OptionEntryType.enteredText, CsOption(value: widget.value, label: _enteredLabel)), ...filtered];
  }

  String get _enteredLabel => widget.enteredTextLabel?.call(widget.value) ?? 'Use: "${widget.value}"';

  void _load({bool firstPage = true, bool samePage = false}) => widget.onLoadItems?.call(
    CsLoadItemsDetail(filteringText: widget.value, firstPage: firstPage, samePage: samePage),
  );

  void _show() {
    if (_open || widget.disabled || widget.readOnly) return;
    setState(() {
      _open = true;
      _highlight = -1;
      _requestedFor = -1;
    });
    _load();
  }

  void _close() {
    if (!_open) return;
    setState(() {
      _open = false;
      _highlight = -1;
    });
  }

  void _onText(String v) {
    widget.onChange?.call(v);
    if (!_open) {
      _show();
    } else {
      setState(() {
        _highlight = -1;
        _requestedFor = -1;
      });
      widget.onLoadItems?.call(CsLoadItemsDetail(filteringText: v, firstPage: true, samePage: false));
    }
  }

  void _pick(OptionEntry e) {
    if (e.disabled) return;
    final value = e.type == OptionEntryType.enteredText ? widget.value : e.option.value;
    widget.onChange?.call(value);
    final detail = CsAutosuggestSelectDetail(
      value: value,
      selectedOption: e.type == OptionEntryType.enteredText ? null : e.option,
    );
    widget.onSelect?.call(detail);
    if (AutosuggestHooks.maybeOf(context)?.keepOpenAfterSelect?.call(detail) ?? false) {
      setState(() {
        _highlight = -1;
        _requestedFor = -1;
      });
      return;
    }
    _close();
  }

  void _move(int to) {
    if (to < 0) return;
    setState(() {
      _keyboard = true;
      _highlight = to;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.disabled || widget.readOnly) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final entries = _entries;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _show();
        return KeyEventResult.handled;
      }
      final down = key == LogicalKeyboardKey.arrowDown;
      _move(_highlight < 0 ? edgeHighlight(entries, last: !down) : stepHighlight(entries, _highlight, down ? 1 : -1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_open && _highlight >= 0 && _highlight < entries.length) {
        _pick(entries[_highlight]);
        return KeyEventResult.handled;
      }
      _close();
      widget.onSubmit?.call(widget.value);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_open) {
        _close();
      } else if (widget.value.isNotEmpty) {
        widget.onChange?.call('');
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) _close();
    return KeyEventResult.ignored;
  }

  Widget _buildList(BuildContext context, bool inSheet) {
    final hooks = AutosuggestHooks.maybeOf(this.context);
    final entries = _entries;
    final optionCount = entries.where((e) => e.type == OptionEntryType.option || e.type == OptionEntryType.child);
    final total = allOptions(widget.options).length;
    final footer = DropdownStatusConfig(
      statusType: widget.statusType,
      empty: widget.empty,
      loadingText: widget.loadingText,
      finishedText: widget.finishedText,
      errorText: widget.errorText,
      recoveryText: widget.recoveryText,
      errorIconAriaLabel: widget.errorIconAriaLabel,
      filteringResultsText: widget.value.isNotEmpty && widget.filteringResultsText != null
          ? widget.filteringResultsText!(optionCount.length, total)
          : null,
      onRecoveryClick: widget.onLoadItems == null ? null : () => _load(firstPage: false, samePage: true),
    ).build(context, isEmpty: total == 0, isNoMatch: false);
    if (entries.isEmpty && footer == null) return const SizedBox.shrink();
    return OptionListView(
      entries: entries,
      highlighted: _highlight,
      inSheet: inSheet,
      semanticLabel: widget.ariaLabel ?? widget.placeholder,
      footer: footer,
      onScrollEnd: widget.statusType == CsDropdownStatusType.pending && widget.onLoadItems != null
          ? () {
              if (_requestedFor == entries.length) return;
              _requestedFor = entries.length;
              _load(firstPage: false);
            }
          : null,
      rowBuilder: (context, i) {
        final e = entries[i];
        final selected = e.type != OptionEntryType.enteredText && e.option.value == widget.value;
        final custom = widget.renderOption;
        final entry = custom != null && e.type != OptionEntryType.enteredText && e.type != OptionEntryType.parent
            ? OptionEntry(
                e.type,
                CsOption(value: e.option.value, labelContent: custom(context, e.option, i == _highlight, selected)),
                group: e.group,
                disabled: e.disabled,
              )
            : e;
        return OptionRow(
          entry: entry,
          highlighted: i == _highlight,
          keyboard: _keyboard,
          showTopDivider: i > 0 && i - 1 != _highlight,
          highlightText: e.type == OptionEntryType.enteredText
              ? null
              : (hooks?.highlightText ?? (widget.filteringType == CsFilteringType.auto ? widget.value : null)),
          onPress: () => _pick(e),
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
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.csStrings;
    final showClear = widget.value.isNotEmpty && !widget.disabled && !widget.readOnly;
    final input = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Listener(
        onPointerDown: (_) {
          if (!_open) _show();
        },
        // CsFieldBox fills a loose height; keep the anchor as tall as the field.
        child: UnconstrainedBox(
          constrainedAxis: Axis.horizontal,
          child: CsInput(
            value: widget.value,
            onChange: _onText,
            focusNode: _focus,
            placeholder: widget.placeholder,
            disabled: widget.disabled,
            readOnly: widget.readOnly,
            invalid: widget.invalid,
            warning: widget.warning,
            autoFocus: widget.autoFocus,
            ariaLabel: widget.ariaLabel,
            leading: AutosuggestHooks.maybeOf(context)?.leading,
            trailing: showClear
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
                    child: CsButton(
                      icon: CsIcons.close,
                      variant: CsButtonVariant.inlineIcon,
                      semanticLabel: widget.clearAriaLabel ?? strings.clear,
                      onPress: () {
                        widget.onChange?.call('');
                        _focus.requestFocus();
                      },
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
    return Semantics(
      expanded: _open,
      child: CsDropdown(
        open: _open,
        onDismiss: _close,
        presentation: widget.presentation,
        sheetLabel: widget.ariaLabel ?? widget.placeholder,
        contentBuilder: _buildList,
        child: input,
      ),
    );
  }
}
