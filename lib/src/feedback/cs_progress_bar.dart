import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../status/cs_status_indicator.dart';
import '../theme/theme.dart';
import 'cs_live_region.dart';
import 'cs_swap.dart';

/// Progress bar states (Cloudscape `status`).
enum CsProgressBarStatus {
  /// Shows the bar and percentage.
  inProgress,

  /// Replaces the bar with a success status, [CsProgressBar.resultText] and
  /// the optional result button.
  success,

  /// Replaces the bar with an error status, [CsProgressBar.resultText] and
  /// the optional result button.
  error,
}

/// Where the progress bar sits (Cloudscape `variant`).
enum CsProgressBarVariant {
  /// On a page or in a container. The default.
  standalone,

  /// Inside a flash message: text takes the flash color, the label is bold
  /// and the result button is not shown (use the flash's action instead).
  flash,

  /// As the value of a key-value pair: the label is styled as a key label.
  keyValue,
}

/// Cloudscape's `ProgressBar`: how far an operation of known length has got,
/// with a label, a percentage and, when it ends, a success or error result.
///
/// ```dart
/// CsProgressBar(
///   label: 'Creating snapshot',
///   description: 'vol-0abc123',
///   value: 42,
///   additionalInfo: 'About 3 minutes remaining',
/// )
///
/// CsProgressBar(
///   label: 'Creating snapshot',
///   status: CsProgressBarStatus.error,
///   resultText: 'Snapshot failed',
///   resultButtonText: 'Retry',
///   onResultButtonPress: retry,
/// )
/// ```
///
/// The bar moves to each new [value] over Cloudscape's 135ms
/// `motion-duration-moderate` (instantly under reduced motion), and the
/// result state fades in. Screen readers hear "label: 42%" at most every 5
/// seconds while the value changes, and the result text when the status
/// changes.
class CsProgressBar extends StatelessWidget {
  const CsProgressBar({
    super.key,
    this.value = 0,
    this.status = CsProgressBarStatus.inProgress,
    this.variant = CsProgressBarVariant.standalone,
    this.label,
    this.labelWidget,
    this.description,
    this.descriptionWidget,
    this.additionalInfo,
    this.additionalInfoWidget,
    this.resultText,
    this.resultWidget,
    this.resultButtonText,
    this.onResultButtonPress,
    this.semanticLabel,
  });

  /// Progress in percent, from 0 to 100. Rounded for display.
  final double value;
  final CsProgressBarStatus status;
  final CsProgressBarVariant variant;

  /// Short name of the operation, shown above the bar. Always provide one
  /// (or [semanticLabel]) for screen readers.
  final String? label;

  /// Rich content in place of [label].
  final Widget? labelWidget;

  /// More detail about the operation, below the label in small text.
  final String? description;
  final Widget? descriptionWidget;

  /// Shown below the bar or result, in small text.
  final String? additionalInfo;
  final Widget? additionalInfoWidget;

  /// Shown next to the status icon when [status] is success or error.
  final String? resultText;
  final Widget? resultWidget;

  /// Label of a button shown after the result text. Not shown when empty
  /// or in the [CsProgressBarVariant.flash] variant.
  final String? resultButtonText;

  /// Called when the result button is pressed (Cloudscape
  /// `onResultButtonClick`).
  final VoidCallback? onResultButtonPress;

  /// Accessible name of the bar (Cloudscape `ariaLabel`). Defaults to
  /// [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final inFlash = variant == CsProgressBarVariant.flash;
    final base = DefaultTextStyle.of(context).style;
    final rounded = value.clamp(0, 100).round();

