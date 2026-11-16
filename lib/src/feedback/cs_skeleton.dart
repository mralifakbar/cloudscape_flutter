import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_swap.dart';

/// Skeleton heights (Cloudscape `variant`), matching the line height of a
/// [CsTypeScale] step. [dynamic] follows the surrounding text style.
enum CsSkeletonVariant {
  /// Matches the font size and line height of the surrounding text.
  dynamic(null),
  textBodyS(CsTypeScale.bodyS),
  textBodyM(CsTypeScale.bodyM),
  textHeadingXs(CsTypeScale.headingXs),
  textHeadingS(CsTypeScale.headingS),
  textHeadingM(CsTypeScale.headingM),
  textHeadingL(CsTypeScale.headingL),
  textHeadingXl(CsTypeScale.headingXl),
  textDisplayL(CsTypeScale.displayL);

  const CsSkeletonVariant(this.scale);

  /// The type step this variant mirrors, or null for [dynamic].
  final CsTypeScale? scale;
}

/// Cloudscape's `Skeleton`: a placeholder shaped like the content that is
/// loading, so the layout does not jump when it arrives.
///
/// A text skeleton is one line tall (the line height of [variant]) with a
/// bar the height of the font inside it, like a line of text. Give it an
/// explicit [height] for blocks such as charts or images.
///
/// ```dart
/// const CsSkeleton(variant: CsSkeletonVariant.textHeadingM, width: 180)
/// const CsSkeleton(height: 120)
///
/// // Show the skeleton while loading, then cross-fade to the content:
/// CsSkeleton(loading: _loading, child: InstanceSummary(instance))
/// ```
///
/// A soft wave crosses the bar every 1.25s while it is on screen. The wave
/// stops when the skeleton leaves the screen or is replaced by [child], and
/// is off under reduced motion, where the bar stays still. Skeletons are
/// hidden from screen readers; announce loading with the surrounding
/// component's loading text or a `CsLiveRegion`.
class CsSkeleton extends StatelessWidget {
  const CsSkeleton({
    super.key,
    this.variant = CsSkeletonVariant.dynamic,
    this.width,
    this.height,
    this.loading = true,
    this.child,
  });

  /// Which text step the skeleton matches. Ignored when [height] is set.
  final CsSkeletonVariant variant;

  /// Width of the bar. Defaults to the available width (Cloudscape's
  /// `inline-size: 100%`), or 160 where the width is unbounded, as in a
  /// [Row].
  final double? width;

  /// Height of the bar, for block placeholders. Defaults to the font size of
  /// [variant] inside a box one line tall.
  final double? height;

  /// While true the skeleton shows; when it turns false the skeleton
  /// cross-fades to [child]. Only meaningful with a [child].
  final bool loading;

  /// The content the skeleton stands in for.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bone = _SkeletonBone(variant: variant, width: width, height: height);
    final content = child;
    if (content == null) return bone;
    return CsSwap(
      alignment: AlignmentDirectional.topStart,
      animateSize: true,
      child: loading
          ? KeyedSubtree(key: const ValueKey('cs-skeleton'), child: bone)
          : KeyedSubtree(key: const ValueKey('cs-skeleton-content'), child: content),
    );
  }
}

/// Several text skeleton lines, the last one shorter, as a placeholder for
/// a paragraph.
///
/// ```dart
/// const CsSkeletonLines(lines: 3)
/// ```
class CsSkeletonLines extends StatelessWidget {
  const CsSkeletonLines({
    super.key,
    this.lines = 3,
    this.variant = CsSkeletonVariant.textBodyM,
    this.lastLineWidthFactor = 0.6,
    this.spacing = 0,
  });

  final int lines;
  final CsSkeletonVariant variant;

  /// Width of the last line as a share of the available width.
  final double lastLineWidthFactor;

  /// Extra gap between lines. Lines already sit one line height apart.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.hasBoundedWidth ? constraints.maxWidth : 240.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: [
            for (var i = 0; i < lines; i++)
              CsSkeleton(
                variant: variant,
                width: i == lines - 1 && lines > 1 ? full * lastLineWidthFactor.clamp(0.0, 1.0) : full,
              ),
          ],
        );
      },
    );
  }
}

class _SkeletonBone extends StatefulWidget {
  const _SkeletonBone({required this.variant, this.width, this.height});

  final CsSkeletonVariant variant;
  final double? width;
  final double? height;

  @override
  State<_SkeletonBone> createState() => _SkeletonBoneState();
}

class _SkeletonBoneState extends State<_SkeletonBone> with SingleTickerProviderStateMixin {
  // styles.scss: $skeleton-wave-duration 1.25s, ease-in-out, infinite.
  static const Duration _waveDuration = Duration(milliseconds: 1250);
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: _waveDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CsMotion.reduceMotion(context)) {
      _wave.stop();
      _wave.value = 0;
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final scale = widget.variant.scale;
    final ambient = DefaultTextStyle.of(context).style;
    final fontSize = scale?.fontSize ?? ambient.fontSize ?? CsTypeScale.bodyM.fontSize;
    final lineHeight = scale?.lineHeight ?? (ambient.height != null ? ambient.height! * fontSize : fontSize * 1.43);
    final barHeight = widget.height ?? fontSize;
    final boxHeight = widget.height ?? math.max(lineHeight, fontSize);
    final reduce = CsMotion.reduceMotion(context);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;

    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = widget.width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 160.0);
          return SizedBox(
            width: width,
            height: boxHeight,
            child: Center(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(width, barHeight),
                  painter: _BonePainter(
                    wave: _wave,
                    animate: !reduce,
                    rtl: rtl,
                    fill: cs.colors.backgroundSkeleton,
                    waveColor: cs.colors.backgroundSkeletonWave,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BonePainter extends CustomPainter {
  _BonePainter({
    required this.wave,
    required this.animate,
    required this.rtl,
    required this.fill,
    required this.waveColor,
  }) : super(repaint: wave);

  final Animation<double> wave;
  final bool animate;
  final bool rtl;
  final Color fill;
  final Color waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final radius = math.min(CsBorderRadius.skeleton, size.height / 2);
    final shape = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(shape, Paint()..color = fill);
    if (!animate) return;
    final t = Curves.easeInOut.transform(wave.value);
    // translateX(-100%) to translateX(100%), mirrored in RTL.
    final dx = (rtl ? 1 - 2 * t : -1 + 2 * t) * size.width;
    final rect = Rect.fromLTWH(dx, 0, size.width, size.height);
    final transparent = waveColor.withValues(alpha: 0);
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: [transparent, waveColor, transparent]).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BonePainter old) =>
      old.animate != animate || old.rtl != rtl || old.fill != fill || old.waveColor != waveColor;
}
