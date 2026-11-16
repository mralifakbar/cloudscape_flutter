import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_form_field.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../overlays/cs_sheet.dart';
import '../system/cs_field_box.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_calendar.dart';
import 'cs_date_input.dart';
import 'cs_dates_internal.dart';
import 'cs_time_input.dart';

/// Units of a relative range (Cloudscape `TimeUnit`).
enum CsTimeUnit { second, minute, hour, day, week, month, year }

/// A date range picker value: a [CsAbsoluteDateRange] or a
/// [CsRelativeDateRange] (Cloudscape `DateRangePickerProps.Value`).
sealed class CsDateRangeValue {
  const CsDateRangeValue();
}

/// A fixed range between two local date-times (Cloudscape `AbsoluteValue`).
///
/// With `dateOnly` both ends are at midnight; with month granularity both
/// are the first day of their month.
@immutable
class CsAbsoluteDateRange extends CsDateRangeValue {
  const CsAbsoluteDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) => other is CsAbsoluteDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'CsAbsoluteDateRange($start, $end)';
}

/// A range that ends now, such as "Last 5 minutes" (Cloudscape
/// `RelativeValue` and `RelativeOption`). Options passed as
/// `relativeOptions` need a unique [key].
@immutable
class CsRelativeDateRange extends CsDateRangeValue {
  const CsRelativeDateRange({this.key, required this.amount, required this.unit});

  /// Matches this value to one of the `relativeOptions`. Null for a custom
  /// range.
  final String? key;

  /// How many [unit]s. A custom range with an empty duration reports 0
  /// (Cloudscape reports `NaN`).
  final int amount;
  final CsTimeUnit unit;

