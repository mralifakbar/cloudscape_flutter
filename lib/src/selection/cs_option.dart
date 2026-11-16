import 'package:flutter/widgets.dart';

import '../icons/cs_icon_data.dart';

/// An entry in the `options` of a select, multiselect or autosuggest: a
/// [CsOption] or a [CsOptionGroup] (Cloudscape `OptionDefinition` and
/// `OptionGroup`).
sealed class CsOptionItem {
  const CsOptionItem();
}

/// One option (Cloudscape `OptionDefinition`).
///
/// ```dart
/// const CsOption(
///   value: 'i-0abc123',
///   label: 'web-server-1',
///   description: 't3.micro',
///   labelTag: 'Running',
///   tags: ['us-east-1a', '2 vCPU'],
///   icon: CsIcons.settings,
/// )
/// ```
///
/// Components compare options by [value].
@immutable
class CsOption extends CsOptionItem {
  const CsOption({
    required this.value,
    this.label,
    this.description,
    this.labelTag,
    this.tags,
    this.filteringTags,
    this.icon,
    this.iconWidget,
    this.iconAriaLabel,
    this.disabled = false,
    this.disabledReason,
    this.labelContent,
  });

  /// Identifies the option. Shown when there is no [label].
  final String value;
  final String? label;

  /// Secondary text under the label, in small text.
  final String? description;

  /// Short text at the end of the label row, such as a count or a status.
  final String? labelTag;

  /// Small text tags under the label and description.
  final List<String>? tags;

  /// Extra words the filter matches but the option does not show unless they
  /// match (Cloudscape `filteringTags`).
  final List<String>? filteringTags;

  /// Leading icon (Cloudscape `iconName`).
  final CsIconData? icon;

  /// Any widget in the icon slot (Cloudscape `iconUrl` / `iconSvg`).
  final Widget? iconWidget;

  /// Accessible name of the icon (Cloudscape `iconAriaLabel` / `iconAlt`).
  final String? iconAriaLabel;
  final bool disabled;

  /// Why the option is disabled, shown in a tooltip.
  final String? disabledReason;

  /// Custom content in place of the label (Cloudscape `labelContent`).
  final Widget? labelContent;

  /// The label, or the value when there is no label.
  String get text => label ?? value;

  /// Whether any searchable field contains [lowerText] (already lowercase).
  /// [strict] only matches at the start of a field.
  bool matches(String lowerText, {bool strict = false}) {
    if (lowerText.isEmpty) return true;
    bool hit(String? v) {
      if (v == null) return false;
      final i = v.toLowerCase().indexOf(lowerText);
      return strict ? i == 0 : i > -1;
    }

    return hit(value) ||
        hit(label) ||
        hit(description) ||
        hit(labelTag) ||
        (tags?.any(hit) ?? false) ||
        (!strict && (filteringTags?.any(hit) ?? false));
  }
}

/// A labelled group of options (Cloudscape `OptionGroup`). In a multiselect
/// the group label selects or clears every option in it.
@immutable
class CsOptionGroup extends CsOptionItem {
  const CsOptionGroup({
    required this.label,
    required this.options,
    this.description,
    this.icon,
    this.disabled = false,
    this.disabledReason,
    this.labelTag,
    this.tags,
  });

  final String label;
  final List<CsOption> options;
  final String? description;
  final CsIconData? icon;

  /// Disables every option in the group.
  final bool disabled;
  final String? disabledReason;
  final String? labelTag;
  final List<String>? tags;

  /// The group's header as an option, for drawing and filtering.
  CsOption get asOption => CsOption(
    value: label,
    label: label,
    description: description,
    icon: icon,
    disabled: disabled,
    disabledReason: disabledReason,
    labelTag: labelTag,
    tags: tags,
  );
}

/// How a select, multiselect or button dropdown filters (Cloudscape
/// `filteringType`).
enum CsFilteringType {
  /// No filter input.
  none,

  /// A filter input; the component filters the options itself.
  auto,

  /// A filter input; the app filters (usually on a server) in `onLoadItems`.
  manual,
}

/// State of a list whose options load asynchronously (Cloudscape
/// `statusType`).
enum CsDropdownStatusType {
  /// More options may load when the list scrolls to its end.
  pending,

  /// Shows `loadingText` with a spinner at the end of the list.
  loading,

  /// Everything loaded. Shows `finishedText` if given.
  finished,

  /// Loading failed. Shows `errorText` and a `recoveryText` retry link.
  error,
}

/// Details of an `onLoadItems` request (Cloudscape `LoadItemsDetail`).
@immutable
class CsLoadItemsDetail {
  const CsLoadItemsDetail({required this.filteringText, required this.firstPage, required this.samePage});

  /// Current filter text.
  final String filteringText;

  /// True when the list opened or the filter changed: replace the options.
  final bool firstPage;

  /// True for a retry after an error: request the same page again.
  final bool samePage;
}
