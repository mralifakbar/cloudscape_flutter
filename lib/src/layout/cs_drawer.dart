import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../feedback/cs_spinner.dart';
import '../icons/icons.dart';
import '../overlays/cs_scrim.dart';
import '../system/cs_focus_trap.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// How a [CsDrawer] is positioned (Cloudscape `position`).
enum CsDrawerPosition {
  /// In the flow of its parent, like any panel. The default; this is how
  /// the app layout shows drawer content.
  static,

  /// Same as [static] in Flutter; scroll stickiness comes from the parent.
  sticky,

  /// Over its parent, aligned to [CsDrawer.placement]. Put the drawer in a
  /// [Stack] (with `Positioned.fill`) over the content it covers.
  absolute,

  /// Over the whole screen, aligned to [CsDrawer.placement], in the app
  /// overlay. Driven by [CsDrawer.open].
  fixed,
}

/// Which edge an overlay drawer attaches to (Cloudscape `placement`).
enum CsDrawerPlacement { start, end, top, bottom }

/// Why a drawer asked to close (Cloudscape `CloseDetail.method`).
enum CsDrawerCloseMethod { closeAction, backdropClick, escape }

/// The close button of a drawer (Cloudscape `closeAction`).
@immutable
class CsDrawerCloseAction {
  const CsDrawerCloseAction({this.ariaLabel, this.disabled = false, this.disabledReason, this.icon = CsIcons.close});

  /// Defaults to the shared "Close" string.
  final String? ariaLabel;
  final bool disabled;
  final String? disabledReason;
  final CsIconData icon;
}

/// Copy for [CsDrawer].
@immutable
class CsDrawerI18nStrings {
  const CsDrawerI18nStrings({this.loadingText});

  /// Text next to the spinner while loading. Defaults to "Loading".
  final String? loadingText;
}

/// Cloudscape's `Drawer`: a panel with a header, scrolling content and an
/// optional sticky footer. Put it in the app layout's tools or drawers, or
/// show it on its own over the content with [position] `fixed` or
/// `absolute`.
///
/// ```dart
/// CsDrawer(
///   header: const Text('Instance details'),
///   footer: CsButton(text: 'Stop instance', onPress: () {}),
///   child: const Text('i-0abc123'),
/// )
/// ```
///
/// Visual refresh: `color-background-drawer`, the header in the panel header
/// font (heading-m) over a `color-border-panel-header` divider, content
/// padded with the panel side tokens, and a footer on
/// `color-background-container-content` under a divider. Overlay drawers
/// slide in from their edge over 250ms (`motion-duration-complex`), close
/// with Escape, the close button and, with [backdrop], a tap outside, and
/// trap focus while open.
class CsDrawer extends StatefulWidget {
  const CsDrawer({
    super.key,
    this.header,
    this.headerActions,
    this.child,
    this.footer,
    this.stickyFooter = true,
    this.loading = false,
    this.disableContentPaddings = false,
    this.i18nStrings = const CsDrawerI18nStrings(),
    this.position = CsDrawerPosition.static,
    this.placement = CsDrawerPlacement.end,
    this.size = 320,
    this.open = true,
    this.onClose,
    this.closeAction,
    this.hideCloseAction = false,
    this.backdrop = false,
    this.autoFocus = true,
    this.trapFocus = true,
    this.semanticLabel,
  });

  /// Drawer title, usually a [Text]; styled as the panel header.
  final Widget? header;

  /// Buttons next to the header.
  final Widget? headerActions;

  /// The drawer content (Cloudscape `children`).
  final Widget? child;

  /// Content at the bottom, such as actions.
  final Widget? footer;

  /// Keeps the footer visible while the content scrolls. When false the
  /// footer scrolls with the content.
  final bool stickyFooter;

  /// Shows a spinner instead of the content.
  final bool loading;
  final bool disableContentPaddings;
  final CsDrawerI18nStrings i18nStrings;
  final CsDrawerPosition position;
  final CsDrawerPlacement placement;

