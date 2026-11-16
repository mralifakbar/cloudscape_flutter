// Not exported. Date math, the masked-input format shared by `CsDateInput`
// and `CsTimeInput`, and the calendar cell shared by `CsCalendar` and the
// date range picker. The mask logic is ported from Cloudscape's
// `internal/components/masked-input` (Apache 2.0).
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../overlays/cs_tooltip.dart';
import '../system/cs_haptics.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

DateTime csDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime csFirstOfMonth(DateTime d) => DateTime(d.year, d.month);

DateTime csAddDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// First of the month [delta] months after [d]'s month.
DateTime csAddMonths(DateTime d, int delta) => DateTime(d.year, d.month + delta);

/// Same day [delta] months away, clamped to that month's length.
DateTime csAddMonthsKeepDay(DateTime d, int delta) {
  final first = csAddMonths(d, delta);
  return DateTime(first.year, first.month, math.min(d.day, csDaysInMonth(first)));
}

int csDaysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

bool csSameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

bool csSameMonth(DateTime? a, DateTime? b) => a != null && b != null && a.year == b.year && a.month == b.month;

bool csSameYear(DateTime? a, DateTime? b) => a != null && b != null && a.year == b.year;

/// Whole months from [a] to [b].
int csMonthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + b.month - a.month;

/// Column (0-6) of [d] in a week starting on [startOfWeek] (0 Sunday to 6 Saturday).
int csWeekColumn(DateTime d, int startOfWeek) => (d.weekday % 7 - startOfWeek + 7) % 7;

String csTwo(int n) => n.toString().padLeft(2, '0');

/// `YYYY-MM-DD`, or `YYYY-MM` with [monthOnly].
String csFormatIso(DateTime d, {bool monthOnly = false}) {
  final ym = '${d.year.toString().padLeft(4, '0')}-${csTwo(d.month)}';
  return monthOnly ? ym : '$ym-${csTwo(d.day)}';
}

/// Parses `YYYY`, `YYYY-MM` or `YYYY-MM-DD` (slashes are accepted too), the
/// way Cloudscape's `parseDate` does: missing parts default to the first.
/// Returns null for anything else or for an impossible day.
DateTime? csParseIso(String value) {
  final m = RegExp(r'^(\d{4})(?:[-/](\d{1,2}))?(?:[-/](\d{1,2}))?').firstMatch(value.trim());
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final month = m.group(2) == null || m.group(2)!.isEmpty ? 1 : int.parse(m.group(2)!);
  final day = m.group(3) == null || m.group(3)!.isEmpty ? 1 : int.parse(m.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > csDaysInMonth(DateTime(year, month))) return null;
  return DateTime(year, month, day);
}

/// True when [value] is a complete `YYYY-MM-DD` (or `YYYY-MM` for months).
bool csIsFullIso(String value, {bool monthOnly = false}) {
  final pattern = monthOnly ? RegExp(r'^\d{4}-\d{2}(-\d{2})?$') : RegExp(r'^\d{4}-\d{2}-\d{2}$');
  return pattern.hasMatch(value) && csParseIso(value) != null;
}

/// Cloudscape `normalizeIsoDateString`: trims incomplete trailing segments.
String csNormalizeIso(String value, {bool monthOnly = false}) {
  final m = RegExp(r'^(\d{4})(?:-(\d{1,2})?)?(?:-(\d{1,2})?)?$').firstMatch(value);
  if (m == null) return '';
  final year = m.group(1)!;
  final month = m.group(2);
  final day = m.group(3);
  if (!monthOnly && month?.length == 2 && day?.length == 2) return '$year-$month-$day';
  if (month?.length == 2) return '$year-$month';
  return year;
}

