import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Badge colors (Cloudscape `color`). The severity colors follow the
/// severity scale of security findings and incident tickets.
enum CsBadgeColor {
  blue,
  grey,
  green,
  red,
  severityCritical,
  severityHigh,
  severityMedium,
  severityLow,
  severityNeutral,
}

/// Style overrides for [CsBadge] (Cloudscape `style.root`). Every field is
/// optional; unset fields keep the token values of the badge's color.
@immutable
class CsBadgeStyle {
  const CsBadgeStyle({
    this.background,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.color,
    this.paddingBlock,
    this.paddingInline,
  });

  final Color? background;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  /// Text color.
  final Color? color;
  final double? paddingBlock;
  final double? paddingInline;

  @override
  bool operator ==(Object other) =>
      other is CsBadgeStyle &&
      other.background == background &&
      other.borderColor == borderColor &&
      other.borderRadius == borderRadius &&
      other.borderWidth == borderWidth &&
      other.color == color &&
      other.paddingBlock == paddingBlock &&
      other.paddingInline == paddingInline;

  @override
  int get hashCode =>
      Object.hash(background, borderColor, borderRadius, borderWidth, color, paddingBlock, paddingInline);
}

/// Cloudscape's `Badge`: a small colored label for a count, a category or a
/// severity, such as "New", "3" or "Critical".
///
/// ```dart
/// const CsBadge(text: 'New', color: CsBadgeColor.blue)
/// const CsBadge(text: 'Critical', color: CsBadgeColor.severityCritical)
/// ```
///
/// Body-s text on a 20px line, 8px side padding, 4px radius. A badge is not
/// interactive. Pair a color with words: never rely on the color alone.
class CsBadge extends StatelessWidget {
  const CsBadge({super.key, this.text, this.child, this.color = CsBadgeColor.grey, this.style, this.semanticLabel})
    : assert(text != null || child != null, 'Pass text or child');

  /// Text displayed inside the badge.
  final String? text;

  /// Custom content in place of [text], such as a number with an icon.
  final Widget? child;

  /// Defaults to grey, like Cloudscape.
  final CsBadgeColor color;

  /// Per-instance overrides of the badge's colors, radius and padding.
  final CsBadgeStyle? style;

  /// Read by screen readers instead of [text], for example "3 unread".
  final String? semanticLabel;

  /// Background, border and text colors of [color] from the badge tokens.
  static (Color background, Color border, Color text) colorsFor(CsColorScheme c, CsBadgeColor color) => switch (color) {
    CsBadgeColor.grey => (c.backgroundBadgeGrey, c.borderBadgeGrey, c.textBadgeGrey),
    CsBadgeColor.green => (c.backgroundBadgeGreen, c.borderBadgeGreen, c.textBadgeGreen),
    CsBadgeColor.blue => (c.backgroundBadgeBlue, c.borderBadgeBlue, c.textBadgeBlue),
    CsBadgeColor.red => (c.backgroundBadgeRed, c.borderBadgeRed, c.textBadgeRed),
    CsBadgeColor.severityCritical => (
      c.backgroundNotificationSeverityCritical,
      c.borderBadgeSeverityCritical,
      c.textBadgeSeverityCritical,
    ),
    CsBadgeColor.severityHigh => (
      c.backgroundNotificationSeverityHigh,
      c.borderBadgeSeverityHigh,
      c.textBadgeSeverityHigh,
    ),
    CsBadgeColor.severityMedium => (
      c.backgroundNotificationSeverityMedium,
      c.borderBadgeSeverityMedium,
      c.textBadgeSeverityMedium,
    ),
    CsBadgeColor.severityLow => (c.backgroundNotificationSeverityLow, c.borderBadgeSeverityLow, c.textBadgeSeverityLow),
    CsBadgeColor.severityNeutral => (
      c.backgroundNotificationSeverityNeutral,
      c.borderBadgeSeverityNeutral,
      c.textBadgeSeverityNeutral,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final (bg, border, fg) = colorsFor(cs.colors, color);
    final s = style;
    final radius = BorderRadius.circular(s?.borderRadius ?? CsBorderRadius.badge);
    final borderWidth = s?.borderWidth ?? CsBorderWidth.badge;
    // `.badge`: font-body-s with the body-m line height.
    final textStyle = cs
        .text(CsTypeScale.bodyS, color: CsColor.textNotificationDefault)
        .copyWith(height: CsTypeScale.bodyM.lineHeight / CsTypeScale.bodyS.fontSize, color: s?.color ?? fg);
    Widget content = DefaultTextStyle(
      style: textStyle,
      softWrap: true,
      child: IconTheme.merge(
        data: IconThemeData(color: s?.color ?? fg, size: 12),
        child: child ?? Text(text!),
      ),
    );
    if (semanticLabel != null) {
      content = Semantics(label: semanticLabel, excludeSemantics: true, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: s?.background ?? bg, borderRadius: radius),
      position: DecorationPosition.background,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: borderWidth > 0
              ? Border.all(
                  color: s?.borderColor ?? border,
                  width: borderWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: (s?.paddingInline ?? CsSpace.xs) + borderWidth,
            vertical: (s?.paddingBlock ?? 0) + borderWidth,
          ),
          child: content,
        ),
      ),
    );
  }
}
