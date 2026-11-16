import 'package:flutter/widgets.dart';

import '../overlays/cs_dropdown.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_option.dart';
import 'cs_token.dart';
import 'cs_token_group.dart';
import 'internal/option_list.dart';
import 'internal/select_base.dart';

/// Copy for [CsMultiselect] (Cloudscape `i18nStrings`).
@immutable
class CsMultiselectI18nStrings {
  const CsMultiselectI18nStrings({
    this.selectAllText = 'Select all',
    this.tokenLimitShowMore = 'Show more',
    this.tokenLimitShowFewer = 'Show fewer',
  });

  /// Label of the "select all" option ([CsMultiselect.enableSelectAll]).
  final String selectAllText;
  final String tokenLimitShowMore;
  final String tokenLimitShowFewer;
}

/// Cloudscape's `Multiselect`: pick any number of options from a dropdown
/// list. Chosen options show as dismissible tokens under the trigger.
///
/// ```dart
/// CsMultiselect(
///   selectedOptions: zones,
///   placeholder: 'Choose availability zones',
///   options: const [
///     CsOption(value: 'us-east-1a'),
///     CsOption(value: 'us-east-1b'),
///     CsOption(value: 'us-east-1c'),
///   ],
///   onChange: (options) => setState(() => zones = options),
/// )
/// ```
///
/// * Options show a checkbox; group labels select or clear their whole
///   group. [enableSelectAll] adds a "Select all" option at the top that
///   acts on the options currently shown (after filtering).
/// * The list stays open while options are toggled ([keepOpen]).
/// * [tokenLimit] shows that many tokens with a "Show more" toggle;
///   [hideTokens] hides them (show the selection elsewhere); [inlineTokens]
///   draws them inside the trigger instead.
///
/// It is controlled: it shows [selectedOptions] and reports the next list
/// through [onChange].
class CsMultiselect extends StatelessWidget {
  const CsMultiselect({
    super.key,
    required this.options,
    required this.selectedOptions,
    this.onChange,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.keepOpen = true,
    this.tokenLimit,
    this.hideTokens = false,
    this.inlineTokens = false,
    this.enableSelectAll = false,
    this.deselectAriaLabel,
    this.tokenLimitShowMoreAriaLabel,
    this.tokenLimitShowFewerAriaLabel,
    this.i18nStrings = const CsMultiselectI18nStrings(),
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
    this.inlineLabelText,
    this.ariaLabel,
    this.ariaRequired = false,
    this.autoFocus = false,
    this.focusNode,
    this.onFocus,
    this.onBlur,
    this.presentation = CsPresentation.auto,
    this.dropdownHeader,
    this.dropdownFooter,
    this.renderOption,
  });

  /// Options and option groups, in display order.
  final List<CsOptionItem> options;

  /// The chosen options, matched to [options] by value.
  final List<CsOption> selectedOptions;

  /// Called with the next list of chosen options.
  final ValueChanged<List<CsOption>>? onChange;

  /// Shown in the trigger (always, as Cloudscape does; the choice shows as
  /// tokens).
  final String? placeholder;
  final bool disabled;

  /// Tokens show read-only and the list does not open.
  final bool readOnly;
  final bool invalid;
  final bool warning;

  /// Keep the list open after each toggle. Cloudscape's default is true.
  final bool keepOpen;

  /// Number of tokens shown before "Show more".
  final int? tokenLimit;

  /// Hide the tokens under the trigger.
  final bool hideTokens;

  /// Draw the chosen options as inline tokens inside the trigger.
  final bool inlineTokens;

  /// Add a "Select all" option.
  final bool enableSelectAll;

  /// Accessible name of a token's dismiss button. Defaults to "Remove" followed by the label.
  final String Function(CsOption option)? deselectAriaLabel;
  final String? tokenLimitShowMoreAriaLabel;
  final String? tokenLimitShowFewerAriaLabel;
  final CsMultiselectI18nStrings i18nStrings;

  /// See [CsFilteringType].
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
  final String? inlineLabelText;
  final String? ariaLabel;
  final bool ariaRequired;
  final bool autoFocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final CsPresentation presentation;
  final Widget? dropdownHeader;
  final Widget? dropdownFooter;

  /// Custom option rows: (context, option, highlighted, selected).
  final Widget Function(BuildContext context, CsOption option, bool highlighted, bool selected)? renderOption;

  bool _isSelected(CsOption o) => selectedOptions.any((s) => s.value == o.value);

  void _toggle(OptionEntry e) {
    if (e.type == OptionEntryType.parent) {
      final group = e.group!;
      final enabled = group.options.where((o) => !o.disabled).toList();
      final all = enabled.every(_isSelected);
      if (all) {
        onChange?.call(selectedOptions.where((s) => !enabled.any((o) => o.value == s.value)).toList());
      } else {
        onChange?.call([...selectedOptions, ...enabled.where((o) => !_isSelected(o))]);
      }
      return;
    }
    final o = e.option;
    if (_isSelected(o)) {
      onChange?.call(selectedOptions.where((s) => s.value != o.value).toList());
    } else {
      onChange?.call([...selectedOptions, o]);
    }
  }

  List<CsOption> _visibleOptions(List<OptionEntry> visible) => [
    for (final e in visible)
      if ((e.type == OptionEntryType.option || e.type == OptionEntryType.child) && !e.disabled) e.option,
  ];

