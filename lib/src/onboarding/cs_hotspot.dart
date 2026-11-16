import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_annotation_context.dart';

/// Which side of its child a [CsHotspot] marker sits on.
enum CsHotspotSide { left, right }

/// Cloudscape's `Hotspot`: a marked place in the app that a tutorial step
/// points to. Outside a running tutorial it renders only its child.
///
/// ```dart
/// CsHotspot(
///   hotspotId: 'create-bucket-button',
///   child: CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: create),
/// )
/// ```
///
/// While a tutorial that uses [hotspotId] runs (see [CsAnnotationContext]),
/// a small circled plus appears next to the child. The current step's
/// marker opens the annotation popover: the task title, the step content,
/// a step counter and Previous, Next and Finish buttons. Pressing the
/// marker of another step jumps to it; pressing the open marker (or the
/// popover's close button, or Escape) dismisses the popover.
class CsHotspot extends StatefulWidget {
  const CsHotspot({
    super.key,
    required this.hotspotId,
    this.child,
    this.side = CsHotspotSide.right,
    this.direction = CsSide.top,
  });

  /// Unique ID of this place in the app, used by [CsTutorialStep.hotspotId].
  final String hotspotId;

  /// The element the hotspot marks. Without a child the marker is inline,
  /// for example inside a checkbox label.
  final Widget? child;

  /// Side of the child the marker sits on.
  final CsHotspotSide side;

  /// Side of the marker the annotation popover opens on. It flips when
  /// there is not enough room.
  final CsSide direction;

  @override
  State<CsHotspot> createState() => _CsHotspotState();
}

class _CsHotspotState extends State<CsHotspot> with SingleTickerProviderStateMixin {
  CsAnnotationContextData? _data;
  String? _registeredId;
  late final AnimationController _pulse;
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'CsHotspot');
  bool _wasOpen = false;
  int? _pulsedForStep;

  /// The pulse plays a few times each time this marker becomes the current
  /// step, then rests: it leads the eye without looping forever.
  static const int _pulseCount = 3;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: CsDurations.refreshOnlyAmbient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = CsAnnotationContext.maybeOf(context);
    if (!identical(data?.registerHotspot, _data?.registerHotspot) || _registeredId != widget.hotspotId) {
      _unregister();
      _data = data;
      _register();
    } else {
      _data = data;
    }
  }

  @override
  void didUpdateWidget(CsHotspot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotspotId != widget.hotspotId) {
      _unregister();
      _register();
    }
  }

  void _register() {
    final data = _data;
    if (data == null) return;
    data.registerHotspot(widget.hotspotId);
    _registeredId = widget.hotspotId;
  }

  void _unregister() {
    final id = _registeredId;
    if (id != null) _data?.unregisterHotspot(id);
    _registeredId = null;
  }

  @override
  void dispose() {
    _unregister();
    _pulse.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  void _afterBuild(CsHotspotSlot? slot) {
    final data = _data;
    final open = slot?.open ?? false;
    final current = slot?.current ?? false;
    final reduce = CsMotion.reduceMotion(context);
    if (current && data != null && data.pulseHotspots && !reduce) {
      if (_pulsedForStep != data.currentStepIndex) {
        _pulsedForStep = data.currentStepIndex;
        _pulse
          ..reset()
          ..repeat(count: _pulseCount);
      }
    } else {
      _pulsedForStep = current ? data?.currentStepIndex : null;
      if (_pulse.isAnimating) _pulse.stop();
      if (_pulse.value != 0) _pulse.value = 0;
    }
    if (open && !_wasOpen) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: CsMotion.duration(context, CsDurations.complex),
        curve: CsCurves.expressive,
      );
    } else if (!open && _wasOpen && current && _triggerFocus.canRequestFocus) {
      // Dismissed: focus returns to the marker, like Cloudscape's
      // `focusOnRender` on the closed annotation.
      _triggerFocus.requestFocus();
    }
    _wasOpen = open;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final slot = data?.slotFor(widget.hotspotId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _afterBuild(slot);
    });

    Widget? marker;
    if (data != null && slot != null) {
      final s = data.i18nStrings;
      final trigger = _HotspotTrigger(
        open: slot.open,
        focusNode: _triggerFocus,
        pulse: _pulse,
        label: s.labelHotspot(slot.open, slot.taskLocalStepIndex, slot.totalLocalSteps),
        onPress: slot.open ? data.dismiss : () => data.openStep(slot.globalStepIndex),
      );
      marker = CsAnchoredOverlay(
        open: slot.open,
        side: widget.direction,
        align: CsAlign.center,
        sideOffset: 4 + CsPopupSurface.arrowHeight,
        preferredExtent: 220,
        dismissOnOutsideTap: false,
        onDismiss: data.dismiss,
        overlayBuilder: (context, placement) => _AnnotationPopover(slot: slot, data: data, placement: placement),
        child: trigger,
      );
    }

    final child = widget.child;
    if (child == null) {
      if (marker == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.xxs),
        child: marker,
      );
    }
    if (marker == null) return child;
    const gap = SizedBox(width: CsSpace.xxs);
    final children = widget.side == CsHotspotSide.right
        ? [Flexible(child: child), gap, marker]
        : [marker, gap, Flexible(child: child)];
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _HotspotTrigger extends StatelessWidget {
  const _HotspotTrigger({
    required this.open,
    required this.focusNode,
    required this.pulse,
    required this.label,
    required this.onPress,
  });

  final bool open;
  final FocusNode focusNode;
  final Animation<double> pulse;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return CsPressable(
      onPress: onPress,
      focusNode: focusNode,
      semanticLabel: label,
      expanded: open,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlCircularFocusRing + 8),
      focusRingOffset: 2,
      builder: (context, state) {
        final color = state.hovered && !state.pressed
            ? cs.colors.textTutorialHotspotHover
            : cs.colors.textTutorialHotspotDefault;
        // `.hotspot::before` extends the click target by space-xxs on every side.
        return Padding(
          padding: const EdgeInsets.all(CsSpace.xxs),
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) => CustomPaint(
              size: const Size.square(16),
              painter: _HotspotIconPainter(open: open, color: color, pulse: pulse.value),
            ),
          ),
        );
      },
    );
  }
}

