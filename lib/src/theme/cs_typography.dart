import 'package:flutter/widgets.dart';

import 'generated/cs_tokens.g.dart';

/// Cloudscape's type scale. Each step pairs the `font-size-*`,
/// `line-height-*`, `font-weight-*` and `letter-spacing-*` tokens of the same
/// name. Content text is [bodyM] (14/20); [bodyS] (12/16) is for secondary
/// detail. Headings and displays are bold.
enum CsTypeScale {
  /// 12px on 16px: descriptions, constraint text, small print.
  bodyS(CsFontTokens.fontSizeBodyS, CsFontTokens.lineHeightBodyS, FontWeight.w400, 0),

  /// 14px on 20px: all content text, controls and table cells.
  bodyM(CsFontTokens.fontSizeBodyM, CsFontTokens.lineHeightBodyM, FontWeight.w400, 0),

  /// 14px bold on 18px: small section headings (`h5`).
  headingXs(
    CsFontTokens.fontSizeHeadingXs,
    CsFontTokens.lineHeightHeadingXs,
    CsFontTokens.fontWeightHeadingXs,
    CsFontTokens.letterSpacingHeadingXs,
  ),

  /// 16px bold on 20px: container titles (`h3`, `h4`).
  headingS(
    CsFontTokens.fontSizeHeadingS,
    CsFontTokens.lineHeightHeadingS,
    CsFontTokens.fontWeightHeadingS,
    CsFontTokens.letterSpacingHeadingS,
  ),

  /// 18px bold on 22px: container titles in visual refresh (`h2`).
  headingM(
    CsFontTokens.fontSizeHeadingM,
    CsFontTokens.lineHeightHeadingM,
    CsFontTokens.fontWeightHeadingM,
    CsFontTokens.letterSpacingHeadingM,
  ),

  /// 20px bold on 24px: section headings.
  headingL(
    CsFontTokens.fontSizeHeadingL,
    CsFontTokens.lineHeightHeadingL,
    CsFontTokens.fontWeightHeadingL,
    CsFontTokens.letterSpacingHeadingL,
  ),

  /// 24px bold on 30px: page titles (`h1`).
  headingXl(
    CsFontTokens.fontSizeHeadingXl,
    CsFontTokens.lineHeightHeadingXl,
    CsFontTokens.fontWeightHeadingXl,
    CsFontTokens.letterSpacingHeadingXl,
  ),

  /// 42px bold on 48px: large numbers in key-value displays (`awsui-value-large`).
  displayL(
    CsFontTokens.fontSizeDisplayL,
    CsFontTokens.lineHeightDisplayL,
    CsFontTokens.fontWeightDisplayL,
    CsFontTokens.letterSpacingDisplayL,
  ),

  /// 64px regular on 72px: hero headlines.
  displayXl(
    CsFontTokens.fontSizeDisplayXl,
    CsFontTokens.lineHeightDisplayXl,
    CsFontTokens.fontWeightDisplayXl,
    CsFontTokens.letterSpacingDisplayXl,
  ),

  /// 16px bold on 20px: tab labels.
  tabs(CsFontTokens.fontSizeTabs, CsFontTokens.lineHeightTabs, CsFontTokens.fontWeightTabs, 0);

  const CsTypeScale(this.fontSize, this.lineHeight, this.weight, this.letterSpacingEm);

  final double fontSize;
  final double lineHeight;
  final FontWeight weight;

  /// Letter spacing in em, from the `letter-spacing-*` token.
  final double letterSpacingEm;
}

/// Font families. Open Sans (SIL OFL) ships with the package; Cloudscape's
/// monospace stack uses system fonts (Monaco, Menlo, Consolas).
///
/// ```dart
/// CsThemeProvider(
///   typography: const CsTypography(sans: 'MyBrandSans', package: null),
///   child: app,
/// )
/// ```
@immutable
class CsTypography {
  const CsTypography({
    this.sans = 'OpenSans',
    this.package = 'cloudscape_flutter',
    this.sansFallback = const ['Helvetica Neue', 'Roboto', 'Arial', 'sans-serif'],
    this.mono = 'Monaco',
    this.monoFallback = const ['Menlo', 'Consolas', 'Courier Prime', 'Courier', 'Courier New', 'monospace'],
  });

  final String sans;

  /// Package the [sans] font assets live in; null for fonts registered by the app.
  final String? package;
  final List<String> sansFallback;
  final String mono;
  final List<String> monoFallback;

  /// `font-weight-normal`.
  static const FontWeight normal = FontWeight.w400;

  /// `font-weight-bold`: headings, buttons, labels, emphasis.
  static const FontWeight bold = FontWeight.w700;

  /// `font-weight-lighter`.
  static const FontWeight lighter = FontWeight.w300;

  /// A text style on [scale].
  TextStyle style(CsTypeScale scale, {FontWeight? weight, Color? color, TextDecoration? decoration}) => TextStyle(
    fontFamily: sans,
    package: package,
    fontFamilyFallback: sansFallback,
    fontSize: scale.fontSize,
    height: scale.lineHeight / scale.fontSize,
    fontWeight: weight ?? scale.weight,
    letterSpacing: scale.letterSpacingEm * scale.fontSize,
    color: color,
    decoration: decoration,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Monospace text. Cloudscape sets code at the body size of its context.
  TextStyle code({CsTypeScale scale = CsTypeScale.bodyM, FontWeight weight = normal, Color? color}) => TextStyle(
    fontFamily: mono,
    fontFamilyFallback: monoFallback,
    fontSize: scale.fontSize,
    height: scale.lineHeight / scale.fontSize,
    fontWeight: weight,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );

  CsTypography copyWith({String? sans, String? package, String? mono}) => CsTypography(
    sans: sans ?? this.sans,
    package: package ?? this.package,
    sansFallback: sansFallback,
    mono: mono ?? this.mono,
    monoFallback: monoFallback,
  );

  @override
  bool operator ==(Object other) =>
      other is CsTypography && other.sans == sans && other.package == package && other.mono == mono;

  @override
  int get hashCode => Object.hash(sans, package, mono);
}
