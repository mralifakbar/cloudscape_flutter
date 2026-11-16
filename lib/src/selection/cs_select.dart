import 'package:flutter/widgets.dart';

import '../overlays/cs_dropdown.dart';
import '../theme/theme.dart';
import 'cs_option.dart';
import 'internal/option_list.dart';
import 'internal/select_base.dart';

/// What a select trigger shows for the chosen option (Cloudscape
/// `triggerVariant`).
enum CsSelectTriggerVariant {
  /// The label (and icon).
  label,

  /// The whole option: icon, label, label tag, description and tags.
  option,
}

/// Cloudscape's `Select`: pick one option from a dropdown list.
///
/// ```dart
/// CsSelect(
///   selectedOption: instanceType,
///   placeholder: 'Choose an instance type',
///   options: const [
///     CsOption(value: 't3.micro', description: '2 vCPU, 1 GiB'),
///     CsOption(value: 't3.small', description: '2 vCPU, 2 GiB'),
///     CsOptionGroup(label: 'Compute optimized', options: [CsOption(value: 'c6i.large')]),
///   ],
///   onChange: (option) => setState(() => instanceType = option),
/// )
/// ```
///
/// * The list opens under the trigger, at least as wide as it, and flips up
///   when there is no room. At or below 688px it opens as a bottom sheet
///   ([presentation]).
/// * Arrow keys open the list and move the highlight, Enter or Space picks,
///   typing letters jumps to a matching option, Escape closes. Focus stays
///   on the trigger, or on the filter input with [filteringType].
/// * [statusType] with [loadingText], [errorText] + [recoveryText] and
///   [finishedText] shows the state of options that load asynchronously
///   through [onLoadItems].
///
/// It is controlled: it shows [selectedOption] and reports picks through
/// [onChange].
class CsSelect extends StatelessWidget {
  const CsSelect({
    super.key,
    required this.options,
    required this.selectedOption,
    this.onChange,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
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
    this.triggerVariant = CsSelectTriggerVariant.label,
    this.inlineLabelText,
    this.ariaLabel,
    this.ariaRequired = false,
    this.selectedAriaLabel,
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

  /// The chosen option, or null to show [placeholder]. Matched to [options]
  /// by value.
  final CsOption? selectedOption;

  /// Called with the picked option.
  final ValueChanged<CsOption>? onChange;

  /// Shown while nothing is chosen.
  final String? placeholder;
  final bool disabled;

  /// The value can be read and focused but not changed.
  final bool readOnly;

  /// Red border with a thick start edge. Pair with the form field's error.
  final bool invalid;

  /// Yellow border with a thick start edge. Ignored when [invalid].
  final bool warning;

  /// Adds a filter input to the dropdown. [CsFilteringType.auto] filters
  /// here (label, value, description, label tag, tags and filtering tags);
  /// [CsFilteringType.manual] leaves it to [onLoadItems].
  final CsFilteringType filteringType;
  final String? filteringPlaceholder;
  final String? filteringAriaLabel;
  final String? filteringClearAriaLabel;

  /// Text under the list while filtering, such as "3 matches".
  final String Function(int matches, int total)? filteringResultsText;

  /// Shown when the filter matches nothing.
  final Widget? noMatch;

  /// Shown when there are no options at all.
  final Widget? empty;

  /// Loading state of the options (Cloudscape `statusType`).
  final CsDropdownStatusType statusType;
  final String? loadingText;

  /// Shown at the end of the list once everything loaded.
  final String? finishedText;
  final String? errorText;

  /// Text of the retry link shown with [errorText]; it calls [onLoadItems]
  /// with `samePage: true`.
  final String? recoveryText;
  final String? errorIconAriaLabel;

  /// Called when the list opens, the filter changes, the list scrolls to its
  /// end while [statusType] is pending, and on retry.
  final ValueChanged<CsLoadItemsDetail>? onLoadItems;
  final CsSelectTriggerVariant triggerVariant;

  /// A label drawn on the trigger's top border (Cloudscape `inlineLabelText`).
  final String? inlineLabelText;

  /// Accessible name when there is no visible label.
  final String? ariaLabel;

  /// Announces the field as required.
  final bool ariaRequired;

  /// Announced with the selected option (Cloudscape `selectedAriaLabel`).
  final String? selectedAriaLabel;
  final bool autoFocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  /// Anchored list or bottom sheet. [CsPresentation.auto] uses a sheet at or
  /// below 688px.
  final CsPresentation presentation;

  /// Content above the options (Cloudscape `renderDropdownHeader`).
  final Widget? dropdownHeader;

  /// Content below the options (Cloudscape `renderDropdownFooter`).
  final Widget? dropdownFooter;

  /// Custom option rows (Cloudscape `renderOption`): (context, option,
  /// highlighted, selected).
  final Widget Function(BuildContext context, CsOption option, bool highlighted, bool selected)? renderOption;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final selected = selectedOption;
    final Widget content;
    if (selected == null) {
      content = Text(
        placeholder ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: cs.body.copyWith(
          color: disabled ? cs.colors.textInputPlaceholderDisabled : cs.colors.textInputPlaceholder,
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      final shown = triggerVariant == CsSelectTriggerVariant.option
          ? selected
          : CsOption(
              value: selected.value,
              label: selected.label,
              icon: selected.icon,
              iconWidget: selected.iconWidget,
              labelTag: selected.labelTag,
            );
      content = OptionContent(
        option: shown,
        triggerVariant: true,
        color: disabled ? cs.colors.textInputDisabled : cs.colors.textBodyDefault,
      );
    }
    final valueText = selected == null ? placeholder : [selected.text, ?selectedAriaLabel].join(', ');
    return SelectBase(
      options: options,
      triggerContent: content,
      semanticValue: valueText,
      isSelected: (o) => o.value == selected?.value,
      onPick: (e) => onChange?.call(e.option),
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
    );
  }
}
