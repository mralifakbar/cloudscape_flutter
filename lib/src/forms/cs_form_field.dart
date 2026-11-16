import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Cloudscape's `FormField`: a bold label over a control, with a description
/// under the label, constraint text under the control and an error or warning
/// message that replaces nothing and announces itself.
///
/// ```dart
/// CsFormField(
///   label: 'Bucket name',
///   description: 'Must be unique across all AWS accounts.',
///   constraintText: 'Use 3 to 63 lowercase letters, numbers, dots and hyphens.',
///   errorText: nameError,
///   child: CsInput(value: name, invalid: nameError != null, onChange: setName),
/// )
/// ```
class CsFormField extends StatelessWidget {
  const CsFormField({
    super.key,
    this.label,
    this.labelWidget,
    this.info,
    this.description,
    this.descriptionWidget,
    this.constraintText,
    this.characterCountText,
    this.errorText,
    this.warningText,
    this.secondaryControl,
    this.stretch = false,
    this.labelHidden = false,
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    required this.child,
  });

  final String? label;

  /// Custom label content in place of [label].
  final Widget? labelWidget;

  /// An info link after the label, separated by a divider (usually a
  /// `CsLink(variant: CsLinkVariant.info)` that opens the help panel).
  final Widget? info;
  final String? description;
  final Widget? descriptionWidget;

  /// Rules for the value, shown under the control.
  final String? constraintText;

  /// "12/50 characters", shown after the constraint text.
  final String? characterCountText;

  /// Shown in red with an error icon, and announced. Null hides it.
  final String? errorText;

  /// Shown in yellow with a warning icon when there is no [errorText].
  final String? warningText;

  /// A control next to the main one (a "Remove" button in an attribute
  /// editor row). Below 688px it moves under the control.
  final Widget? secondaryControl;

  /// Let the control take the full width. By default Cloudscape caps form
  /// controls at 2/3 of the field width on wide layouts (`stretch: false`).
  final bool stretch;

  /// Keep the label for screen readers only.
  final bool labelHidden;
  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final hasLabel = label != null || labelWidget != null;
    final labelStyle = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textFormLabel);
    final secondaryStyle = cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary);

    final header = <Widget>[];
    if (hasLabel && !labelHidden) {
      Widget labelRow = labelWidget ?? Text(label!, style: labelStyle);
      if (info != null) {
        labelRow = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(padding: const EdgeInsetsDirectional.only(end: CsSpace.xs), child: labelRow),
            Container(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: cs.colors.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
                ),
              ),
              child: info,
            ),
          ],
        );
      }
      header.add(DefaultTextStyle(style: labelStyle, child: labelRow));
    }
    if (description != null || descriptionWidget != null) {
      header.add(DefaultTextStyle(style: secondaryStyle, child: descriptionWidget ?? Text(description!)));
    }

    final narrow = context.csIsNarrow;
    Widget control = child;
    if (secondaryControl != null) {
      control = narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CsSpace.xs,
              children: [child, Align(alignment: AlignmentDirectional.centerStart, child: secondaryControl)],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CsSpace.l,
              children: [Expanded(flex: 2, child: child), Flexible(child: secondaryControl!)],
            );
    } else if (!stretch && !narrow) {
      control = FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 0.66,
        child: child,
      );
    }

    final hints = <Widget>[];
    if (errorText != null) {
      hints.add(
        _Message(
          icon: CsIcons.statusNegative,
          variant: CsIconVariant.error,
          iconLabel: errorIconAriaLabel ?? strings.error,
          text: errorText!,
          color: CsColor.textStatusError,
        ),
      );
    } else if (warningText != null) {
      hints.add(
        _Message(
          icon: CsIcons.statusWarning,
          variant: CsIconVariant.warning,
          iconLabel: warningIconAriaLabel ?? strings.warning,
          text: warningText!,
          color: CsColor.textStatusWarning,
        ),
      );
    }
    if (constraintText != null || characterCountText != null) {
      hints.add(
        Text(
          [?constraintText, ?characterCountText].join(' '),
          style: secondaryStyle,
        ),
      );
    }

    return Semantics(
      container: true,
      label: labelHidden ? label : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header.isNotEmpty) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: header),
            const SizedBox(height: CsSpace.xxs),
          ],
          control,
          if (hints.isNotEmpty) ...[
            const SizedBox(height: CsSpace.xxs),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hints),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.variant,
    required this.iconLabel,
    required this.text,
    required this.color,
  });

  final CsIconData icon;
  final CsIconVariant variant;
  final String iconLabel;
  final String text;
  final CsColor color;

  @override
  Widget build(BuildContext context) {
    final style = context.cs.text(CsTypeScale.bodyS, color: color);
    return Semantics(
      liveRegion: true,
      label: '$iconLabel. $text',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CsSpace.xxs,
          children: [
            CsIcon(icon, size: CsIconSize.small, variant: variant),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}
