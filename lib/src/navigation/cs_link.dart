import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_focus_ring.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Link styles (Cloudscape `variant`).
enum CsLinkVariant {
  /// Underlined link inside running text. The default.
  primary,

  /// No underline until hovered, for links that stand alone (table cells,
  /// key-value pairs).
  secondary,

  /// The "Info" link next to headers and form labels that opens the help
  /// panel: bold body-s.
  info,

  /// Bold link at a heading or value size.
  awsuiValueLarge,
}

/// Link colors (Cloudscape `color`).
enum CsLinkColor {
  normal,

  /// For links on dark or colored backgrounds (flash messages).
  inverted,
}

/// Cloudscape's `Link`.
///
/// ```dart
/// CsLink(text: 'Learn more about buckets', external: true, onFollow: openDocs)
/// CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: openHelp)
/// ```
///
/// Flutter has no `href`, so navigation happens in [onFollow]. [external]
/// adds an external-link icon and announces that the link opens a new tab.
class CsLink extends StatefulWidget {
  const CsLink({
    super.key,
    required this.text,
    this.onFollow,
    this.variant = CsLinkVariant.primary,
    this.color = CsLinkColor.normal,
    this.fontSize,
    this.external = false,
    this.externalIconAriaLabel,
    this.ariaLabel,
    this.focusNode,
  });

  final String text;

  /// Called when the link is activated (Cloudscape `onFollow`).
  final VoidCallback? onFollow;
  final CsLinkVariant variant;
  final CsLinkColor color;

  /// Type step. Defaults to the surrounding text size (body-s for [CsLinkVariant.info]).
  final CsTypeScale? fontSize;
  final bool external;
  final String? externalIconAriaLabel;
  final String? ariaLabel;
  final FocusNode? focusNode;

  @override
  State<CsLink> createState() => _CsLinkState();
}

class _CsLinkState extends State<CsLink> {
  bool _hover = false;
  bool _focus = false;

  void _follow() => widget.onFollow?.call();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final inverted = widget.color == CsLinkColor.inverted;
    final secondary = widget.variant == CsLinkVariant.secondary;
    final info = widget.variant == CsLinkVariant.info;
    final Color fg = inverted
        ? (_hover ? c.textLinkInvertedHover : c.textLinkInvertedDefault)
        : info
        ? (_hover ? c.textLinkInfoHover : c.textLinkInfoDefault)
        : secondary
        ? (_hover ? c.textLinkSecondaryHover : c.textLinkSecondaryDefault)
        : (_hover ? c.textLinkHover : c.textLinkDefault);
    final base = DefaultTextStyle.of(context).style;
    var style = widget.fontSize != null
        ? cs.typography.style(widget.fontSize!)
        : info
        ? cs.typography.style(CsTypeScale.bodyS, weight: CsTypography.bold)
        : base;
    if (widget.variant == CsLinkVariant.awsuiValueLarge) style = style.copyWith(fontWeight: CsTypography.bold);
    final underline = !info && (!secondary || _hover);
    style = style.copyWith(
      color: fg,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: fg,
      decorationThickness: 1,
    );

    final label = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: widget.text),
          if (widget.external)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                child: CsIcon(CsIcons.external, size: CsIconSize.small, dangerouslySetColor: fg),
              ),
            ),
        ],
        recognizer: TapGestureRecognizer()..onTap = _follow,
      ),
      style: style,
    );

    return Semantics(
      link: true,
      label: widget.ariaLabel,
      hint: widget.external ? (widget.externalIconAriaLabel ?? context.csStrings.opensInNewWindow) : null,
      onTap: widget.onFollow == null ? null : _follow,
      excludeSemantics: widget.ariaLabel != null,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: widget.onFollow != null,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _follow())},
        child: CsFocusRing(
          visible: _focus,
          offset: 1,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _follow, child: label),
        ),
      ),
    );
  }
}
