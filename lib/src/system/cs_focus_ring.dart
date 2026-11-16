import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Paints Cs's keyboard focus ring (`focus-visible:ring-2 ring-cs-brand`)
/// just outside a control's bounds, so it never shifts layout.
class CsFocusRingPainter extends CustomPainter {
  const CsFocusRingPainter({required this.borderRadius, required this.color, this.width = 2, this.offset = 0});

  final BorderRadius borderRadius;
  final Color color;
  final double width;

  /// Gap between the control edge and the ring.
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final inflate = offset + width / 2;
    final rect = (Offset.zero & size).inflate(inflate);
    final r = borderRadius.resolve(TextDirection.ltr);
    Radius grow(Radius radius) =>
        radius == Radius.zero ? Radius.zero : Radius.elliptical(radius.x + inflate, radius.y + inflate);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: grow(r.topLeft),
        topRight: grow(r.topRight),
        bottomLeft: grow(r.bottomLeft),
        bottomRight: grow(r.bottomRight),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(CsFocusRingPainter old) =>
      old.borderRadius != borderRadius || old.color != color || old.width != width || old.offset != offset;
}

/// Shows the focus ring around [child] while [visible]. For focusable
/// widgets not built on CsPressable, such as text inputs.
class CsFocusRing extends StatelessWidget {
  const CsFocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.color = CsColor.borderItemFocused,
    this.width = 2,
    this.offset = 0,
  });

  final bool visible;
  final Widget child;
  final BorderRadius borderRadius;
  final CsColor color;
  final double width;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return CustomPaint(
      foregroundPainter: CsFocusRingPainter(
        borderRadius: borderRadius,
        color: context.cs.color(color),
        width: width,
        offset: offset,
      ),
      child: child,
    );
  }
}
