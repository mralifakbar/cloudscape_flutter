import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../status/cs_status_indicator.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Copy to clipboard variants (Cloudscape `variant`).
enum CsCopyToClipboardVariant {
  /// A normal button with a copy icon and [CsCopyToClipboard.copyButtonText].
  button,

  /// An icon button.
  icon,

  /// The text ([CsCopyToClipboard.textToDisplay] or the copied text)
  /// followed by an inline copy icon.
  inline,
}

/// Cloudscape's `CopyToClipboard`: copies a value (an ID, an ARN, a
/// command) and confirms in a small popover.
///
/// ```dart
/// CsCopyToClipboard(
///   variant: CsCopyToClipboardVariant.inline,
///   textToCopy: 'i-0abc123',
///   copySuccessText: 'Instance ID copied',
///   copyErrorText: 'Instance ID failed to copy',
/// )
/// ```
///
/// The popover shows a success or error status and closes on an outside tap
/// or Escape. Copying uses Flutter's [Clipboard].
class CsCopyToClipboard extends StatefulWidget {
  const CsCopyToClipboard({
    super.key,
    required this.textToCopy,
    required this.copySuccessText,
    required this.copyErrorText,
    this.variant = CsCopyToClipboardVariant.button,
    this.copyButtonText,
    this.copyButtonAriaLabel,
    this.textToDisplay,
    this.wrapText = true,
    this.disabled = false,
    this.disabledReason,
    this.onCopySuccess,
    this.onCopyFailure,
    this.mono = false,
  });

  /// The text placed on the clipboard.
  final String textToCopy;

  /// Popover text after a successful copy.
  final String copySuccessText;

  /// Popover text when copying failed.
  final String copyErrorText;
  final CsCopyToClipboardVariant variant;

  /// Text of the button variant. Defaults to "Copy".
  final String? copyButtonText;

  /// Accessible name of the icon and inline variants. Defaults to "Copy to clipboard".
  final String? copyButtonAriaLabel;

  /// Text shown in the inline variant in place of [textToCopy].
  final String? textToDisplay;

  /// Inline variant: wrap long text (true) or keep it on one line with an ellipsis.
  final bool wrapText;
  final bool disabled;

  /// Why copying is unavailable, shown in a tooltip.
  final String? disabledReason;
  final ValueChanged<String>? onCopySuccess;
  final ValueChanged<String>? onCopyFailure;

  /// Inline variant in monospace (IDs, ARNs).
  final bool mono;

  @override
  State<CsCopyToClipboard> createState() => _CsCopyToClipboardState();
}

class _CsCopyToClipboardState extends State<CsCopyToClipboard> {
  bool _open = false;
  bool _success = true;

  Future<void> _copy() async {
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    } on Object {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _success = ok;
      _open = true;
    });
    if (ok) {
      widget.onCopySuccess?.call(widget.textToCopy);
    } else {
      widget.onCopyFailure?.call(widget.textToCopy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final ariaLabel = widget.copyButtonAriaLabel ?? strings.copyToClipboard;
    final onPress = widget.disabled ? null : _copy;

    Widget trigger = switch (widget.variant) {
      CsCopyToClipboardVariant.button => CsButton(
        text: widget.copyButtonText ?? strings.copy,
        icon: CsIcons.copy,
        semanticLabel: widget.copyButtonAriaLabel,
        disabled: widget.disabled,
        disabledReason: widget.disabledReason,
        onPress: onPress,
      ),
      CsCopyToClipboardVariant.icon => CsButton(
        icon: CsIcons.copy,
        variant: CsButtonVariant.icon,
        semanticLabel: ariaLabel,
        disabled: widget.disabled,
        disabledReason: widget.disabledReason,
        onPress: onPress,
      ),
      CsCopyToClipboardVariant.inline => CsButton(
        icon: CsIcons.copy,
        variant: CsButtonVariant.inlineIcon,
        semanticLabel: ariaLabel,
        disabled: widget.disabled,
        disabledReason: widget.disabledReason,
        onPress: onPress,
      ),
    };

    trigger = CsAnchoredOverlay(
      open: _open,
      onDismiss: () => setState(() => _open = false),
      side: CsSide.top,
      sideOffset: CsPopupSurface.arrowHeight + CsSpace.xxs,
      overlayBuilder: (context, placement) => CsPopupSurface(
        placement: placement,
        showArrow: true,
        child: Semantics(
          liveRegion: true,
          child: CsStatusIndicator(
            type: _success ? CsStatusType.success : CsStatusType.error,
            text: _success ? widget.copySuccessText : widget.copyErrorText,
          ),
        ),
      ),
      child: trigger,
    );

    if (widget.variant != CsCopyToClipboardVariant.inline) return trigger;
    final text = widget.textToDisplay ?? widget.textToCopy;
    final style = widget.mono ? cs.code() : cs.body;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            text,
            style: style,
            softWrap: widget.wrapText,
            maxLines: widget.wrapText ? null : 1,
            overflow: widget.wrapText ? null : TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
          child: trigger,
        ),
      ],
    );
  }
}