  /// The start of this range counted back from [now] (`clock.now()` by
  /// default). Months and years keep the day of the month where they can.
  DateTime startFrom([DateTime? now]) {
    final n = now ?? clock.now();
    return switch (unit) {
      CsTimeUnit.second => n.subtract(Duration(seconds: amount)),
      CsTimeUnit.minute => n.subtract(Duration(minutes: amount)),
      CsTimeUnit.hour => n.subtract(Duration(hours: amount)),
      CsTimeUnit.day => DateTime(n.year, n.month, n.day - amount, n.hour, n.minute, n.second),
      CsTimeUnit.week => DateTime(n.year, n.month, n.day - 7 * amount, n.hour, n.minute, n.second),
      CsTimeUnit.month => DateTime(n.year, n.month - amount, n.day, n.hour, n.minute, n.second),
      CsTimeUnit.year => DateTime(n.year - amount, n.month, n.day, n.hour, n.minute, n.second),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is CsRelativeDateRange && other.key == key && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(key, amount, unit);

  @override
  String toString() => 'CsRelativeDateRange($key, $amount ${unit.name})';
}

/// Result of `isValidRange` (Cloudscape `ValidationResult`).
@immutable
class CsDateRangeValidationResult {
  const CsDateRangeValidationResult.valid() : valid = true, errorMessage = null;

  const CsDateRangeValidationResult.invalid(String this.errorMessage) : valid = false;

  final bool valid;

  /// Shown in the dropdown and announced when [valid] is false.
  final String? errorMessage;
}

/// Checks a range before it is applied. Receives null when nothing is
/// selected.
typedef CsDateRangeValidator = CsDateRangeValidationResult Function(CsDateRangeValue? value);

/// Which kinds of range can be picked (Cloudscape `rangeSelectorMode`).
enum CsDateRangeSelectorMode {
  /// Relative and absolute, with a switch between them. The default.
  defaultMode,

  /// Absolute ranges only.
  absoluteOnly,

  /// Relative ranges only.
  relativeOnly,
}

/// Which period the first of two calendar grids shows (Cloudscape
/// `absoluteMultiGridStartPeriod`).
enum CsDateRangeStartPeriod {
  /// The previous period when nothing is selected, the current one
  /// otherwise. The default.
  auto,

  /// Always start with the previous month (or year).
  previous,

  /// Always start with the current month (or year).
  current,
}

/// The absolute range being edited in the dropdown, as typed (Cloudscape
/// `PendingAbsoluteValue`): ISO dates (`YYYY-MM-DD`) and times (`hh:mm:ss`).
@immutable
class CsPendingAbsoluteRange {
  const CsPendingAbsoluteRange({this.startDate = '', this.startTime = '', this.endDate = '', this.endTime = ''});

  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;

  CsPendingAbsoluteRange copyWith({String? startDate, String? startTime, String? endDate, String? endTime}) =>
      CsPendingAbsoluteRange(
        startDate: startDate ?? this.startDate,
        startTime: startTime ?? this.startTime,
        endDate: endDate ?? this.endDate,
        endTime: endTime ?? this.endTime,
      );

  @override
  bool operator ==(Object other) =>
      other is CsPendingAbsoluteRange &&
      other.startDate == startDate &&
      other.startTime == startTime &&
      other.endDate == endDate &&
      other.endTime == endTime;

  @override
  int get hashCode => Object.hash(startDate, startTime, endDate, endTime);
}

/// Extra content under the absolute calendar (Cloudscape
/// `customAbsoluteRangeControl`): gets the pending range and a setter.
typedef CsAbsoluteRangeControlBuilder =
    Widget Function(BuildContext context, CsPendingAbsoluteRange range, ValueChanged<CsPendingAbsoluteRange> setRange);

/// Replaces the relative tab (Cloudscape `renderRelativeRangeContent`).
typedef CsRelativeRangeContentBuilder =
    Widget Function(BuildContext context, CsRelativeDateRange? range, ValueChanged<CsRelativeDateRange> setRange);

/// Replaces the trigger content (Cloudscape `renderTriggerContent`); gets
/// the formatted range, or the placeholder.
typedef CsDateRangeTriggerBuilder = Widget Function(BuildContext context, String formattedDate);

String _plural(int n, String one) => n == 1 ? one : '${one}s';

/// Copy for [CsDateRangePicker] (Cloudscape `DateRangePickerProps.
/// I18nStrings`). Every field defaults to Cloudscape's English.
@immutable
class CsDateRangePickerI18nStrings {
  const CsDateRangePickerI18nStrings({
    this.modeSelectionLabel = 'Date range mode',
    this.relativeModeTitle = 'Relative mode',
    this.absoluteModeTitle = 'Absolute mode',
    this.relativeRangeSelectionHeading = 'Choose a range',
    this.relativeRangeSelectionMonthlyDescription =
        'Each option represents the full month, counting from its first day to its last.',
    this.cancelButtonLabel = 'Cancel',
    this.clearButtonLabel = 'Clear and dismiss',
    this.applyButtonLabel = 'Apply',
    this.formatRelativeRange,
    this.formatUnit,
    this.customRelativeRangeOptionLabel = 'Custom range',
    this.customRelativeRangeOptionDescription = 'Set a custom range in the past',
    this.customRelativeRangeDurationLabel = 'Duration',
    this.customRelativeRangeDurationPlaceholder = 'Enter a duration',
    this.customRelativeRangeUnitLabel = 'Unit of time',
    this.startMonthLabel = 'Start month',
    this.startDateLabel = 'Start date',
    this.startTimeLabel = 'Start time',
    this.endMonthLabel = 'End month',
    this.endDateLabel = 'End date',
    this.endTimeLabel = 'End time',
    this.dateConstraintText,
    this.dateTimeConstraintText,
    this.monthConstraintText,
    this.errorIconAriaLabel = 'Error',
    this.incompleteRangeErrorMessage =
        'The selected date range is incomplete. Select a start and end date for the date range.',
    this.renderSelectedAbsoluteRangeAriaLive,
    this.todayAriaLabel = 'Today',
    this.currentMonthAriaLabel = 'This month',
    this.nextMonthAriaLabel = 'Next month',
    this.previousMonthAriaLabel = 'Previous month',
    this.nextYearAriaLabel = 'Next year',
    this.previousYearAriaLabel = 'Previous year',
    this.datePlaceholder,
    this.timePlaceholder,
  });

  /// Accessible name of the relative / absolute switch.
  final String modeSelectionLabel;
  final String relativeModeTitle;
  final String absoluteModeTitle;
  final String relativeRangeSelectionHeading;

  /// Shown under the heading with month granularity.
  final String relativeRangeSelectionMonthlyDescription;
  final String cancelButtonLabel;
  final String clearButtonLabel;
  final String applyButtonLabel;

  /// Turns a relative range into text. Default "Last 5 minutes".
  final String Function(CsRelativeDateRange value)? formatRelativeRange;

  /// A unit's name for an amount. Default "minute" / "minutes".
  final String Function(CsTimeUnit unit, int amount)? formatUnit;
  final String customRelativeRangeOptionLabel;
  final String customRelativeRangeOptionDescription;
  final String customRelativeRangeDurationLabel;
  final String customRelativeRangeDurationPlaceholder;
  final String customRelativeRangeUnitLabel;
  final String startMonthLabel;
  final String startDateLabel;
  final String startTimeLabel;
  final String endMonthLabel;
  final String endDateLabel;
  final String endTimeLabel;

  /// Constraint text with `dateOnly`. Default "For date, use YYYY/MM/DD."
  /// (with dashes for ISO input).
  final String? dateConstraintText;

  /// Constraint text with times. Default "For date, use YYYY/MM/DD. For
  /// time, use 24 hr format."
  final String? dateTimeConstraintText;

  /// Constraint text with month granularity. Default "For month, use
  /// YYYY/MM."
  final String? monthConstraintText;

  /// Accessible name of the error icon.
  final String errorIconAriaLabel;

  /// Shown when Apply is pressed with a missing or unreadable start or end
  /// date. Cloudscape leaves this check to `isValidRange`; here a range
  /// handed to `isValidRange` is always complete.
  final String incompleteRangeErrorMessage;

  /// Announcement when an absolute range is picked. Default "Range selected
  /// from {start} to {end}".
  final String Function(String startDate, String endDate)? renderSelectedAbsoluteRangeAriaLive;
  final String todayAriaLabel;
  final String currentMonthAriaLabel;
  final String nextMonthAriaLabel;
  final String previousMonthAriaLabel;
  final String nextYearAriaLabel;
  final String previousYearAriaLabel;

  /// Placeholder of the date inputs. Default `YYYY/MM/DD` (or `YYYY-MM-DD`).
  final String? datePlaceholder;

  /// Placeholder of the time inputs. Default the time format, such as
  /// `hh:mm:ss`.
  final String? timePlaceholder;

  String unit(CsTimeUnit unit, int amount) => formatUnit?.call(unit, amount) ?? _plural(amount, unit.name);

  String relativeRange(CsRelativeDateRange value) =>
      formatRelativeRange?.call(value) ?? 'Last ${value.amount} ${_plural(value.amount, value.unit.name)}';

  String selectedRange(String start, String end) =>
      renderSelectedAbsoluteRangeAriaLive?.call(start, end) ?? 'Range selected from $start to $end';
}

const _customKey = '__cs_custom_relative_range__';

/// Cloudscape's `DateRangePicker`: a trigger that opens a dropdown for
/// picking an absolute range on a calendar (with optional times) or a
/// relative range such as "Last 5 minutes".
///
/// It is controlled: [value] is a [CsAbsoluteDateRange], a
/// [CsRelativeDateRange] or null, and [onChange] fires when the user
/// applies a range (or clears it). Changes inside the dropdown stay pending
/// until Apply, which first runs [isValidRange].
///
/// ```dart
/// CsDateRangePicker(
///   value: range,
///   onChange: (v) => setState(() => range = v),
///   placeholder: 'Filter by a date and time range',
///   relativeOptions: const [
///     CsRelativeDateRange(key: 'previous-5-minutes', amount: 5, unit: CsTimeUnit.minute),
///     CsRelativeDateRange(key: 'previous-1-hour', amount: 1, unit: CsTimeUnit.hour),
///     CsRelativeDateRange(key: 'previous-1-day', amount: 1, unit: CsTimeUnit.day),
///   ],
///   isValidRange: (v) {
///     if (v is CsAbsoluteDateRange && v.end.isBefore(v.start)) {
///       return const CsDateRangeValidationResult.invalid('The end date must be after the start date.');
///     }
///     if (v is CsRelativeDateRange && v.amount <= 0) {
///       return const CsDateRangeValidationResult.invalid('Enter a duration.');
///     }
///     return const CsDateRangeValidationResult.valid();
///   },
/// )
/// ```
///
/// * Wide screens show two month grids side by side; at or below 688px
///   (`context.csIsNarrow`) one grid, and the dropdown opens as a bottom
///   sheet (see [presentation]).
/// * Calendar picks: the first tap sets the start (00:00:00), the second
///   the end (23:59:59), swapping them when the second is earlier; a third
///   tap starts over. The date and time fields below the calendar edit the
///   same pending range.
/// * Keyboard: the trigger opens with Enter or Space; in the grid, arrows
///   move by day and week, Page Up and Page Down by month, Home and End to
///   the ends of the week, Enter and Space pick; Escape closes and returns
///   focus to the trigger.
class CsDateRangePicker extends StatefulWidget {
  const CsDateRangePicker({
    super.key,
    required this.value,
    this.onChange,
    this.relativeOptions = const [],
    this.isValidRange,
    this.isDateEnabled,
    this.dateDisabledReason,
    this.startOfWeek,
    this.i18nStrings = const CsDateRangePickerI18nStrings(),
    this.dateOnly = false,
    this.granularity = CsDateGranularity.day,
    this.rangeSelectorMode = CsDateRangeSelectorMode.defaultMode,
    this.dateInputFormat = CsDateInputFormat.slashed,
    this.timeInputFormat = CsTimeInputFormat.hhMmSs,
    this.absoluteFormat = CsDateFormat.iso,
    this.hideTimeOffset = false,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.showClearButton = true,
    this.customAbsoluteRangeControl,
    this.customRelativeRangeUnits,
    this.renderRelativeRangeContent,
    this.renderTriggerContent,
    this.absoluteMultiGridStartPeriod = CsDateRangeStartPeriod.auto,
    this.ariaLabel,
    this.onFocus,
    this.onBlur,
    this.presentation = CsPresentation.auto,
    this.focusNode,
  });

  /// The applied range, or null.
  final CsDateRangeValue? value;

  /// Called with the new range on Apply, or null on Clear.
  final ValueChanged<CsDateRangeValue?>? onChange;

  /// Suggested relative ranges. Each needs a unique `key`.
  final List<CsRelativeDateRange> relativeOptions;

  /// Checks a range before it is applied; an invalid result keeps the
  /// dropdown open and shows its message. Valid by default.
  final CsDateRangeValidator? isValidRange;

  /// Days that can be picked in the calendar. Typed dates are not checked.
  final CsIsDateEnabled? isDateEnabled;

  /// Why a disabled day can not be picked, shown in a tooltip.
  final CsDateDisabledReason? dateDisabledReason;

  /// First day of the week, 0 (Sunday) to 6 (Saturday).
  final int? startOfWeek;
  final CsDateRangePickerI18nStrings i18nStrings;

  /// Hide the time inputs; ranges hold whole days.
  final bool dateOnly;

  /// Days or months.
  final CsDateGranularity granularity;
  final CsDateRangeSelectorMode rangeSelectorMode;

  /// How dates are typed in the absolute tab.
  final CsDateInputFormat dateInputFormat;

  /// Parts of the time inputs. Ignored with [dateOnly] or months.
  final CsTimeInputFormat timeInputFormat;

  /// How an absolute range is written in the trigger.
  final CsDateFormat absoluteFormat;

  /// Leave the UTC offset out of the trigger text.
  final bool hideTimeOffset;

  /// Shown in the trigger while [value] is null.
  final String? placeholder;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;

  /// Show "Clear and dismiss" in the footer.
  final bool showClearButton;
  final CsAbsoluteRangeControlBuilder? customAbsoluteRangeControl;

  /// Units offered for a custom relative range.
  final List<CsTimeUnit>? customRelativeRangeUnits;
  final CsRelativeRangeContentBuilder? renderRelativeRangeContent;
  final CsDateRangeTriggerBuilder? renderTriggerContent;
  final CsDateRangeStartPeriod absoluteMultiGridStartPeriod;

  /// Accessible name of the trigger and dropdown.
  final String? ariaLabel;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  /// Dropdown on wide screens, bottom sheet on phones by default.
  final CsPresentation presentation;

  /// Focus node of the trigger (Cloudscape `ref.focus()`).
  final FocusNode? focusNode;

  @override
  State<CsDateRangePicker> createState() => _CsDateRangePickerState();
}

class _CsDateRangePickerState extends State<CsDateRangePicker> {
  bool _open = false;
  FocusNode? _ownNode;

  /// Shared with the unit menu so taps in it do not close this dropdown.
  final Object _tapGroup = Object();

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'CsDateRangePicker'));