/// Seconds since midnight parsed from `hh`, `hh:mm` or `hh:mm:ss`, or null.
({int hour, int minute, int second})? csParseTime(String value) {
  final m = RegExp(r'^(\d{1,2})(?::(\d{1,2}))?(?::(\d{1,2}))?$').firstMatch(value.trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final mi = m.group(2) == null ? 0 : int.parse(m.group(2)!);
  final s = m.group(3) == null ? 0 : int.parse(m.group(3)!);
  if (h > 23 || mi > 59 || s > 59) return null;
  return (hour: h, minute: mi, second: s);
}

/// One numeric part of a mask, such as the month of a date.
class CsMaskSegment {
  const CsMaskSegment({required this.min, required int max, required this.length, this.defaultValue})
    : _max = max,
      _maxOf = null;

  /// A segment whose maximum depends on the whole value (days in a month).
  const CsMaskSegment.dynamic({required this.min, required int Function(String value) max, required this.length})
    : _max = 0,
      _maxOf = max,
      defaultValue = null;

  final int min;
  final int _max;
  final int Function(String value)? _maxOf;
  final int length;
  final int? defaultValue;

  int max(String value) => _maxOf?.call(value) ?? _max;
}

class _Segment {
  _Segment(this.def, this.start);

  final CsMaskSegment def;
  final int start;
  int get end => start + def.length;
  int get length => def.length;
  int get min => def.min;
  int max(String value) => def.max(value);
  int? get defaultValue => def.defaultValue;
}

/// Result of a mask edit: the new text and the caret position.
typedef CsMaskResult = ({String value, int position});

String _insertAt(String text, String toInsert, int start, [int? end]) {
  final e = math.min(end ?? start, text.length);
  final s = math.min(start, text.length);
  return text.substring(0, s) + toInsert + text.substring(e);
}

String _pad(String v, int length) => v.padLeft(length, '0');

/// Cloudscape's `MaskFormat`: fixed-length numeric segments joined by a
/// separator, with min/max autofix as the user types.
class CsMaskFormat {
  CsMaskFormat({
    required this.separator,
    List<String> inputSeparators = const [],
    required List<CsMaskSegment> segments,
  }) : _inputSeparators = [...inputSeparators, separator] {
    var position = 0;
    for (final def in segments) {
      final seg = _Segment(def, position);
      _segments.add(seg);
      for (var j = 0; j < def.length; j++) {
        _positions[position++] = seg;
      }
      position++;
    }
  }

  final String separator;
  final List<String> _inputSeparators;
  final List<_Segment> _segments = [];
  final Map<int, _Segment> _positions = {};

  int get maxLength => _segments.last.end;

  bool isSeparator(String key) => _inputSeparators.contains(key);

  String tryAppendSeparator(String value) {
    final withSeparator = '$value$separator';
    return isValid(withSeparator) ? withSeparator : value;
  }

  bool isValid(String value) {
    final parts = value.split(separator);
    if (parts.length > _segments.length) return false;
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final seg = _segments[i];
      final last = i == parts.length - 1;
      if (part.isEmpty) {
        if (last) continue;
        return false;
      }
      if (!RegExp(r'^\d+$').hasMatch(part)) return false;
      if (part.length < seg.length && !last) return false;
      if (part.length > seg.length) return false;
      final n = int.parse(part);
      if (n < seg.min || n > seg.max(value)) {
        if (last && part.length < seg.length) continue;
        return false;
      }
    }
    return true;
  }

  String getValidValue(String value) {
    var v = value;
    while (v.isNotEmpty) {
      if (isValid(v)) return tryAppendSeparator(v);
      v = v.substring(0, v.length - 1);
    }
    return '';
  }

  /// Pads the last segment and fills missing ones with defaults: `10:1` is
  /// `10:01:00`.
  String autoComplete(String value) {
    if (value.isEmpty) return value;
    final parts = value.split(separator);
    final complete = parts.sublist(0, parts.length - 1);
    final lastSeg = _segments[math.min(complete.length, _segments.length - 1)];
    final partial = [...complete, _padWithDefault(parts.last, lastSeg)];
    while (partial.length < _segments.length) {
      partial.add(_padWithDefault('', _segments[partial.length]));
    }
    return correctMinMaxValues(partial.join(separator));
  }

  int _segmentValueWithAddition(int position, String value, String digit) {
    final seg = _positions[position]!;
    final segValue = value.length > seg.start
        ? value.substring(seg.start, math.min(value.length, seg.start + seg.length))
        : '';
    final segPos = position - seg.start;
    return int.parse(_insertAt(segValue, digit, segPos, segPos + 1));
  }

  CsMaskResult replaceDigitsWithZeroes(String value, int cursorStart, int cursorEnd) {
    final position = isCursorAtSeparator(cursorStart) ? cursorStart + 1 : cursorStart;
    if (isCursorAtSeparator(cursorStart)) cursorStart++;
    if (!isSegmentStart(cursorStart)) {
      final seg = _positions[cursorStart]!;
      value = _insertAt(value, _pad('', seg.end - cursorStart), cursorStart, seg.end);
      cursorStart = seg.end + 1;
    }
    _Segment? current;
    while (cursorStart < cursorEnd && (current = _positions[cursorStart + 1]) != null) {
      final insertionEnd = math.min(cursorEnd, current!.end);
      value = _insertAt(value, _pad('', insertionEnd - current.start), current.start, insertionEnd);
      cursorStart = insertionEnd + 1;
    }
    return (value: correctMinMaxValues(value), position: position);
  }

  CsMaskResult? handleSeparatorInput(String value, int position) {
    if (position == value.length && !isSegmentStart(position)) {
      final seg = _positions[position];
      if (seg == null) return null;
      var segValue = value.substring(seg.start, math.min(value.length, seg.end));
      segValue = _padWithDefault(segValue, seg);
      value = correctMinMaxValues(_insertAt(value, segValue, seg.start, seg.end));
      return (value: value, position: value.length);
    }
    return null;
  }

  bool isCursorAtSeparator(int position) => position > 0 && position < maxLength && _positions[position] == null;

  bool isSegmentStart(int position) => position == 0 || isCursorAtSeparator(position - 1);

  CsMaskResult deleteSeparator(String value, int position) {
    value = _insertAt(value, '0', position - 2, position - 1);
    return (value: correctMinMaxValues(value), position: position - 2);
  }

  CsMaskResult deleteDigit(String value, int position) {
    value = _insertAt(value, '0', position - 1, position);
    if (value.length >= 2 && value.substring(value.length - 2) == '0$separator') {
      value = value.substring(0, value.length - 2);
    }
    return (value: correctMinMaxValues(value), position: position - 1);
  }

  String correctMinMaxValues(String value) {
    var seg = _positions[0];
    while (seg != null && value.length >= seg.end) {
      final n = int.tryParse(value.substring(seg.start, seg.end)) ?? 0;
      final max = seg.max(value);
      if (n < seg.min) value = _insertAt(value, _pad('${seg.min}', seg.length), seg.start, seg.end);
      if (n > max) value = _insertAt(value, '$max', seg.start, seg.end);
      seg = _positions[seg.end + 1];
    }
    final end = _segments.last.end;
    return value.length > end ? value.substring(0, end) : value;
  }

  String formatPastedText(String text, String value, int cursorStart, int cursorEnd) {
    var position = cursorStart;
    var formatted = value;
    if (cursorEnd > cursorStart && cursorEnd == value.length) formatted = value.substring(0, cursorStart);
    for (final key in text.trim().split('')) {
      if (position >= maxLength) break;
      if (!isSeparator(key) && !RegExp(r'^\d$').hasMatch(key)) continue;
      final r = processKey(formatted, key, position);
      formatted = r.value;
      position = r.position;
    }
    return tryAppendSeparator(formatted);
  }

  CsMaskResult processKey(String initialValue, String key, int initialPosition) {
    var value = initialValue;
    var position = initialPosition;
    if (isSeparator(key)) {
      final r = handleSeparatorInput(value, position);
      if (r != null) {
        value = r.value;
        position = r.position;
      }
    } else if (_positions[position] != null) {
      final atEnd = position == value.length;
      final segValue = _segmentValueWithAddition(position, value, key);
      final segMax = _positions[position]!.max(value);
      final segMin = _positions[position]!.min;
      final firstDigitGreater = int.parse(key) > int.parse('$segMax'[0]);
      final validPosition = atEnd || '$segValue'.length == 1;
      if (isSegmentStart(position) && validPosition && firstDigitGreater) {
        value = _insertAt(value, '0$key', position, position + 2);
        position += 2;
      } else if (segValue > segMax && isSegmentStart(position)) {
        value = _insertAt(value, '$segMax', position, position + '$segMax'.length);
        position += '$segMax'.length;
      } else if (segValue > segMax) {
        value = _insertAt(value, '$segMax', position - 1, position + 1);
        position += 1;
      } else if (segValue < segMin && !isSegmentStart(position)) {
        value = _insertAt(value, '$segMin', position, position + 1);
        position += 1;
      } else {
        value = _insertAt(value, key, position, position + 1);
        position += 1;
      }
    }
    value = tryAppendSeparator(value);
    if (isCursorAtSeparator(position)) position++;
    return (value: value, position: position);
  }

  String _padWithDefault(String segValue, _Segment seg) {
    final def = _pad('${seg.defaultValue ?? seg.min}', seg.length);
    return _insertAt(def, segValue, seg.length - segValue.length, seg.length);
  }

  /// Cloudscape `keyHandler`: a digit or separator typed at a selection.
  CsMaskResult keyHandler(String initialValue, String key, int selectionStart, int selectionEnd) {
    var value = initialValue;
    final position = selectionStart;
    if (selectionStart == value.length && value.length == maxLength) return (value: value, position: position);
    if (selectionStart != value.length && selectionEnd == value.length) {
      final sliceEnd = isCursorAtSeparator(selectionStart) ? selectionStart + 1 : selectionStart;
      value = initialValue.substring(0, sliceEnd);
    }
    if (isCursorAtSeparator(position)) return (value: value, position: position + 1);
    return processKey(value, key, position);
  }

  /// Cloudscape `backspaceHandler`.
  CsMaskResult backspaceHandler(String initialValue, int selectionStart, int selectionEnd) {
    if (selectionStart != selectionEnd) {
      if (selectionEnd != initialValue.length) {
        return replaceDigitsWithZeroes(initialValue, selectionStart, selectionEnd);
      }
      return (value: initialValue.substring(0, selectionStart), position: selectionStart);
    }
    if (selectionStart <= 0) return (value: initialValue, position: 0);
    final atSeparator = isSegmentStart(selectionStart);
    final atEnd = selectionStart == initialValue.length;
    if (!atEnd) {
      return atSeparator ? deleteSeparator(initialValue, selectionStart) : deleteDigit(initialValue, selectionStart);
    }
    if (atSeparator) {
      final cut = math.max(0, selectionStart - 2);
      return (value: initialValue.substring(0, cut), position: cut);
    }
    return (value: initialValue.substring(0, selectionStart - 1), position: selectionStart - 1);
  }
}

