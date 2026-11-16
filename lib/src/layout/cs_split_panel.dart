import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/icons.dart';
import '../overlays/cs_routes.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'internal/cs_resize_handle.dart';
import 'internal/cs_split_panel_scope.dart';

export 'internal/cs_split_panel_scope.dart' show CsSplitPanelPosition;

/// What closing the split panel does (Cloudscape `closeBehavior`).
enum CsSplitPanelCloseBehavior {
  /// Collapses to a bar (bottom) or a slim column (side) with an open button.
  collapse,

  /// Removes the panel; the app layout shows an open trigger instead.
  hide,
}

/// Copy for [CsSplitPanel] (Cloudscape `SplitPanelProps.I18nStrings`).
@immutable
class CsSplitPanelI18nStrings {
  const CsSplitPanelI18nStrings({
    this.closeButtonAriaLabel = 'Close panel',
    this.openButtonAriaLabel = 'Open panel',
    this.preferencesTitle = 'Split panel preferences',
    this.preferencesPositionLabel = 'Split panel position',
    this.preferencesPositionDescription = 'Choose the default split panel position for the service.',
    this.preferencesPositionSide = 'Side',
    this.preferencesPositionBottom = 'Bottom',
    this.preferencesConfirm = 'Confirm',
    this.preferencesCancel = 'Cancel',
    this.preferencesCloseAriaLabel = 'Close',
    this.preferencesButtonAriaLabel = 'Preferences',
    this.resizeHandleAriaLabel = 'Resize split panel',
    this.resizeHandleTooltipText,
  });

  final String closeButtonAriaLabel;
  final String openButtonAriaLabel;
  final String preferencesTitle;
  final String preferencesPositionLabel;
  final String preferencesPositionDescription;
  final String preferencesPositionSide;
  final String preferencesPositionBottom;
  final String preferencesConfirm;
  final String preferencesCancel;
  final String preferencesCloseAriaLabel;

  /// Label of the settings button in the header.
  final String preferencesButtonAriaLabel;
  final String resizeHandleAriaLabel;
  final String? resizeHandleTooltipText;
}

/// Cloudscape's `SplitPanel`: a secondary panel, usually details of the
/// selected table item, shown under or beside the main content of a
/// `CsAppLayout`.
///
/// ```dart
/// CsAppLayout(
///   content: const Text('Instances table'),
///   splitPanel: const CsSplitPanel(
///     header: 'i-0abc123',
///     child: Text('Instance details'),
///   ),
/// )
/// ```
///
/// Inside an app layout the panel gets its open state, position and size
/// from the layout and offers a resize handle, a preferences button (bottom
/// or side) and a close button. On phones (at or below 688px) it always docks
/// at the bottom and opens full screen. Used on its own it renders as an
/// open bottom panel that collapses into its header.
class CsSplitPanel extends StatefulWidget {
  const CsSplitPanel({
    super.key,
    required this.child,
    this.header,
    this.headerWidget,
    this.headerActions,
    this.headerDescription,
    this.headerInfo,
    this.headerBefore,
    this.closeBehavior = CsSplitPanelCloseBehavior.collapse,
    this.hidePreferencesButton = false,
    this.i18nStrings = const CsSplitPanelI18nStrings(),
    this.semanticLabel,
  });

  /// The panel content (Cloudscape `children`).
  final Widget child;

  /// Panel title.
  final String? header;

  /// Custom title in place of [header].
  final Widget? headerWidget;

  /// Buttons next to the title.
  final Widget? headerActions;

  /// Text under the title.
  final String? headerDescription;

  /// An info link after the title.
  final Widget? headerInfo;

  /// Content before the title, such as a status icon.
  final Widget? headerBefore;
  final CsSplitPanelCloseBehavior closeBehavior;
  final bool hidePreferencesButton;
  final CsSplitPanelI18nStrings i18nStrings;

  /// Name of the panel region. Defaults to [header].
  final String? semanticLabel;

  @override
  State<CsSplitPanel> createState() => _CsSplitPanelState();
}

class _CsSplitPanelState extends State<CsSplitPanel> {
  bool _standaloneOpen = true;

