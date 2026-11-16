import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_focus_trap.dart';
import '../theme/theme.dart';

/// Copy for [CsDialog] (Cloudscape `i18nStrings`).
@immutable
class CsDialogI18nStrings {
  const CsDialogI18nStrings({this.dismissAriaLabel});

  /// Accessible name of the close button. Defaults to "Close dialog".
  final String? dismissAriaLabel;
}

/// Cloudscape's `Dialog`: a small panel that opens in place, next to the
/// content it is about (a quick edit inside a card, a confirmation in a
/// side panel), without a backdrop and without blocking the page.
///
/// Render it while it should show and remove it on [onDismiss]; Escape and
/// the close button both call it:
///
/// ```dart
/// if (_editing)
///   CsDialog(
///     header: 'Rename distribution',
///     onDismiss: () => setState(() => _editing = false),
///     footer: Row(
///       mainAxisAlignment: MainAxisAlignment.end,
///       children: [CsButton(text: 'Save', variant: CsButtonVariant.primary, onPress: save)],
///     ),
///     child: CsInput(value: _name, onChange: (v) => setState(() => _name = v)),
///   )
/// ```
///
/// Focus moves into the dialog when it appears and returns to whatever had
/// focus before when it goes away, as long as that widget still exists. Tab
/// is not trapped: the page stays usable. For a blocking dialog with a
/// backdrop, use `CsModal`.
class CsDialog extends StatelessWidget {
  const CsDialog({
    super.key,
    this.header,
    this.headerWidget,
    required this.onDismiss,
    this.headerActions,
    this.child,
    this.footer,
    this.i18nStrings,
    this.autofocus = true,
  }) : assert(header != null || headerWidget != null, 'A dialog needs a header.');

  /// Heading of the dialog, also its accessible name.
  final String? header;

  /// Rich content in place of [header].
  final Widget? headerWidget;

  /// Called by the close button and Escape. Remove the dialog in response.
  final VoidCallback onDismiss;

  /// Actions in the header row, before the close button (an info link, a
  /// settings icon button).
  final Widget? headerActions;

  /// Content of the dialog.
  final Widget? child;

  /// Footer, usually action buttons. Hidden when null.
  final Widget? footer;
  final CsDialogI18nStrings? i18nStrings;

  /// Move focus into the dialog when it appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final d = cs.space;
    final radius = BorderRadius.circular(CsBorderRadius.dialog);
    final headerSlot = headerWidget ?? Text(header!);
    final hasContent = child != null;
    final hasFooter = footer != null;

    // styles.scss: the header pads by the section padding minus the
    // actions' own padding, so its controls line up with the other sections.
    final header0 = Padding(
      padding: EdgeInsetsDirectional.only(
        start: d.dialogHorizontal,
        end: d.dialogHorizontal - CsSpace.dialogActionInline,
        top: d.dialogVertical - d.dialogActionBlock,
        bottom: hasContent || hasFooter ? CsSpace.dialogSectionGap : d.dialogVertical - d.dialogActionBlock,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: DefaultTextStyle(style: cs.text(CsTypeScale.headingS), child: headerSlot),
            ),
          ),
          if (headerActions != null) ...[const SizedBox(width: CsSpace.dialogHeaderGap), headerActions!],
          const SizedBox(width: CsSpace.dialogHeaderGap),
          CsButton(
            variant: CsButtonVariant.icon,
            icon: CsIcons.close,
            semanticLabel: i18nStrings?.dismissAriaLabel ?? 'Close dialog',
            onPress: onDismiss,
          ),
        ],
      ),
    );

    EdgeInsetsDirectional section({required bool first, required bool last}) => EdgeInsetsDirectional.only(
      start: d.dialogHorizontal,
      end: d.dialogHorizontal,
      top: first ? d.dialogVertical : CsSpace.dialogSectionGap,
      bottom: last ? d.dialogVertical : CsSpace.dialogSectionGap,
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header0,
        if (hasContent)
          Padding(
            padding: section(first: false, last: !hasFooter),
            child: child,
          ),
        if (hasFooter) Padding(padding: section(first: false, last: true), child: footer),
      ],
    );

    return CsFocusTrap(
      disableFocusTrap: true,
      disableAutoFocus: !autofocus,
      onEscPress: onDismiss,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: header,
        child: Container(
          decoration: BoxDecoration(
            color: c.backgroundDialogDefault,
            borderRadius: radius,
            boxShadow: cs.shadows.dialog,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: CsRing.inside(c.borderDialogDefault, width: CsBorderWidth.dialog),
          ),
          child: DefaultTextStyle.merge(style: cs.body, child: body),
        ),
      ),
    );
  }
}