/// Cloudscape's annotation icon: a 14px circle with a 2px stroke holding a
/// plus (closed) or a minus (open), and an expanding ring while it pulses.
class _HotspotIconPainter extends CustomPainter {
  const _HotspotIconPainter({required this.open, required this.color, required this.pulse});

  final bool open;
  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(8, 8);
    if (pulse > 0 && pulse < 1) {
      final t = Curves.easeOut.transform(pulse);
      canvas.drawCircle(
        center,
        7 + 7 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: color.a * (1 - t) * 0.6),
      );
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawCircle(center, 7, stroke);
    final bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square
      ..color = color;
    canvas.drawLine(const Offset(6, 8), const Offset(10, 8), bar);
    if (!open) canvas.drawLine(const Offset(8, 6), const Offset(8, 10), bar);
  }

  @override
  bool shouldRepaint(_HotspotIconPainter old) => old.open != open || old.color != color || old.pulse != pulse;
}

class _AnnotationPopover extends StatelessWidget {
  const _AnnotationPopover({required this.slot, required this.data, required this.placement});

  final CsHotspotSlot slot;
  final CsAnnotationContextData data;
  final CsPopupPlacement placement;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = data.i18nStrings;
    final small = cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary);
    final counter = s.stepCounterText(slot.taskLocalStepIndex, slot.totalLocalSteps);
    final width = placement.maxWidth < 310 ? placement.maxWidth : 310.0;
    return ConstrainedBox(
      // `size="medium"`, not fixed width: at most 310px.
      constraints: BoxConstraints(maxWidth: width, maxHeight: placement.maxHeight),
      child: CsPopupSurface(
        placement: placement,
        showArrow: true,
        fill: cs.colors.backgroundStatusInfo,
        outline: cs.colors.borderStatusInfo,
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.m, vertical: CsSpace.s),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: '${slot.title ?? ''} $counter'.trim(),
          child: DefaultTextStyle(
            style: cs.body,
            // Long content or large text scrolls inside the popover.
            child: SingleChildScrollView(
              child: Column(
                key: ValueKey(slot.taskLocalStepIndex),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: CsSpace.xxxs),
                          child: Text(slot.title ?? '', style: small),
                        ),
                      ),
                      CsButton(
                        icon: CsIcons.close,
                        variant: CsButtonVariant.icon,
                        semanticLabel: s.labelDismissAnnotation,
                        onPress: data.dismiss,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: CsSpace.xxs),
                    child: slot.content ?? const SizedBox.shrink(),
                  ),
                  if (slot.warningAlert != null) ...[
                    const SizedBox(height: CsSpace.s),
                    _WarningAlert(child: slot.warningAlert!),
                  ],
                  const SizedBox(height: CsSpace.s),
                  Container(height: CsBorderLine.dividerSectionWidth, color: cs.colors.borderDividerDefault),
                  const SizedBox(height: CsSpace.s),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: CsSpace.xs,
                    children: [
                      Padding(
                        // `.stepCounter`: margin-inline-end 2 * base size (8px).
                        padding: const EdgeInsetsDirectional.only(end: CsSpace.m),
                        child: Text(counter, style: small),
                      ),
                      Wrap(
                        spacing: CsSpace.xs,
                        runSpacing: CsSpace.xs,
                        children: [
                          if (slot.showPreviousButton)
                            CsButton(
                              text: s.previousButtonText,
                              variant: CsButtonVariant.link,
                              disabled: !slot.previousButtonEnabled,
                              onPress: data.previous,
                            ),
                          if (slot.showFinishButton)
                            CsButton(text: s.finishButtonText, onPress: data.finish)
                          else
                            CsButton(text: s.nextButtonText, disabled: !slot.nextButtonEnabled, onPress: data.next),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The warning alert inside an annotation popover (Cloudscape renders an
/// `Alert type="warning"` there).
class _WarningAlert extends StatelessWidget {
  const _WarningAlert({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.alertHorizontal, vertical: CsSpace.xs),
      decoration: BoxDecoration(
        color: cs.colors.backgroundStatusWarning,
        borderRadius: BorderRadius.circular(CsBorderRadius.alert),
        border: Border.all(color: cs.colors.borderStatusWarning, width: CsBorderWidth.alert),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: CsTypeScale.bodyM.lineHeight,
            child: CsIcon(
              CsIcons.statusWarning,
              variant: CsIconVariant.warning,
              semanticLabel: context.csStrings.warning,
            ),
          ),
          const SizedBox(width: CsSpace.xs),
          Expanded(
            child: DefaultTextStyle(style: cs.body, child: child),
          ),
        ],
      ),
    );
  }
}
