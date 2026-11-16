import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../system/cs_focus_ring.dart';
import '../theme/theme.dart';

/// Cloudscape's `TruncatedText`: text that ends with an ellipsis when it
/// does not fit, and shows the full text in a tooltip on hover, keyboard
/// focus or tap.
///
/// ```dart
/// const CsTruncatedText('arn:aws:s3:::example-bucket/logs/2026/11/16/distribution-d111111abcdef8.gz')
/// const CsTruncatedText(longDescription, maxLines: 2)
/// ```
///
/// Only truncated text is interactive: when everything fits, it is plain
/// text, out of the Tab order, with no tooltip. When truncated it becomes
/// focusable (Tab shows the tooltip, Escape hides it), a mouse hover shows
/// it, and a tap toggles it on touch screens. Screen readers always get the
/// full text.
class CsTruncatedText extends StatefulWidget {
  const CsTruncatedText(this.text, {super.key, this.maxLines = 1, this.tooltipText, this.style, this.textAlign});

  /// The text to display.
  final String text;

  /// Lines before truncating. Cloudscape truncates to one line; more lines
  /// clamp a description.
  final int maxLines;

  /// Tooltip content when it should differ from [text].
  final String? tooltipText;

  /// Merged over the surrounding text style.
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<CsTruncatedText> createState() => _CsTruncatedTextState();
}

class _CsTruncatedTextState extends State<CsTruncatedText> {
  final FocusNode _focus = FocusNode(debugLabel: 'CsTruncatedText');
  bool _open = false;
  bool _hovered = false;
  bool _focusVisible = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setOpen(bool value) {
    if (_open != value && mounted) setState(() => _open = value);
  }

  bool _measureTruncated(BuildContext context, TextStyle style, double maxWidth) {
    if (!maxWidth.isFinite) return false;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: widget.maxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      textAlign: widget.textAlign ?? TextAlign.start,
    )..layout(maxWidth: maxWidth);
    final exceeded = painter.didExceedMaxLines || painter.width > maxWidth + 0.5;
    painter.dispose();
    return exceeded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final truncated = _measureTruncated(context, style, constraints.maxWidth);
        final text = Text(
          widget.text,
          style: style,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: widget.maxLines > 1,
          textAlign: widget.textAlign,
        );
        if (!truncated) {
          if (_open || _focusVisible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _open = false;
                _focusVisible = false;
              });
            });
          }
          return text;
        }
        Widget trigger = CsFocusRing(
          visible: _focusVisible,
          // Cloudscape pulls the outline inside, since the text sits flush
          // against whatever truncates it.
          offset: -2,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          child: text,
        );
        trigger = MouseRegion(
          onEnter: (e) {
            if (e.kind == PointerDeviceKind.touch) return;
            _hovered = true;
            _setOpen(true);
          },
          onExit: (_) {
            _hovered = false;
            if (!_focus.hasFocus) _setOpen(false);
          },
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _setOpen(!_open), child: trigger),
        );
        trigger = Focus(
          focusNode: _focus,
          onFocusChange: (focused) {
            final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
            setState(() => _focusVisible = focused && keyboard);
            if (focused && keyboard) {
              _setOpen(true);
            } else if (!focused && !_hovered) {
              _setOpen(false);
            }
          },
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape && _open) {
              _setOpen(false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            label: widget.text,
            tooltip: widget.tooltipText,
            excludeSemantics: true,
            focusable: true,
            child: trigger,
          ),
        );
        return CsAnchoredOverlay(
          open: _open,
          side: CsSide.top,
          sideOffset: 6 + CsPopupSurface.arrowHeight,
          preferredExtent: 60,
          focusPopupWhenUnfocused: false,
          onDismiss: () => _setOpen(false),
          overlayBuilder: (context, placement) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: CsPopupSurface(
              placement: placement,
              showArrow: true,
              child: ExcludeSemantics(child: Text(widget.tooltipText ?? widget.text, style: cs.body)),
            ),
          ),
          child: trigger,
        );
      },
    );
  }
}