  Future<void> _openPreferences(CsSplitPanelScope scope) async {
    final result = await Navigator.of(context).push<CsSplitPanelPosition>(
      CsDialogRoute(
        semanticLabel: widget.i18nStrings.preferencesTitle,
        builder: (context) =>
            _Preferences(initial: scope.position, sideAvailable: scope.sideAvailable, strings: widget.i18nStrings),
      ),
    );
    if (result != null && result != scope.position) scope.onPositionChange(result);
  }

  Widget _title(BuildContext context) {
    final cs = context.cs;
    final title =
        widget.headerWidget ??
        Text(widget.header ?? '', style: cs.text(CsTypeScale.headingM), maxLines: 2, overflow: TextOverflow.ellipsis);
    return Semantics(
      header: true,
      headingLevel: 2,
      child: DefaultTextStyle.merge(style: cs.text(CsTypeScale.headingM), child: title),
    );
  }

  Widget _header(BuildContext context, {required CsSplitPanelScope? scope, required bool open, required bool side}) {
    final cs = context.cs;
    final s = widget.i18nStrings;
    final toggle = CsButton(
      variant: CsButtonVariant.icon,
      icon: open ? (side ? CsIcons.angleRight : CsIcons.angleDown) : (side ? CsIcons.angleLeft : CsIcons.angleUp),
      semanticLabel: open ? s.closeButtonAriaLabel : s.openButtonAriaLabel,
      expanded: open,
      onPress: scope?.onToggle ?? () => setState(() => _standaloneOpen = !_standaloneOpen),
    );
    final prefs = scope != null && !widget.hidePreferencesButton && open && !scope.narrow
        ? CsButton(
            variant: CsButtonVariant.icon,
            icon: CsIcons.settings,
            semanticLabel: s.preferencesButtonAriaLabel,
            onPress: () => _openPreferences(scope),
          )
        : null;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: side ? CsSpace.panelSideLeft : cs.space.layoutContentHorizontal,
        end: side ? cs.space.panelSideRight : cs.space.layoutContentHorizontal,
        top: cs.space.panelHeaderVertical,
        bottom: cs.space.panelHeaderVertical,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CsSpace.xs,
        children: [
          if (widget.headerBefore != null) widget.headerBefore!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: CsSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [_title(context), ?widget.headerInfo],
                ),
                if (open && widget.headerDescription != null)
                  Text(
                    widget.headerDescription!,
                    style: cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingSecondary),
                  ),
              ],
            ),
          ),
          if (open && widget.headerActions != null) widget.headerActions!,
          ?prefs,
          if (widget.closeBehavior == CsSplitPanelCloseBehavior.collapse || open) toggle,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final scope = CsSplitPanelScope.maybeOf(context);
    final open = scope?.open ?? _standaloneOpen;
    final side = scope != null && scope.position == CsSplitPanelPosition.side && !scope.narrow;
    final label = widget.semanticLabel ?? widget.header;

    if (!open && widget.closeBehavior == CsSplitPanelCloseBehavior.hide && scope != null) {
      return const SizedBox.shrink();
    }

    if (side && !open) {
      // Collapsed side panel: a slim column with the open button
      // (`space-layout-toggle-padding * 2 + space-layout-toggle-diameter`).
      return Semantics(
        container: true,
        label: label,
        child: Container(
          width: CsSpace.layoutTogglePadding * 2 + CsSpace.layoutToggleDiameter,
          padding: EdgeInsets.only(top: cs.space.scaledS),
          decoration: BoxDecoration(
            color: c.backgroundLayoutPanelContent,
            border: BorderDirectional(start: BorderSide(color: c.borderDividerPanelSide)),
          ),
          alignment: Alignment.topCenter,
          child: CsButton(
            variant: CsButtonVariant.icon,
            icon: CsIcons.angleLeft,
            semanticLabel: widget.i18nStrings.openButtonAriaLabel,
            expanded: false,
            onPress: scope.onToggle,
          ),
        ),
      );
    }

    final header = _header(context, scope: scope, open: open, side: side);
    final content = Padding(
      padding: EdgeInsetsDirectional.only(
        start: side ? CsSpace.panelSideLeft : cs.space.layoutContentHorizontal,
        end: side ? cs.space.panelSideRight : cs.space.layoutContentHorizontal,
        bottom: cs.space.panelSplitBottom,
      ),
      child: DefaultTextStyle.merge(style: cs.body, child: widget.child),
    );

    Widget? handle;
    if (scope != null && open && !scope.narrow) {
      handle = CsResizeHandle(
        axis: side ? CsResizeAxis.horizontal : CsResizeAxis.vertical,
        size: scope.size,
        min: scope.minSize,
        max: scope.maxSize,
        growDirection: -1,
        semanticLabel: widget.i18nStrings.resizeHandleAriaLabel,
        tooltip: widget.i18nStrings.resizeHandleTooltipText,
        onResizeTo: scope.onResize,
        onDrag: (d) {
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final delta = side && rtl ? -d : d;
          scope.onResize((scope.size - delta).clamp(scope.minSize, scope.maxSize).toDouble());
        },
      );
    }

    final bounded = scope != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (handle != null && !side) handle,
        header,
        if (open)
          if (bounded) Expanded(child: SingleChildScrollView(child: content)) else content,
      ],
    );

    final decoration = side
        ? BoxDecoration(
            color: c.backgroundLayoutPanelContent,
            border: BorderDirectional(start: BorderSide(color: c.borderDividerPanelSide)),
          )
        : BoxDecoration(
            color: c.backgroundLayoutPanelContent,
            border: Border(top: BorderSide(color: c.borderDividerPanelBottom)),
            boxShadow: scope != null && !scope.narrow ? cs.shadows.splitBottom : null,
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: DecoratedBox(
        decoration: decoration,
        child: side
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?handle,
                  Expanded(child: body),
                ],
              )
            : body,
      ),
    );
  }
}

