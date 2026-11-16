import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../navigation/cs_link.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_live_region.dart';

/// Which side of the trigger a popover opens on (Cloudscape `position`).
/// [left] and [right] are the start and end sides, so they mirror in
/// right-to-left layouts. When there is not enough room, the popover flips
/// to the opposite side.
enum CsPopoverPosition { top, right, bottom, left }

/// Maximum popover widths (Cloudscape `size`).
enum CsPopoverSize {
  /// 210px.
  small(210),

  /// 310px. The default.
  medium(310),

  /// 482px, or 310px on windows narrower than 480px.
  large(482);

  const CsPopoverSize(this.width);
  final double width;
}

/// What the trigger contains (Cloudscape `triggerType`).
enum CsPopoverTriggerType {
  /// Inline components such as a status indicator. A dashed line runs under
  /// the whole trigger. The default.
  text,

  /// Plain text. The text itself gets a dashed underline.
  textInline,

  /// A button or other control that draws itself. Taps and Enter/Space on
  /// it toggle the popover; its own `onPress` still runs.
  custom,
}

/// Cloudscape's `Popover`: a small panel of extra detail that opens from a
/// trigger on tap, such as the full status of a resource or the definition
/// of a term.
///
/// ```dart
/// CsPopover(
///   header: 'Memory error',
///   content: const Text('This instance contains insufficient memory. Stop the instance and choose a larger type.'),
///   child: const CsStatusIndicator(type: CsStatusType.error, text: 'Error'),
/// )
///
/// CsPopover(
///   triggerType: CsPopoverTriggerType.custom,
///   dismissButton: false,
///   size: CsPopoverSize.small,
///   content: const CsStatusIndicator(type: CsStatusType.success, text: 'ARN copied'),
///   child: CsButton(text: 'Copy ARN', icon: CsIcons.copy, onPress: copyArn),
/// )
/// ```
///
/// The popover is uncontrolled by default: the trigger opens and closes it.
/// Pass [visible] (and [onVisibleChange]) to control it. A tap outside,
/// Escape and the close button close it. With [dismissButton] focus moves
/// into the popover and Tab stays inside until it closes; without it, focus
/// stays on the trigger, Tab closes the popover and the content is announced
/// as a live region.
///
/// It scales in from the trigger and fades, and leaves along the same path
/// (instantly under reduced motion). At or below 688px, [CsPopoverPosition.left]
/// and [CsPopoverPosition.right] open below the trigger instead, and the
/// popover shifts to stay 8px inside the screen.
class CsPopover extends StatefulWidget {
  const CsPopover({
    super.key,
    required this.child,
    this.content,
    this.header,
    this.dismissButton = true,
    this.dismissAriaLabel,
    this.position = CsPopoverPosition.right,
    this.size = CsPopoverSize.medium,
    this.fixedWidth = false,
    this.triggerType = CsPopoverTriggerType.text,
    this.triggerAriaLabel,
    this.wrapTriggerText = true,
    this.visible,
    this.onVisibleChange,
    this.onDismiss,
  });

  /// The trigger.
  final Widget child;

  /// Body of the popover, in `color-text-body-secondary`.
  final Widget? content;

  /// Heading of the popover.
  final String? header;

  /// Shows a close button in the popover and moves focus into it.
  final bool dismissButton;

  /// Accessible name of the close button. Defaults to "Close popover".
  final String? dismissAriaLabel;
  final CsPopoverPosition position;
  final CsPopoverSize size;

  /// Makes the popover as wide as [size] allows regardless of content (for
  /// a column layout inside it). Otherwise the popover shrinks to its
  /// content, which it measures with intrinsic sizing; content that cannot
  /// report an intrinsic width (a `LayoutBuilder`, a lazy list) needs
  /// [fixedWidth].
  final bool fixedWidth;
  final CsPopoverTriggerType triggerType;

