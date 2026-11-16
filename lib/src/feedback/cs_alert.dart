import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../navigation/cs_link.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_message_layout.dart';

/// Alert types (Cloudscape `type`), each with its own icon and colors.
enum CsAlertType { success, error, warning, info }

/// Copy for [CsAlert] (Cloudscape `i18nStrings`). Unset fields fall back to
/// [CsStrings] ("Success", "Error", "Warning", "Info") and "Dismiss alert".
@immutable
class CsAlertI18nStrings {
  const CsAlertI18nStrings({
    this.successIconAriaLabel,
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    this.infoIconAriaLabel,
    this.dismissAriaLabel,
  });

  final String? successIconAriaLabel;
  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;
  final String? infoIconAriaLabel;

  /// Accessible name of the dismiss button. Defaults to "Dismiss alert".
  final String? dismissAriaLabel;
}

/// Cloudscape's `Alert`: a short, important message in the context of a
/// page or form, such as a warning before a destructive action or a
/// constraint the user should know about.
///
/// ```dart
/// const CsAlert(
///   type: CsAlertType.warning,
///   header: 'Instance is running',
///   content: 'Stop i-0abc123 before you change its instance type.',
/// )
///
/// CsAlert(
///   type: CsAlertType.error,
///   header: 'Could not delete bucket',
///   content: 'example-bucket is not empty.',
///   action: CsButton(text: 'Empty bucket', onPress: empty),
///   dismissible: true,
///   onDismiss: () => setState(() => _visible = false),
///   visible: _visible,
/// )
/// ```
///
/// Keep the alert mounted and drive [visible]: it fades in over Cloudscape's
/// 180ms `motion-duration-show-paced` when it appears, and collapses when it
/// is hidden. The action moves below the message when it would leave the
/// message less than 70% of the width, as it does at phone widths.
class CsAlert extends StatefulWidget {
  const CsAlert({
    super.key,
    this.type = CsAlertType.info,
    this.header,
    this.headerWidget,
    this.content,
    this.child,
    this.action,
    this.buttonText,
    this.onButtonPress,
    this.dismissible = false,
    this.onDismiss,
    this.dismissAriaLabel,
    this.statusIconAriaLabel,
    this.visible = true,
    this.i18nStrings,
    this.focusNode,
  });

  final CsAlertType type;

  /// Heading text, in bold.
  final String? header;

  /// Rich content in place of [header].
  final Widget? headerWidget;

  /// The message text.
  final String? content;

  /// Rich message content in place of [content]: text with links, a list.
  final Widget? child;

  /// An action next to the message. Cloudscape's guidelines allow a button
  /// only.
  final Widget? action;

  /// Shows a normal button with this text as the action. Ignored when
  /// [action] is set (Cloudscape deprecates it in favor of `action`).
  final String? buttonText;

  /// Called when the [buttonText] button is pressed (Cloudscape
  /// `onButtonClick`).
  final VoidCallback? onButtonPress;

  /// Shows a close button that calls [onDismiss].
  final bool dismissible;
  final VoidCallback? onDismiss;

  /// Accessible name of the dismiss button. [i18nStrings] wins when both
  /// are set, as in Cloudscape.
  final String? dismissAriaLabel;

  /// Accessible name of the status icon. [i18nStrings] wins when both are
  /// set. Defaults to the type name ("Warning").
  final String? statusIconAriaLabel;

  /// Shows the alert. Hidden alerts take no space.
  final bool visible;
  final CsAlertI18nStrings? i18nStrings;

  /// Focus node of the message group, so the page can move focus to the
  /// alert (Cloudscape's `ref.focus()`), for example after a failed submit.
  final FocusNode? focusNode;

  /// Icon of [type].
  static CsIconData iconFor(CsAlertType type) => switch (type) {
    CsAlertType.error => CsIcons.statusNegative,
    CsAlertType.warning => CsIcons.statusWarning,
    CsAlertType.success => CsIcons.statusPositive,
    CsAlertType.info => CsIcons.statusInfo,
  };

  @override
  State<CsAlert> createState() => _CsAlertState();
}

