import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Spinner sizes.
enum CsSpinnerSize {
  /// 16px, inline with body text and inside buttons.
  normal(16, 2),

  /// 32px.
  big(32, 3),

  /// 48px, for a whole region that is loading.
  large(48, 4);

  const CsSpinnerSize(this.dimension, this.stroke);
  final double dimension;
  final double stroke;
}

/// Spinner colors.
enum CsSpinnerVariant {
  /// Takes the current text color.
  normal,

  /// `color-text-interactive-disabled`.
  disabled,

  /// `color-text-inverted`, on dark or colored backgrounds.
  inverted,
}

/// Cloudscape's `Spinner`: shows that a short, unknown amount of work is in
/// progress. The ring turns every 0.7s while its two halves grow and shrink.
///
/// ```dart
/// const CsSpinner()
/// const CsSpinner(size: CsSpinnerSize.large)
/// ```
///
/// Cloudscape keeps the spinner moving even with motion disabled, because a
/// still spinner reads as stuck; here the halves stop pulsing under reduced
/// motion and only the slow rotation remains. It stops when it leaves the
/// screen.
class CsSpinner extends StatefulWidget {
  const CsSpinner({
    super.key,
    this.size = CsSpinnerSize.normal,
    this.variant = CsSpinnerVariant.normal,
    this.semanticLabel,
    this.dangerouslySetColor,
  });

  final CsSpinnerSize size;
  final CsSpinnerVariant variant;

  /// Announced to screen readers. Defaults to [CsStrings.loading]; pass an
  /// empty string when surrounding text already says what is loading.
  final String? semanticLabel;
  final Color? dangerouslySetColor;

  @override
  State<CsSpinner> createState() => _CsSpinnerState();
}

class _CsSpinnerState extends State<CsSpinner> with TickerProviderStateMixin {
  late final AnimationController _rotate;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _rotate = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CsMotion.reduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _rotate.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color =
        widget.dangerouslySetColor ??
        switch (widget.variant) {
          CsSpinnerVariant.disabled => cs.colors.textInteractiveDisabled,
          CsSpinnerVariant.inverted => cs.colors.textInverted,
          CsSpinnerVariant.normal => DefaultTextStyle.of(context).style.color ?? cs.colors.textBodyDefault,
        };
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final label = widget.semanticLabel ?? context.csStrings.loading;
    final spinner = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size.dimension),
        painter: _SpinnerPainter(
          rotation: _rotate,
          pulse: _pulse,
          color: color,
          stroke: widget.size.stroke,
          rtl: rtl,
        ),
      ),
    );
    if (label.isEmpty) return ExcludeSemantics(child: spinner);
    return Semantics(label: label, liveRegion: true, child: ExcludeSemantics(child: spinner));
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.rotation,
    required this.pulse,
    required this.color,
    required this.stroke,
    required this.rtl,
  }) : super(repaint: Listenable.merge([rotation, pulse]));

  final Animation<double> rotation;
  final Animation<double> pulse;
  final Color color;
  final double stroke;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // Each half shows a quarter-circle border that swings between 0 and
    // 120 degrees (left) and 90 and -30 degrees (right) on an ease-in-out
    // 1.5s cycle, inside a ring turning once per 0.7s.
    final t = Curves.easeInOut.transform(pulse.value < 0.5 ? pulse.value * 2 : 2 - pulse.value * 2);
    final dir = rtl ? -1.0 : 1.0;
    final turn = rotation.value * 2 * math.pi * dir;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = color;
    final leftAngle = (0 + 120 * t) * math.pi / 180 * dir;
    final rightAngle = (90 - 120 * t) * math.pi / 180 * dir;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(turn);
    canvas.translate(-size.width / 2, -size.height / 2);
    // Left half: clip to the left side, draw a half arc rotated by leftAngle.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    _half(canvas, size, rect, paint, leftAngle);
    canvas.restore();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
    _half(canvas, size, rect, paint, rightAngle);
    canvas.restore();
    canvas.restore();
  }

  void _half(Canvas canvas, Size size, Rect rect, Paint paint, double angle) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);
    // The CSS circle has its top and start borders colored: a half circle
    // from the bottom-left corner over the top to the top-right corner.
    canvas.drawArc(rect, math.pi * 0.75, math.pi, false, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color || old.stroke != stroke || old.rtl != rtl;
}
