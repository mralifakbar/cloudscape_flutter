// Scale and tick math for the charts, ported from d3-array / d3-scale (ISC)
// as used by Cloudscape's cartesian charts (src/internal/components/
// cartesian-chart/scales.ts, ticks.ts, label-utils.ts).
import 'dart:math' as math;

import '../../system/cs_strings.dart';

const double _e10 = 7.0710678118654755; // sqrt(50)
const double _e5 = 3.1622776601683795; // sqrt(10)
const double _e2 = 1.4142135623730951; // sqrt(2)

(int, int, double) _tickSpec(double start, double stop, double count) {
  final step = (stop - start) / math.max(0, count);
  final power = (math.log(step) / math.ln10).floor();
  final error = step / math.pow(10, power);
  final factor = error >= _e10
      ? 10
      : error >= _e5
      ? 5
      : error >= _e2
      ? 2
      : 1;
  int i1;
  int i2;
  double inc;
  if (power < 0) {
    inc = math.pow(10, -power) / factor;
    i1 = (start * inc).round();
    i2 = (stop * inc).round();
    if (i1 / inc < start) ++i1;
    if (i2 / inc > stop) --i2;
    inc = -inc;
  } else {
    inc = math.pow(10, power) * factor.toDouble();
    i1 = (start / inc).round();
    i2 = (stop / inc).round();
    if (i1 * inc < start) ++i1;
    if (i2 * inc > stop) --i2;
  }
  if (i2 < i1 && 0.5 <= count && count < 2) return _tickSpec(start, stop, count * 2);
  return (i1, i2, inc);
}

/// d3's `ticks(start, stop, count)`: about [count] round values between
/// [start] and [stop].
List<double> niceTicks(double start, double stop, int count) {
  if (count <= 0 || !start.isFinite || !stop.isFinite) return const [];
  if (start == stop) return [start];
  final reverse = stop < start;
  final (a, b) = reverse ? (stop, start) : (start, stop);
  final (i1, i2, inc) = _tickSpec(a, b, count.toDouble());
  if (!(i2 >= i1)) return const [];
  final n = i2 - i1 + 1;
  final out = List<double>.generate(n, (i) => inc < 0 ? (i1 + i) / -inc : (i1 + i) * inc);
  return reverse ? out.reversed.toList() : out;
}

double _tickIncrement(double start, double stop, int count) => _tickSpec(start, stop, count.toDouble()).$3;

/// d3's linear `scale.nice(count)`: widens [lo]..[hi] to round tick steps.
(double, double) niceDomain(double lo, double hi, int count) {
  var start = lo;
  var stop = hi;
  final swap = stop < start;
  if (swap) (start, stop) = (stop, start);
  double? prestep;
  for (var i = 0; i < 10; i++) {
    final step = _tickIncrement(start, stop, count);
    if (step == prestep) break;
    if (step > 0) {
      start = (start / step).floor() * step;
      stop = (stop / step).ceil() * step;
    } else if (step < 0) {
      start = (start * step).ceil() / step;
      stop = (stop * step).floor() / step;
    } else {
      break;
    }
    prestep = step;
  }
  return swap ? (stop, start) : (start, stop);
}

/// Ticks of a base-10 log axis: powers of ten, with 2x and 5x steps when
/// the domain spans few decades. Cloudscape falls back to 3 ticks when a
/// log axis would get more than 10.
List<double> logTicks(double lo, double hi, int count) {
  if (lo <= 0 || hi <= 0 || !lo.isFinite || !hi.isFinite) return const [];
  final a = math.min(lo, hi);
  final b = math.max(lo, hi);
  final e0 = (math.log(a) / math.ln10).floor();
  final e1 = (math.log(b) / math.ln10).ceil();
  List<double> build(List<int> multipliers) {
    final out = <double>[];
    for (var e = e0; e <= e1; e++) {
      for (final m in multipliers) {
        final v = m * math.pow(10, e).toDouble();
        if (v >= a * (1 - 1e-9) && v <= b * (1 + 1e-9)) out.add(v);
      }
    }
    return out;
  }

  final decades = e1 - e0;
  var ticks = decades < count / 2 ? build(const [1, 2, 5]) : build(const [1]);
  if (ticks.length > 10) ticks = build(const [1]);
  if (ticks.length > 10) {
    final stride = (ticks.length / 3).ceil();
    ticks = [for (var i = 0; i < ticks.length; i += stride) ticks[i]];
  }
  return ticks;
}

/// Log axis `nice()`: out to the enclosing powers of ten.
(double, double) niceLogDomain(double lo, double hi) {
  if (lo <= 0 || hi <= 0) return (lo, hi);
  final a = math.pow(10, (math.log(lo) / math.ln10).floor()).toDouble();
  final b = math.pow(10, (math.log(hi) / math.ln10).ceil()).toDouble();
  return (a, b);
}