  bool get _monthOnly => widget.granularity == CsDateGranularity.month;
  bool get _hideTime => widget.dateOnly || _monthOnly;

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  CsDateRangeValue? get _value {
    final v = widget.value;
    if (v is CsAbsoluteDateRange && widget.rangeSelectorMode == CsDateRangeSelectorMode.relativeOnly) return null;
    if (v is CsRelativeDateRange && widget.rangeSelectorMode == CsDateRangeSelectorMode.absoluteOnly) return null;
    return v;
  }

  void _close({bool focusTrigger = false}) {
    if (!_open) return;
    setState(() => _open = false);
    if (focusTrigger) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
  }

  String _formatDateTime(DateTime d, CsStrings strings) {
    final labels = CsDateLabels(strings);
    if (widget.absoluteFormat == CsDateFormat.longLocalized) {
      if (_monthOnly) return labels.monthYear(d);
      final date = labels.date(d);
      if (widget.dateOnly) return date;
      final time = '${csTwo(d.hour)}:${csTwo(d.minute)}:${csTwo(d.second)}';
      if (widget.hideTimeOffset) return '$date, $time';
      final offset = d.timeZoneOffset.inMinutes;
      final h = offset.abs() ~/ 60;
      final m = offset.abs() % 60;
      final tz = offset == 0 ? '(UTC)' : '(UTC${offset < 0 ? '-' : '+'}$h${m == 0 ? '' : ':$m'})';
      return '$date, $time $tz';
    }
    final slashed = widget.absoluteFormat == CsDateFormat.slashed;
    var date = csFormatIso(d, monthOnly: _monthOnly);
    if (slashed) date = date.replaceAll('-', '/');
    if (_hideTime) return date;
    final time = '${csTwo(d.hour)}:${csTwo(d.minute)}:${csTwo(d.second)}';
    if (widget.hideTimeOffset) return '${date}T$time';
    final offset = d.timeZoneOffset.inMinutes;
    final tz = offset == 0 ? 'Z' : '${offset < 0 ? '-' : '+'}${csTwo(offset.abs() ~/ 60)}:${csTwo(offset.abs() % 60)}';
    return '${date}T$time$tz';
  }

  String? _formatted(CsStrings strings) {
    final v = _value;
    return switch (v) {
      null => null,
      CsRelativeDateRange() => widget.i18nStrings.relativeRange(v),
      CsAbsoluteDateRange() => '${_formatDateTime(v.start, strings)} – ${_formatDateTime(v.end, strings)}',
    };
  }

  CsDateRangeValidationResult _apply(CsDateRangeValue? value) {
    final result = widget.isValidRange?.call(value) ?? const CsDateRangeValidationResult.valid();
    if (result.valid) widget.onChange?.call(value);
    return result;
  }

