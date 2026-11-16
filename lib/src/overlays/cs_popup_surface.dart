import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_anchored_overlay.dart';

/// The floating surface of popovers, tooltips and dropdowns: Cloudscape's
/// popover container (`color-background-popover`, a 2px
/// `color-border-popover` border, 8px radius, `shadow-popover`) and,
/// optionally, its arrow pointing at the anchor.
///
/// Pass the [placement] from [CsAnchoredOverlay.overlayBuilder] to draw
/// the arrow; without it the surface is a plain rounded panel.
///
/// ```dart
/// CsAnchoredOverlay(
///   open: open,
///   overlayBuilder: (context, placement) => CsPopupSurface(
///     placement: placement,
///     showArrow: true,
///     child: const CsText('Copied'),
///   ),
///   child: trigger,
/// )
/// ```
class CsPopupSurface extends StatelessWidget {
  const CsPopupSurface({
    super.key,
    required this.child,
    this.placement,
    this.showArrow = false,
    this.borderRadius = CsBorderRadius.popover,
    this.borderWidth = CsBorderWidth.popover,
    this.padding = const EdgeInsets.symmetric(horizontal: CsSpace.m, vertical: CsSpace.s),
    this.shadows,
    this.fill,
    this.outline,
    this.clip = true,
  });

  final Widget child;
  final CsPopupPlacement? placement;
  final bool showArrow;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  /// Defaults to the theme's `shadow-popover`.
  final List<BoxShadow>? shadows;

  /// Defaults to `color-background-popover`.
  final Color? fill;

  /// Defaults to `color-border-popover`.
  final Color? outline;

  /// Clip content to the rounded shape (off for content that paints its own
  /// overflow, such as nested menus).
  final bool clip;

  /// Height of the arrow, for overlays that need to add it to their offset.
  static const double arrowHeight = 10;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final radius = BorderRadius.circular(borderRadius);
    Widget content = Padding(padding: padding, child: child);
    if (clip) content = ClipRRect(borderRadius: radius, child: content);
    return CustomPaint(
      painter: _SurfacePainter(
        fill: fill ?? cs.colors.backgroundPopover,
        outline: outline ?? cs.colors.borderPopover,
        strokeWidth: borderWidth,
        radius: borderRadius,
        shadows: shadows ?? cs.shadows.popover,
        placement: showArrow ? placement : null,
      ),
      child: content,
    );
  }
}

class _SurfacePainter extends CustomPainter {
  _SurfacePainter({
    required this.fill,
    required this.outline,
    required this.strokeWidth,
    required this.radius,
    required this.shadows,
    required this.placement,
  }) : super(repaint: placement?.popupRect);

  final Color fill;
  final Color outline;
  final double strokeWidth;
  final double radius;
  final List<BoxShadow> shadows;
  final CsPopupPlacement? placement;

  Path _shape(Size size) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final p = placement;
    if (p == null) return body;
    final popup = p.popupRect.value;
    if (popup.isEmpty) return body;
    final along = p.arrowOffset(popup);
    // Cloudscape's arrow: a 20x10 triangle (a square rotated 45 degrees with
    // a 2px rounded tip), drawn pointing up at x = 0, then rotated onto the
    // anchor side. It overlaps the body by the border width so the border
    // runs around it.
    final arrow = Path()
      ..moveTo(-10, strokeWidth)
      ..lineTo(-1.4, -8.6)
      ..quadraticBezierTo(0, -10, 1.4, -8.6)
      ..lineTo(10, strokeWidth)
      ..close();
    final Matrix4 m;
    switch (p.side) {
      case CsSide.bottom:
        m = Matrix4.translationValues(along, 0, 0);
      case CsSide.top:
        m = Matrix4.translationValues(along, size.height, 0)..rotateZ(3.141592653589793);
      case CsSide.right:
        m = Matrix4.translationValues(0, along, 0)..rotateZ(-3.141592653589793 / 2);
      case CsSide.left:
        m = Matrix4.translationValues(size.width, along, 0)..rotateZ(3.141592653589793 / 2);
    }
    return Path.combine(PathOperation.union, body, arrow.transform(m.storage));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    for (final s in shadows) {
      final paint = Paint()
        ..color = s.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma);
      canvas.save();
      canvas.translate(s.offset.dx, s.offset.dy);
      if (s.spreadRadius != 0) {
        final grow = 1 + s.spreadRadius * 2 / size.shortestSide.clamp(1, double.infinity);
        canvas.translate(size.width / 2, size.height / 2);
        canvas.scale(grow, grow);
        canvas.translate(-size.width / 2, -size.height / 2);
      }
      canvas.drawPath(shape, paint);
      canvas.restore();
    }
    canvas.drawPath(shape, Paint()..color = fill);
    if (strokeWidth > 0) {
      // Inside stroke, like a CSS border: clip to the shape and draw double width.
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2
          ..color = outline,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.fill != fill ||
      old.outline != outline ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.shadows != shadows ||
      old.placement != placement;
}
