import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_option.dart';
import 'internal/option_list.dart';

/// Token sizes (Cloudscape `variant`).
enum CsTokenVariant {
  /// A box with the label, optional icon, label tag, description and tags.
  normal,

  /// A 20px-tall single-line token that sits inline with text or inside a
  /// trigger. Shows the label (and label tag) only.
  inline,
}

/// Cloudscape's `Token`: a compact representation of a chosen item, such as
/// a selected option or an applied filter, optionally dismissible.
///
/// ```dart
/// CsToken(
///   label: 'example-bucket',
///   description: 'us-east-1',
///   icon: CsIcons.folder,
///   dismissLabel: 'Remove example-bucket',
///   onDismiss: () => remove('example-bucket'),
/// )
/// ```
///
/// Normal tokens have a 2px `color-border-item-selected` border on
/// `color-background-item-selected` with an 8px radius; inline tokens are
/// 20px tall with a 1px border and a 4px radius. Read-only and disabled
/// tokens use their own fills, and their dismiss button does nothing.
class CsToken extends StatelessWidget {
  const CsToken({
    super.key,
    this.label,
    this.labelWidget,
    this.labelTag,
    this.description,
    this.tags,
    this.icon,
    this.iconWidget,
    this.variant = CsTokenVariant.normal,
    this.disabled = false,
    this.readOnly = false,
    this.dismissLabel,
    this.onDismiss,
    this.tooltipContent,
    this.ariaLabel,
  }) : assert(label != null || labelWidget != null, 'Pass label or labelWidget');

  /// The token text.
  final String? label;

  /// Custom label content in place of [label].
  final Widget? labelWidget;

  /// Short text after the label.
  final String? labelTag;

  /// Small text under the label (normal variant only).
  final String? description;

  /// Small tags under the label (normal variant only).
  final List<String>? tags;

  /// Leading icon (Cloudscape `icon`), drawn x-small in inline tokens.
  final CsIconData? icon;

  /// Any widget in the icon slot.
  final Widget? iconWidget;
  final CsTokenVariant variant;
  final bool disabled;
  final bool readOnly;

  /// Accessible name of the dismiss button. Defaults to "Remove" followed by the label.
  final String? dismissLabel;

  /// Shows a dismiss button when set.
  final VoidCallback? onDismiss;

  /// Shown in a tooltip on hover and focus (Cloudscape `tooltipContent`),
  /// typically the full label of a truncated inline token.
  final String? tooltipContent;

  /// Accessible name of the token when [label] is not descriptive.
  final String? ariaLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final inline = variant == CsTokenVariant.inline;
    final Color border;
    final Color background;
    if (disabled) {
      border = c.borderControlDisabled;
      background = c.backgroundContainerContent;
    } else if (readOnly) {
      border = c.borderInputDisabled;
      background = c.backgroundContainerContent;
    } else {
      border = c.borderItemSelected;
      background = c.backgroundItemSelected;
    }
    final fg = disabled ? c.textDisabled : c.textBodyDefault;
    final dismissible = onDismiss != null;

    Widget content;
    if (inline) {
      final style = cs.text(CsTypeScale.bodyS).copyWith(color: fg);
      final lead = iconWidget != null
          ? CsIcon.custom(iconWidget!, size: CsIconSize.xSmall)
          : icon != null
          ? CsIcon(icon!, size: CsIconSize.xSmall, dangerouslySetColor: fg)
          : null;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
              child: lead,
            ),
          Flexible(
            child:
                labelWidget ??
                Text(
                  labelTag == null ? label! : '${label!} ${labelTag!}',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        ],
      );
    } else {
      content = DefaultTextStyle.merge(
        style: TextStyle(color: fg),
        child: labelWidget != null
            ? labelWidget!
            : OptionContent(
                option: CsOption(
                  value: label!,
                  label: label,
                  labelTag: labelTag,
                  description: description,
                  tags: tags,
                  icon: icon,
                  iconWidget: iconWidget,
                ),
                disabled: disabled,
                color: fg,
              ),
      );
    }

    Widget? dismiss;
    if (dismissible) {
      dismiss = Padding(
        padding: EdgeInsetsDirectional.only(start: inline ? CsSpace.xxs + CsBorderWidth.field : CsSpace.xxs),
        child: CsButton(
          icon: CsIcons.close,
          variant: CsButtonVariant.inlineIcon,
          semanticLabel: dismissLabel ?? context.csStrings.removeItem(label ?? ''),
          disabled: disabled || readOnly,
          onPress: disabled || readOnly ? null : onDismiss,
        ),
      );
    }

    final radius = BorderRadius.circular(inline ? CsBorderRadius.tokenInline : CsBorderRadius.token);
    final borderWidth = inline ? CsBorderWidth.field : CsBorderWidth.token;
    final EdgeInsetsDirectional padding = inline
        ? EdgeInsetsDirectional.symmetric(horizontal: cs.space.scaledXxs)
        : EdgeInsetsDirectional.only(
            start: CsSpace.fieldHorizontal,
            end: dismissible ? CsSpace.xxs : CsSpace.fieldHorizontal,
            top: cs.space.tokenVertical,
            bottom: cs.space.tokenVertical,
          );

    Widget box = Container(
      constraints: inline ? const BoxConstraints(minHeight: _inlineHeight) : null,
      padding: padding.add(EdgeInsets.all(borderWidth)),
      decoration: BoxDecoration(color: background, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: inline ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Flexible(child: content),
          ?dismiss,
        ],
      ),
    );

    box = Semantics(container: true, label: ariaLabel, enabled: !disabled, readOnly: readOnly, child: box);
    if (tooltipContent != null) box = CsTooltip(content: tooltipContent!, child: box);
    return box;
  }

  /// `$token-max-height-inline` in token/constants.scss.
  static const double _inlineHeight = 20;
}
