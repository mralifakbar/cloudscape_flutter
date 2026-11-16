import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Sends a polite screen reader announcement from [context]'s view. Used for
/// live messages that have no visible region of their own ("Item removed").
void csEditorsAnnounce(BuildContext context, String message) {
  if (message.isEmpty) return;
  final view = View.maybeOf(context);
  if (view == null) return;
  SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
}

/// A validation message under a control, drawn like `CsFormField`'s: a
/// small status icon and body-s text in the status color, announced.
class CsEditorsMessage extends StatelessWidget {
  const CsEditorsMessage({super.key, required this.text, required this.warning, this.iconLabel});

  final String text;

  /// Warning (yellow) rather than error (red).
  final bool warning;
  final String? iconLabel;

  @override
  Widget build(BuildContext context) {
    final strings = context.csStrings;
    final color = warning ? CsColor.textStatusWarning : CsColor.textStatusError;
    final label = iconLabel ?? (warning ? strings.warning : strings.error);
    return Semantics(
      liveRegion: true,
      label: '$label. $text',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CsSpace.xxs,
          children: [
            CsIcon(
              warning ? CsIcons.statusWarning : CsIcons.statusNegative,
              size: CsIconSize.small,
              variant: warning ? CsIconVariant.warning : CsIconVariant.error,
            ),
            Expanded(
              child: Text(text, style: context.cs.text(CsTypeScale.bodyS, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
