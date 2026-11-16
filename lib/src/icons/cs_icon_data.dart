import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Line cap of an icon stroke.
enum CsIconCap { butt, round, square }

/// One shape of a Cloudscape icon, in the icon's 16x16 viewBox.
@immutable
class CsIconPart {
  const CsIconPart(
    this.d, {
    this.filled = false,
    this.stroked = true,
    this.roundJoin = false,
    this.cap = CsIconCap.butt,
    this.visible = 1,
    this.clip,
  });

  /// SVG path data.
  final String d;

  /// Fill with the icon color (`class="filled"`).
  final bool filled;

  /// Stroke with the icon color. False for `class="no-stroke"`.
  final bool stroked;

  /// `stroke-linejoin: round`. Miter otherwise.
  final bool roundJoin;
  final CsIconCap cap;

  /// Fraction of the path that is drawn, from its start. Cloudscape draws
  /// some parts partially at rest and completes them on hover.
  final double visible;

  /// Clip rect as `[left, top, right, bottom]` in viewBox units.
  final List<double>? clip;
}

/// A Cloudscape icon: a name and its vector parts. Pass it to `CsIcon`.
///
/// ```dart
/// CsIcon(CsIcons.settings)
/// ```
///
/// Build your own from SVG path data in a 16x16 viewBox, drawn the way
/// Cloudscape draws icons (outlined with the current color):
///
/// ```dart
/// const CsIconData('rocket', [CsIconPart('M8 1L11 8H5Z', roundJoin: true)])
/// ```
@immutable
class CsIconData {
  const CsIconData(this.name, this.parts, {this.viewBox = 16, this.matchTextDirection = false});

  /// Cloudscape icon name (`"status-positive"`).
  final String name;
  final List<CsIconPart> parts;

  /// Width and height of the square viewBox the parts are drawn in.
  final double viewBox;

  /// Mirror the icon in right-to-left layouts (arrows, external).
  final bool matchTextDirection;

  static final Map<String, ui.Path> _cache = {};

  /// The parsed path of [part], cached by its data.
  static ui.Path pathOf(CsIconPart part) => _cache.putIfAbsent(part.d, () => parseSvgPath(part.d));

  @override
  bool operator ==(Object other) => other is CsIconData && other.name == name && listEquals(other.parts, parts);

  @override
  int get hashCode => Object.hash(name, parts.length);

  @override
  String toString() => 'CsIconData($name)';
}

/// Parses SVG path data (`M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T`, `A`, `Z`,
/// absolute and relative) into a [ui.Path].
ui.Path parseSvgPath(String data) {
  final path = ui.Path();
  final tokens = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?').allMatches(data);
  final list = tokens.map((m) => m[0]!).toList();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  double? cx, cy; // last control point, for S and T
  String prev = '';

  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(list[i++]);
  bool flag() {
    // Arc flags may be packed without separators ("0 1 0" or "010").
    final t = list[i];
    if (t.length > 1 && (t.startsWith('0') || t.startsWith('1')) && !t.contains('.')) {
      list[i] = t.substring(1);
      return t[0] == '1';
    }
    i++;
    return t == '1';
  }

  while (i < list.length) {
    if (isCmd(list[i])) {
      cmd = list[i++];
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        sx = x;
        sy = y;
        path.moveTo(x, y);
        cx = cy = null;
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
        cx = cy = null;
      case 'H':
        x = (rel ? x : 0) + next();
        path.lineTo(x, y);
        cx = cy = null;
      case 'V':
        y = (rel ? y : 0) + next();
        path.lineTo(x, y);
        cx = cy = null;
      case 'C':
        final x1 = ox + next(), y1 = oy + next(), x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'S':
        final x1 = (prev == 'C' || prev == 'S') && cx != null ? 2 * x - cx : x;
        final y1 = (prev == 'C' || prev == 'S') && cy != null ? 2 * y - cy : y;
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'Q':
        final x1 = ox + next(), y1 = oy + next();
        x = ox + next();
        y = oy + next();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'T':
        final x1 = (prev == 'Q' || prev == 'T') && cx != null ? 2 * x - cx : x;
        final y1 = (prev == 'Q' || prev == 'T') && cy != null ? 2 * y - cy : y;
        x = ox + next();
        y = oy + next();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x1;
        cy = y1;
      case 'A':
        final rx = next(), ry = next(), rotation = next();
        final large = flag(), sweep = flag();
        x = ox + next();
        y = oy + next();
        path.arcToPoint(
          ui.Offset(x, y),
          radius: ui.Radius.elliptical(rx, ry),
          rotation: rotation * math.pi / 180,
          largeArc: large,
          clockwise: sweep,
        );
        cx = cy = null;
      case 'Z':
        path.close();
        x = sx;
        y = sy;
        cx = cy = null;
    }
    prev = cmd.toUpperCase();
  }
  return path;
}