/// Applies a [CsMaskFormat] to edits in a text field, the way Cloudscape's
/// masked input handles key presses, Backspace and paste.
class CsMaskInputFormatter extends TextInputFormatter {
  CsMaskInputFormatter(this.format, {this.autofix = false});

  final CsMaskFormat format;
  final bool autofix;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    if (oldText == newText) return newValue;

    var prefix = 0;
    final minLen = math.min(oldText.length, newText.length);
    while (prefix < minLen && oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < minLen - prefix && oldText[oldText.length - 1 - suffix] == newText[newText.length - 1 - suffix]) {
      suffix++;
    }
    var removedStart = prefix;
    var removedEnd = oldText.length - suffix;
    final inserted = newText.substring(prefix, newText.length - suffix);
    final sel = oldValue.selection;
    if (sel.isValid && !sel.isCollapsed && sel.start <= removedStart && sel.end >= removedEnd) {
      removedStart = sel.start;
      removedEnd = sel.end;
    }

    CsMaskResult result;
    if (inserted.isEmpty) {
      result = removedEnd - removedStart == 1
          ? format.backspaceHandler(oldText, removedEnd, removedEnd)
          : format.backspaceHandler(oldText, removedStart, removedEnd);
    } else if (inserted.length == 1) {
      final key = inserted;
      if (!RegExp(r'^\d$').hasMatch(key) && !format.isSeparator(key)) return oldValue;
      result = format.keyHandler(oldText, key, removedStart, removedEnd);
    } else {
      final text = format.formatPastedText(inserted, oldText, removedStart, removedEnd);
      result = (value: text, position: text.length);
    }

