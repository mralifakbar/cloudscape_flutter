import 'package:flutter/widgets.dart';

import '../feedback/cs_spinner.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Status types (Cloudscape `type`), each with its icon and color.
enum CsStatusType { error, warning, success, info, stopped, pending, inProgress, loading, notStarted, log }

/// Color overrides (Cloudscape `colorOverride`).
enum CsStatusColor { red, grey, blue, green, yellow }

/// Cloudscape's `StatusIndicator`: an icon and short text for the state of a
/// resource or process, such as "Running", "Stopped" or "3 errors".
///
/// ```dart
/// const CsStatusIndicator(type: CsStatusType.success, text: 'Available')
/// const CsStatusIndicator(type: CsStatusType.loading, text: 'Deploying')
/// ```
///
/// Status is never color alone: each type has its own icon.
class CsStatusIndicator extends StatelessWidget {
  const CsStatusIndicator({
    super.key,
    required this.type,
    this.text,
    this.child,
    this.colorOverride,
    this.wrapText = true,
    this.iconAriaLabel,
    this.iconSize = CsIconSize.normal,
  });

  final CsStatusType type;
  final String? text;

  /// Custom content in place of [text].
  final Widget? child;
  final CsStatusColor? colorOverride;

  /// False keeps the text on one line with an ellipsis.
  final bool wrapText;

  /// Accessible name of the icon, announced before the text. Defaults to the
  /// status name ("Error", "Success").
  final String? iconAriaLabel;
  final CsIconSize iconSize;

  /// Icon of [type].
  static CsIconData? iconFor(CsStatusType type) => switch (type) {
    CsStatusType.error => CsIcons.statusNegative,
    CsStatusType.warning => CsIcons.statusWarning,
    CsStatusType.success => CsIcons.statusPositive,
    CsStatusType.info => CsIcons.statusInfo,
    CsStatusType.stopped => CsIcons.statusStopped,
    CsStatusType.pending => CsIcons.statusPending,
    CsStatusType.inProgress => CsIcons.statusInProgress,
    CsStatusType.notStarted => CsIcons.statusNotStarted,
    CsStatusType.log => CsIcons.dot,
    CsStatusType.loading => null,
  };

  /// Text and icon color of [type], or of [override] when set.
  static Color colorFor(CsColorScheme c, CsStatusType type, [CsStatusColor? override]) {
    if (override != null) {
      return switch (override) {
        CsStatusColor.red => c.textStatusError,
        CsStatusColor.grey => c.textStatusInactive,
        CsStatusColor.blue => c.textStatusInfo,
        CsStatusColor.green => c.textStatusSuccess,
        CsStatusColor.yellow => c.textStatusWarning,
      };
    }
    return switch (type) {
      CsStatusType.error => c.textStatusError,
      CsStatusType.warning => c.textStatusWarning,
      CsStatusType.success => c.textStatusSuccess,
      CsStatusType.info => c.textStatusInfo,
      _ => c.textStatusInactive,
    };
  }

  String _defaultLabel(CsStrings s) => switch (type) {
    CsStatusType.error => s.error,
    CsStatusType.warning => s.warning,
    CsStatusType.success => s.success,
    CsStatusType.info => s.info,
    CsStatusType.stopped => s.stopped,
    CsStatusType.pending => s.pending,
    CsStatusType.inProgress => s.inProgress,
    CsStatusType.loading => s.loading,
    CsStatusType.notStarted => s.notStarted,
    CsStatusType.log => '',
  };

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = colorFor(cs.colors, type, colorOverride);
    final icon = iconFor(type);
    final glyph = type == CsStatusType.loading
        ? CsSpinner(semanticLabel: '', dangerouslySetColor: color)
        : CsIcon(icon!, size: iconSize, dangerouslySetColor: color);
    final label = iconAriaLabel ?? _defaultLabel(context.csStrings);
    final textStyle = DefaultTextStyle.of(context).style.merge(cs.body).copyWith(color: color);
    final content =
        child ??
        (text == null
            ? null
            : Text(
                text!,
                maxLines: wrapText ? null : 1,
                overflow: wrapText ? null : TextOverflow.ellipsis,
                softWrap: wrapText,
              ));
    return Semantics(
      label: label.isEmpty ? null : label,
      child: DefaultTextStyle(
        style: textStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(height: CsTypeScale.bodyM.lineHeight, child: Center(child: glyph)),
            ),
            if (content != null) ...[
              const SizedBox(width: CsSpace.xxs),
              wrapText ? Flexible(child: content) : Flexible(child: content),
            ],
          ],
        ),
      ),
    );
  }
}