    final labelStyle = switch (variant) {
      CsProgressBarVariant.standalone => cs.text(CsTypeScale.bodyM),
      CsProgressBarVariant.flash => base.copyWith(fontWeight: CsTypography.bold),
      CsProgressBarVariant.keyValue => cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textLabel),
    };
    final smallStyle = inFlash
        ? cs.text(CsTypeScale.bodyS).copyWith(color: base.color)
        : cs.text(CsTypeScale.bodyS, color: CsColor.textSmall);

    Widget? labelSlot = labelWidget ?? (label != null ? Text(label!) : null);
    if (labelSlot != null) {
      labelSlot = DefaultTextStyle(style: labelStyle, child: labelSlot);
      if (variant == CsProgressBarVariant.keyValue) {
        labelSlot = Padding(
          padding: EdgeInsets.only(bottom: cs.space.scaledXxxs),
          child: labelSlot,
        );
      }
    }
    final descriptionSlot = descriptionWidget ?? (description != null ? Text(description!) : null);
    final infoSlot = additionalInfoWidget ?? (additionalInfo != null ? Text(additionalInfo!) : null);

    final inProgress = status == CsProgressBarStatus.inProgress;
    final Widget body = inProgress
        ? KeyedSubtree(
            key: const ValueKey('cs-progress'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressTrack(value: rounded, inFlash: inFlash, semanticLabel: semanticLabel ?? label),
                CsLiveRegion(
                  hidden: true,
                  delay: const Duration(seconds: 5),
                  message: [?(semanticLabel ?? label), '$rounded%'].join(': '),
                ),
              ],
            ),
          )
        : KeyedSubtree(
            key: ValueKey('cs-progress-${status.name}'),
            child: CsLiveRegion(
              delay: Duration.zero,
              child: _ResultState(
                status: status,
                inFlash: inFlash,
                result: resultWidget ?? (resultText != null ? Text(resultText!) : null),
                buttonText: resultButtonText,
                onButtonPress: onResultButtonPress,
              ),
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?labelSlot,
        if (descriptionSlot != null) DefaultTextStyle(style: smallStyle, child: descriptionSlot),
        CsSwap(duration: CsDurations.showPaced, alignment: AlignmentDirectional.topStart, child: body),
        if (infoSlot != null) DefaultTextStyle(style: smallStyle, child: infoSlot),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.value, required this.inFlash, this.semanticLabel});

  final int value;
  final bool inFlash;
  final String? semanticLabel;

  // styles.scss: block-size 0.4 * $base-size (4px), border-radius 10px,
  // percentage column 3.3 * $base-size (33px), max-inline-size 800px.
  static const double _barHeight = 4;
  static const double _barRadius = 10;
  static const double _percentWidth = 33;
  static const double _maxWidth = 800;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final track = inFlash ? c.backgroundProgressBarFlash : c.backgroundProgressBarDefault;
    final fill = inFlash ? c.backgroundProgressBarValueFlash : c.backgroundProgressBarValueDefault;
    final percentStyle = inFlash
        ? cs.text(CsTypeScale.bodyS).copyWith(color: DefaultTextStyle.of(context).style.color)
        : cs.text(CsTypeScale.bodyS, color: CsColor.textSmall);
    final complete = value >= 100;

    return Semantics(
      label: semanticLabel,
      value: '$value%',
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth, minHeight: CsFontTokens.lineHeightBodyM),
          child: Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value / 100),
                  duration: CsMotion.duration(context, CsDurations.moderate),
                  curve: Curves.linear,
                  builder: (context, fraction, _) => CustomPaint(
                    size: const Size(double.infinity, _barHeight),
                    painter: _TrackPainter(fraction: fraction, track: track, fill: fill, complete: complete),
                  ),
                ),
              ),
              const SizedBox(width: CsSpace.s),
              SizedBox(
                width: _percentWidth,
                child: ExcludeSemantics(
                  child: Text('$value%', style: percentStyle, textAlign: TextAlign.end, softWrap: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.fraction, required this.track, required this.fill, required this.complete});

  final double fraction;
  final Color track;
  final Color fill;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Radius.circular(_ProgressTrack._barRadius);
    final y = (size.height - _ProgressTrack._barHeight) / 2;
    final bar = Rect.fromLTWH(0, y, size.width, _ProgressTrack._barHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, r), Paint()..color = track);
    final w = size.width * fraction.clamp(0.0, 1.0);
    if (w <= 0) return;
    // The value keeps square trailing corners until the bar is full.
    final valueRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, y, w, _ProgressTrack._barHeight),
      topLeft: r,
      bottomLeft: r,
      topRight: complete ? r : Radius.zero,
      bottomRight: complete ? r : Radius.zero,
    );
    canvas.drawRRect(valueRect, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill || old.complete != complete;
}

class _ResultState extends StatelessWidget {
  const _ResultState({
    required this.status,
    required this.inFlash,
    required this.result,
    required this.buttonText,
    required this.onButtonPress,
  });

  final CsProgressBarStatus status;
  final bool inFlash;
  final Widget? result;
  final String? buttonText;
  final VoidCallback? onButtonPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final content = result ?? const SizedBox.shrink();
    if (inFlash) return Align(alignment: AlignmentDirectional.centerStart, child: content);
    final hasButton = buttonText != null && buttonText!.isNotEmpty;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(end: hasButton ? CsSpace.m : 0),
          child: CsStatusIndicator(
            type: status == CsProgressBarStatus.success ? CsStatusType.success : CsStatusType.error,
            child: content,
          ),
        ),
        if (hasButton)
          Padding(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
            child: CsButton(text: buttonText, onPress: onButtonPress),
          ),
      ],
    );
  }
}