  Widget _dropdown(BuildContext context, bool inSheet) {
    return _RangeDropdown(
      picker: widget,
      value: _value,
      inSheet: inSheet,
      singleGrid: inSheet || context.csIsNarrow,
      tapGroup: _tapGroup,
      onApply: _apply,
      onClear: () => widget.onChange?.call(null),
      onClose: () {
        if (inSheet) CsSheetScope.closeFrom(context);
        _close(focusTrigger: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final formatted = _formatted(strings);
    final inactive = widget.disabled || widget.readOnly;
    final status = widget.invalid
        ? CsFieldStatus.invalid
        : widget.warning
        ? CsFieldStatus.warning
        : CsFieldStatus.none;
    final shown = formatted ?? widget.placeholder ?? '';

    final trigger = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (has) => has ? widget.onFocus?.call() : widget.onBlur?.call(),
      child: CsPressable(
        focusNode: _node,
        onPress: widget.disabled ? null : (widget.readOnly ? () {} : () => setState(() => _open = true)),
        disabled: widget.disabled,
        showFocusRing: false,
        scaleOnPress: false,
        expanded: inactive ? null : _open,
        semanticLabel: widget.ariaLabel,
        semanticValue: shown,
        excludeChildSemantics: true,
        builder: (context, state) {
          final Widget content =
              widget.renderTriggerContent?.call(context, shown) ??
              Row(
                children: [
                  CsIcon(
                    CsIcons.calendar,
                    variant: inactive ? CsIconVariant.disabled : CsIconVariant.normal,
                    // Cloudscape `.icon-wrapper`: interactive color, hover color on hover.
                    dangerouslySetColor: inactive
                        ? null
                        : cs.color(state.hovered ? CsColor.textInteractiveHover : CsColor.textInteractiveDefault),
                  ),
                  const SizedBox(width: CsSpace.xs),
                  Expanded(
                    child: Text(
                      shown,
                      style: cs.text(
                        CsTypeScale.bodyM,
                        color: widget.disabled
                            ? CsColor.textInputDisabled
                            : formatted == null
                            ? CsColor.textInputPlaceholder
                            : CsColor.textBodyDefault,
                      ),
                    ),
                  ),
                ],
              );
          return CsFieldBox(
            focused: state.focused || _open,
            status: status,
            disabled: widget.disabled,
            readOnly: widget.readOnly,
            child: content,
          );
        },
      ),
    );

    final constrained = ConstrainedBox(
      // Cloudscape `.root { max-inline-size: 32em }` (39em for long dates).
      constraints: BoxConstraints(
        maxWidth: widget.absoluteFormat == CsDateFormat.longLocalized && !_hideTime ? 39 * 14 : 32 * 14,
      ),
      child: UnconstrainedBox(constrainedAxis: Axis.horizontal, child: trigger),
    );
    if (inactive) return constrained;
    return CsDropdown(
      open: _open,
      onDismiss: () => _close(),
      presentation: widget.presentation,
      matchTriggerWidth: false,
      preferredHeight: 480,
      trapFocus: true,
      sheetLabel: widget.ariaLabel ?? widget.placeholder,
      tapRegionGroupId: _tapGroup,
      contentBuilder: _dropdown,
      child: constrained,
    );
  }
}

/// The dropdown: mode switch, absolute calendar or relative options,
/// validation error and the Clear / Cancel / Apply footer.
class _RangeDropdown extends StatefulWidget {
  const _RangeDropdown({
    required this.picker,
    required this.value,
    required this.inSheet,
    required this.singleGrid,
    required this.tapGroup,
    required this.onApply,
    required this.onClear,
    required this.onClose,
  });

  final CsDateRangePicker picker;
  final CsDateRangeValue? value;
  final bool inSheet;
  final bool singleGrid;
  final Object tapGroup;
  final CsDateRangeValidationResult Function(CsDateRangeValue? value) onApply;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  State<_RangeDropdown> createState() => _RangeDropdownState();
}

enum _Mode { absolute, relative }

class _RangeDropdownState extends State<_RangeDropdown> {
  late _Mode _mode;
  late CsPendingAbsoluteRange _absolute;
  CsRelativeDateRange? _relative;
  CsDateRangeValidationResult _validation = const CsDateRangeValidationResult.valid();
  bool _applyClicked = false;

  CsDateRangePicker get p => widget.picker;
  bool get _monthOnly => p.granularity == CsDateGranularity.month;
  bool get _hideTime => p.dateOnly || _monthOnly;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _mode = switch (p.rangeSelectorMode) {
      CsDateRangeSelectorMode.absoluteOnly => _Mode.absolute,
      CsDateRangeSelectorMode.relativeOnly => _Mode.relative,
      CsDateRangeSelectorMode.defaultMode =>
        v is CsAbsoluteDateRange || (v == null && p.relativeOptions.isEmpty) ? _Mode.absolute : _Mode.relative,
    };
    _absolute = v is CsAbsoluteDateRange ? _split(v) : const CsPendingAbsoluteRange();
    _relative = v is CsRelativeDateRange ? v : null;
  }

  CsPendingAbsoluteRange _split(CsAbsoluteDateRange v) {
    String time(DateTime d) => _hideTime ? '' : '${csTwo(d.hour)}:${csTwo(d.minute)}:${csTwo(d.second)}';
    return CsPendingAbsoluteRange(
      startDate: csFormatIso(v.start, monthOnly: _monthOnly),
      startTime: time(v.start),
      endDate: csFormatIso(v.end, monthOnly: _monthOnly),
      endTime: time(v.end),
    );
  }

  /// Cloudscape `joinAbsoluteValue`, returning null when a date is missing.
  CsAbsoluteDateRange? _join(CsPendingAbsoluteRange r) {
    final complete = _monthOnly ? RegExp(r'^\d{4}-\d{2}$') : RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!complete.hasMatch(r.startDate) || !complete.hasMatch(r.endDate)) return null;
    final s = csParseIso(r.startDate);
    final e = csParseIso(r.endDate);
    if (s == null || e == null) return null;
    if (_hideTime) return CsAbsoluteDateRange(start: s, end: e);
    final st = csParseTime(r.startTime.isEmpty ? '00:00:00' : r.startTime);
    final et = csParseTime(r.endTime.isEmpty ? '23:59:59' : r.endTime);
    if (st == null || et == null) return null;
    return CsAbsoluteDateRange(
      start: DateTime(s.year, s.month, s.day, st.hour, st.minute, st.second),
      end: DateTime(e.year, e.month, e.day, et.hour, et.minute, et.second),
    );
  }

  CsDateRangeValidationResult _validate({required bool apply}) {
    CsDateRangeValue? value;
    if (_mode == _Mode.relative) {
      value = _relative;
    } else {
      final empty = _absolute == const CsPendingAbsoluteRange();
      value = _join(_absolute);
      if (value == null && !empty) {
        return CsDateRangeValidationResult.invalid(p.i18nStrings.incompleteRangeErrorMessage);
      }
    }
    if (apply) return widget.onApply(value);
    return p.isValidRange?.call(value) ?? const CsDateRangeValidationResult.valid();
  }

  void _onApply() {
    final result = _validate(apply: true);
    if (!result.valid) {
      setState(() {
        _applyClicked = true;
        _validation = result;
      });
      SemanticsService.sendAnnouncement(View.of(context), result.errorMessage ?? '', Directionality.of(context));
      return;
    }
    widget.onClose();
  }

  void _revalidate() {
    if (_applyClicked) _validation = _validate(apply: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final i18n = p.i18nStrings;
    final single = widget.singleGrid;
    const grid = CsSize.calendarGridWidth;
    final contentWidth = single ? grid + 2 * CsSpace.l : 2 * grid + CsSpace.xs + 2 * CsSpace.l;
    final horizontal = widget.inSheet ? CsSpace.m : CsSpace.l;

    final body = Padding(
      padding: EdgeInsets.only(top: widget.inSheet ? 0 : CsSpace.m, left: horizontal, right: horizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.rangeSelectorMode == CsDateRangeSelectorMode.defaultMode) ...[
            _ModeSwitcher(
              label: i18n.modeSelectionLabel,
              relativeTitle: i18n.relativeModeTitle,
              absoluteTitle: i18n.absoluteModeTitle,
              absolute: _mode == _Mode.absolute,
              onChange: (absolute) => setState(() {
                _mode = absolute ? _Mode.absolute : _Mode.relative;
                _applyClicked = false;
                _validation = const CsDateRangeValidationResult.valid();
              }),
            ),
            const SizedBox(height: CsSpace.s),
          ],
          if (_mode == _Mode.absolute)
            _RangeCalendar(
              picker: p,
              value: _absolute,
              singleGrid: single,
              stretch: widget.inSheet,
              onChange: (r) => setState(() {
                _absolute = r;
                _revalidate();
              }),
            )
          else
            _RelativeRange(
              picker: p,
              initial: _relative,
              singleGrid: single,
              tapGroup: widget.tapGroup,
              onChange: (r) => setState(() {
                _relative = r;
                _revalidate();
              }),
            ),
          if (!_validation.valid) ...[
            const SizedBox(height: CsSpace.s),
            _ErrorBox(message: _validation.errorMessage ?? '', iconLabel: i18n.errorIconAriaLabel),
          ],
        ],
      ),
    );

    final footer = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.colors.borderDropdownItemDefault)),
      ),
      padding: EdgeInsets.only(
        left: single ? CsSpace.xs : CsSpace.l,
        right: single ? CsSpace.xs : CsSpace.l,
        bottom: CsSpace.s,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (p.showClearButton)
            Padding(
              padding: const EdgeInsets.only(top: CsSpace.s),
              child: CsButton(
                variant: CsButtonVariant.link,
                text: i18n.clearButtonLabel,
                onPress: () {
                  widget.onClear();
                  widget.onClose();
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CsSpace.xs,
              children: [
                CsButton(variant: CsButtonVariant.link, text: i18n.cancelButtonLabel, onPress: widget.onClose),
                CsButton(text: i18n.applyButtonLabel, onPress: _onApply),
              ],
            ),
          ),
        ],
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: CsSpace.l),
        footer,
      ],
    );

    if (widget.inSheet) {
      return SingleChildScrollView(child: content);
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) => CsDatesDropdownSurface(
          semanticLabel: p.ariaLabel,
          child: SizedBox(
            width: math.min(contentWidth, constraints.maxWidth),
            child: SingleChildScrollView(child: content),
          ),
        ),
      ),
    );
  }
}

