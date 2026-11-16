import 'package:flutter/widgets.dart';

import '../feedback/cs_spinner.dart';
import '../feedback/cs_swap.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_haptics.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Button variants (Cloudscape `variant`).
enum CsButtonVariant {
  /// The default: outlined in `color-border-button-normal-default`.
  normal,

  /// The main action of a page or form, filled blue. One per view.
  primary,

  /// No border or fill until hovered. Secondary actions next to a primary
  /// button ("Cancel"), and actions in headers and tables.
  link,

  /// Icon only, no border. Toolbars and compact actions. Needs a
  /// `semanticLabel`.
  icon,

  /// Icon only, with no vertical padding, sized to sit inline with text
  /// (an info, copy or remove icon inside a row). Needs a `semanticLabel`.
  inlineIcon,

  /// Text styled as a link with no padding, inline with surrounding text.
  inlineLink,

  /// Used by modals for their close button.
  modalDismiss,

  /// Used by flash messages for their dismiss button, on a colored background.
  flashbarIcon,
}

/// Which side of the text the icon sits on (Cloudscape `iconAlign`).
enum CsButtonIconAlign { left, right }

/// Cloudscape's `Button`.
///
/// ```dart
/// CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: launch)
/// CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: cancel)
/// CsButton(icon: CsIcons.refresh, variant: CsButtonVariant.icon, semanticLabel: 'Refresh', onPress: refresh)
/// CsButton(text: 'Delete', disabled: true, disabledReason: 'Stop the instance first.', onPress: delete)
/// ```
///
/// Buttons are fully rounded with a 2px border and bold 14px text, 32px tall
/// in comfortable density and 28px in compact. Feedback starts on
/// pointer-down (a 0.98 spring scale); hover colors switch instantly. While
/// [loading], a spinner replaces the icon and presses are ignored. A disabled
/// button with a [disabledReason] stays focusable and shows the reason in a
/// tooltip.
class CsButton extends StatelessWidget {
  const CsButton({
    super.key,
    this.text,
    this.child,
    this.onPress,
    this.onLongPress,
    this.variant = CsButtonVariant.normal,
    this.icon,
    this.iconWidget,
    this.iconAlign = CsButtonIconAlign.left,
    this.loading = false,
    this.loadingText,
    this.disabled = false,
    this.disabledReason,
    this.fullWidth = false,
    this.wrapText = true,
    this.external = false,
    this.isLink = false,
    this.expanded,
    this.semanticLabel,
    this.haptic = CsHaptic.none,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         text != null ||
             child != null ||
             semanticLabel != null ||
             !(variant == CsButtonVariant.icon || variant == CsButtonVariant.inlineIcon),
         'Icon buttons need a semanticLabel',
       );

  /// Button text, sentence case and a verb: "Create distribution".
  final String? text;

  /// Custom content in place of [text].
  final Widget? child;

  /// Null renders the button disabled.
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final CsButtonVariant variant;

  /// One of [CsIcons] (Cloudscape `iconName`).
  final CsIconData? icon;

  /// Any widget in the icon slot (Cloudscape `iconSvg` / `iconUrl`).
  final Widget? iconWidget;
  final CsButtonIconAlign iconAlign;

  /// Shows a spinner in place of the icon and ignores presses.
  final bool loading;

  /// Announced while [loading] (Cloudscape `loadingText`).
  final String? loadingText;
  final bool disabled;

  /// Why the button is disabled. Keeps it focusable and shows the reason in
  /// a tooltip on hover, focus and long press.
  final String? disabledReason;

  /// Stretch to the parent's width.
  final bool fullWidth;

  /// False keeps the text on one line, truncating with an ellipsis.
  final bool wrapText;

  /// Adds an external-link icon after the text and announces "opens in a new
  /// tab" (Cloudscape `external` with `href`).
  final bool external;

  /// Announce as a link (a button with `href`).
  final bool isLink;

  /// Announces the disclosure state of a button that opens a menu or panel
  /// (Cloudscape `ariaExpanded`).
  final bool? expanded;

  /// Accessible name. Required for icon-only variants (Cloudscape `ariaLabel`).
  final String? semanticLabel;
  final CsHaptic haptic;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get _disabled => disabled || (onPress == null && onLongPress == null);

  bool get _iconOnly =>
      variant == CsButtonVariant.icon ||
      variant == CsButtonVariant.inlineIcon ||
      variant == CsButtonVariant.modalDismiss ||
      variant == CsButtonVariant.flashbarIcon ||
      (text == null && child == null);

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final isDisabled = _disabled;
    final hasReason = isDisabled && disabledReason != null;
    final iconOnly = _iconOnly;
    final radius = BorderRadius.circular(CsBorderRadius.button);

    final pressable = CsPressable(
      onPress: isDisabled ? null : onPress,
      onLongPress: isDisabled ? null : onLongPress,
      disabled: isDisabled,
      loading: loading,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing + _focusGutter),
      focusRingOffset: _focusGutter,
      haptic: haptic,
      focusNode: focusNode,
      autofocus: autofocus,
      // A disabled button with a reason stays reachable so its tooltip can be read.
      canRequestFocus: !isDisabled || hasReason,
      isLink: isLink,
      expanded: expanded,
      semanticLabel: loading && loadingText != null ? loadingText : semanticLabel,
      semanticHint: hasReason ? disabledReason : (external ? context.csStrings.opensInNewWindow : null),
      excludeChildSemantics: iconOnly || semanticLabel != null || (loading && loadingText != null),
      scaleOnPress: variant != CsButtonVariant.inlineLink,
      builder: (context, state) {
        final s = _VariantStyle.of(
          variant,
          c,
          isDisabled
              ? _State.disabled
              : (state.pressed ? _State.active : (state.hovered ? _State.hover : _State.normal)),
        );
        final textStyle = cs
            .text(CsTypeScale.bodyM, weight: CsTypography.bold)
            .copyWith(
              color: s.foreground,
              letterSpacing: 0.005 * CsTypeScale.bodyM.fontSize,
              decoration: null,
              decorationColor: s.foreground,
            );

        final Widget? iconSlot = loading
            ? const CsSpinner(key: ValueKey('cs-button-spinner'), semanticLabel: '')
            : iconWidget != null
            ? KeyedSubtree(
                key: iconWidget!.key ?? const ValueKey('cs-button-icon'),
                child: SizedBox.square(dimension: 16, child: Center(child: iconWidget)),
              )
            : (icon != null ? CsIcon(icon!, key: ValueKey(icon!.name), dangerouslySetColor: s.foreground) : null);

        Widget? label;
        if (!iconOnly) {
          label =
              child ??
              Text(
                text!,
                style: textStyle,
                maxLines: wrapText ? null : 1,
                overflow: wrapText ? null : TextOverflow.ellipsis,
                softWrap: wrapText,
                textAlign: fullWidth ? TextAlign.center : TextAlign.start,
              );
        }

        final iconGap = variant == CsButtonVariant.inlineLink ? CsSpace.xs : CsSpace.xxs;
        final leading = iconAlign == CsButtonIconAlign.left ? iconSlot : null;
        final trailing = iconAlign == CsButtonIconAlign.right ? iconSlot : null;
        final externalIcon = external && !iconOnly
            ? CsIcon(CsIcons.external, size: CsIconSize.normal, dangerouslySetColor: s.foreground)
            : null;

        Widget content;
        if (iconOnly) {
          content = SizedBox.square(
            dimension: 16,
            child: Center(
              child: CsSwap(child: iconSlot ?? const SizedBox.shrink(key: ValueKey('empty'))),
            ),
          );
        } else {
          content = Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                // Cloudscape pulls the icon 4px toward the edge and adds 4px
                // before the text, so the visual gap stays even.
                Transform.translate(
                  offset: Offset(variant == CsButtonVariant.inlineLink ? 0 : -CsSpace.xxs * _dir(context), 0),
                  child: CsSwap(child: leading),
                ),
                SizedBox(width: variant == CsButtonVariant.inlineLink ? iconGap : 0),
              ],
              Flexible(child: label!),
              if (externalIcon != null) ...[SizedBox(width: iconGap), externalIcon],
              if (trailing != null) ...[
                SizedBox(width: variant == CsButtonVariant.inlineLink ? iconGap : 0),
                Transform.translate(
                  offset: Offset(variant == CsButtonVariant.inlineLink ? 0 : CsSpace.xxs * _dir(context), 0),
                  child: CsSwap(child: trailing),
                ),
              ],
            ],
          );
        }

        final padding = _padding(cs, iconOnly);
        final border =
            s.border == null || variant == CsButtonVariant.inlineLink || variant == CsButtonVariant.inlineIcon
            ? null
            : CsRing.inside(s.border!, width: CsBorderWidth.button);
        // Inline variants have no padding or border; keep the 2px border
        // space on boxed variants so every state is the same size.
        final boxed = variant != CsButtonVariant.inlineLink && variant != CsButtonVariant.inlineIcon;
        return Container(
          width: fullWidth ? double.infinity : null,
          constraints: boxed ? BoxConstraints(minHeight: cs.space.sizeVerticalInput) : null,
          padding: padding.add(boxed ? const EdgeInsets.all(CsBorderWidth.button) : EdgeInsets.zero),
          decoration: BoxDecoration(color: s.background, borderRadius: radius),
          foregroundDecoration: border == null ? null : BoxDecoration(borderRadius: radius, border: border),
          child: DefaultTextStyle(
            style: textStyle,
            child: IconTheme(
              data: IconThemeData(color: s.foreground),
              child: Center(widthFactor: 1, heightFactor: 1, child: content),
            ),
          ),
        );
      },
    );

    Widget result = pressable;
    if (hasReason) {
      result = CsTooltip(content: disabledReason!, child: result);
    }
    if (fullWidth) result = SizedBox(width: double.infinity, child: result);
    return result;
  }

  double get _focusGutter => switch (variant) {
    CsButtonVariant.inlineIcon => CsSpace.buttonInlineIconFocusOutlineGutter,
    CsButtonVariant.inlineLink => CsSpace.buttonInlineLinkFocusOutlineGutter,
    _ => CsSpace.buttonFocusOutlineGutter,
  };

  static double _dir(BuildContext context) => Directionality.maybeOf(context) == TextDirection.rtl ? -1 : 1;

  EdgeInsetsGeometry _padding(CsThemeData cs, bool iconOnly) {
    final d = cs.space;
    return switch (variant) {
      CsButtonVariant.inlineLink => EdgeInsets.zero,
      CsButtonVariant.inlineIcon => const EdgeInsets.symmetric(horizontal: CsSpace.xxs),
      CsButtonVariant.icon ||
      CsButtonVariant.flashbarIcon => EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: d.buttonVertical),
      CsButtonVariant.modalDismiss => EdgeInsets.symmetric(
        horizontal: CsSpace.xxs,
        vertical: d.buttonModalDismissVertical,
      ),
      _ when iconOnly => EdgeInsets.symmetric(horizontal: d.buttonIconOnlyHorizontal, vertical: d.buttonVertical),
      _ => EdgeInsets.symmetric(horizontal: d.buttonHorizontal, vertical: d.buttonVertical),
    };
  }
}

