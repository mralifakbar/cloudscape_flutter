import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'generated/cs_colors.g.dart';
import 'generated/cs_tokens.g.dart';
import 'cs_typography.dart';

/// Content density (Cloudscape's `Density` mode). Compact tightens vertical
/// spacing and control heights for data-heavy pages.
enum CsDensity { comfortable, compact }

/// How large interactive targets are.
enum CsTapTargetSize {
  /// Pads small controls so their hit area is at least 44x44. The default on
  /// touch platforms (iOS, Android, Fuchsia).
  padded,

  /// Hit area matches the visual. The default with a mouse, where Cloudscape's
  /// 32px controls are the norm.
  shrinkWrap;

  /// The platform default.
  static CsTapTargetSize get platformDefault => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android || TargetPlatform.fuchsia => padded,
    _ => shrinkWrap,
  };
}

/// A resolved Cloudscape theme for one mode and density. Read it with
/// `context.cs`.
///
/// ```dart
/// final cs = context.cs;
/// Container(
///   color: cs.colors.backgroundContainerContent,
///   padding: EdgeInsets.all(cs.space.scaledM),
///   child: Text('Instances', style: cs.text(CsTypeScale.headingM)),
/// )
/// ```
@immutable
class CsThemeData {
  const CsThemeData({
    required this.brightness,
    required this.colors,
    this.density = CsDensity.comfortable,
    this.densityTokens = CsDensityTokens.comfortable,
    this.shadows = CsShadows.light,
    this.typography = const CsTypography(),
    this.tapTargetSize = CsTapTargetSize.shrinkWrap,
    this.visualContext,
    this.motionDisabled = false,
  });

  /// Cloudscape light mode.
  factory CsThemeData.light({
    CsDensity density = CsDensity.comfortable,
    CsTypography typography = const CsTypography(),
    CsTapTargetSize? tapTargetSize,
    Map<CsColor, Color> colorOverrides = const {},
    bool motionDisabled = false,
  }) => CsThemeData(
    brightness: Brightness.light,
    colors: CsColorSchemes.light.copyWith(colorOverrides),
    density: density,
    densityTokens: density == CsDensity.compact ? CsDensityTokens.compact : CsDensityTokens.comfortable,
    shadows: CsShadows.light,
    typography: typography,
    tapTargetSize: tapTargetSize ?? CsTapTargetSize.platformDefault,
    motionDisabled: motionDisabled,
  );

  /// Cloudscape dark mode.
  factory CsThemeData.dark({
    CsDensity density = CsDensity.comfortable,
    CsTypography typography = const CsTypography(),
    CsTapTargetSize? tapTargetSize,
    Map<CsColor, Color> colorOverrides = const {},
    bool motionDisabled = false,
  }) => CsThemeData(
    brightness: Brightness.dark,
    colors: CsColorSchemes.dark.copyWith(colorOverrides),
    density: density,
    densityTokens: density == CsDensity.compact ? CsDensityTokens.compact : CsDensityTokens.comfortable,
    shadows: CsShadows.dark,
    typography: typography,
    tapTargetSize: tapTargetSize ?? CsTapTargetSize.platformDefault,
    motionDisabled: motionDisabled,
  );

  /// Used when no theme is above a widget.
  static const CsThemeData fallback = CsThemeData(brightness: Brightness.light, colors: CsColorSchemes.light);

  final Brightness brightness;
  final CsColorScheme colors;
  final CsDensity density;

  /// Spacing and sizes for [density]. Tables in compact mode use
  /// [CsDensityTokens.compactTable].
  final CsDensityTokens densityTokens;
  final CsShadows shadows;
  final CsTypography typography;
  final CsTapTargetSize tapTargetSize;

  /// The visual context this theme was recolored for, if any.
  final CsVisualContextName? visualContext;

  /// Cloudscape's `disableMotion`: transitions and springs become instant.
  /// The platform reduce-motion setting has the same effect.
  final bool motionDisabled;

  bool get isDark => brightness == Brightness.dark;

  /// Density-aware spacing and sizes: `context.cs.space.scaledM`.
  CsDensityTokens get space => densityTokens;