class _Preferences extends StatefulWidget {
  const _Preferences({required this.initial, required this.sideAvailable, required this.strings});

  final CsSplitPanelPosition initial;
  final bool sideAvailable;
  final CsSplitPanelI18nStrings strings;

  @override
  State<_Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<_Preferences> {
  late CsSplitPanelPosition _value = widget.initial;

  Widget _option(BuildContext context, CsSplitPanelPosition v, String label, {bool disabled = false}) {
    final cs = context.cs;
    final c = cs.colors;
    final selected = _value == v;
    return CsPressable(
      onPress: disabled ? null : () => setState(() => _value = v),
      disabled: disabled,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: label,
      excludeChildSemantics: true,
      scaleOnPress: false,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
        child: Row(
          spacing: CsSpace.xs,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: disabled
                    ? c.backgroundControlDisabled
                    : selected
                    ? c.backgroundControlChecked
                    : c.backgroundControlDefault,
                border: selected || disabled ? null : Border.all(color: c.borderControlDefault, width: 2),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.foregroundControlDefault),
                    )
                  : null,
            ),
            Text(label, style: cs.text(CsTypeScale.bodyM, color: disabled ? CsColor.textControlDisabled : null)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = widget.strings;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(CsSpace.l),
        decoration: BoxDecoration(
          color: cs.colors.backgroundContainerContent,
          borderRadius: BorderRadius.circular(CsBorderRadius.container),
          boxShadow: cs.shadows.modal,
        ),
        child: DefaultTextStyle(
          style: cs.body,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(CsSpace.l, CsSpace.m, CsSpace.s, CsSpace.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(s.preferencesTitle, style: cs.text(CsTypeScale.headingM)),
                      ),
                    ),
                    CsButton(
                      variant: CsButtonVariant.modalDismiss,
                      icon: CsIcons.close,
                      semanticLabel: s.preferencesCloseAriaLabel,
                      onPress: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.preferencesPositionLabel, style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold)),
                    Text(
                      s.preferencesPositionDescription,
                      style: cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary),
                    ),
                    const SizedBox(height: CsSpace.xs),
                    _option(context, CsSplitPanelPosition.bottom, s.preferencesPositionBottom),
                    _option(
                      context,
                      CsSplitPanelPosition.side,
                      s.preferencesPositionSide,
                      disabled: !widget.sideAvailable,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(CsSpace.l),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: CsSpace.xs,
                  children: [
                    CsButton(
                      variant: CsButtonVariant.link,
                      text: s.preferencesCancel,
                      onPress: () => Navigator.of(context).pop(),
                    ),
                    CsButton(
                      variant: CsButtonVariant.primary,
                      text: s.preferencesConfirm,
                      onPress: () => Navigator.of(context).pop(_value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