    var value = result.value;
    if (autofix) value = format.correctMinMaxValues(value);
    if (value.isNotEmpty && !format.isValid(value)) return oldValue;
    final position = result.position.clamp(0, value.length);
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: position),
    );
  }
}

/// Date mask: `YYYY/MM/DD` (or `YYYY-MM-DD`), months only with [monthOnly].
CsMaskFormat csDateMask({required bool iso, bool monthOnly = false}) {
  int maxDays(String value) {
    final digits = value.replaceAll('/', '-');
    final base = digits.length >= 7 ? digits.substring(0, 7) : digits;
    final parsed = csParseIso(base);
    return parsed == null ? 31 : csDaysInMonth(parsed);
  }

  return CsMaskFormat(
    separator: iso ? '-' : '/',
    inputSeparators: iso ? const ['/', '.', ' '] : const ['-', '.', ' '],
    segments: [
      const CsMaskSegment(min: 0, max: 9999, length: 4, defaultValue: 2000),
      const CsMaskSegment(min: 1, max: 12, length: 2),
      if (!monthOnly) CsMaskSegment.dynamic(min: 1, max: maxDays, length: 2),
    ],
  );
}

/// Time mask: `hh`, `hh:mm` or `hh:mm:ss` with [parts] segments.
CsMaskFormat csTimeMask({required int parts, bool use24Hour = true}) => CsMaskFormat(
  separator: ':',
  segments: [
    use24Hour ? const CsMaskSegment(min: 0, max: 23, length: 2) : const CsMaskSegment(min: 1, max: 12, length: 2),
    const CsMaskSegment(min: 0, max: 59, length: 2),
    const CsMaskSegment(min: 0, max: 59, length: 2),
  ].sublist(0, parts),
);