  /// Resolves a color token.
  Color color(CsColor token) => colors[token];

  /// Minimum hit-area edge for interactive controls under [tapTargetSize].
  double get minTapTarget => tapTargetSize == CsTapTargetSize.padded ? 44 : 0;

  /// A text style on [scale]. Color defaults to `color-text-body-default`
  /// for body steps and `color-text-heading-default` for headings.
  TextStyle text(CsTypeScale scale, {FontWeight? weight, CsColor? color, TextDecoration? decoration}) {
    final isHeading = scale != CsTypeScale.bodyS && scale != CsTypeScale.bodyM;
    return typography.style(
      scale,
      weight: weight,
      color: colors[color ?? (isHeading ? CsColor.textHeadingDefault : CsColor.textBodyDefault)],
      decoration: decoration,
    );
  }

  /// Body text (14/20) in `color-text-body-default`.
  TextStyle get body => text(CsTypeScale.bodyM);

  /// Monospace text on [scale].
  TextStyle code({CsTypeScale scale = CsTypeScale.bodyM, CsColor color = CsColor.textBodyDefault}) =>
      typography.code(scale: scale, color: colors[color]);

  /// This theme recolored for [context] (top navigation, header, alert...).
  /// The top navigation and header contexts are always dark.
  CsThemeData withVisualContext(CsVisualContextName context) {
    final forcedDark = context == CsVisualContextName.topNavigation || context == CsVisualContextName.header;
    final base = forcedDark && !isDark ? _darkBase() : this;
    return base.copyWith(
      colors: base.colors.copyWith(CsColorSchemes.contextOverrides(context, brightness)),
      visualContext: context,
    );
  }

  CsThemeData _darkBase() => copyWith(
    brightness: Brightness.dark,
    colors: CsColorSchemes.dark,
    shadows: CsShadows.dark,
  );

  CsThemeData copyWith({
    Brightness? brightness,
    CsColorScheme? colors,
    CsDensity? density,
    CsDensityTokens? densityTokens,
    CsShadows? shadows,
    CsTypography? typography,
    CsTapTargetSize? tapTargetSize,
    CsVisualContextName? visualContext,
    bool? motionDisabled,
  }) => CsThemeData(
    brightness: brightness ?? this.brightness,
    colors: colors ?? this.colors,
    density: density ?? this.density,
    densityTokens:
        densityTokens ??
        (density == null
            ? this.densityTokens
            : (density == CsDensity.compact ? CsDensityTokens.compact : CsDensityTokens.comfortable)),
    shadows: shadows ?? this.shadows,
    typography: typography ?? this.typography,
    tapTargetSize: tapTargetSize ?? this.tapTargetSize,
    visualContext: visualContext ?? this.visualContext,
    motionDisabled: motionDisabled ?? this.motionDisabled,
  );

  /// Interpolates colors; discrete settings switch at the midpoint.
  static CsThemeData lerp(CsThemeData a, CsThemeData b, double t) {
    if (identical(a, b) || a == b) return b;
    final pick = t < 0.5 ? a : b;
    return CsThemeData(
      brightness: pick.brightness,
      colors: CsColorScheme.lerp(a.colors, b.colors, t),
      density: pick.density,
      densityTokens: pick.densityTokens,
      shadows: pick.shadows,
      typography: pick.typography,
      tapTargetSize: pick.tapTargetSize,
      visualContext: pick.visualContext,
      motionDisabled: pick.motionDisabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CsThemeData &&
      other.brightness == brightness &&
      other.colors == colors &&
      other.density == density &&
      identical(other.densityTokens, densityTokens) &&
      identical(other.shadows, shadows) &&
      other.typography == typography &&
      other.tapTargetSize == tapTargetSize &&
      other.visualContext == visualContext &&
      other.motionDisabled == motionDisabled;

  @override
  int get hashCode => Object.hash(
    brightness,
    colors,
    density,
    densityTokens,
    shadows,
    typography,
    tapTargetSize,
    visualContext,
    motionDisabled,
  );
}
