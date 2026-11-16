import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Box text variants (Cloudscape `variant`). Each sets a default type step,
/// weight, color and vertical padding, like the HTML element it is named
/// after.
enum CsBoxVariant {
  /// Plain block, inherits text style.
  div,

  /// Plain inline text, inherits text style.
  span,

  /// Page title: heading-xl, bold, heading color, 4px vertical padding.
  h1,

  /// Section title: heading-l.
  h2,

  /// heading-m.
  h3,

  /// heading-s.
  h4,

  /// heading-xs.
  h5,

  /// Paragraph: body-m with 4px vertical padding.
  p,

  /// Bold body-m.
  strong,

  /// body-s in `color-text-small`.
  small,

  /// Monospace body-s.
  code,

  /// Monospace body-m preserving whitespace.
  pre,

  /// Monospace body-m sample output.
  samp,

  /// The label of a key-value pair: bold, `color-text-label`.
  awsuiKeyLabel,

  /// Italic body-s in `color-text-label-gen-ai`, labels generative AI output.
  awsuiGenAiLabel,

  /// Large numbers in dashboards: display-l, bold.
  awsuiValueLarge,

  /// Inline code chip: monospace body-s on `color-background-inline-code`.
  awsuiInlineCode,
}

/// Box text colors (Cloudscape `color`).
enum CsBoxColor {
  /// The variant's default color.
  defaultColor(null),

  /// The surrounding text color.
  inherit(null),

  /// `color-text-label`.
  textLabel(CsColor.textLabel),

  /// `color-text-body-secondary`.
  textBodySecondary(CsColor.textBodySecondary),

  /// `color-text-status-error`.
  textStatusError(CsColor.textStatusError),

  /// `color-text-status-success`.
  textStatusSuccess(CsColor.textStatusSuccess),

  /// `color-text-status-info`.
  textStatusInfo(CsColor.textStatusInfo),

  /// `color-text-status-inactive`.
  textStatusInactive(CsColor.textStatusInactive),

  /// `color-text-status-warning`.
  textStatusWarning(CsColor.textStatusWarning),

  /// `color-text-notification-default`, on dark or colored surfaces.
  inverted(CsColor.textNotificationDefault);

  const CsBoxColor(this.token);
  final CsColor? token;
}

/// Box font weights (Cloudscape `fontWeight`).
enum CsBoxFontWeight {
  light(FontWeight.w300),
  normal(FontWeight.w400),
  bold(FontWeight.w700),
  heavy(FontWeight.w700);

  const CsBoxFontWeight(this.weight);
  final FontWeight weight;
}

/// Spacing steps for [CsBox] padding and margin (Cloudscape `SpacingSize`).
enum CsSpacingSize {
  n(0),
  xxxs(CsSpace.xxxs),
  xxs(CsSpace.xxs),
  xs(CsSpace.xs),
  s(CsSpace.s),
  m(CsSpace.m),
  l(CsSpace.l),
  xl(CsSpace.xl),
  xxl(CsSpace.xxl),
  xxxl(CsSpace.xxxl);

  const CsSpacingSize(this.value);
  final double value;
}

/// Padding or margin on some sides of a [CsBox]. Unset sides keep the
/// variant's default.
@immutable
class CsBoxSpacing {
  const CsBoxSpacing({this.top, this.bottom, this.start, this.end});

  /// The same step on every side.
  const CsBoxSpacing.all(CsSpacingSize size) : top = size, bottom = size, start = size, end = size;

  /// [vertical] on top and bottom, [horizontal] on start and end.
  const CsBoxSpacing.symmetric({CsSpacingSize? vertical, CsSpacingSize? horizontal})
    : top = vertical,
      bottom = vertical,
      start = horizontal,
      end = horizontal;

  final CsSpacingSize? top;
  final CsSpacingSize? bottom;
  final CsSpacingSize? start;
  final CsSpacingSize? end;

  EdgeInsetsDirectional resolve(EdgeInsetsDirectional fallback) => EdgeInsetsDirectional.only(
    top: top?.value ?? fallback.top,
    bottom: bottom?.value ?? fallback.bottom,
    start: start?.value ?? fallback.start,
    end: end?.value ?? fallback.end,
  );
}