/// The chrome of a Cloudscape dropdown (date picker and date range picker):
/// `color-background-dropdown-item-default`, a 2px
/// `color-border-dropdown-container` border, 8px radius, `shadow-dropdown`.
class CsDatesDropdownSurface extends StatelessWidget {
  const CsDatesDropdownSurface({super.key, required this.child, this.semanticLabel});

  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.dropdown));
    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: semanticLabel != null,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: cs.colors.backgroundContainerContent,
          borderRadius: radius,
          boxShadow: cs.shadows.dropdown,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: CsRing.inside(cs.colors.borderDropdownContainer, width: CsBorderWidth.dropdown),
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}

/// Which outer edges of a range selection a cell sits on, for the 2px
/// `color-background-control-checked` border around a selected range.
@immutable
class CsCellEdges {
  const CsCellEdges({this.top = false, this.bottom = false, this.start = false, this.end = false});

  static const CsCellEdges all = CsCellEdges(top: true, bottom: true, start: true, end: true);
  static const CsCellEdges none = CsCellEdges();

  final bool top;
  final bool bottom;
  final bool start;
  final bool end;
}

/// One day (or month) of a calendar grid, styled from Cloudscape's
/// `calendar/styles.scss` and `date-range-picker/calendar/grids/styles.scss`.
class CsCalendarCell extends StatelessWidget {
  const CsCalendarCell({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.height,
    required this.onPress,
    this.focusNode,
    this.focusable = true,
    this.enabled = true,
    this.currentPage = true,
    this.visible = true,
    this.selected = false,
    this.current = false,
    this.inRange = false,
    this.rangeEdges = CsCellEdges.none,
    this.disabledReason,
  });

  final String text;
  final String semanticLabel;
  final double height;
  final VoidCallback? onPress;
  final FocusNode? focusNode;

  /// Enabled, or disabled with a reason (which keeps it focusable).
  final bool focusable;
  final bool enabled;

  /// Belongs to the page being shown (days of the adjacent month do not).
  final bool currentPage;

  /// False draws an empty slot (range grids hide the adjacent months).
  final bool visible;
  final bool selected;

  /// Today, or this month in a month grid.
  final bool current;
  final bool inRange;
  final CsCellEdges rangeEdges;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    if (!visible) return SizedBox(height: height);
    final cs = context.cs;
    final c = cs.colors;
    final dir = Directionality.of(context);
    const r = Radius.circular(CsBorderRadius.item);