/// Cloudscape's tick counts: one x tick per 100px, one y tick per 50px.
int xTickCount(double size) => math.max(1, (size / 100).ceil());
int yTickCount(double size) => math.max(1, (size / 50).ceil());

/// Formats a number the way an SVG label prints `value.toString()`, with
/// floating point noise removed: `0.30000000000000004` is `0.3`.
String formatChartNumber(num value) {
  if (value is int) return '$value';
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value > 0 ? 'Infinity' : '-Infinity';
  if (value == value.roundToDouble() && value.abs() < 1e15) return value.round().toString();
  var s = value.toStringAsPrecision(12);
  if (s.contains('e')) return value.toString();
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Default label of a `DateTime` tick or popover position: precision
/// follows the domain, like d3's multi-scale time format.
String formatChartTime(DateTime d, CsStrings strings, {double spanMs = 0}) {
  final month = strings.monthNamesShort[d.month - 1];
  final midnight = d.hour == 0 && d.minute == 0 && d.second == 0;
  if (spanMs >= 2 * 365 * 86400000 && d.month == 1 && d.day == 1 && midnight) return '${d.year}';
  if (spanMs >= 60 * 86400000 && d.day == 1 && midnight) return '$month ${d.year}';
  if (midnight) return '$month ${d.day}';
  if (d.second != 0 && spanMs < 3600000) return '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
  if (spanMs >= 86400000) return '$month ${d.day}, ${_two(d.hour)}:${_two(d.minute)}';
  return '${_two(d.hour)}:${_two(d.minute)}';
}

enum _TimeUnit { second, minute, hour, day, month, year }

const _kTimeSteps = <(_TimeUnit, int)>[
  (_TimeUnit.second, 1), (_TimeUnit.second, 5), (_TimeUnit.second, 15), (_TimeUnit.second, 30), //
  (_TimeUnit.minute, 1), (_TimeUnit.minute, 5), (_TimeUnit.minute, 15), (_TimeUnit.minute, 30),
  (_TimeUnit.hour, 1), (_TimeUnit.hour, 3), (_TimeUnit.hour, 6), (_TimeUnit.hour, 12),
  (_TimeUnit.day, 1), (_TimeUnit.day, 2), (_TimeUnit.day, 7),
  (_TimeUnit.month, 1), (_TimeUnit.month, 3),
  (_TimeUnit.year, 1), (_TimeUnit.year, 2), (_TimeUnit.year, 5), (_TimeUnit.year, 10), (_TimeUnit.year, 25),
  (_TimeUnit.year, 50), (_TimeUnit.year, 100),
];

double _unitMs(_TimeUnit unit) => switch (unit) {
  _TimeUnit.second => 1000,
  _TimeUnit.minute => 60000,
  _TimeUnit.hour => 3600000,
  _TimeUnit.day => 86400000,
  _TimeUnit.month => 30 * 86400000,
  _TimeUnit.year => 365 * 86400000,
};

/// d3's time `ticks(count)`: about [count] ticks on calendar boundaries
/// (d3's interval table), with Cloudscape's fix for uneven 2-day steps.
List<DateTime> timeTicks(DateTime start, DateTime end, int count) {
  final startMs = start.millisecondsSinceEpoch.toDouble();
  final endMs = end.millisecondsSinceEpoch.toDouble();
  if (!(endMs > startMs)) return [start];
  final utc = start.isUtc;
  final target = (endMs - startMs) / math.max(1, count);
  var choice = _kTimeSteps.last;
  for (var i = 0; i < _kTimeSteps.length; i++) {
    final s = _kTimeSteps[i];
    final ms = _unitMs(s.$1) * s.$2;
    if (ms >= target) {
      // d3 picks the closer of the two neighbouring intervals.
      if (i > 0) {
        final p = _kTimeSteps[i - 1];
        final pms = _unitMs(p.$1) * p.$2;
        choice = target / pms < ms / target ? p : s;
      } else {
        choice = s;
      }
      break;
    }
  }
  final (unit, step) = choice;
  DateTime make(int y, [int mo = 1, int d = 1, int h = 0, int mi = 0, int s = 0]) =>
      utc ? DateTime.utc(y, mo, d, h, mi, s) : DateTime(y, mo, d, h, mi, s);
  final s0 = start;
  var cur = switch (unit) {
    _TimeUnit.second => make(s0.year, s0.month, s0.day, s0.hour, s0.minute, s0.second ~/ step * step),
    _TimeUnit.minute => make(s0.year, s0.month, s0.day, s0.hour, s0.minute ~/ step * step),
    _TimeUnit.hour => make(s0.year, s0.month, s0.day, s0.hour ~/ step * step),
    _TimeUnit.day => make(s0.year, s0.month, s0.day),
    _TimeUnit.month => make(s0.year, (s0.month - 1) ~/ step * step + 1),
    _TimeUnit.year => make(s0.year ~/ step * step),
  };
  DateTime next(DateTime d) => switch (unit) {
    _TimeUnit.second => make(d.year, d.month, d.day, d.hour, d.minute, d.second + step),
    _TimeUnit.minute => make(d.year, d.month, d.day, d.hour, d.minute + step),
    _TimeUnit.hour => make(d.year, d.month, d.day, d.hour + step),
    _TimeUnit.day => make(d.year, d.month, d.day + step),
    _TimeUnit.month => make(d.year, d.month + step),
    _TimeUnit.year => make(d.year + step),
  };
  final out = <DateTime>[];
  for (var guard = 0; guard < 500; guard++) {
    final ms = cur.millisecondsSinceEpoch;
    if (ms > endMs) break;
    if (ms >= startMs) out.add(cur);
    final n = next(cur);
    if (!n.isAfter(cur)) break;
    cur = n;
  }
  return out;
}

/// A position on a continuous axis: linear, log or time (as milliseconds).
class ContinuousScale {
  ContinuousScale({required this.d0, required this.d1, required this.r0, required this.r1, this.log = false});

  final double d0;
  final double d1;
  final double r0;
  final double r1;
  final bool log;

  double _t(double v) => log ? (v <= 0 ? double.negativeInfinity : math.log(v) / math.ln10) : v;

  /// Maps a domain value to a pixel position. A zero-width domain maps to
  /// the middle of the range, as d3 does.
  double call(double v) {
    final a = _t(d0);
    final b = _t(d1);
    if (b == a || !a.isFinite || !b.isFinite) return (r0 + r1) / 2;
    return r0 + (_t(v) - a) / (b - a) * (r1 - r0);
  }

  /// Inverse of [call].
  double invert(double px) {
    if (r1 == r0) return d0;
    final a = _t(d0);
    final b = _t(d1);
    final t = a + (px - r0) / (r1 - r0) * (b - a);
    return log ? math.pow(10, t).toDouble() : t;
  }

  double get min => math.min(r0, r1);
  double get max => math.max(r0, r1);
}

/// d3's `scaleBand` with Cloudscape's paddings: bars get an inner padding
/// of 0.2 and an outer padding of 0.05; line-only categorical charts get
/// 0.7 and 0 so points sit closer to the edges.
class BandScale {
  BandScale({required this.count, required double r0, required double r1, required bool linesOnly}) {
    final paddingInner = linesOnly ? 0.7 : 0.2;
    final paddingOuter = linesOnly ? 0.0 : 0.05;
    final reverse = r1 < r0;
    final lo = reverse ? r1 : r0;
    final hi = reverse ? r0 : r1;
    final n = math.max(count, 1);
    step = (hi - lo) / math.max(1, n - paddingInner + paddingOuter * 2);
    bandwidth = step * (1 - paddingInner);
    _start = lo + (hi - lo - step * (n - paddingInner)) * 0.5;
    _reverse = reverse;
    _hi = hi;
    _lo = lo;
  }

  final int count;
  late final double step;
  late final double bandwidth;
  late final double _start;
  late final bool _reverse;
  late final double _hi;
  late final double _lo;

  /// Start edge of band [i].
  double call(int i) {
    final p = _start + step * i;
    return _reverse ? _hi - (p - _lo) - bandwidth : p;
  }

  /// Center of band [i].
  double center(int i) => call(i) + bandwidth / 2;
}

/// A formatted tick: its pixel [position], label [lines] and the width or
/// height the label takes along the axis.
class FormattedTick {
  FormattedTick(this.position, this.lines, this.space, {this.value});

  final double position;
  final List<String> lines;
  final double space;
  final Object? value;
}

const double _kLabelGap = 4;

bool _intersects(FormattedTick a, FormattedTick b) {
  final (l, r) = a.position < b.position ? (a, b) : (b, a);
  return l.position + l.space / 2 + _kLabelGap > r.position - r.space / 2;
}

/// Cloudscape's `getVisibleTicks`: drops labels that do not fit inside
/// [from]..[until], then either keeps every n-th label so the rest do not
/// overlap ([balance], bottom x axes) or drops each label that overlaps the
/// previous one.
List<FormattedTick> visibleTicks(List<FormattedTick> ticks, double from, double until, {bool balance = false}) {
  final inRange = ticks
      .where((t) => t.position.isFinite && from <= t.position - t.space / 2 && t.position + t.space / 2 <= until)
      .toList();
  if (balance) {
    var ratio = 1;
    while (ratio < inRange.length) {
      var ok = true;
      for (var i = ratio; i < inRange.length; i += ratio) {
        if (_intersects(inRange[i - ratio], inRange[i])) {
          ok = false;
          break;
        }
      }
      if (ok) break;
      ratio++;
    }
    return [for (var i = 0; i < inRange.length; i += ratio) inRange[i]];
  }
  final out = <FormattedTick>[];
  FormattedTick? prev;
  for (final t in inRange) {
    if (prev == null || !_intersects(prev, t)) {
      out.add(t);
      prev = t;
    }
  }
  return out;
}
