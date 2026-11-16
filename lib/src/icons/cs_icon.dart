import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/cs_theme.dart';
import '../theme/generated/cs_colors.g.dart';
import 'cs_icon_data.dart';

/// Icon sizes (Cloudscape `size`). Each size has its own stroke width, so
/// small icons stay crisp and large ones do not look thin.
enum CsIconSize {
  /// 12px, 1.5px stroke. Inline with 12px text.
  xSmall(12, 16, 1.5, 0.75),

  /// 16px on a 16px line, 2px stroke.
  small(16, 16, 2, 1),

  /// 16px on a 20px line, 2px stroke. The default.
  normal(16, 20, 2, 1),

  /// 20px on a 24px line, 2px stroke.
  medium(20, 24, 2, 1.25),

  /// 32px on a 30px line, 3px stroke.
  big(32, 32, 3, 2),

  /// 48px on a 48px line, 4px stroke.
  large(48, 48, 4, 3);

  const CsIconSize(this.dimension, this.lineHeight, this.stroke, this.scaleFactor);

  /// Width and height of the glyph.
  final double dimension;

  /// Height of the line the icon sits on when [CsIcon.mapHeight] is set.
  final double lineHeight;

  /// Visual stroke width in logical pixels.
  final double stroke;

  /// Cloudscape scales the stroke down by this factor inside the 16-unit
  /// viewBox, which the glyph scaling cancels out.
  final double scaleFactor;
}

/// Icon color variants (Cloudscape `variant`). [normal] takes the color of
/// the surrounding text.
enum CsIconVariant {
  normal(null),
  disabled(CsColor.textInteractiveDisabled),
  inverted(CsColor.textInverted),
  subtle(CsColor.textIconSubtle),
  warning(CsColor.textStatusWarning),
  error(CsColor.textStatusError),
  success(CsColor.textStatusSuccess),
  link(CsColor.textLinkDefault),
  info(CsColor.textStatusInfo);

  const CsIconVariant(this.token);

  /// The color token, or null to inherit.
  final CsColor? token;
}

/// Cloudscape's `Icon`: one of the 148 built-in [CsIcons] (or any
/// [CsIconData]), outlined with the current text color.
///
/// ```dart
/// CsIcon(CsIcons.statusPositive, variant: CsIconVariant.success)
/// CsIcon(CsIcons.external, size: CsIconSize.small)
/// ```
///
/// Use [CsIcon.custom] for an image or any other widget in an icon slot.
class CsIcon extends StatelessWidget {
  const CsIcon(
    this.icon, {
    super.key,
    this.size = CsIconSize.normal,
    this.variant = CsIconVariant.normal,
    this.semanticLabel,
    this.badge = false,
    this.mapHeight = false,
    this.dangerouslySetColor,
  }) : custom = null;

  /// Wraps [child] (an image, a brand mark) so it sizes like an icon.
  const CsIcon.custom(
    Widget child, {
    super.key,
    this.size = CsIconSize.normal,
    this.semanticLabel,
    this.badge = false,
    this.mapHeight = false,
  }) : icon = null,
       custom = child,
       variant = CsIconVariant.normal,
       dangerouslySetColor = null;

  final CsIconData? icon;
  final Widget? custom;
  final CsIconSize size;
  final CsIconVariant variant;

  /// Accessible name. Without one the icon is decorative and hidden from
  /// screen readers, as Cloudscape does without `ariaLabel`.
  final String? semanticLabel;

  /// A small dot at the top end corner (`badge`), for unread notifications.
  final bool badge;

  /// Size the box to the icon's line height instead of its glyph, so it
  /// aligns with a line of text (Cloudscape's mapped height).
  final bool mapHeight;

  /// Raw color override. Prefer [variant]. Without either, the icon takes
  /// the surrounding text color (Cloudscape's `currentColor`), so it ignores
  /// Material's default icon theme.
  final Color? dangerouslySetColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color =
        dangerouslySetColor ??
        (variant.token != null
            ? cs.colors[variant.token!]
            : (DefaultTextStyle.of(context).style.color ?? IconTheme.of(context).color ?? cs.colors.textBodyDefault));
    final d = size.dimension;
    Widget glyph = custom != null
        ? SizedBox.square(
            dimension: d,
            child: FittedBox(child: custom),
          )
        : CustomPaint(
            size: Size.square(d),
            painter: CsIconPainter(
              icon: icon!,
              color: color,
              stroke: size.stroke,
              textDirection: Directionality.maybeOf(context),
            ),
          );
    if (badge) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          PositionedDirectional(
            top: 0,
            end: -3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: cs.colors.backgroundBadgeIcon, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      );
    }
    if (mapHeight && size.lineHeight != d) {
      glyph = SizedBox(
        width: d,
        height: size.lineHeight,
        child: Center(child: glyph),
      );
    }
    if (semanticLabel == null) return ExcludeSemantics(child: glyph);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

/// Paints a [CsIconData] at any size with a fixed visual stroke width.
class CsIconPainter extends CustomPainter {
  const CsIconPainter({required this.icon, required this.color, this.stroke = 2, this.textDirection});

  final CsIconData icon;
  final Color color;

  /// Stroke width in logical pixels at the painted size.
  final double stroke;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / icon.viewBox;
    canvas.save();
    if (icon.matchTextDirection && textDirection == TextDirection.rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.scale(scale);
    for (final part in icon.parts) {
      var path = CsIconData.pathOf(part);
      if (part.visible < 1) {
        final out = ui.Path();
        for (final m in path.computeMetrics()) {
          out.addPath(m.extractPath(0, m.length * part.visible), Offset.zero);
        }
        path = out;
      }
      if (part.clip != null) {
        canvas.save();
        final c = part.clip!;
        canvas.clipRect(Rect.fromLTRB(c[0], c[1], c[2], c[3]));
      }
      if (part.filled) {
        canvas.drawPath(path, Paint()..color = color);
      }
      if (part.stroked) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color
            ..strokeWidth = stroke / scale
            ..strokeJoin = part.roundJoin ? StrokeJoin.round : StrokeJoin.miter
            ..strokeCap = switch (part.cap) {
              CsIconCap.round => StrokeCap.round,
              CsIconCap.square => StrokeCap.square,
              CsIconCap.butt => StrokeCap.butt,
            },
        );
      }
      if (part.clip != null) canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CsIconPainter old) =>
      old.icon != icon || old.color != color || old.stroke != stroke || old.textDirection != textDirection;
}