  void _selectAll(List<OptionEntry> visible) {
    final shown = _visibleOptions(visible);
    if (shown.every(_isSelected)) {
      onChange?.call(selectedOptions.where((s) => !shown.any((o) => o.value == s.value)).toList());
    } else {
      onChange?.call([...selectedOptions, ...shown.where((o) => !_isSelected(o))]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final enabledOptions = allOptions(options).where((o) => !o.disabled).toList();
    final selectedCount = enabledOptions.where(_isSelected).length;

    void remove(CsOption o) => onChange?.call(selectedOptions.where((s) => s.value != o.value).toList());

    final placeholderText = Text(
      placeholder ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: cs.body.copyWith(
        color: disabled ? cs.colors.textInputPlaceholderDisabled : cs.colors.textInputPlaceholder,
        fontStyle: FontStyle.italic,
      ),
    );
    Widget content = placeholderText;
    if (inlineTokens && selectedOptions.isNotEmpty) {
      content = _InlineTokens(options: selectedOptions, disabled: disabled, readOnly: readOnly);
    }

    Widget? below;
    if (!hideTokens && !inlineTokens && selectedOptions.isNotEmpty) {
      below = CsTokenGroup(
        items: [
          for (final o in selectedOptions)
            CsTokenGroupItem(
              label: o.text,
              labelTag: o.labelTag,
              description: o.description,
              tags: o.tags,
              icon: o.icon,
              iconWidget: o.iconWidget,
              disabled: disabled || o.disabled,
              dismissLabel: deselectAriaLabel?.call(o) ?? strings.removeItem(o.text),
            ),
        ],
        limit: tokenLimit,
        readOnly: readOnly,
        i18nStrings: CsTokenGroupI18nStrings(
          limitShowMore: i18nStrings.tokenLimitShowMore,
          limitShowFewer: i18nStrings.tokenLimitShowFewer,
        ),
        limitShowMoreAriaLabel: tokenLimitShowMoreAriaLabel,
        limitShowFewerAriaLabel: tokenLimitShowFewerAriaLabel,
        onDismiss: disabled || readOnly ? null : (i) => remove(selectedOptions[i]),
      );
    }

    return SelectBase(
      options: options,
      multiple: true,
      closeOnPick: !keepOpen,
      triggerContent: content,
      semanticValue: selectedOptions.isEmpty ? placeholder : selectedOptions.map((o) => o.text).join(', '),
      isSelected: _isSelected,
      onPick: _toggle,
      groupState: (group, visible) {
        final enabled = group.options.where((o) => !o.disabled).toList();
        final n = enabled.where(_isSelected).length;
        return (enabled.isNotEmpty && n == enabled.length, n > 0);
      },
      selectAllText: enableSelectAll ? i18nStrings.selectAllText : null,
      allSelected: enabledOptions.isNotEmpty && selectedCount == enabledOptions.length,
      someSelected: selectedCount > 0,
      onSelectAll: _selectAll,
      filteringType: filteringType,
      filteringPlaceholder: filteringPlaceholder,
      filteringAriaLabel: filteringAriaLabel,
      filteringClearAriaLabel: filteringClearAriaLabel,
      filteringResultsText: filteringResultsText,
      noMatch: noMatch,
      empty: empty,
      statusType: statusType,
      loadingText: loadingText,
      finishedText: finishedText,
      errorText: errorText,
      recoveryText: recoveryText,
      errorIconAriaLabel: errorIconAriaLabel,
      onLoadItems: onLoadItems,
      disabled: disabled,
      readOnly: readOnly,
      invalid: invalid,
      warning: warning,
      inlineLabelText: inlineLabelText,
      ariaLabel: ariaLabel,
      ariaRequired: ariaRequired,
      autofocus: autoFocus,
      focusNode: focusNode,
      onFocus: onFocus,
      onBlur: onBlur,
      presentation: presentation,
      dropdownHeader: dropdownHeader,
      dropdownFooter: dropdownFooter,
      optionBuilder: renderOption,
      below: below,
    );
  }
}

/// Inline tokens inside the trigger: as many as fit, then "+N".
class _InlineTokens extends StatelessWidget {
  const _InlineTokens({required this.options, required this.disabled, required this.readOnly});

  final List<CsOption> options;
  final bool disabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Rough fit: keep room for the counter; Cloudscape fades the overflow.
        const counterRoom = 40.0;
        final style = cs.text(CsTypeScale.bodyS);
        var used = 0.0;
        var shown = 0;
        for (final o in options) {
          final painter = TextPainter(
            text: TextSpan(text: o.text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final w = painter.width + 2 * cs.space.scaledXxs + 2 + CsSpace.xxs;
          painter.dispose();
          if (used + w > constraints.maxWidth - counterRoom && shown > 0) break;
          used += w;
          shown++;
        }
        final hidden = options.length - shown;
        return Row(
          spacing: CsSpace.xxs,
          children: [
            for (final o in options.take(shown))
              Flexible(
                child: CsToken(label: o.text, variant: CsTokenVariant.inline, disabled: disabled, readOnly: readOnly),
              ),
            if (hidden > 0) Text('+$hidden', style: cs.body),
          ],
        );
      },
    );
  }
}