class _CsAlertState extends State<CsAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: CsDurations.showPaced);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.visible && _fade.value == 0 && !_fade.isAnimating) _show();
  }

  @override
  void didUpdateWidget(CsAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _show();
    if (!widget.visible) _fade.value = 0;
  }

  void _show() {
    if (CsMotion.reduceMotion(context)) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  String _iconLabel(CsStrings strings) {
    final i = widget.i18nStrings;
    final fromI18n = switch (widget.type) {
      CsAlertType.success => i?.successIconAriaLabel,
      CsAlertType.error => i?.errorIconAriaLabel,
      CsAlertType.warning => i?.warningIconAriaLabel,
      CsAlertType.info => i?.infoIconAriaLabel,
    };
    return fromI18n ??
        widget.statusIconAriaLabel ??
        switch (widget.type) {
          CsAlertType.success => strings.success,
          CsAlertType.error => strings.error,
          CsAlertType.warning => strings.warning,
          CsAlertType.info => strings.info,
        };
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    final strings = context.csStrings;
    final outer = context.cs.colors;
    final (border, background) = switch (widget.type) {
      CsAlertType.error => (outer.borderStatusError, outer.backgroundAlertError),
      CsAlertType.warning => (outer.borderStatusWarning, outer.backgroundAlertWarning),
      CsAlertType.success => (outer.borderStatusSuccess, outer.backgroundAlertSuccess),
      CsAlertType.info => (outer.borderStatusInfo, outer.backgroundAlertInfo),
    };

    final alert = FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: CsCurves.showPaced),
      child: CsVisualContext(
        context: CsVisualContextName.alert,
        child: Builder(
          builder: (context) {
            final cs = context.cs;
            final c = cs.colors;
            final iconColor = switch (widget.type) {
              CsAlertType.error => c.textAlertIconError,
              CsAlertType.warning => c.textAlertIconWarning,
              CsAlertType.success => c.textAlertIconSuccess,
              CsAlertType.info => c.textAlertIconInfo,
            };
            final textStyle = cs.text(CsTypeScale.bodyM).copyWith(color: c.textAlertDefault);
            final textMargin = EdgeInsets.symmetric(vertical: cs.space.scaledXxs + CsBorderWidth.button);

            final headerSlot = widget.headerWidget ?? (widget.header != null ? Text(widget.header!) : null);
            final contentSlot = widget.child ?? (widget.content != null ? Text(widget.content!) : null);

            final message = Padding(
              padding: textMargin,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CsIcon(
                    CsAlert.iconFor(widget.type),
                    semanticLabel: _iconLabel(strings),
                    dangerouslySetColor: iconColor,
                  ),
                  const SizedBox(width: CsSpace.xxs * 2),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: CsSpace.alertMessageRight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (headerSlot != null)
                            CsVisualContext(
                              context: CsVisualContextName.alertHeader,
                              child: Builder(
                                builder: (context) => DefaultTextStyle(
                                  style: textStyle.copyWith(
                                    fontWeight: CsFontTokens.fontWeightAlertHeader,
                                    color: context.cs.colors.textAlertDefault,
                                  ),
                                  child: Semantics(header: true, child: headerSlot),
                                ),
                              ),
                            ),
                          ?contentSlot,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            final action =
                widget.action ??
                (widget.buttonText != null ? CsButton(text: widget.buttonText, onPress: widget.onButtonPress) : null);

            final body = CsMessageActionLayout(
              gap: CsSpace.alertActionLeft,
              wrappedIndent: CsSize.iconNormal + CsSpace.xs,
              wrappedBottom: CsSpace.xxs,
              message: Focus(
                focusNode: widget.focusNode,
                canRequestFocus: widget.focusNode != null,
                skipTraversal: true,
                child: Semantics(container: true, explicitChildNodes: true, child: message),
              ),
              action: action == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
                      child: action,
                    ),
            );

            final dismissLabel = widget.i18nStrings?.dismissAriaLabel ?? widget.dismissAriaLabel ?? 'Dismiss alert';

            return Container(
              padding: EdgeInsets.symmetric(vertical: cs.space.alertVertical, horizontal: CsSpace.alertHorizontal),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(CsBorderRadius.alert),
                border: CsRing.inside(border, width: CsBorderWidth.alert),
              ),
              child: DefaultTextStyle(
                style: textStyle,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: body),
                    if (widget.dismissible)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
                        child: Transform.translate(
                          offset: Offset(CsSpace.xxs * (Directionality.of(context) == TextDirection.rtl ? -1 : 1), 0),
                          child: CsButton(
                            variant: CsButtonVariant.icon,
                            icon: CsIcons.close,
                            semanticLabel: dismissLabel,
                            onPress: widget.onDismiss,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    // Cloudscape underlines links inside alerts.
    return CsLinkDefaults(variant: CsLinkVariant.primary, child: alert);
  }
}
