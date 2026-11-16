import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Cloudscape's form variants. Cloudscape no longer draws them differently;
/// the value is kept so ported code compiles.
enum CsFormVariant { fullPage, embedded }

/// Cloudscape's `Form`: the frame around a create or edit flow. It stacks a
/// [header], the form content ([child], usually containers of
/// `CsFormField`s), a form-level error alert and the action row: primary
/// [actions] at the end, [secondaryActions] at the start.
///
/// ```dart
/// CsForm(
///   header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Create bucket'),
///   errorText: submitError,
///   actions: CsSpaceBetween(
///     direction: CsSpaceBetweenDirection.horizontal,
///     size: CsSpacingSize.xs,
///     children: [
///       CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: cancel),
///       CsButton(text: 'Create bucket', variant: CsButtonVariant.primary, onPress: submit),
///     ],
///   ),
///   child: fields,
/// )
/// ```
///
/// When the action row does not fit (on a phone), the secondary actions wrap
/// onto their own line under the primary ones, both aligned to the end, as
/// in Cloudscape. A new [errorText] is announced to screen readers.
class CsForm extends StatelessWidget {
  const CsForm({
    super.key,
    this.child,
    this.header,
    this.errorText,
    this.errorWidget,
    this.errorIconAriaLabel,
    this.actions,
    this.secondaryActions,
    this.variant = CsFormVariant.fullPage,
  });

  /// The main form content.
  final Widget? child;

  /// The form title and description, usually a `CsHeader` with
  /// `CsHeaderVariant.h1`.
  final Widget? header;

  /// A form-level validation message, shown in an error alert under the
  /// content and announced. Null hides it.
  final String? errorText;

  /// Rich error content in place of [errorText].
  final Widget? errorWidget;

  /// Accessible name of the error icon. Defaults to "Error".
  final String? errorIconAriaLabel;

  /// The primary actions, usually a horizontal `CsSpaceBetween` (size xs)
  /// of a link-variant Cancel and a primary submit button.
  final Widget? actions;

  /// Actions aligned to the start of the row. Use a button dropdown if there
  /// are several.
  final Widget? secondaryActions;

  /// Kept for parity with Cloudscape, where it no longer changes anything.
  final CsFormVariant variant;

  @override
  Widget build(BuildContext context) {
    final space = context.cs.space;
    final hasError = errorText != null || errorWidget != null;
    final iconLabel = errorIconAriaLabel ?? context.csStrings.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Padding(
            padding: EdgeInsets.only(bottom: space.scaledM),
            child: header,
          ),
        ?child,
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: space.scaledL),
            child: _FormErrorAlert(iconLabel: iconLabel, text: errorText, child: errorWidget),
          ),
        if (actions != null || secondaryActions != null)
          Padding(
            padding: EdgeInsets.only(top: space.scaledL),
            child: _ActionsRow(actions: actions, secondaryActions: secondaryActions),
          ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({this.actions, this.secondaryActions});

  final Widget? actions;
  final Widget? secondaryActions;

  @override
  Widget build(BuildContext context) {
    final gap = context.cs.space.scaledM;
    final dir = Directionality.of(context);
    final reversed = dir == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr;
    // form/styles.scss lays the row out `row-reverse` with `space-between`
    // and wrap: a Wrap in the opposite direction does the same, and puts
    // the primary actions first when it wraps.
    return Wrap(
      textDirection: reversed,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        if (actions != null) Directionality(textDirection: dir, child: actions!),
        if (secondaryActions != null) Directionality(textDirection: dir, child: secondaryActions!),
      ],
    );
  }
}

/// The error alert of a form: Cloudscape's `Alert` with `type="error"`.
class _FormErrorAlert extends StatelessWidget {
  const _FormErrorAlert({required this.iconLabel, this.text, this.child});

  final String iconLabel;
  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final style = cs.text(CsTypeScale.bodyM, color: CsColor.textAlertDefault);
    return Semantics(
      liveRegion: true,
      container: true,
      label: text == null ? iconLabel : '$iconLabel, $text',
      child: Container(
        decoration: BoxDecoration(
          color: c.backgroundAlertError,
          borderRadius: BorderRadius.circular(CsBorderRadius.alert),
          border: CsRing.inside(c.borderStatusError, width: CsBorderWidth.alert),
        ),
        padding: EdgeInsets.symmetric(vertical: cs.space.alertVertical, horizontal: CsSpace.alertHorizontal),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CsSpace.xs,
          children: [
            ExcludeSemantics(child: CsIcon(CsIcons.statusNegative, dangerouslySetColor: c.textAlertIconError)),
            Expanded(
              child: DefaultTextStyle(
                style: style,
                child: text != null ? ExcludeSemantics(child: Text(text!)) : child!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