enum _State { normal, hover, active, disabled }

class _VariantStyle {
  const _VariantStyle(this.background, this.border, this.foreground);

  final Color? background;
  final Color? border;
  final Color foreground;

  static _VariantStyle of(CsButtonVariant variant, CsColorScheme c, _State s) {
    const none = Color(0x00000000);
    switch (variant) {
      case CsButtonVariant.normal:
        return switch (s) {
          _State.normal => _VariantStyle(
            c.backgroundButtonNormalDefault,
            c.borderButtonNormalDefault,
            c.textButtonNormalDefault,
          ),
          _State.hover => _VariantStyle(
            c.backgroundButtonNormalHover,
            c.borderButtonNormalHover,
            c.textButtonNormalHover,
          ),
          _State.active => _VariantStyle(
            c.backgroundButtonNormalActive,
            c.borderButtonNormalActive,
            c.textButtonNormalActive,
          ),
          _State.disabled => _VariantStyle(
            c.backgroundButtonNormalDisabled,
            c.borderButtonNormalDisabled,
            c.textButtonNormalDisabled,
          ),
        };
      case CsButtonVariant.primary:
        return switch (s) {
          _State.normal => _VariantStyle(
            c.backgroundButtonPrimaryDefault,
            c.borderButtonPrimaryDefault,
            c.textButtonPrimaryDefault,
          ),
          _State.hover => _VariantStyle(
            c.backgroundButtonPrimaryHover,
            c.borderButtonPrimaryHover,
            c.textButtonPrimaryHover,
          ),
          _State.active => _VariantStyle(
            c.backgroundButtonPrimaryActive,
            c.borderButtonPrimaryActive,
            c.textButtonPrimaryActive,
          ),
          _State.disabled => _VariantStyle(
            c.backgroundButtonPrimaryDisabled,
            c.borderButtonPrimaryDisabled,
            c.textButtonPrimaryDisabled,
          ),
        };
      case CsButtonVariant.link:
        return switch (s) {
          _State.normal => _VariantStyle(
            c.backgroundButtonLinkDefault,
            c.backgroundButtonLinkDefault,
            c.textButtonLinkDefault,
          ),
          _State.hover => _VariantStyle(
            c.backgroundButtonLinkHover,
            c.backgroundButtonLinkHover,
            c.textButtonLinkHover,
          ),
          _State.active => _VariantStyle(
            c.backgroundButtonLinkActive,
            c.backgroundButtonLinkActive,
            c.textButtonLinkActive,
          ),
          _State.disabled => _VariantStyle(
            c.backgroundButtonLinkDisabled,
            c.borderButtonLinkDisabled,
            c.textButtonLinkDisabled,
          ),
        };
      case CsButtonVariant.icon:
        return switch (s) {
          _State.hover => _VariantStyle(none, none, c.textButtonIconHover),
          _State.disabled => _VariantStyle(none, none, c.textButtonIconDisabled),
          _ => _VariantStyle(none, none, c.textInteractiveDefault),
        };
      case CsButtonVariant.inlineIcon:
        return switch (s) {
          _State.hover => _VariantStyle(none, none, c.textButtonInlineIconHover),
          _State.disabled => _VariantStyle(none, none, c.textButtonInlineIconDisabled),
          _ => _VariantStyle(none, none, c.textButtonInlineIconDefault),
        };
      case CsButtonVariant.inlineLink:
        return switch (s) {
          _State.hover => _VariantStyle(none, none, c.textButtonInlineLinkHover),
          _State.active => _VariantStyle(none, none, c.textButtonNormalActive),
          _State.disabled => _VariantStyle(none, none, c.textInteractiveDisabled),
          _State.normal => _VariantStyle(none, none, c.textButtonNormalDefault),
        };
      case CsButtonVariant.modalDismiss:
        return switch (s) {
          _State.hover => _VariantStyle(none, none, c.textInteractiveHover),
          _State.disabled => _VariantStyle(none, none, c.textInteractiveDisabled),
          _ => _VariantStyle(none, none, c.textInteractiveDefault),
        };
      case CsButtonVariant.flashbarIcon:
        return switch (s) {
          _State.hover => _VariantStyle(none, none, c.textInteractiveInvertedHover),
          _State.disabled => _VariantStyle(none, none, c.textInteractiveDisabled),
          _ => _VariantStyle(none, none, c.textInteractiveInvertedDefault),
        };
    }
  }
}
