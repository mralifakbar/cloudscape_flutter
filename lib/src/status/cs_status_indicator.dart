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

/// How the icon and text flow (Cloudscape's internal `__display`).
enum CsStatusDisplay {
  /// The icon keeps its own column and wrapped lines align under the text.
  /// The default.
  inlineBlock,

  /// The icon flows with the text like a glyph, and wrapped lines start
  /// under the icon. Use inside a sentence or a table cell.
  inline,
}

/// Cloudscape's `StatusIndicator`: an icon and short text for the state of a
/// resource or process, such as "Running", "Stopped" or "3 errors".
///
/// ```dart
/// const CsStatusIndicator(type: CsStatusType.success, text: 'Available')
/// const CsStatusIndicator(type: CsStatusType.loading, text: 'Deploying')
/// ```
///
/// Status is never color alone: each type has its own icon. The icon is
/// announced before the text ("Error, 3 failed checks"); pass
/// [iconAriaLabel] when the text alone does not describe the status.
class CsStatusIndicator extends StatefulWidget {
  const CsStatusIndicator({
    super.key,
    this.type = CsStatusType.success,
    this.text,
    this.child,
    this.colorOverride,
    this.wrapText = true,
    this.iconAriaLabel,
    this.iconSize = CsIconSize.normal,
    this.display = CsStatusDisplay.inlineBlock,
    this.animate = false,
    this.embedded = false,
  });

  /// The status. Defaults to success, like Cloudscape.
  final CsStatusType type;

  /// A short text fragment that communicates the status.
  final String? text;

  /// Custom content in place of [text], for example a link.
  final Widget? child;

  /// Replaces the color of the type, keeping its icon.
  final CsStatusColor? colorOverride;

  /// False keeps the text on one line with an ellipsis.
  final bool wrapText;

  /// Accessible name of the icon, announced before the text. Defaults to the
  /// status name ("Error", "Success"); pass an empty string to announce only
  /// the text.
  final String? iconAriaLabel;

  /// Icon size. The loading spinner follows it.
  final CsIconSize iconSize;

  /// Flow of icon and text.
  final CsStatusDisplay display;

  /// Fade in and, for errors, shake the icon once when first shown
  /// (Cloudscape `__animate`, used by form errors). Reduced motion skips it.
  final bool animate;

  /// Leaves out the status background, for status indicators embedded in
  /// other components. The background tokens are transparent in the
  /// default theme, so this only matters with a custom theme.
  final bool embedded;

  /// Icon of [type]; null for [CsStatusType.loading], which shows a spinner.
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

  /// Background of [type] (`color-background-status-indicator-*`), or of
  /// [override] when set.
  static Color backgroundFor(CsColorScheme c, CsStatusType type, [CsStatusColor? override]) {
    if (override != null) {
      return switch (override) {
        CsStatusColor.red => c.backgroundStatusIndicatorError,
        CsStatusColor.grey => c.backgroundStatusIndicatorNeutral,
        CsStatusColor.blue => c.backgroundStatusIndicatorInfo,
        CsStatusColor.green => c.backgroundStatusIndicatorSuccess,
        CsStatusColor.yellow => c.backgroundStatusIndicatorWarning,
      };
    }
    return switch (type) {
      CsStatusType.error => c.backgroundStatusIndicatorError,
      CsStatusType.warning => c.backgroundStatusIndicatorWarning,
      CsStatusType.success => c.backgroundStatusIndicatorSuccess,
      CsStatusType.info => c.backgroundStatusIndicatorInfo,
      _ => c.backgroundStatusIndicatorNeutral,
    };
  }

  /// The default spoken name of [type].
  static String labelFor(CsStrings s, CsStatusType type) => switch (type) {
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
  State<CsStatusIndicator> createState() => _CsStatusIndicatorState();
}

class _CsStatusIndicatorState extends State<CsStatusIndicator> with SingleTickerProviderStateMixin {
  AnimationController? _entrance;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      // `motion-duration-refresh-only-medium`: fade-in of the container and a
      // horizontal shake of the error icon.
      _entrance = AnimationController(vsync: this, duration: CsDurations.refreshOnlyMedium);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = _entrance;
    if (c != null && c.status == AnimationStatus.dismissed) {
      if (CsMotion.reduceMotion(context)) {
        c.value = 1;
      } else {
        c.forward();
      }
    }
  }

  @override
  void dispose() {
    _entrance?.dispose();
    super.dispose();
  }

  Widget _glyph(Color color) {
    final w = widget;
    if (w.type == CsStatusType.loading) {
      final spinner = CsSpinner(semanticLabel: '', dangerouslySetColor: color);
      if (w.iconSize == CsIconSize.normal || w.iconSize == CsIconSize.small) return spinner;
      return SizedBox.square(
        dimension: w.iconSize.dimension,
        child: FittedBox(child: spinner),
      );
    }
    Widget icon = CsIcon(CsStatusIndicator.iconFor(w.type)!, size: w.iconSize, dangerouslySetColor: color);
    final c = _entrance;
    if (c != null && w.type == CsStatusType.error) {
      // `awsui-motion-shake-horizontally`: -5px, +5px at 50%, then rest.
      icon = AnimatedBuilder(
        animation: c,
        builder: (context, child) {
          final t = c.value;
          final dx = t < 0.5 ? -5 + 20 * t : 5 * (1 - CsCurves.refreshOnlyA.transform((t - 0.5) * 2));
          return Transform.translate(offset: Offset(t == 0 || t == 1 ? 0 : dx, 0), child: child);
        },
        child: icon,
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final cs = context.cs;
    final color = CsStatusIndicator.colorFor(cs.colors, w.type, w.colorOverride);
    final glyph = ExcludeSemantics(child: _glyph(color));
    final label = w.iconAriaLabel ?? CsStatusIndicator.labelFor(context.csStrings, w.type);
    final textStyle = DefaultTextStyle.of(context).style.merge(cs.body).copyWith(color: color);
    final lineHeight = w.iconSize.dimension > CsTypeScale.bodyM.lineHeight
        ? w.iconSize.dimension
        : CsTypeScale.bodyM.lineHeight;

    Widget body;
    if (w.display == CsStatusDisplay.inline && w.child == null && w.text != null) {
      body = Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox(
                height: lineHeight,
                child: Center(widthFactor: 1, child: glyph),
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: w.text),
          ],
        ),
        maxLines: w.wrapText ? null : 1,
        overflow: w.wrapText ? null : TextOverflow.ellipsis,
        softWrap: w.wrapText,
      );
    } else {
      final content =
          w.child ??
          (w.text == null
              ? null
              : Text(
                  w.text!,
                  maxLines: w.wrapText ? null : 1,
                  overflow: w.wrapText ? null : TextOverflow.ellipsis,
                  softWrap: w.wrapText,
                ));
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: lineHeight,
            child: Center(widthFactor: 1, child: glyph),
          ),
          if (content != null) ...[const SizedBox(width: CsSpace.xxs), Flexible(child: content)],
        ],
      );
    }

    final background = w.embedded ? null : CsStatusIndicator.backgroundFor(cs.colors, w.type, w.colorOverride);
    if (background != null && background.a > 0) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(CsBorderRadius.statusIndicator),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: CsSpace.statusIndicatorPaddingHorizontal),
          child: body,
        ),
      );
    }

    final c = _entrance;
    if (c != null) {
      body = FadeTransition(
        opacity: CurvedAnimation(parent: c, curve: CsCurves.refreshOnlyA),
        child: body,
      );
    }

    return Semantics(
      label: label.isEmpty ? null : label,
      child: DefaultTextStyle(style: textStyle, child: body),
    );
  }
}