/// Cloudscape's `Box`: the text and spacing primitive. Set a [variant] for
/// a semantic text style (h1 to h5, p, small, code, key label, large value),
/// override [fontSize], [fontWeight] and [color], and add token-based
/// [padding] and [margin].
///
/// ```dart
/// const CsBox(variant: CsBoxVariant.h1, text: 'Distributions')
/// const CsBox(variant: CsBoxVariant.awsuiKeyLabel, text: 'Status')
/// CsBox(color: CsBoxColor.textBodySecondary, child: Text('No instances'))
/// ```
class CsBox extends StatelessWidget {
  const CsBox({
    super.key,
    this.text,
    this.child,
    this.variant = CsBoxVariant.div,
    this.color = CsBoxColor.defaultColor,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.padding,
    this.margin,
    this.maxLines,
    this.overflow,
  }) : assert(text != null || child != null, 'Pass text or child');

  final String? text;
  final Widget? child;
  final CsBoxVariant variant;
  final CsBoxColor color;
  final CsTypeScale? fontSize;
  final CsBoxFontWeight? fontWeight;
  final TextAlign? textAlign;
  final CsBoxSpacing? padding;
  final CsBoxSpacing? margin;
  final int? maxLines;
  final TextOverflow? overflow;

  /// The resolved style for [variant] with the overrides applied, merged over
  /// [base] (the surrounding text style) for inheriting variants.
  static TextStyle styleFor(
    CsThemeData cs,
    TextStyle base, {
    CsBoxVariant variant = CsBoxVariant.div,
    CsBoxColor color = CsBoxColor.defaultColor,
    CsTypeScale? fontSize,
    CsBoxFontWeight? fontWeight,
  }) {
    final c = cs.colors;
    TextStyle style;
    switch (variant) {
      case CsBoxVariant.div || CsBoxVariant.span:
        style = base;
      case CsBoxVariant.h1:
        style = cs.text(CsTypeScale.headingXl);
      case CsBoxVariant.h2:
        style = cs.text(CsTypeScale.headingL);
      case CsBoxVariant.h3:
        style = cs.text(CsTypeScale.headingM);
      case CsBoxVariant.h4:
        style = cs.text(CsTypeScale.headingS);
      case CsBoxVariant.h5:
        style = cs.text(CsTypeScale.headingXs);
      case CsBoxVariant.p:
        style = cs.text(CsTypeScale.bodyM);
      case CsBoxVariant.strong:
        style = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold);
      case CsBoxVariant.small:
        style = cs.text(CsTypeScale.bodyS, color: CsColor.textSmall);
      case CsBoxVariant.code:
        style = cs.code(scale: CsTypeScale.bodyS);
      case CsBoxVariant.pre || CsBoxVariant.samp:
        style = cs.code();
      case CsBoxVariant.awsuiKeyLabel:
        style = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textLabel);
      case CsBoxVariant.awsuiGenAiLabel:
        style = cs.text(CsTypeScale.bodyS, color: CsColor.textLabelGenAi).copyWith(fontStyle: FontStyle.italic);
      case CsBoxVariant.awsuiValueLarge:
        style = cs.text(CsTypeScale.displayL).copyWith(color: base.color);
      case CsBoxVariant.awsuiInlineCode:
        style = cs.code(scale: CsTypeScale.bodyS);
    }
    if (fontSize != null) {
      final s = cs.typography.style(fontSize);
      style = style.copyWith(
        fontSize: s.fontSize,
        height: s.height,
        letterSpacing: s.letterSpacing,
        fontWeight: fontWeight == null && variant.index >= CsBoxVariant.h1.index && variant.index <= CsBoxVariant.h5.index
            ? style.fontWeight
            : s.fontWeight,
      );
    }
    if (fontWeight != null) style = style.copyWith(fontWeight: fontWeight.weight);
    if (color == CsBoxColor.inherit) {
      style = style.copyWith(color: base.color);
    } else if (color.token != null) {
      style = style.copyWith(color: c[color.token!]);
    }
    return style;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final base = DefaultTextStyle.of(context).style;
    final style = styleFor(cs, base, variant: variant, color: color, fontSize: fontSize, fontWeight: fontWeight);
    final isHeading = variant.index >= CsBoxVariant.h1.index && variant.index <= CsBoxVariant.h5.index;
    final defaultPadding = (isHeading || variant == CsBoxVariant.p)
        ? const EdgeInsetsDirectional.symmetric(vertical: CsSpace.xxs)
        : EdgeInsetsDirectional.zero;

    Widget content = text != null
        ? Text(text!, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow)
        : DefaultTextStyle(
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
            child: child!,
          );
    if (variant == CsBoxVariant.awsuiInlineCode) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.staticXxs, vertical: CsSpace.staticXxxs),
        decoration: BoxDecoration(
          color: cs.colors.backgroundInlineCode,
          borderRadius: BorderRadius.circular(CsSpace.staticXxs),
        ),
        child: content,
      );
    }
    final pad = padding?.resolve(defaultPadding) ?? defaultPadding;
    if (pad != EdgeInsetsDirectional.zero) content = Padding(padding: pad, child: content);
    if (margin != null) content = Padding(padding: margin!.resolve(EdgeInsetsDirectional.zero), child: content);
    if (isHeading) content = Semantics(header: true, child: content);
    if (textAlign != null && text == null) {
      content = Align(
        alignment: switch (textAlign!) {
          TextAlign.center => Alignment.center,
          TextAlign.right || TextAlign.end => AlignmentDirectional.centerEnd,
          _ => AlignmentDirectional.centerStart,
        },
        widthFactor: 1,
        child: content,
      );
    }
    return content;
  }
}

