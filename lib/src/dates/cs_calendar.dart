import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_haptics.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_dates_internal.dart';

/// What a calendar, date input or date picker selects (Cloudscape
/// `granularity`).
enum CsDateGranularity {
  /// A day: values are `YYYY-MM-DD`.
  day,

  /// A month: values are `YYYY-MM`, and the calendar shows the months of a
  /// year.
  month,
}

/// Decides whether a day (or month) can be picked (Cloudscape
/// `isDateEnabled`).
typedef CsIsDateEnabled = bool Function(DateTime date);

/// Explains why a day can not be picked (Cloudscape `dateDisabledReason`).
/// Return null or an empty string for no reason.
typedef CsDateDisabledReason = String? Function(DateTime date);

/// Copy for [CsCalendar] (Cloudscape `CalendarProps.I18nStrings`). Unset
/// fields fall back to Cloudscape's English and to `context.csStrings`.
///
/// ```dart
/// const CsCalendarI18nStrings(todayAriaLabel: 'Hari ini', nextMonthAriaLabel: 'Bulan berikutnya')
/// ```
@immutable
class CsCalendarI18nStrings {
  const CsCalendarI18nStrings({
    this.todayAriaLabel,
    this.nextMonthAriaLabel,
    this.previousMonthAriaLabel,
    this.currentMonthAriaLabel,
    this.nextYearAriaLabel,
    this.previousYearAriaLabel,
    this.weekdayNamesShort,
  });

  /// Added to today's announcement. Default "Today".
  final String? todayAriaLabel;

  /// Default "Next month".
  final String? nextMonthAriaLabel;

  /// Default "Previous month".
  final String? previousMonthAriaLabel;

  /// Added to the current month's announcement in a month calendar.
  /// Default "Current month".
  final String? currentMonthAriaLabel;

  /// Default "Next year".
  final String? nextYearAriaLabel;

  /// Default "Previous year".
  final String? previousYearAriaLabel;

  /// Seven column headings starting with Sunday. Defaults to the first three
  /// letters of `CsStrings.weekdayNames` ("Sun", "Mon", ...).
  final List<String>? weekdayNamesShort;

  /// These strings with unset fields taken from [other].
  CsCalendarI18nStrings merge(CsCalendarI18nStrings? other) => other == null
      ? this
      : CsCalendarI18nStrings(
          todayAriaLabel: todayAriaLabel ?? other.todayAriaLabel,
          nextMonthAriaLabel: nextMonthAriaLabel ?? other.nextMonthAriaLabel,
          previousMonthAriaLabel: previousMonthAriaLabel ?? other.previousMonthAriaLabel,
          currentMonthAriaLabel: currentMonthAriaLabel ?? other.currentMonthAriaLabel,
          nextYearAriaLabel: nextYearAriaLabel ?? other.nextYearAriaLabel,
          previousYearAriaLabel: previousYearAriaLabel ?? other.previousYearAriaLabel,
          weekdayNamesShort: weekdayNamesShort ?? other.weekdayNamesShort,
        );
}

/// Date labels shared by the date components, built from [CsStrings].
@immutable
class CsDateLabels {
  const CsDateLabels(this.strings, {this.weekdayNamesShort});

  final CsStrings strings;
  final List<String>? weekdayNamesShort;

  /// "January 5, 2026" (Cloudscape `getDateLabel(..., 'short')`).
  String date(DateTime d) => '${strings.monthNames[d.month - 1]} ${d.day}, ${d.year}';

  /// "Monday, January 5, 2026".
  String fullDate(DateTime d) => strings.fullDate(d);

  /// "January 2026".
  String monthYear(DateTime d) => strings.monthYear(d);

  /// "Jan".
  String monthShort(DateTime d) => strings.monthNamesShort[d.month - 1];

  /// Short name of weekday [dayIndex] (0 Sunday to 6 Saturday).
  String weekdayShort(int dayIndex) {
    final custom = weekdayNamesShort;
    if (custom != null && custom.length == 7) return custom[dayIndex];
    final name = strings.weekdayNames[(dayIndex + 6) % 7];
    return name.length <= 3 ? name : name.substring(0, 3);
  }

  /// Full name of weekday [dayIndex] (0 Sunday to 6 Saturday).
  String weekday(int dayIndex) => strings.weekdayNames[(dayIndex + 6) % 7];
}