  /// Width of start and end drawers, height of top and bottom ones, for the
  /// `absolute` and `fixed` positions. Phones use the full screen width.
  final double size;

  /// Whether an overlay drawer is shown. Keep the drawer mounted and drive
  /// this so it can animate out.
  final bool open;

  /// Asked to close, with the reason. The close button only shows when this
  /// is set (and [hideCloseAction] is false).
  final ValueChanged<CsDrawerCloseMethod>? onClose;
  final CsDrawerCloseAction? closeAction;
  final bool hideCloseAction;

  /// Dims the content behind an overlay drawer; tapping it closes the drawer.
  final bool backdrop;

  /// Moves focus into an overlay drawer when it opens.
  final bool autoFocus;

  /// Keeps Tab inside an open overlay drawer.
  final bool trapFocus;

  /// Name of the drawer region (Cloudscape `ariaLabel`).
  final String? semanticLabel;

  @override
  State<CsDrawer> createState() => _CsDrawerState();
}

class _CsDrawerState extends State<CsDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final OverlayPortalController _portal = OverlayPortalController();

  bool get _overlay => widget.position == CsDrawerPosition.fixed || widget.position == CsDrawerPosition.absolute;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: CsDurations.complex, value: widget.open ? 1 : 0)
      ..addStatusListener((s) {
        if (s == AnimationStatus.dismissed && mounted) setState(() {});
      });
    if (widget.position == CsDrawerPosition.fixed) _portal.show();
  }

  @override
  void didUpdateWidget(CsDrawer old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) {
      if (CsMotion.reduceMotion(context)) {
        _anim.value = widget.open ? 1 : 0;
      } else {
        widget.open ? _anim.forward() : _anim.reverse();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _panel(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final strings = context.csStrings;
    final showClose = widget.onClose != null && !widget.hideCloseAction;
    final action = widget.closeAction ?? const CsDrawerCloseAction();

    final closeButton = showClose
        ? CsButton(
            variant: CsButtonVariant.icon,
            icon: action.icon,
            semanticLabel: action.ariaLabel ?? strings.close,
            disabled: action.disabled,
            disabledReason: action.disabledReason,
            onPress: () => widget.onClose?.call(CsDrawerCloseMethod.closeAction),
          )
        : null;

    Widget? header;
    if (widget.header != null || widget.headerActions != null) {
      header = Container(
        padding: EdgeInsetsDirectional.only(
          top: cs.space.panelHeaderVertical,
          bottom: cs.space.panelHeaderVertical,
          start: CsSpace.panelSideLeft,
          end: showClose ? CsSpace.l + cs.space.scaledXxl : cs.space.panelSideRight,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderPanelHeader)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CsSpace.xs,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                headingLevel: 2,
                child: DefaultTextStyle.merge(
                  style: cs.text(CsTypeScale.headingM),
                  child: widget.header ?? const SizedBox(),
                ),
              ),
            ),
            ?widget.headerActions,
          ],
        ),
      );
    }

    Widget content;
    if (widget.loading) {
      final text = widget.i18nStrings.loadingText ?? strings.loading;
      content = Padding(
        padding: EdgeInsetsDirectional.only(
          top: cs.space.panelContentTop,
          start: CsSpace.panelSideLeft,
          end: cs.space.panelSideRight,
          bottom: cs.space.panelContentBottom,
        ),
        child: Semantics(
          liveRegion: true,
          label: text,
          child: Row(
            spacing: CsSpace.xs,
            children: [
              const CsSpinner(),
              Flexible(
                child: Text(text, style: cs.text(CsTypeScale.bodyM, color: CsColor.textStatusInactive)),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Padding(
        padding: widget.disableContentPaddings || widget.child == null
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.only(
                top: cs.space.panelContentTop,
                start: CsSpace.panelSideLeft,
                end: cs.space.panelSideRight,
                bottom: cs.space.panelContentBottom,
              ),
        child: DefaultTextStyle.merge(style: cs.body, child: widget.child ?? const SizedBox()),
      );
    }

    Widget? footer;
    if (widget.footer != null) {
      footer = Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.only(
          top: cs.space.panelContentTop,
          bottom: cs.space.panelContentTop,
          start: CsSpace.panelSideLeft,
          end: cs.space.panelSideRight,
        ),
        decoration: BoxDecoration(
          color: c.backgroundContainerContent,
          border: Border(top: BorderSide(color: c.borderPanelHeader)),
        ),
        child: widget.footer,
      );
    }

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight.isFinite;
        if (!bounded) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [?header, content, ?footer],
          );
        }
        if (widget.stickyFooter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              Expanded(child: SingleChildScrollView(child: content)),
              ?footer,
            ],
          );
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?header,
                  Expanded(child: content),
                  ?footer,
                ],
              ),
            ),
          ),
        );
      },
    );

    final border = BorderSide(color: c.borderPanelHeader);
    final decoration = BoxDecoration(
      color: c.backgroundDrawer,
      border: !_overlay
          ? null
          : switch (widget.placement) {
              CsDrawerPlacement.end => BorderDirectional(start: border),
              CsDrawerPlacement.start => BorderDirectional(end: border),
              CsDrawerPlacement.top => Border(bottom: border),
              CsDrawerPlacement.bottom => Border(top: border),
            },
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: decoration,
        child: Stack(
          children: [
            body,
            if (closeButton != null)
              PositionedDirectional(top: CsSpace.staticM - 6, end: cs.space.scaledL - 6, child: closeButton),
          ],
        ),
      ),
    );
  }

  Widget _overlayLayer(BuildContext context, {required bool fullScreen}) {
    final narrow = context.csIsNarrow;
    final horizontal = widget.placement == CsDrawerPlacement.start || widget.placement == CsDrawerPlacement.end;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final begin = switch (widget.placement) {
      CsDrawerPlacement.start => Offset(rtl ? 1 : -1, 0),
      CsDrawerPlacement.end => Offset(rtl ? -1 : 1, 0),
      CsDrawerPlacement.top => const Offset(0, -1),
      CsDrawerPlacement.bottom => const Offset(0, 1),
    };
    final align = switch (widget.placement) {
      CsDrawerPlacement.start => AlignmentDirectional.centerStart,
      CsDrawerPlacement.end => AlignmentDirectional.centerEnd,
      CsDrawerPlacement.top => AlignmentDirectional.topCenter,
      CsDrawerPlacement.bottom => AlignmentDirectional.bottomCenter,
    };
    final curved = CurvedAnimation(parent: _anim, curve: CsCurves.expressive);
    Widget panel = _panel(context);
    panel = CsFocusTrap(
      disableFocusTrap: !widget.trapFocus || !widget.open,
      disableAutoFocus: !widget.autoFocus,
      onEscPress: () => widget.onClose?.call(CsDrawerCloseMethod.escape),
      child: panel,
    );
    panel = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => widget.onClose?.call(CsDrawerCloseMethod.escape),
      },
      child: panel,
    );
    final sized = SizedBox(
      width: horizontal ? (narrow && fullScreen ? double.infinity : widget.size) : double.infinity,
      height: horizontal ? double.infinity : widget.size,
      child: panel,
    );
    return Stack(
      children: [
        if (widget.backdrop)
          Positioned.fill(
            child: FadeTransition(
              opacity: curved,
              child: CsScrim(onPress: () => widget.onClose?.call(CsDrawerCloseMethod.backdropClick)),
            ),
          ),
        Align(
          alignment: align,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
            child: sized,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_overlay) return _panel(context);
    final visible = widget.open || _anim.status != AnimationStatus.dismissed;
    if (widget.position == CsDrawerPosition.absolute) {
      if (!visible) return const SizedBox.shrink();
      return _overlayLayer(context, fullScreen: false);
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => visible ? _overlayLayer(context, fullScreen: true) : const SizedBox.shrink(),
      child: const SizedBox.shrink(),
    );
  }
}