/// Cloudscape's segmented control, reduced to the relative / absolute
/// switch.
class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.label,
    required this.relativeTitle,
    required this.absoluteTitle,
    required this.absolute,
    required this.onChange,
  });

  final String label;
  final String relativeTitle;
  final String absoluteTitle;
  final bool absolute;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.input));
    Widget segment(String text, bool selected, VoidCallback onPress) => Expanded(
      child: CsPressable(
        onPress: onPress,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        semanticLabel: text,
        excludeChildSemantics: true,
        borderRadius: radius,
        builder: (context, state) => Container(
          constraints: const BoxConstraints(minHeight: 28),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: CsSpace.s, vertical: CsSpace.xxxs),
          decoration: BoxDecoration(
            color: selected
                ? c.backgroundSegmentActive
                : state.active
                ? c.backgroundSegmentHover
                : c.backgroundSegmentDefault,
            borderRadius: radius,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: cs.text(
              CsTypeScale.bodyM,
              weight: CsTypography.bold,
              color: selected
                  ? CsColor.textSegmentActive
                  : state.active
                  ? CsColor.textSegmentHover
                  : CsColor.textSegmentDefault,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(CsSpace.xxxs),
        decoration: BoxDecoration(
          color: c.backgroundSegmentWrapper,
          borderRadius: const BorderRadius.all(Radius.circular(CsBorderRadius.input + CsSpace.xxxs)),
          border: CsRing.inside(c.borderSegmentWrapper),
        ),
        child: Row(
          spacing: CsSpace.xxxs,
          children: [
            segment(relativeTitle, !absolute, () => onChange(false)),
            segment(absoluteTitle, absolute, () => onChange(true)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.iconLabel});

  final String message;
  final String iconLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.alert));
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(color: cs.colors.backgroundStatusError, borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: CsRing.inside(cs.colors.borderStatusError, width: CsBorderWidth.alert),
        ),
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.alertHorizontal, vertical: CsSpace.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CsIcon(CsIcons.statusNegative, variant: CsIconVariant.error, semanticLabel: iconLabel),
            ),
            const SizedBox(width: CsSpace.xs),
            Expanded(child: Text(message, style: cs.body)),
          ],
        ),
      ),
    );
  }
}

/// The absolute tab: one or two calendar grids and the date and time
/// fields.
class _RangeCalendar extends StatefulWidget {
  const _RangeCalendar({
    required this.picker,
    required this.value,
    required this.singleGrid,
    required this.stretch,
    required this.onChange,
  });

  final CsDateRangePicker picker;
  final CsPendingAbsoluteRange value;
  final bool singleGrid;
  final bool stretch;
  final ValueChanged<CsPendingAbsoluteRange> onChange;

  @override
  State<_RangeCalendar> createState() => _RangeCalendarState();
}

class _GridCell {
  const _GridCell(this.date, this.visible);

  final DateTime date;
  final bool visible;
}

class _RangeCalendarState extends State<_RangeCalendar> {
  late DateTime _page;
  DateTime? _focused;
  final List<FocusNode> _nodes = [];
  String _announcement = '';

  CsDateRangePicker get p => widget.picker;
  bool get _monthOnly => p.granularity == CsDateGranularity.month;
  bool get _hideTime => p.dateOnly || _monthOnly;
  int get _grids => widget.singleGrid ? 1 : 2;

  DateTime? get _start => widget.value.startDate.isEmpty ? null : csParseIso(widget.value.startDate);
  DateTime? get _end => widget.value.endDate.isEmpty ? null : csParseIso(widget.value.endDate);