/// Cloudscape's `Calendar`: a month grid (or a year of months) for picking
/// one date, shown inline. For a field with a calendar dropdown use
/// `CsDatePicker`.
///
/// It is controlled: [value] is `YYYY-MM-DD` (`YYYY-MM` with
/// [CsDateGranularity.month]) or an empty string, and [onChange] receives the
/// picked date in the same format.
///
/// ```dart
/// CsCalendar(
///   value: launchDate,
///   isDateEnabled: (d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
///   dateDisabledReason: (d) => 'Launches run on weekdays only.',
///   onChange: (v) => setState(() => launchDate = v),
/// )
/// ```
///
/// * The grid always shows six weeks; days of the next month are dimmed but
///   can be picked, as in Cloudscape.
/// * Today has the `color-background-calendar-current-date` fill and bold
///   text; the selected day is `color-background-control-checked` with
///   `color-text-calendar-date-selected` text.
/// * Days rejected by [isDateEnabled] can not be picked. With a
///   [dateDisabledReason] they stay focusable and show the reason in a
///   tooltip.
/// * Keyboard: the grid is one Tab stop. Arrows move by day and week (by
///   month and quarter in a month calendar), Page Up and Page Down by month
///   (with Shift, by year), Home and End to the start and end of the row,
///   Enter and Space pick. Disabled days are skipped.
/// * On touch, a horizontal swipe changes the month.
class CsCalendar extends StatefulWidget {
  const CsCalendar({
    super.key,
    required this.value,
    this.onChange,
    this.isDateEnabled,
    this.dateDisabledReason,
    this.startOfWeek,
    this.granularity = CsDateGranularity.day,
    this.ariaLabel,
    this.i18nStrings,
    this.autofocus = false,
    this.stretch = false,
  }) : assert(startOfWeek == null || (startOfWeek >= 0 && startOfWeek <= 6));

  /// The selected date: `YYYY-MM-DD`, `YYYY-MM` for months, or empty.
  final String value;

  /// Called with the picked date, formatted like [value].
  final ValueChanged<String>? onChange;

  /// Days (or months) that can be picked. All of them by default.
  final CsIsDateEnabled? isDateEnabled;

  /// Why a disabled date can not be picked. A reason keeps the date
  /// focusable and shows it in a tooltip.
  final CsDateDisabledReason? dateDisabledReason;

  /// First day of the week, 0 (Sunday) to 6 (Saturday). Defaults to
  /// `CsStrings.firstDayOfWeek`.
  final int? startOfWeek;

  /// Days or months.
  final CsDateGranularity granularity;

  /// Accessible name of the calendar (Cloudscape `ariaLabel`).
  final String? ariaLabel;
  final CsCalendarI18nStrings? i18nStrings;

  /// Focus the selected day (or today) when the calendar appears. Date
  /// pickers set this when they open.
  final bool autofocus;

  /// Fill the available width instead of Cloudscape's 238px grid. Pickers
  /// set it in bottom sheets on phones.
  final bool stretch;

  @override
  State<CsCalendar> createState() => _CsCalendarState();
}

class _CsCalendarState extends State<CsCalendar> {
  late DateTime _displayed;
  DateTime? _focusedDate;
  final List<FocusNode> _nodes = [];
  List<DateTime> _cells = const [];

  bool get _monthPicker => widget.granularity == CsDateGranularity.month;
  int get _columns => _monthPicker ? 3 : 7;

  DateTime? get _selected {
    if (widget.value.length < 4) return null;
    return csParseIso(widget.value);
  }