  /// Accessible name of a text trigger, for triggers without visible text or
  /// several triggers with the same text.
  final String? triggerAriaLabel;

  /// False keeps a text trigger on one line with an ellipsis.
  final bool wrapTriggerText;

  /// Controls whether the popover is open. Leave null for an uncontrolled
  /// popover.
  final bool? visible;

  /// Called with the next open state whenever the trigger, the close
  /// button, Escape or an outside tap would change it.
  final ValueChanged<bool>? onVisibleChange;

  /// Called when the popover closes by the close button, Escape, Tab or an
  /// outside tap.
  final VoidCallback? onDismiss;

  @override
  State<CsPopover> createState() => CsPopoverState();
}

/// State of a [CsPopover]. Reach it with a `GlobalKey<CsPopoverState>` to
/// [dismiss] the popover from code (Cloudscape's `ref.dismiss()`).
class CsPopoverState extends State<CsPopover> {
  bool _internalOpen = false;
  bool _pointerDownInside = false;

  bool get _open => widget.visible ?? _internalOpen;

  void _set(bool open) {
    if (open == _open) return;
    if (widget.visible == null) setState(() => _internalOpen = open);
    widget.onVisibleChange?.call(open);
  }

  void _toggle() => _set(!_open);

  /// Closes the popover without moving focus.
  void dismiss() {
    if (!_open) return;
    _set(false);
    widget.onDismiss?.call();
  }

  Widget _trigger(BuildContext context) {
    final child = widget.child;
    switch (widget.triggerType) {
      case CsPopoverTriggerType.custom:
        // The custom control keeps its own press handling; Enter and Space
        // run its action and then toggle the popover, as a click on
        // Cloudscape's wrapper would.
        return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): _TogglePopoverIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): _TogglePopoverIntent(),
            SingleActivator(LogicalKeyboardKey.space): _TogglePopoverIntent(),
          },
          child: Actions(
            actions: {
              _TogglePopoverIntent: CallbackAction<_TogglePopoverIntent>(
                onInvoke: (_) {
                  final focused = FocusManager.instance.primaryFocus?.context;
                  if (focused != null) Actions.maybeInvoke(focused, const ActivateIntent());
                  _toggle();
                  return null;
                },
              ),
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _pointerDownInside = true,
              onPointerCancel: (_) => _pointerDownInside = false,
              onPointerUp: (_) {
                if (_pointerDownInside) _toggle();
                _pointerDownInside = false;
              },
              child: child,
            ),
          ),
        );
      case CsPopoverTriggerType.text:
      case CsPopoverTriggerType.textInline:
        final inline = widget.triggerType == CsPopoverTriggerType.textInline;
        return CsPressable(
          onPress: _toggle,
          scaleOnPress: false,
          expanded: _open,
          semanticLabel: widget.triggerAriaLabel,
          excludeChildSemantics: widget.triggerAriaLabel != null,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          focusRingOffset: 1,
          minTapTargetSize: 0,
          builder: (context, state) {
            final color = DefaultTextStyle.of(context).style.color ?? context.cs.colors.textBodyDefault;
            Widget content = DefaultTextStyle.merge(
              maxLines: widget.wrapTriggerText ? null : 1,
              overflow: widget.wrapTriggerText ? null : TextOverflow.ellipsis,
              softWrap: widget.wrapTriggerText,
              style: inline
                  ? TextStyle(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dashed,
                      decorationColor: color,
                      decorationThickness: CsBorderLine.dividerListWidth,
                    )
                  : null,
              child: child,
            );
            if (!inline) {
              content = CustomPaint(
                foregroundPainter: _DashedUnderline(color: color),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: CsBorderLine.dividerListWidth),
                  child: content,
                ),
              );
            }
            return content;
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Phones rarely have a popover's width beside the trigger, so start and
    // end positions open below it, the fallback Cloudscape picks there.
    final narrow = context.csIsNarrow;
    final side = switch (widget.position) {
      CsPopoverPosition.top => CsSide.top,
      CsPopoverPosition.bottom => CsSide.bottom,
      CsPopoverPosition.right when narrow => CsSide.bottom,
      CsPopoverPosition.left when narrow => CsSide.bottom,
      CsPopoverPosition.right => rtl ? CsSide.left : CsSide.right,
      CsPopoverPosition.left => rtl ? CsSide.right : CsSide.left,
    };
    final trapFocus = widget.dismissButton;

    Widget trigger = _trigger(context);
    if (!trapFocus) {
      // Without a close button focus stays on the trigger; Tab away closes.
      trigger = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab && _open) dismiss();
          return KeyEventResult.ignored;
        },
        child: trigger,
      );
    }

    return CsAnchoredOverlay(
      open: _open,
      onDismiss: dismiss,
      side: side,
      align: CsAlign.center,
      sideOffset: CsPopupSurface.arrowHeight + CsSpace.xxs,
      preferredExtent: side == CsSide.top || side == CsSide.bottom ? 120 : widget.size.width,
      trapFocus: trapFocus,
      overlayBuilder: (context, placement) => _PopoverBody(popover: widget, placement: placement, onDismiss: dismiss),
      child: trigger,
    );
  }
}