  int get _startOfWeek => p.startOfWeek ?? context.csStrings.firstDayOfWeek % 7;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 84; i++) {
      final node = FocusNode(debugLabel: 'CsDateRangePicker cell $i');
      node.addListener(() => _onNodeFocus(i, node));
      _nodes.add(node);
    }
    _page = _findPage();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _focusable;
      if (target != null) _nodeFor(target)?.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  DateTime _startOfPage(DateTime d) => _monthOnly ? DateTime(d.year) : csFirstOfMonth(d);
  DateTime _addPage(DateTime d, int n) => _monthOnly ? DateTime(d.year + n) : csAddMonths(d, n);
  bool _samePage(DateTime a, DateTime b) => _monthOnly ? csSameYear(a, b) : csSameMonth(a, b);
  bool _sameItem(DateTime? a, DateTime? b) => _monthOnly ? csSameMonth(a, b) : csSameDay(a, b);

  /// Cloudscape `findMonthToDisplay` / `findYearToDisplay`.
  DateTime _findPage() {
    final start = _start;
    final end = _end;
    var period = p.absoluteMultiGridStartPeriod;
    if (period == CsDateRangeStartPeriod.auto) {
      period = start != null || end != null ? CsDateRangeStartPeriod.current : CsDateRangeStartPeriod.previous;
    }
    if (period == CsDateRangeStartPeriod.previous && start != null && end != null && !_samePage(start, end)) {
      period = CsDateRangeStartPeriod.current;
    }
    final offset = widget.singleGrid || period == CsDateRangeStartPeriod.current ? 0 : -1;
    return _startOfPage(_addPage(start ?? end ?? csDay(clock.now()), offset));
  }

  bool _enabled(DateTime d) => p.isDateEnabled?.call(d) ?? true;

  String? _reason(DateTime d) {
    if (_enabled(d)) return null;
    final r = p.dateDisabledReason?.call(d);
    return r == null || r.isEmpty ? null : r;
  }

  bool _isFocusable(DateTime d) => _enabled(d) || _reason(d) != null;

  bool _visiblePage(DateTime d) {
    for (var g = 0; g < _grids; g++) {
      if (_samePage(d, _addPage(_page, g))) return true;
    }
    return false;
  }

  DateTime? get _focusable {
    if (_focused != null) return _focused;
    final start = _start;
    if (start != null && _isFocusable(start) && _visiblePage(start)) return start;
    final today = csDay(clock.now());
    if (_isFocusable(today) && _visiblePage(today)) return today;
    if (_isFocusable(_page)) return _page;
    return null;
  }

  List<_GridCell> _cells(int grid) {
    final base = _addPage(_page, grid);
    if (_monthOnly) return [for (var m = 1; m <= 12; m++) _GridCell(DateTime(base.year, m), true)];
    // Cloudscape pads the first of two grids before the month and every
    // other grid after it; days of the neighbouring month are left blank.
    final padBefore = _grids == 2 && grid == 0;
    final lead = csWeekColumn(base, _startOfWeek);
    DateTime first = DateTime(base.year, base.month, 1 - lead);
    if (padBefore) {
      final last = DateTime(base.year, base.month + 1, 0);
      final trail = 6 - csWeekColumn(last, _startOfWeek);
      first = DateTime(last.year, last.month, last.day + trail - 41);
    }
    return [
      for (var i = 0; i < 42; i++)
        () {
          final d = DateTime(first.year, first.month, first.day + i);
          return _GridCell(d, csSameMonth(d, base));
        }(),
    ];
  }

  FocusNode? _nodeFor(DateTime date) {
    for (var g = 0; g < _grids; g++) {
      final cells = _cells(g);
      for (var i = 0; i < cells.length; i++) {
        if (cells[i].visible && _sameItem(cells[i].date, date)) return _nodes[g * 42 + i];
      }
    }
    return null;
  }

  void _onNodeFocus(int index, FocusNode node) {
    if (!node.hasFocus) return;
    final g = index ~/ 42;
    if (g >= _grids) return;
    final cells = _cells(g);
    final i = index % 42;
    if (i >= cells.length) return;
    final date = cells[i].date;
    if (!_sameItem(date, _focused)) setState(() => _focused = date);
  }

  String _label(DateTime d) {
    final labels = CsDateLabels(context.csStrings);
    return _monthOnly ? labels.monthYear(d) : labels.date(d);
  }

  String _time(DateTime d) => switch (p.timeInputFormat) {
    CsTimeInputFormat.hh => csTwo(d.hour),
    CsTimeInputFormat.hhMm => '${csTwo(d.hour)}:${csTwo(d.minute)}',
    CsTimeInputFormat.hhMmSs => '${csTwo(d.hour)}:${csTwo(d.minute)}:${csTwo(d.second)}',
  };

  /// Cloudscape `onSelectDateHandler`.
  void _select(DateTime date) {
    if (!_enabled(date)) return;
    final i18n = p.i18nStrings;
    final v = widget.value;
    final start = _start;
    final end = _end;
    DateTime? newStart;
    DateTime? newEnd;
    var clearEnd = false;
    String announceStart(DateTime d) =>
        '${i18n.startDateLabel}, ${_label(d)}${_hideTime ? '' : ', ${i18n.startTimeLabel}, ${_time(d)}'}. ';
    String announceEnd(DateTime d) =>
        '${i18n.endDateLabel}, ${_label(d)}${_hideTime ? '' : ', ${i18n.endTimeLabel}, ${_time(d)}'}. ';
    String announceRange(DateTime a, DateTime b) => i18n.selectedRange(_label(a), _label(b));
    String announcement;
    final day = csDay(date);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    if ((start == null && end == null) || (start != null && end != null)) {
      newStart = day;
      clearEnd = start != null;
      announcement = announceStart(day);
    } else if (start != null) {
      if (day.isBefore(start)) {
        newStart = day;
        newEnd = DateTime(start.year, start.month, start.day, 23, 59, 59);
        announcement = announceStart(day) + announceRange(day, newEnd);
      } else {
        newEnd = dayEnd;
        announcement = announceEnd(dayEnd) + announceRange(start, dayEnd);
      }
    } else {
      final existing = end!;
      if (day.isAfter(existing)) {
        newStart = csDay(existing);
        newEnd = dayEnd;
        announcement = announceEnd(dayEnd) + announceRange(existing, dayEnd);
      } else {
        newStart = day;
        announcement = announceStart(day) + announceRange(day, existing);
      }
    }
    String? date_(DateTime? d) => d == null ? null : csFormatIso(d, monthOnly: _monthOnly);
    String? time_(DateTime? d) =>
        d == null || _hideTime ? (d == null ? null : '') : '${csTwo(d.hour)}:${csTwo(d.minute)}:${csTwo(d.second)}';
    widget.onChange(
      CsPendingAbsoluteRange(
        startDate: date_(newStart) ?? v.startDate,
        startTime: time_(newStart) ?? v.startTime,
        endDate: clearEnd ? '' : (date_(newEnd) ?? v.endDate),
        endTime: clearEnd ? '' : (time_(newEnd) ?? v.endTime),
      ),
    );
    setState(() => _announcement = announcement);
    SemanticsService.sendAnnouncement(View.of(context), announcement, Directionality.of(context));
  }

  void _changePage(int amount) {
    setState(() {
      _page = _addPage(_page, amount);
      _focused = null;
    });
  }

  DateTime _move(DateTime from, int step) {
    final limitYears = _monthOnly ? 10 : 1;
    var current = _monthOnly ? csAddMonths(from, step) : csAddDays(from, step);
    while (!_isFocusable(current)) {
      if ((current.year - from.year).abs() > limitYears) return from;
      current = _monthOnly ? csAddMonths(current, step) : csAddDays(current, step);
    }
    return current;
  }

  void _focusDate(DateTime date) {
    setState(() {
      if (!_visiblePage(date)) {
        final page = _startOfPage(date);
        _page = page.isBefore(_page) ? page : _addPage(page, -(_grids - 1));
      }
      _focused = date;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodeFor(date)?.requestFocus();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final from = _focusable;
    if (from == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.space) {
      _select(from);
      return KeyEventResult.handled;
    }
    final m = _monthOnly;
    var step = 1;
    DateTime target;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      step = (key == LogicalKeyboardKey.arrowRight) != rtl ? 1 : -1;
      target = _move(from, step);
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      target = _move(from, step * (m ? 3 : 7));
    } else if (key == LogicalKeyboardKey.pageUp || key == LogicalKeyboardKey.pageDown) {
      step = key == LogicalKeyboardKey.pageDown ? 1 : -1;
      final shift = HardwareKeyboard.instance.isShiftPressed;
      target = csAddMonthsKeepDay(from, step * (m || shift ? 12 : 1));
    } else if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      step = key == LogicalKeyboardKey.end ? -1 : 1;
      final columns = m ? 3 : 7;
      final column = m ? (from.month - 1) % 3 : csWeekColumn(from, _startOfWeek);
      final delta = key == LogicalKeyboardKey.home ? -column : columns - 1 - column;
      target = m ? csAddMonths(from, delta) : csAddDays(from, delta);
    } else {
      return KeyEventResult.ignored;
    }
    if (!_isFocusable(target)) {
      final found = _move(target, step);
      target = _isFocusable(found) ? found : from;
    }
    _focusDate(target);
    return KeyEventResult.handled;
  }

  void _onStartDate(String value) {
    widget.onChange(widget.value.copyWith(startDate: value));
    if ((_monthOnly && value.length >= 4) || value.length >= 8) {
      final d = csParseIso(value);
      if (d != null) setState(() => _page = _startOfPage(d));
    }
  }

  Widget _grid(BuildContext context, int g, double rowHeight, DateTime? focusable) {
    final cs = context.cs;
    final i18n = p.i18nStrings;
    final labels = CsDateLabels(context.csStrings);
    final cells = _cells(g);
    final cols = _monthOnly ? 3 : 7;
    final start = _start;
    final end = _end;
    final rangeA = start ?? end;
    final rangeB = end ?? start;
    final today = csDay(clock.now());

    bool inRange(int i) {
      if (i < 0 || i >= cells.length || !cells[i].visible) return false;
      if (rangeA == null || rangeB == null || _sameItem(rangeA, rangeB)) return false;
      final d = cells[i].date;
      final lo = rangeA.isBefore(rangeB) ? rangeA : rangeB;
      final hi = rangeA.isBefore(rangeB) ? rangeB : rangeA;
      if (_monthOnly) {
        final k = d.year * 12 + d.month;
        return k >= lo.year * 12 + lo.month && k <= hi.year * 12 + hi.month;
      }
      return !d.isBefore(csDay(lo)) && !d.isAfter(csDay(hi));
    }

    Widget cellAt(int i) {
      final cell = cells[i];
      final d = cell.date;
      final row = i ~/ cols;
      final col = i % cols;
      final ranged = inRange(i);
      final enabled = cell.visible && _enabled(d);
      final reason = cell.visible ? _reason(d) : null;
      final current = !ranged && _sameItem(d, today);
      final label = _monthOnly ? labels.monthYear(d) : labels.date(d);
      final node = _nodes[g * 42 + i];
      final tabStop = cell.visible && _sameItem(d, focusable);
      node.skipTraversal = !tabStop;
      return CsCalendarCell(
        text: _monthOnly ? labels.monthShort(d) : '${d.day}',
        semanticLabel: _sameItem(d, today)
            ? '$label. ${_monthOnly ? i18n.currentMonthAriaLabel : i18n.todayAriaLabel}'
            : label,
        height: rowHeight,
        focusNode: cell.visible ? node : null,
        focusable: cell.visible && (enabled || reason != null),
        enabled: enabled,
        visible: cell.visible,
        selected: _sameItem(d, start) || _sameItem(d, end),
        current: current,
        inRange: ranged,
        rangeEdges: ranged
            ? CsCellEdges(
                top: row == 0 || !inRange(i - cols),
                bottom: !inRange(i + cols),
                start: col == 0 || !inRange(i - 1),
                end: col == cols - 1 || !inRange(i + 1),
              )
            : CsCellEdges.none,
        disabledReason: reason,
        onPress: () => _select(d),
      );
    }

    final rows = <Widget>[
      if (!_monthOnly)
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: CsSpace.s, bottom: CsSpace.xxs),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Text(
                      labels.weekdayShort((_startOfWeek + c) % 7),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: cs.text(CsTypeScale.bodyS, color: CsColor.textCalendarMonth),
                    ),
                  ),
              ],
            ),
          ),
        ),
      for (var r = 0; r < cells.length ~/ cols; r++)
        Padding(
          padding: EdgeInsets.only(top: _monthOnly && r > 0 ? CsSpace.calendarGridGutter : 0),
          child: Row(children: [for (var c = 0; c < cols; c++) Expanded(child: cellAt(r * cols + c))]),
        ),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final i18n = p.i18nStrings;
    final labels = CsDateLabels(context.csStrings);
    final focusable = _focusable;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    String title(DateTime d) => _monthOnly ? '${d.year}' : labels.monthYear(d);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Builder(
        builder: (context) {
          final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
          var rowHeight = 20 * scale + 2 * CsSpace.xxs;
          if (widget.stretch && cs.minTapTarget > 0) rowHeight = math.max(rowHeight, 40);

          final header = Row(
            children: [
              CsButton(
                variant: CsButtonVariant.icon,
                icon: rtl ? CsIcons.angleRight : CsIcons.angleLeft,
                semanticLabel: _monthOnly ? i18n.previousYearAriaLabel : i18n.previousMonthAriaLabel,
                onPress: () => _changePage(-1),
              ),
              for (var g = 0; g < _grids; g++)
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: g == _grids - 1,
                    child: Text(
                      title(_addPage(_page, g)),
                      textAlign: TextAlign.center,
                      style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold),
                    ),
                  ),
                ),
              CsButton(
                variant: CsButtonVariant.icon,
                icon: rtl ? CsIcons.angleLeft : CsIcons.angleRight,
                semanticLabel: _monthOnly ? i18n.nextYearAriaLabel : i18n.nextMonthAriaLabel,
                onPress: () => _changePage(1),
              ),
            ],
          );

          final grids = Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            onFocusChange: (has) {
              if (!has && _focused != null) setState(() => _focused = null);
            },
            child: CsCalendarPageFade(
              pageKey: _page,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CsSpace.xs,
                children: [for (var g = 0; g < _grids; g++) Expanded(child: _grid(context, g, rowHeight, focusable))],
              ),
            ),
          );

          final calendarWidth = widget.stretch
              ? double.infinity
              : _grids * CsSize.calendarGridWidth * scale + (_grids - 1) * CsSpace.xs;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: calendarWidth),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [header, grids]),
                ),
              ),
              const SizedBox(height: CsSpace.s),
              _inputs(context),
              if (p.customAbsoluteRangeControl != null) ...[
                const SizedBox(height: CsSpace.s),
                p.customAbsoluteRangeControl!(context, widget.value, widget.onChange),
              ],
              // Screen readers hear each pick (Cloudscape's hidden live region).
              Semantics(liveRegion: true, label: _announcement, child: const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  Widget _inputs(BuildContext context) {
    final i18n = p.i18nStrings;
    final iso = p.dateInputFormat == CsDateInputFormat.iso;
    final sep = iso ? '-' : '/';
    final showTime = !_hideTime;
    final datePlaceholder = i18n.datePlaceholder != null
        ? (_monthOnly ? i18n.datePlaceholder!.split(sep).take(2).join(sep) : i18n.datePlaceholder!)
        : 'YYYY${sep}MM${_monthOnly ? '' : '${sep}DD'}';
    final timePlaceholder = i18n.timePlaceholder != null
        ? i18n.timePlaceholder!.split(':').take(p.timeInputFormat.parts).join(':')
        : p.timeInputFormat.pattern;
    final format = iso ? CsDateFormat.iso : CsDateFormat.slashed;
    final String constraint;
    if (_monthOnly) {
      constraint = i18n.monthConstraintText ?? 'For month, use YYYY${sep}MM.';
    } else if (p.dateOnly) {
      constraint = i18n.dateConstraintText ?? 'For date, use YYYY${sep}MM${sep}DD.';
    } else {
      constraint = i18n.dateTimeConstraintText ?? 'For date, use YYYY${sep}MM${sep}DD. For time, use 24 hr format.';
    }
    final v = widget.value;

    Widget group({required bool start}) {
      final dateField = CsFormField(
        stretch: true,
        label: _monthOnly
            ? (start ? i18n.startMonthLabel : i18n.endMonthLabel)
            : (start ? i18n.startDateLabel : i18n.endDateLabel),
        child: CsDateInput(
          value: start ? v.startDate : v.endDate,
          format: format,
          granularity: p.granularity,
          placeholder: datePlaceholder,
          onChange: start ? _onStartDate : (s) => widget.onChange(v.copyWith(endDate: s)),
        ),
      );
      if (!showTime) return dateField;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CsSpace.xs,
        children: [
          Expanded(child: dateField),
          Expanded(
            child: CsFormField(
              stretch: true,
              label: start ? i18n.startTimeLabel : i18n.endTimeLabel,
              child: CsTimeInput(
                value: start ? v.startTime : v.endTime,
                format: p.timeInputFormat,
                placeholder: timePlaceholder,
                onChange: (s) => widget.onChange(start ? v.copyWith(startTime: s) : v.copyWith(endTime: s)),
              ),
            ),
          ),
        ],
      );
    }

    final groups = _grids == 2 && !widget.stretch
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.xs,
            children: [
              Expanded(child: group(start: true)),
              Expanded(child: group(start: false)),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.xs,
            children: [group(start: true), group(start: false)],
          );
    return CsFormField(constraintText: constraint, stretch: true, child: groups);
  }
}

