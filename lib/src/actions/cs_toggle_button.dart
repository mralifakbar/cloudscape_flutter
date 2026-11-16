import 'package:flutter/widgets.dart';

import '../feedback/cs_spinner.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_haptics.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// Toggle button variants (Cloudscape `variant`).
enum CsToggleButtonVariant {
  /// Outlined like a normal button; pressed fills with
  /// `color-background-toggle-button-normal-pressed`.
  normal,

  /// Icon only, no border; pressed recolors the icon. Needs an [CsToggleButton.ariaLabel].
  icon,
}

/// Cloudscape's `ToggleButton`: a button that stays pressed until pressed
/// again, such as "Bookmark" or "Show grid".
///
/// ```dart
/// CsToggleButton(
///   text: 'Favorite',
///   icon: CsIcons.star,
///   pressedIcon: CsIcons.starFilled,
///   pressed: favorite,
///   onChange: (pressed) => setState(() => favorite = pressed),
/// )
/// ```
///
/// It is controlled: it shows [pressed] and reports the next state through
/// [onChange]. Screen readers hear it as a toggle with its pressed state.
class CsToggleButton extends StatelessWidget {
  const CsToggleButton({
    super.key,
    required this.pressed,
    this.onChange,
    this.text,
    this.variant = CsToggleButtonVariant.normal,
    this.icon,
    this.pressedIcon,
    this.iconWidget,
    this.pressedIconWidget,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
    this.ariaLabel,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         variant != CsToggleButtonVariant.icon || ariaLabel != null || text != null,
         'Icon toggles need an ariaLabel',
       );

  /// Whether the button is pressed (on).
  final bool pressed;

  /// Called with the next pressed state.
  final ValueChanged<bool>? onChange;

  /// Button text (normal variant).
  final String? text;
  final CsToggleButtonVariant variant;

  /// Icon while not pressed (Cloudscape `iconName`).
  final CsIconData? icon;

  /// Icon while pressed (Cloudscape `pressedIconName`). Defaults to [icon].
  final CsIconData? pressedIcon;

  /// Custom icon (Cloudscape `iconSvg`).
  final Widget? iconWidget;

  /// Custom pressed icon (Cloudscape `pressedIconSvg`).
  final Widget? pressedIconWidget;
  final bool disabled;

  /// Why it is disabled; keeps it focusable and shows the reason in a tooltip.
  final String? disabledReason;

  /// Shows a spinner in place of the icon and ignores presses.
  final bool loading;
  final String? loadingText;

  /// Accessible name, required for the icon variant. Icon toggles also show
  /// it in a tooltip.
  final String? ariaLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final isDisabled = disabled || onChange == null;
    final hasReason = isDisabled && disabledReason != null;
    final iconOnly = variant == CsToggleButtonVariant.icon;

    Widget result = CsPressable(
      onPress: isDisabled ? null : () => onChange!(!pressed),
      disabled: isDisabled,
      loading: loading,
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: !isDisabled || hasReason,
      toggled: pressed,
      haptic: CsHaptic.selection,
      semanticLabel: loading && loadingText != null ? loadingText : (ariaLabel ?? text),
      semanticHint: hasReason ? disabledReason : null,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing + CsSpace.buttonFocusOutlineGutter),
      focusRingOffset: CsSpace.buttonFocusOutlineGutter,
      builder: (context, state) {
        Color? background;
        Color? border;
        Color foreground;
        if (iconOnly) {
          foreground = isDisabled
              ? c.textButtonIconDisabled
              : pressed
              ? c.textToggleButtonIconPressed
              : state.hovered
              ? c.textButtonIconHover
              : c.textInteractiveDefault;
        } else if (isDisabled) {
          background = c.backgroundButtonNormalDisabled;
          border = c.borderButtonNormalDisabled;
          foreground = c.textButtonNormalDisabled;
        } else if (pressed) {
          background = c.backgroundToggleButtonNormalPressed;
          border = c.borderToggleButtonNormalPressed;
          foreground = c.textToggleButtonNormalPressed;
        } else if (state.active) {
          background = c.backgroundToggleButtonNormalHover;
          border = c.borderToggleButtonNormalHover;
          foreground = state.pressed ? c.textButtonNormalActive : c.textButtonNormalHover;
        } else {
          background = c.backgroundToggleButtonNormalDefault;
          border = c.borderToggleButtonNormalDefault;
          foreground = c.textButtonNormalDefault;
        }

        final custom = pressed ? (pressedIconWidget ?? iconWidget) : iconWidget;
        final glyph = pressed ? (pressedIcon ?? icon) : icon;
        final Widget? iconSlot = loading
            ? const CsSpinner(semanticLabel: '')
            : custom != null
            ? SizedBox.square(dimension: 16, child: Center(child: custom))
            : glyph != null
            ? CsIcon(glyph, key: ValueKey('${glyph.name}-$pressed'), dangerouslySetColor: foreground)
            : null;

        final textStyle = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: foreground);
        final Widget content = iconOnly || text == null
            ? SizedBox.square(dimension: 16, child: Center(child: iconSlot))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconSlot != null) ...[
                    Transform.translate(offset: Offset(-CsSpace.xxs * _dir(context), 0), child: iconSlot),
                  ],
                  Flexible(child: Text(text!, style: textStyle)),
                ],
              );
        final radius = BorderRadius.circular(CsBorderRadius.button);
        final d = cs.space;
        final padding = iconOnly
            ? EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: d.buttonVertical)
            : text == null
            ? EdgeInsets.symmetric(horizontal: d.buttonIconOnlyHorizontal, vertical: d.buttonVertical)
            : EdgeInsets.symmetric(horizontal: d.buttonHorizontal, vertical: d.buttonVertical);
        return Container(
          constraints: BoxConstraints(minHeight: d.sizeVerticalInput),
          padding: padding.add(const EdgeInsets.all(CsBorderWidth.button)),
          decoration: BoxDecoration(color: background, borderRadius: radius),
          foregroundDecoration: border == null
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: border, width: CsBorderWidth.button),
                ),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        );
      },
    );
    if (hasReason) {
      result = CsTooltip(content: disabledReason!, child: result);
    } else if (iconOnly && ariaLabel != null) {
      result = CsTooltip(content: ariaLabel!, child: result);
    }
    return result;
  }

  static double _dir(BuildContext context) => Directionality.maybeOf(context) == TextDirection.rtl ? -1 : 1;
}
