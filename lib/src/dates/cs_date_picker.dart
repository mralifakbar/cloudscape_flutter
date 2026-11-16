import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_sheet.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_calendar.dart';
import 'cs_date_input.dart';
import 'cs_dates_internal.dart';

/// Builds the accessible name of the calendar button from the selected date
/// ("January 5, 2026"), or null when nothing is selected.
typedef CsOpenCalendarAriaLabel = String Function(String? selectedDate);

/// Copy for [CsDatePicker] (Cloudscape `DatePickerProps.I18nStrings`): the
/// calendar's strings plus the calendar button's label.
///
/// ```dart
/// CsDatePickerI18nStrings(
///   openCalendarAriaLabel: (d) => d == null ? 'Pilih tanggal' : 'Pilih tanggal, terpilih $d',
/// )
/// ```
@immutable
class CsDatePickerI18nStrings extends CsCalendarI18nStrings {
  const CsDatePickerI18nStrings({
    super.todayAriaLabel,
    super.nextMonthAriaLabel,
    super.previousMonthAriaLabel,
    super.currentMonthAriaLabel,
    super.nextYearAriaLabel,
    super.previousYearAriaLabel,
    super.weekdayNamesShort,
    this.openCalendarAriaLabel,
  });

  /// Default "Choose date" and "Choose date, selected date is {date}".
  final CsOpenCalendarAriaLabel? openCalendarAriaLabel;
}

/// Cloudscape's `DatePicker`: a [CsDateInput] with a calendar button that
/// opens a [CsCalendar] in a dropdown, or in a bottom sheet on phones.
///
/// It is controlled: [value] is ISO (`YYYY-MM-DD`, `YYYY-MM` with month
/// [granularity]) and [onChange] receives typed text as it changes and the
/// picked date when a day is chosen in the calendar.
///
/// ```dart
/// CsFormField(
///   label: 'Certificate expiry',
///   constraintText: 'Use YYYY/MM/DD format.',
///   child: CsDatePicker(
///     value: expiry,
///     placeholder: 'YYYY/MM/DD',
///     isDateEnabled: (d) => !d.isBefore(DateTime(2026)),
///     onChange: (v) => setState(() => expiry = v),
///   ),
/// )
/// ```
///
/// * Picking a day closes the calendar and moves focus to the calendar
///   button; Escape closes it the same way. Focusing the text field closes
///   it.
/// * Disabled and read-only pickers disable the calendar button.
/// * The field is at most 234px wide, as in Cloudscape.
class CsDatePicker extends StatefulWidget {
  const CsDatePicker({
    super.key,
    required this.value,
    this.onChange,
    this.isDateEnabled,
    this.dateDisabledReason,
    this.startOfWeek,
    this.granularity = CsDateGranularity.day,
    this.format = CsDateFormat.slashed,
    this.inputFormat = CsDateInputFormat.slashed,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warning = false,
    this.autoFocus = false,
    this.ariaLabel,
    this.onFocus,
    this.onBlur,
    this.i18nStrings,
    this.presentation = CsPresentation.auto,
    this.focusNode,
  });

  /// ISO date: `YYYY-MM-DD`, `YYYY-MM` for months, partial while typing, or
  /// empty.
  final String value;
  final ValueChanged<String>? onChange;

  /// Days that can be picked in the calendar. Typed dates are not checked;
  /// validate them too.
  final CsIsDateEnabled? isDateEnabled;

  /// Why a disabled day can not be picked, shown in a tooltip.
  final CsDateDisabledReason? dateDisabledReason;

  /// First day of the week, 0 (Sunday) to 6 (Saturday).
  final int? startOfWeek;
  final CsDateGranularity granularity;

  /// How the date is shown in the field.
  final CsDateFormat format;

  /// How it is typed when [format] is [CsDateFormat.longLocalized].
  final CsDateInputFormat inputFormat;
  final String? placeholder;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool warning;
  final bool autoFocus;

  /// Accessible name of the field and the calendar.
  final String? ariaLabel;

  /// Focus entered the field or the calendar button.
  final VoidCallback? onFocus;