/// The relative tab: suggested ranges as radio buttons plus a custom
/// duration and unit.
class _RelativeRange extends StatefulWidget {
  const _RelativeRange({
    required this.picker,
    required this.initial,
    required this.singleGrid,
    required this.tapGroup,
    required this.onChange,
  });

  final CsDateRangePicker picker;
  final CsRelativeDateRange? initial;
  final bool singleGrid;
  final Object tapGroup;
  final ValueChanged<CsRelativeDateRange> onChange;

  @override
  State<_RelativeRange> createState() => _RelativeRangeState();
}

class _RelativeRangeState extends State<_RelativeRange> {
  String? _selected;
  int? _duration;
  late CsTimeUnit _unit;
  bool _unitOpen = false;

  CsDateRangePicker get p => widget.picker;

  List<CsTimeUnit> get _units {
    if (p.customRelativeRangeUnits != null) return p.customRelativeRangeUnits!;
    if (p.granularity == CsDateGranularity.month) return const [CsTimeUnit.month, CsTimeUnit.year];
    if (p.dateOnly) return const [CsTimeUnit.day, CsTimeUnit.week, CsTimeUnit.month, CsTimeUnit.year];
    return CsTimeUnit.values;
  }

  CsTimeUnit get _initialUnit {
    final preferred = p.granularity == CsDateGranularity.month
        ? CsTimeUnit.month
        : p.dateOnly
        ? CsTimeUnit.day
        : CsTimeUnit.minute;
    return _units.contains(preferred) ? preferred : _units.first;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _selected = r == null ? null : (r.key ?? _customKey);
    _duration = r?.amount;
    _unit = r?.unit ?? _initialUnit;
  }

