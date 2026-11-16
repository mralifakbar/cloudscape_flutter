import 'package:flutter/widgets.dart';

/// Cloudscape's responsive breakpoints (`src/internal/breakpoints.ts`), used
/// by grids, column layouts and the app layout. Below [xs] (688px) Cloudscape
/// switches to its mobile layout.
enum CsBreakpoint {
  /// Under 465px.
  base(0),

  /// 465px and up.
  xxs(465),

  /// 688px and up. The app layout's mobile breakpoint.
  xs(688),

  /// 912px and up.
  s(912),

  /// 1120px and up.
  m(1120),

  /// 1320px and up.
  l(1320),

  /// 1840px and up.
  xl(1840);

  const CsBreakpoint(this.minWidth);

  /// Smallest width, in logical pixels, at which this breakpoint applies.
  final double minWidth;

  /// The largest breakpoint that applies at [width].
  static CsBreakpoint of(double width) {
    for (final b in values.reversed) {
      if (width > b.minWidth || b == base) return b;
    }
    return base;
  }

  /// Picks the value for [actual] from a breakpoint map, falling back to the
  /// nearest smaller breakpoint that has one (Cloudscape's `matchBreakpointMapping`).
  static T? match<T>(Map<CsBreakpoint, T> mapping, CsBreakpoint actual) {
    for (var i = actual.index; i >= 0; i--) {
      final v = mapping[values[i]];
      if (v != null) return v;
    }
    return null;
  }
}

/// Breakpoint helpers on [BuildContext].
extension CsBreakpointContext on BuildContext {
  /// The breakpoint for the current window width.
  CsBreakpoint get csBreakpoint => CsBreakpoint.of(MediaQuery.sizeOf(this).width);

  /// True below Cloudscape's mobile breakpoint (688px): app layout panels
  /// become overlays, menus and selects open as bottom sheets.
  bool get csIsNarrow => MediaQuery.sizeOf(this).width <= CsBreakpoint.xs.minWidth;
}

/// Cloudscape draws most borders inside the box (`box-sizing: border-box`)
/// and focus rings outside it. These build the Flutter equivalents.
abstract final class CsRing {
  /// A border drawn inside the box edge, like a CSS border.
  static Border inside(Color color, {double width = 1}) =>
      Border.all(color: color, width: width, strokeAlign: BorderSide.strokeAlignInside);

  /// A stroke drawn outside the box edge that takes no layout space (a CSS
  /// `box-shadow: 0 0 0 1px` faux border).
  static Border outside(Color color, {double width = 1}) =>
      Border.all(color: color, width: width, strokeAlign: BorderSide.strokeAlignOutside);
}
