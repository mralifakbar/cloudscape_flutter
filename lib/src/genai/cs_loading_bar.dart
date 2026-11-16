import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_gen_ai_gradients.dart';

/// Loading bar variants (Cloudscape `LoadingBarProps.Variant`).
enum CsLoadingBarVariant {
  /// A full-width 2px gradient bar for an ongoing generative AI process.
  genAi,

  /// The same bar faded out at both ends, for the edge of an element with
  /// rounded corners (the bottom of a chat bubble or a prompt input).
  genAiMasked,
}

/// Cloudscape's gen-AI `LoadingBar`: a 2px animated gradient that signals a
/// generative AI process is running.
///
/// The gradient (`colorBackgroundLoadingBarGenAi`) slides along the bar in a
/// 3 second loop. The loop exists only while the bar is mounted, so show the
/// bar while the response streams and remove it afterwards. Under reduced
/// motion the bar is a static gradient.
///
/// ```dart
/// if (generating) const CsLoadingBar(variant: CsLoadingBarVariant.genAi)
/// ```
class CsLoadingBar extends StatefulWidget {
  const CsLoadingBar({super.key, this.variant = CsLoadingBarVariant.genAi, this.semanticLabel});

  final CsLoadingBarVariant variant;

  /// Optional accessible name. Cloudscape's bar is decorative; pair it with
  /// an avatar in its loading state or a live announcement instead.
  final String? semanticLabel;

  /// Height of the bar (`block-size: 2px` in the loading bar SCSS).
  static const double height = 2;

  @override
  State<CsLoadingBar> createState() => _CsLoadingBarState();
}

class _CsLoadingBarState extends State<CsLoadingBar> with TickerProviderStateMixin {
  // `searchbar 3s cubic-bezier(0, 0.08, 1, 0.82) infinite` in the SCSS.
  static const Duration _period = Duration(seconds: 3);
  static const Curve _curve = Cubic(0, 0.08, 1, 0.82);

  late final AnimationController _slide;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: _period);
    _fade = AnimationController(vsync: this, duration: CsDurations.complex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (CsMotion.reduceMotion(context)) {
      _slide
        ..stop()
        ..value = 0;
      _fade.value = 1;
    } else {
      if (!_slide.isAnimating) _slide.repeat();
      if (_fade.value < 1 && !_fade.isAnimating) _fade.forward();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget bar = AnimatedBuilder(
      animation: Listenable.merge([_slide, _fade]),
      builder: (context, _) => Opacity(
        opacity: CsCurves.expressive.transform(_fade.value),
        child: CustomPaint(
          size: const Size(double.infinity, CsLoadingBar.height),
          painter: _GradientBarPainter(progress: _curve.transform(_slide.value), reverse: rtl),
        ),
      ),
    );
    if (widget.variant == CsLoadingBarVariant.genAiMasked) {
      bar = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: CsGenAiGradients.loadingBarMask.createShader,
        child: bar,
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      container: widget.semanticLabel != null,
      child: SizedBox(height: CsLoadingBar.height, width: double.infinity, child: bar),
    );
  }
}

class _GradientBarPainter extends CustomPainter {
  const _GradientBarPainter({required this.progress, required this.reverse});

  final double progress;
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // `background-size: 200% 100%`, moved from 0 to -200%: the gradient tile
    // is twice the bar's width and travels one full tile per loop.
    final tile = size.width * 2;
    final shift = (reverse ? -progress : progress) * tile;
    final shader = LinearGradient(
      colors: CsGenAiGradients.loadingBar.colors,
      stops: CsGenAiGradients.loadingBar.stops,
      tileMode: TileMode.repeated,
    ).createShader(Rect.fromLTWH(shift - tile, 0, tile, size.height));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GradientBarPainter old) => old.progress != progress || old.reverse != reverse;
}