  void _report() => widget.onChange(CsRelativeDateRange(amount: _duration ?? 0, unit: _unit));

  @override
  Widget build(BuildContext context) {
    final r = p.renderRelativeRangeContent;
    if (r != null) return r(context, widget.initial, widget.onChange);
    final cs = context.cs;
    final i18n = p.i18nStrings;
    final options = p.relativeOptions;
    final showRadios = options.isNotEmpty;
    final showCustom = !showRadios || _selected == _customKey;

    final custom = <Widget>[
      if (!showRadios)
        Text(
          i18n.customRelativeRangeOptionDescription,
          style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
        ),
      () {
        final duration = CsFormField(
          stretch: true,
          label: i18n.customRelativeRangeDurationLabel,
          child: CsInput(
            type: CsInputType.number,
            value: _duration == null || _duration == 0 ? '' : '$_duration',
            placeholder: i18n.customRelativeRangeDurationPlaceholder,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChange: (s) {
              setState(() => _duration = int.tryParse(s));
              _report();
            },
          ),
        );
        final unit = CsFormField(
          stretch: true,
          label: i18n.customRelativeRangeUnitLabel,
          child: _UnitSelect(
            value: _unit,
            units: _units,
            open: _unitOpen,
            tapGroup: widget.tapGroup,
            label: (u) => i18n.unit(u, _duration ?? 0),
            onOpenChange: (o) => setState(() => _unitOpen = o),
            onChange: (u) {
              setState(() {
                _unit = u;
                _unitOpen = false;
              });
              _report();
            },
          ),
        );
        final controls = widget.singleGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.s,
                children: [duration, unit],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CsSpace.xs,
                children: [
                  Expanded(child: duration),
                  Expanded(child: unit),
                ],
              );
        // Cloudscape indents the custom controls to line up with the radio
        // labels and keeps them to 80% of the width.
        return Padding(
          padding: EdgeInsetsDirectional.only(start: showRadios ? CsSize.control + CsSpace.xs : 0),
          child: FractionallySizedBox(
            widthFactor: widget.singleGrid ? 1 : 0.8,
            alignment: AlignmentDirectional.centerStart,
            child: controls,
          ),
        );
      }(),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CsSpace.xs,
      children: [
        if (showRadios)
          CsFormField(
            label: i18n.relativeRangeSelectionHeading,
            description: p.granularity == CsDateGranularity.month
                ? i18n.relativeRangeSelectionMonthlyDescription
                : null,
            stretch: true,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: i18n.relativeRangeSelectionHeading,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in options)
                    _Radio(
                      label: i18n.relativeRange(o),
                      checked: _selected == o.key,
                      onPress: () {
                        setState(() => _selected = o.key);
                        widget.onChange(o);
                      },
                    ),
                  _Radio(
                    label: i18n.customRelativeRangeOptionLabel,
                    description: i18n.customRelativeRangeOptionDescription,
                    checked: _selected == _customKey,
                    onPress: () {
                      setState(() {
                        _selected = _customKey;
                        _duration = null;
                        _unit = _initialUnit;
                      });
                      _report();
                    },
                  ),
                ],
              ),
            ),
          ),
        if (showCustom) ...custom,
      ],
    );
  }
}

/// A radio button row in the style of Cloudscape's `RadioGroup`.
class _Radio extends StatelessWidget {
  const _Radio({required this.label, required this.checked, required this.onPress, this.description});

  final String label;
  final String? description;
  final bool checked;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    return CsPressable(
      onPress: onPress,
      checked: checked,
      inMutuallyExclusiveGroup: true,
      isButton: false,
      semanticLabel: description == null ? label : '$label, $description',
      excludeChildSemantics: true,
      scaleOnPress: false,
      showFocusRing: false,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.xxxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: CsSize.control,
                height: CsSize.control,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked ? c.backgroundControlChecked : c.backgroundControlDefault,
                  border: Border.all(
                    color: checked ? c.backgroundControlChecked : c.borderControlDefault,
                    width: checked ? 0 : CsBorderWidth.field + 1,
                  ),
                  boxShadow: state.focused ? [BoxShadow(color: c.borderItemFocused, spreadRadius: 2)] : null,
                ),
                alignment: Alignment.center,
                child: checked
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.backgroundControlDefault),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: CsSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: cs.text(CsTypeScale.bodyM, color: CsColor.textFormLabel)),
                  if (description != null)
                    Text(description!, style: cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The unit picker: a select-style trigger and a dropdown of units.
class _UnitSelect extends StatelessWidget {
  const _UnitSelect({
    required this.value,
    required this.units,
    required this.open,
    required this.tapGroup,
    required this.label,
    required this.onOpenChange,
    required this.onChange,
  });

  final CsTimeUnit value;
  final List<CsTimeUnit> units;
  final bool open;
  final Object tapGroup;
  final String Function(CsTimeUnit unit) label;
  final ValueChanged<bool> onOpenChange;
  final ValueChanged<CsTimeUnit> onChange;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final trigger = CsPressable(
      onPress: () => onOpenChange(!open),
      expanded: open,
      semanticValue: label(value),
      showFocusRing: false,
      scaleOnPress: false,
      excludeChildSemantics: true,
      builder: (context, state) => CsFieldBox(
        focused: state.focused || open,
        trailing: const Padding(
          padding: EdgeInsetsDirectional.only(end: CsSpace.xs),
          child: CsIcon(CsIcons.caretDownFilled, variant: CsIconVariant.subtle),
        ),
        child: Text(label(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: cs.body),
      ),
    );
    return CsDropdown(
      open: open,
      onDismiss: () => onOpenChange(false),
      presentation: CsPresentation.popover,
      trapFocus: true,
      tapRegionGroupId: tapGroup,
      contentBuilder: (context, inSheet) => CsMenuPanel(
        children: [
          for (final u in units)
            CsMenuRow(label: label(u), selected: u == value, autofocus: u == value, onPress: () => onChange(u)),
        ],
      ),
      child: UnconstrainedBox(constrainedAxis: Axis.horizontal, child: trigger),
    );
  }
}