class _TogglePopoverIntent extends Intent {
  const _TogglePopoverIntent();
}

class _PopoverBody extends StatelessWidget {
  const _PopoverBody({required this.popover, required this.placement, required this.onDismiss});

  final CsPopover popover;
  final CsPopupPlacement placement;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // container.scss: the large size falls back to medium below 480px.
    final width = popover.size == CsPopoverSize.large && screenWidth < 480
        ? CsPopoverSize.medium.width
        : popover.size.width;
    final dir = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    Widget? content = popover.content == null
        ? null
        : DefaultTextStyle(
            style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
            child: CsLinkDefaults(variant: CsLinkVariant.primary, child: popover.content!),
          );
    if (content != null && !popover.dismissButton) {
      content = CsLiveRegion(delay: Duration.zero, child: content);
    }

    final dismiss = popover.dismissButton
        ? Transform.translate(
            // body.scss: `.dismiss` pulls the button out by space-xxs plus the popover border.
            offset: Offset((CsSpace.xxs + CsBorderWidth.popover) * dir, 0),
            child: CsButton(
              variant: CsButtonVariant.icon,
              icon: CsIcons.close,
              semanticLabel: popover.dismissAriaLabel ?? 'Close popover',
              onPress: onDismiss,
            ),
          )
        : null;

    Widget body;
    if (popover.header != null) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(popover.header!, style: cs.text(CsTypeScale.headingXs))),
              ),
              if (dismiss != null) ...[const SizedBox(width: CsSpace.xxs), dismiss],
            ],
          ),
          if (content != null) ...[SizedBox(height: dismiss != null ? 0 : CsSpace.xs), content],
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(fit: popover.fixedWidth ? FlexFit.tight : FlexFit.loose, child: content ?? const SizedBox()),
          if (dismiss != null) ...[const SizedBox(width: CsSpace.xxs), dismiss],
        ],
      );
    }

    return ConstrainedBox(
      constraints: popover.fixedWidth
          ? BoxConstraints.tightFor(width: width).enforce(BoxConstraints(maxWidth: placement.maxWidth))
          : BoxConstraints(maxWidth: width),
      child: CsPopupSurface(
        placement: placement,
        showArrow: true,
        child: DefaultTextStyle(
          style: cs.body,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: popover.header,
            child: popover.fixedWidth ? body : IntrinsicWidth(child: body),
          ),
        ),
      ),
    );
  }
}

class _DashedUnderline extends CustomPainter {
  const _DashedUnderline({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = CsBorderLine.dividerListWidth;
    final y = size.height - CsBorderLine.dividerListWidth / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedUnderline old) => old.color != color;
}