    // A disabled day with a reason stays focusable (Cloudscape gives it
    // tabIndex -1) so keyboard users reach its tooltip; it takes no action.
    final reasonOnly = !enabled && focusable;
    Widget cell = CsPressable(
      onPress: enabled ? onPress : (reasonOnly ? () {} : null),
      disabled: !enabled && !reasonOnly,
      isButton: enabled,
      focusNode: focusNode,
      canRequestFocus: focusable,
      minTapTargetSize: 0,
      showFocusRing: false,
      scaleOnPress: false,
      semanticLabel: semanticLabel,
      semanticHint: disabledReason,
      selected: enabled ? selected : null,
      excludeChildSemantics: true,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      haptic: CsHaptic.none,
      builder: (context, state) {
        final hover = enabled && currentPage && state.active;
        final CsColor textColor;
        if (selected) {
          textColor = CsColor.textCalendarDateSelected;
        } else if (!enabled) {
          textColor = CsColor.textDropdownItemDisabled;
        } else if (hover) {
          textColor = CsColor.textCalendarDateHover;
        } else if (currentPage) {
          textColor = CsColor.textDropdownItemDefault;
        } else {
          textColor = CsColor.textDropdownItemSecondary;
        }
        final bold = selected || current || inRange;

        // Range cells round only the corners where two outer edges meet.
        BorderRadiusDirectional radius = const BorderRadiusDirectional.all(r);
        if (inRange) {
          final e = rangeEdges;
          radius = BorderRadiusDirectional.only(
            topStart: e.top && e.start ? r : Radius.zero,
            topEnd: e.top && e.end ? r : Radius.zero,
            bottomStart: e.bottom && e.start ? r : Radius.zero,
            bottomEnd: e.bottom && e.end ? r : Radius.zero,
          );
        }
        final resolved = radius.resolve(dir);

        Color? fill;
        if (selected) {
          fill = c.backgroundControlChecked;
        } else if (hover) {
          fill = c.backgroundDropdownItemHover;
        } else if (inRange) {
          fill = c.backgroundDropdownItemSelected;
        } else if (current) {
          fill = c.backgroundCalendarCurrentDate;
        }

        Border? border;
        if (selected && !inRange) {
          border = CsRing.inside(c.backgroundControlChecked, width: CsBorderLine.itemWidth);
        } else if (hover && !selected) {
          border = CsRing.inside(c.borderDropdownItemHover, width: CsBorderLine.itemWidth);
        } else if (inRange) {
          final side = BorderSide(color: c.backgroundControlChecked, width: CsBorderLine.itemWidth);
          final e = rangeEdges;
          final startSide = e.start ? side : BorderSide.none;
          final endSide = e.end ? side : BorderSide.none;
          border = Border(
            top: e.top ? side : BorderSide.none,
            bottom: e.bottom ? side : BorderSide.none,
            left: dir == TextDirection.ltr ? startSide : endSide,
            right: dir == TextDirection.ltr ? endSide : startSide,
          );
        }

        Widget content = Container(
          constraints: BoxConstraints(minHeight: height),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, borderRadius: resolved),
          foregroundDecoration: border == null ? null : BoxDecoration(border: border, borderRadius: resolved),
          padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: cs
                .text(CsTypeScale.bodyM, color: textColor, weight: bold ? CsTypography.bold : null)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        );
        if (state.focused) {
          // Cloudscape's focus-highlight sits 5px inside the cell
          // (`space-calendar-grid-focus-outline-gutter`), with a light ring
          // around it on selected cells so it reads on the blue fill.
          content = CustomPaint(
            foregroundPainter: _CellFocusPainter(
              color: c.borderItemFocused,
              inset: -CsSpace.calendarGridFocusOutlineGutter - 2,
              halo: selected ? c.borderCalendarGridSelectedFocusRing : null,
            ),
            child: content,
          );
        }
        return content;
      },
    );
    if (disabledReason != null && disabledReason!.isNotEmpty) {
      cell = CsTooltip(content: disabledReason!, child: cell);
    }
    return cell;
  }
}

/// Cloudscape's calendar focus highlight: a 2px ring inset into the cell
/// (`space-calendar-grid-focus-outline-gutter`) with a 3px radius, plus a
/// light halo inside it on selected cells so it reads on the blue fill.
/// (`CsFocusRingPainter` only supports rings drawn outside.)
class _CellFocusPainter extends CustomPainter {
  const _CellFocusPainter({required this.color, required this.inset, this.halo});

  final Color color;
  final double inset;
  final Color? halo;

  @override
  void paint(Canvas canvas, Size size) {
    void ring(double deflate, Color c) {
      final rect = (Offset.zero & size).deflate(deflate);
      if (rect.width <= 0 || rect.height <= 0) return;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(CsBorderRadius.calendarDayFocusRing)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c,
      );
    }

    final d = math.max(1.0, math.min(inset, math.min(size.width, size.height) / 2 - 4));
    ring(d, color);
    if (halo != null) ring(d + 2, halo!);
  }

  @override
  bool shouldRepaint(_CellFocusPainter old) => old.color != color || old.inset != inset || old.halo != halo;
}

/// Wraps a calendar body in Cloudscape's quick fade-in (`motion-duration-
/// show-quick`), replayed whenever [pageKey] changes. Reduced motion shows
/// pages instantly.
class CsCalendarPageFade extends StatelessWidget {
  const CsCalendarPageFade({super.key, required this.pageKey, required this.child});

  final Object pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: CsMotion.duration(context, CsDurations.showQuick),
      switchInCurve: CsCurves.showQuick,
      switchOutCurve: CsCurves.showQuick,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          for (final p in previous)
            ExcludeFocus(
              child: ExcludeSemantics(child: IgnorePointer(child: p)),
            ),
          ?current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(pageKey), child: child),
    );
  }
}