  @override
  void initState() {
    super.initState();
    _displayed = _selected ?? csDay(clock.now());
    for (var i = 0; i < 42; i++) {
      final node = FocusNode(debugLabel: 'CsCalendar cell $i');
      node.addListener(() => _onNodeFocus(i, node));
      _nodes.add(node);
    }
    if (widget.autofocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _focusable;
        if (target != null) _nodeFor(target)?.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CsCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final s = _selected;
      if (s != null && !_samePage(s, _displayed)) _displayed = s;
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool _enabled(DateTime d) => widget.isDateEnabled?.call(d) ?? true;

  String? _reason(DateTime d) {
    if (_enabled(d)) return null;
    final r = widget.dateDisabledReason?.call(d);
    return r == null || r.isEmpty ? null : r;
  }

  bool _isFocusable(DateTime d) => _enabled(d) || _reason(d) != null;

  bool _sameItem(DateTime? a, DateTime? b) => _monthPicker ? csSameMonth(a, b) : csSameDay(a, b);
  bool _samePage(DateTime a, DateTime b) => _monthPicker ? csSameYear(a, b) : csSameMonth(a, b);

  int get _startOfWeek => widget.startOfWeek ?? context.csStrings.firstDayOfWeek % 7;

  /// Cloudscape `getBaseDay` / `getBaseMonth`: the first focusable item of
  /// the page, or its first item.
  DateTime get _baseDate {
    final start = _monthPicker ? DateTime(_displayed.year) : csFirstOfMonth(_displayed);
    if (_isFocusable(start)) return start;
    final next = _move(start, 1);
    return _samePage(next, start) ? next : start;
  }

  /// Cloudscape `moveDay` / `moveMonth`: steps until a focusable item, or
  /// returns [from] when there is none within the limit.
  DateTime _move(DateTime from, int step) {
    final limitYears = _monthPicker ? 10 : 1;
    var current = _monthPicker ? csAddMonths(from, step) : csAddDays(from, step);
    while (!_isFocusable(current)) {
      if ((current.year - from.year).abs() > limitYears) return from;
      current = _monthPicker ? csAddMonths(current, step) : csAddDays(current, step);
    }
    return current;
  }

  List<DateTime> _buildCells() {
    if (_monthPicker) return [for (var m = 1; m <= 12; m++) DateTime(_displayed.year, m)];
    final first = csFirstOfMonth(_displayed);
    final lead = csWeekColumn(first, _startOfWeek);
    return [for (var i = 0; i < 42; i++) DateTime(first.year, first.month, 1 - lead + i)];
  }

  DateTime? get _focusable {
    final focused = _focusedDate;
    if (focused != null) return focused;
    final base = _baseDate;
    final selected = _selected;
    if (selected != null && _isFocusable(selected) && _samePage(selected, base)) return selected;
    final today = csDay(clock.now());
    if (_isFocusable(today) && _samePage(today, base)) return today;
    if (_isFocusable(base)) return base;
    return null;
  }

  FocusNode? _nodeFor(DateTime date) {
    final cells = _buildCells();
    for (var i = 0; i < cells.length; i++) {
      if (_sameItem(cells[i], date) && (_monthPicker || csSameMonth(cells[i], date))) return _nodes[i];
    }
    return null;
  }

  void _onNodeFocus(int index, FocusNode node) {
    if (!node.hasFocus || index >= _cells.length) return;
    final date = _cells[index];
    if (!_sameItem(date, _focusedDate)) setState(() => _focusedDate = date);
  }

  void _select(DateTime date) {
    if (!_enabled(date)) return;
    widget.onChange?.call(csFormatIso(date, monthOnly: _monthPicker));
    setState(() => _focusedDate = null);
  }

  void _changePage(int amount) {
    setState(() {
      final base = _baseDate;
      _displayed = _monthPicker ? DateTime(base.year + amount) : csAddMonths(base, amount);
      _focusedDate = null;
    });
  }

  void _focusDate(DateTime date) {
    setState(() {
      if (!_samePage(date, _displayed)) _displayed = date;
      _focusedDate = date;
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
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.space) {
      _select(from);
      return KeyEventResult.handled;
    }

    DateTime? target;
    var step = 1;
    final m = _monthPicker;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      step = (key == LogicalKeyboardKey.arrowRight) != rtl ? 1 : -1;
      target = _move(from, step);
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      target = _move(from, step * (m ? 3 : 7));
    } else if (key == LogicalKeyboardKey.pageUp || key == LogicalKeyboardKey.pageDown) {
      step = key == LogicalKeyboardKey.pageDown ? 1 : -1;
      final months = m || shift ? 12 : 1;
      target = csAddMonthsKeepDay(from, step * months);
    } else if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      step = key == LogicalKeyboardKey.end ? -1 : 1;
      final column = m ? (from.month - 1) % 3 : csWeekColumn(from, _startOfWeek);
      final delta = key == LogicalKeyboardKey.home ? -column : (_columns - 1 - column);
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

  void _onSwipeEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    csHaptic(CsHaptic.selection);
    _changePage((v < 0) != rtl ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final i18n = widget.i18nStrings ?? const CsCalendarI18nStrings();
    final labels = CsDateLabels(strings, weekdayNamesShort: i18n.weekdayNamesShort);
    _cells = _buildCells();
    final focusable = _focusable;
    final selected = _selected;
    final today = csDay(clock.now());
    final base = _baseDate;

    final prevLabel = _monthPicker
        ? i18n.previousYearAriaLabel ?? 'Previous year'
        : i18n.previousMonthAriaLabel ?? strings.previousMonth;
    final nextLabel = _monthPicker
        ? i18n.nextYearAriaLabel ?? 'Next year'
        : i18n.nextMonthAriaLabel ?? strings.nextMonth;
    final currentLabel = _monthPicker
        ? i18n.currentMonthAriaLabel ?? 'Current month'
        : i18n.todayAriaLabel ?? strings.today;
    final headerText = _monthPicker ? '${base.year}' : labels.monthYear(base);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Builder(
        builder: (context) {
          final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
          return LayoutBuilder(
            builder: (context, constraints) {
              var width = CsSize.calendarGridWidth * scale;
              if (widget.stretch && constraints.maxWidth.isFinite) width = constraints.maxWidth;
              if (constraints.maxWidth.isFinite) width = math.min(width, constraints.maxWidth);
              final lineHeight = 20 * scale;
              var rowHeight = lineHeight + 2 * CsSpace.xxs;
              if (widget.stretch && cs.minTapTarget > 0) rowHeight = math.max(rowHeight, 40);

              final header = Row(
                children: [
                  CsButton(
                    variant: CsButtonVariant.icon,
                    icon: Directionality.of(context) == TextDirection.rtl ? CsIcons.angleRight : CsIcons.angleLeft,
                    semanticLabel: prevLabel,
                    onPress: () => _changePage(-1),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        headerText,
                        textAlign: TextAlign.center,
                        style: cs.text(
                          CsTypeScale.bodyM,
                          weight: CsTypography.bold,
                          color: CsColor.textDropdownItemDefault,
                        ),
                      ),
                    ),
                  ),
                  CsButton(
                    variant: CsButtonVariant.icon,
                    icon: Directionality.of(context) == TextDirection.rtl ? CsIcons.angleLeft : CsIcons.angleRight,
                    semanticLabel: nextLabel,
                    onPress: () => _changePage(1),
                  ),
                ],
              );

              Widget cellAt(int i) {
                final date = _cells[i];
                final enabled = _enabled(date);
                final reason = _reason(date);
                final isCurrent = _sameItem(date, today);
                final currentPage = _monthPicker || csSameMonth(date, base);
                final label = _monthPicker ? labels.monthYear(date) : labels.date(date);
                return CsCalendarCell(
                  text: _monthPicker ? labels.monthShort(date) : '${date.day}',
                  semanticLabel: isCurrent ? '$label. $currentLabel' : label,
                  height: rowHeight,
                  focusNode: _nodes[i],
                  focusable: enabled || reason != null,
                  enabled: enabled,
                  currentPage: currentPage,
                  selected: _sameItem(date, selected),
                  current: isCurrent,
                  disabledReason: reason,
                  onPress: widget.onChange == null ? null : () => _select(date),
                );
              }

              for (var i = 0; i < _cells.length; i++) {
                final tabStop = _sameItem(_cells[i], focusable) && (_monthPicker || csSameMonth(_cells[i], base));
                _nodes[i].skipTraversal = !tabStop;
              }

              final List<Widget> rows;
              if (_monthPicker) {
                rows = [
                  for (var r = 0; r < 4; r++)
                    Padding(
                      padding: EdgeInsets.only(top: r == 0 ? 0 : CsSpace.calendarGridGutter),
                      child: Row(
                        spacing: CsSpace.calendarGridGutter,
                        children: [for (var c = 0; c < 3; c++) Expanded(child: cellAt(r * 3 + c))],
                      ),
                    ),
                ];
              } else {
                rows = [
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
                  for (var r = 0; r < 6; r++)
                    Row(children: [for (var c = 0; c < 7; c++) Expanded(child: cellAt(r * 7 + c))]),
                ];
              }

              final grid = Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onKey,
                onFocusChange: (has) {
                  if (!has && _focusedDate != null) setState(() => _focusedDate = null);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
                  onHorizontalDragEnd: _onSwipeEnd,
                  child: CsCalendarPageFade(
                    pageKey: _monthPicker ? base.year : base.year * 12 + base.month,
                    child: Padding(
                      padding: _monthPicker ? const EdgeInsets.all(CsSpace.xs) : EdgeInsets.zero,
                      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
                    ),
                  ),
                ),
              );

              return Semantics(
                container: true,
                explicitChildNodes: true,
                label: widget.ariaLabel,
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.all(CsSpace.xs),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [header, grid]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