/// Accent colors for [CsVisualAccent].
enum CsVisualAccentColor {
  red(CsColor.backgroundVisualAccentRed, CsColor.textVisualAccentRed),
  yellow(CsColor.backgroundVisualAccentYellow, CsColor.textVisualAccentYellow),
  indigo(CsColor.backgroundVisualAccentIndigo, CsColor.textVisualAccentIndigo),
  green(CsColor.backgroundVisualAccentGreen, CsColor.textVisualAccentGreen),
  orange(CsColor.backgroundVisualAccentOrange, CsColor.textVisualAccentOrange),
  purple(CsColor.backgroundVisualAccentPurple, CsColor.textVisualAccentPurple),
  grey(CsColor.backgroundVisualAccentGrey, CsColor.textVisualAccentGrey),
  teal(CsColor.backgroundVisualAccentTeal, CsColor.textVisualAccentTeal);

  const CsVisualAccentColor(this.background, this.foreground);
  final CsColor background;
  final CsColor foreground;
}

/// Cloudscape's Box `visualAccent`: a tinted tile behind an icon or short
/// label, used to mark categories in cards and lists.
///
/// ```dart
/// const CsVisualAccent(color: CsVisualAccentColor.indigo, child: CsIcon(CsIcons.globe))
/// ```
class CsVisualAccent extends StatelessWidget {
  const CsVisualAccent({
    super.key,
    required this.color,
    required this.child,
    this.equalAspect = false,
    this.radius = CsSpacingSize.xs,
    this.fullyRounded = false,
  });

  final CsVisualAccentColor color;
  final Widget child;

  /// Square tile with equal padding (`aspectRatio: 'equal'`).
  final bool equalAspect;

  /// Corner radius step.
  final CsSpacingSize radius;

  /// Circle or pill (`borderRadius: 'full'`).
  final bool fullyRounded;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final fg = c[color.foreground];
    return Container(
      padding: equalAspect
          ? const EdgeInsets.all(CsSpace.xs)
          : const EdgeInsets.symmetric(horizontal: CsSpace.xs, vertical: CsSpace.xxs),
      decoration: BoxDecoration(
        color: c[color.background],
        borderRadius: BorderRadius.circular(fullyRounded ? 999 : radius.value),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: fg),
        child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: child),
      ),
    );
  }
}