  /// Focus left the field.
  final VoidCallback? onBlur;
  final CsDatePickerI18nStrings? i18nStrings;

  /// Dropdown on wide screens, bottom sheet on phones by default.
  final CsPresentation presentation;

  /// Focus node of the text field (Cloudscape `ref.focus()`).
  final FocusNode? focusNode;

  @override
  State<CsDatePicker> createState() => _CsDatePickerState();
}

class _CsDatePickerState extends State<CsDatePicker> {
  bool _open = false;
  final FocusNode _button = FocusNode(debugLabel: 'CsDatePicker calendar button');

  bool get _monthOnly => widget.granularity == CsDateGranularity.month;

  @override
  void dispose() {
    _button.dispose();
    super.dispose();
  }

  void _close({bool focusButton = false}) {
    if (!_open) return;
    setState(() => _open = false);
    if (focusButton) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _button.requestFocus();
      });
    }
  }

  String _buttonLabel(CsStrings strings) {
    String? selected;
    if (csIsFullIso(widget.value, monthOnly: _monthOnly)) {
      final d = csParseIso(widget.value)!;
      final labels = CsDateLabels(strings);
      selected = _monthOnly ? labels.monthYear(d) : labels.date(d);
    }
    final custom = widget.i18nStrings?.openCalendarAriaLabel;
    if (custom != null) return custom(selected);
    return selected == null ? 'Choose date' : 'Choose date, selected date is $selected';
  }

  Widget _calendar(BuildContext context, bool inSheet) {
    final calendar = CsCalendar(
      value: widget.value,
      granularity: widget.granularity,
      isDateEnabled: widget.isDateEnabled,
      dateDisabledReason: widget.dateDisabledReason,
      startOfWeek: widget.startOfWeek,
      ariaLabel: widget.ariaLabel,
      i18nStrings: widget.i18nStrings,
      autofocus: true,
      stretch: inSheet,
      onChange: (v) {
        widget.onChange?.call(v);
        if (inSheet) CsSheetScope.closeFrom(context);
        _close(focusButton: true);
      },
    );
    if (inSheet) {
      return Padding(padding: const EdgeInsets.fromLTRB(CsSpace.m, 0, CsSpace.m, CsSpace.m), child: calendar);
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _close(focusButton: true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: CsDatesDropdownSurface(semanticLabel: widget.ariaLabel, child: calendar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.csStrings;
    final buttonDisabled = widget.disabled || widget.readOnly;
    final trigger = ConstrainedBox(
      // Cloudscape `.date-picker-container { max-inline-size: 234px }`.
      constraints: const BoxConstraints(maxWidth: 234),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (has) {
                if (has) {
                  _close();
                  widget.onFocus?.call();
                }
              },
              child: CsDateInput(
                value: widget.value,
                onChange: widget.onChange,
                onBlur: widget.onBlur,
                granularity: widget.granularity,
                format: widget.format,
                inputFormat: widget.inputFormat,
                placeholder: widget.placeholder,
                disabled: widget.disabled,
                readOnly: widget.readOnly,
                invalid: widget.invalid,
                warning: widget.warning,
                autoFocus: widget.autoFocus,
                ariaLabel: widget.ariaLabel,
                focusNode: widget.focusNode,
              ),
            ),
          ),
          const SizedBox(width: CsSpace.xs),
          CsButton(
            icon: CsIcons.calendar,
            semanticLabel: _buttonLabel(strings),
            disabled: buttonDisabled,
            expanded: buttonDisabled ? null : _open,
            focusNode: _button,
            onPress: buttonDisabled ? null : () => setState(() => _open = true),
          ),
        ],
      ),
    );
    if (buttonDisabled) return trigger;
    return CsDropdown(
      open: _open,
      onDismiss: () => _close(),
      presentation: widget.presentation,
      matchTriggerWidth: false,
      preferredHeight: 320,
      trapFocus: true,
      sheetLabel: widget.ariaLabel ?? _buttonLabel(strings),
      contentBuilder: _calendar,
      child: trigger,
    );
  }
}
