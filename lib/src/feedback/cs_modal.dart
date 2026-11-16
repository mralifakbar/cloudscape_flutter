import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_scrim.dart';
import '../system/cs_focus_trap.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// Modal widths (Cloudscape `size`). [max] grows with the window up to the
/// largest width the guidelines allow.
enum CsModalSize {
  /// 320px.
  small(320),

  /// 600px. The default.
  medium(600),

  /// 820px.
  large(820),

  /// 1024px.
  xLarge(1024),

  /// 1280px.
  xxLarge(1280),

  /// The window width minus 120px (room for closed app layout panels and a
  /// 20px margin on each side).
  max(null);

  const CsModalSize(this.width);

  /// Fixed maximum width, or null for [max].
  final double? width;
}

/// Vertical placement of a modal (Cloudscape `position`).
enum CsModalPosition {
  /// Centered, re-centering as the content changes height. The default.
  center,

  /// Anchored near the top, growing downward. Use when content changes
  /// height while open, so the dialog does not jump.
  top,
}

/// Why a modal asked to close (Cloudscape `onDismiss` `reason`).
enum CsModalDismissReason {
  /// The close button in the header.
  closeButton,

  /// A tap on the backdrop.
  overlay,

  /// Escape, or the system back gesture or button.
  keyboard,
}

/// Cloudscape's `Modal`: a dialog that interrupts the page to collect a
/// decision or a short task (confirm a deletion, edit a setting), with a
/// header, scrollable content and a footer of actions.
///
/// Keep it mounted and drive [visible]; it never closes itself. Every
/// dismissal (close button, backdrop, Escape, back gesture) calls
/// [onDismiss] with its reason, and the parent sets [visible] to false:
///
/// ```dart
/// CsModal(
///   visible: _visible,
///   onDismiss: (_) => setState(() => _visible = false),
///   header: 'Delete instance',
///   footerActions: [
///     CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => setState(() => _visible = false)),
///     CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: delete),
///   ],
///   child: const Text('Permanently delete i-0abc123? You cannot undo this action.'),
/// )
/// ```
///
/// The modal renders in the root overlay, so where it sits in the tree does
/// not matter; the widget itself takes no space. It fades the backdrop in
/// and scales the dialog from 0.95 over Cloudscape's 115ms responsive
/// motion, and leaves along the same path. Focus moves into the modal (to
/// the close button), Tab cycles inside it and focus returns to the trigger
/// when it closes. On phones the dialog takes the full width minus a 12px
/// gutter on each side; the content scrolls and the footer stays visible.
///
/// For a one-off modal without managing state, use [showCsModal].
class CsModal extends StatefulWidget {
  const CsModal({
    super.key,
    required this.visible,
    this.onDismiss,
    this.header,
    this.headerWidget,
    this.child,
    this.footer,
    this.footerActions,
    this.size = CsModalSize.medium,
    this.position = CsModalPosition.center,
    this.hideDismissButton = false,
    this.closeAriaLabel,
    this.disableContentPaddings = false,
    this.width,
    this.height,
    this.useRootOverlay = true,
  });

  /// Shows the modal. Changes animate.
  final bool visible;

  /// Called when the user asks to close the modal. Set [visible] to false in
  /// response.
  final ValueChanged<CsModalDismissReason>? onDismiss;

  /// Title of the modal, a level 2 heading. Always provide one: screen
  /// readers announce it as the dialog's name.
  final String? header;

  /// Rich content in place of [header].
  final Widget? headerWidget;

  /// Body of the modal. Scrolls when it is taller than the window.
  final Widget? child;

  /// Footer content, below a divider. Usually the actions; see
  /// [footerActions] for the common layout.
  final Widget? footer;

  /// Buttons aligned to the end of the footer with an 8px gap (Cloudscape's
  /// `Box float="right"` with a horizontal `SpaceBetween`). They wrap on
  /// narrow screens. Ignored when [footer] is set.
  final List<Widget>? footerActions;
  final CsModalSize size;
  final CsModalPosition position;

  /// Hides the close button, so the user picks one of the footer actions.
  /// Escape, the backdrop and the back gesture still call [onDismiss].
  final bool hideDismissButton;

  /// Accessible name of the close button. Defaults to "Close modal".
  final String? closeAriaLabel;

  /// Removes the content padding, for content that brings its own (a
  /// table, an image).
  final bool disableContentPaddings;

  /// Fixed width in logical pixels, at least 320. Takes precedence over
  /// [size]; capped at the available width.
  final double? width;

  /// Fixed height in logical pixels. The content scrolls inside it; capped
  /// at the available height.
  final double? height;

  /// Render in the root overlay (above app bars and other navigators).
  final bool useRootOverlay;

  @override
  State<CsModal> createState() => _CsModalState();
}

class _CsModalState extends State<CsModal> with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: CsDurations.responsive)..addStatusListener(_onStatus);
    if (widget.visible) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.visible) _show();
      });
    }
  }

  @override
  void didUpdateWidget(CsModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      // The portal cannot change during build; wait for the end of the frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.visible ? _show() : _hide();
      });
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _portal.isShowing && !widget.visible && mounted) {
      setState(_portal.hide);
    }
  }

  void _show() {
    if (!_portal.isShowing) setState(_portal.show);
    _anim.duration = CsMotion.duration(context, CsDurations.responsive);
    _anim.forward();
  }

  void _hide() {
    _anim.duration = CsMotion.duration(context, CsDurations.responsive);
    if (_anim.duration == Duration.zero) {
      _anim.value = 0;
      if (_portal.isShowing) setState(_portal.hide);
      return;
    }
    _anim.reverse();
  }

  void _dismiss(CsModalDismissReason reason) {
    if (widget.visible) widget.onDismiss?.call(reason);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.visible,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss(CsModalDismissReason.keyboard);
      },
      child: OverlayPortal(
        controller: _portal,
        overlayLocation: widget.useRootOverlay ? OverlayChildLocation.rootOverlay : OverlayChildLocation.nearestOverlay,
        overlayChildBuilder: (context) => AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => IgnorePointer(ignoring: !widget.visible, child: child),
          child: _CsModalFrame(modal: widget, animation: _anim, onDismiss: _dismiss),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// The backdrop and dialog of a modal for a given entry animation, shared by
// [CsModal] and [showCsModal].
class _CsModalFrame extends StatelessWidget {
  const _CsModalFrame({required this.modal, required this.animation, required this.onDismiss});

  final CsModal modal;
  final Animation<double> animation;
  final ValueChanged<CsModalDismissReason> onDismiss;

  // styles.scss: `.dialog.max.breakpoint-xs` leaves 2 * 4 * 10px + 40px.
  static const double _maxSizeMargin = 120;

  // styles.scss: `.dialog` is at least the `small` width.
  static const double _minWidth = 320;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final strings = context.csStrings;
    final media = MediaQuery.of(context);
    final reduce = CsMotion.reduceMotion(context);
    final fade = CurvedAnimation(parent: animation, curve: CsCurves.responsive);
    final closeLabel = modal.closeAriaLabel ?? 'Close modal';

    final screen = media.size;
    // `.focus-lock` pads the dialog by space-s on every side.
    const gutter = CsSpace.s;
    final available = math.max(0.0, screen.width - media.padding.horizontal - gutter * 2);
    final double width;
    if (modal.width != null) {
      width = math.min(math.max(modal.width!, _minWidth), available);
    } else if (modal.size == CsModalSize.max) {
      width = screen.width > CsBreakpoint.xs.minWidth ? math.min(screen.width - _maxSizeMargin, available) : available;
    } else {
      width = math.min(modal.size.width!, available);
    }

    final availableHeight = math.max(
      0.0,
      screen.height - media.padding.vertical - media.viewInsets.bottom - gutter * 2,
    );
    Widget dialog = _ModalSurface(
      modal: modal,
      closeLabel: closeLabel,
      onDismiss: onDismiss,
      maxHeight: availableHeight,
    );
    dialog = SizedBox(width: width, child: dialog);
    dialog = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: modal.header,
      child: dialog,
    );
    dialog = CsFocusTrap(
      onEscPress: () => onDismiss(CsModalDismissReason.keyboard),
      child: DefaultTextStyle(
        style: cs.body,
        child: IconTheme(
          data: IconThemeData(color: cs.colors.textBodyDefault, size: 16),
          child: dialog,
        ),
      ),
    );
    dialog = FadeTransition(
      opacity: fade,
      child: reduce ? dialog : ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1).animate(fade), child: dialog),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: fade,
          child: CsScrim(semanticLabel: strings.close, onPress: () => onDismiss(CsModalDismissReason.overlay)),
        ),
        BlockSemantics(
          child: Padding(
            padding: media.padding + EdgeInsets.only(bottom: media.viewInsets.bottom) + const EdgeInsets.all(gutter),
            child: Align(
              alignment: modal.position == CsModalPosition.top ? Alignment.topCenter : Alignment.center,
              child: dialog,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModalSurface extends StatelessWidget {
  const _ModalSurface({
    required this.modal,
    required this.closeLabel,
    required this.onDismiss,
    required this.maxHeight,
  });

  final CsModal modal;
  final String closeLabel;
  final ValueChanged<CsModalDismissReason> onDismiss;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final radius = BorderRadius.circular(CsBorderRadius.container);
    final headerSlot = modal.headerWidget ?? (modal.header != null ? Text(modal.header!) : null);
    final showHeader = headerSlot != null || !modal.hideDismissButton;

    final header = showHeader
        ? Container(
            color: c.backgroundContainerHeader,
            padding: EdgeInsetsDirectional.only(
              top: CsSpace.containerHeaderTop,
              bottom: cs.space.containerHeaderBottom,
              start: CsSpace.modalHorizontal,
              end: CsSpace.modalHorizontal,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
                    child: Semantics(
                      header: true,
                      child: DefaultTextStyle(
                        style: cs.text(CsTypeScale.headingM),
                        child: headerSlot ?? const SizedBox(),
                      ),
                    ),
                  ),
                ),
                if (!modal.hideDismissButton) ...[
                  const SizedBox(width: CsSpace.xs),
                  CsButton(
                    variant: CsButtonVariant.modalDismiss,
                    icon: CsIcons.close,
                    semanticLabel: closeLabel,
                    autofocus: true,
                    onPress: () => onDismiss(CsModalDismissReason.closeButton),
                  ),
                ],
              ],
            ),
          )
        : null;

    final contentPadding = modal.disableContentPaddings
        ? EdgeInsets.zero
        : EdgeInsets.only(
            top: CsSpace.containerContentTop,
            bottom: cs.space.modalContentBottom,
            left: CsSpace.modalHorizontal,
            right: CsSpace.modalHorizontal,
          );
    final content = SingleChildScrollView(padding: contentPadding, child: modal.child ?? const SizedBox.shrink());

    Widget? footerSlot = modal.footer;
    final actions = modal.footerActions;
    if (footerSlot == null && actions != null && actions.isNotEmpty) {
      footerSlot = Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(alignment: WrapAlignment.end, spacing: CsSpace.xs, runSpacing: CsSpace.xs, children: actions),
      );
    }
    final footer = footerSlot == null
        ? null
        : Container(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledS, horizontal: CsSpace.containerHorizontal),
            decoration: BoxDecoration(
              color: c.backgroundContainerContent,
              border: Border(
                top: BorderSide(color: c.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
              ),
            ),
            child: footerSlot,
          );

    Widget column = Column(
      mainAxisSize: modal.height != null ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        if (modal.height != null) Expanded(child: content) else Flexible(child: content),
        ?footer,
      ],
    );
    if (modal.height != null) {
      // A fixed height keeps at least 60px for the content, as Cloudscape does.
      column = SizedBox(height: math.max(60.0, math.min(modal.height!, maxHeight)), child: column);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: c.backgroundContainerContent, borderRadius: radius, boxShadow: cs.shadows.modal),
      child: ClipRRect(borderRadius: radius, child: column),
    );
  }
}

/// Opens a [CsModal] in its own route and completes with the value it is
/// closed with. Close it from inside with `Navigator.of(context).pop(value)`.
///
/// ```dart
/// final confirmed = await showCsModal<bool>(
///   context: context,
///   header: 'Delete bucket',
///   builder: (context) => const Text('Permanently delete example-bucket?'),
///   footerBuilder: (context) => Row(
///     mainAxisAlignment: MainAxisAlignment.end,
///     children: [
///       CsButton(text: 'Cancel', variant: CsButtonVariant.link, onPress: () => Navigator.of(context).pop(false)),
///       const SizedBox(width: 8),
///       CsButton(text: 'Delete', variant: CsButtonVariant.primary, onPress: () => Navigator.of(context).pop(true)),
///     ],
///   ),
/// );
/// ```
///
/// The close button always closes it. With [dismissible] false, the
/// backdrop, Escape and the back gesture do nothing, so the user has to pick
/// a footer action.
Future<T?> showCsModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? header,
  Widget? headerWidget,
  WidgetBuilder? footerBuilder,
  CsModalSize size = CsModalSize.medium,
  CsModalPosition position = CsModalPosition.center,
  bool hideDismissButton = false,
  bool dismissible = true,
  String? closeAriaLabel,
  bool disableContentPaddings = false,
  double? width,
  double? height,
  bool useRootNavigator = true,
}) {
  final theme = CsTheme.of(context);
  final strings = CsLocale.of(context);
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _CsModalRoute<T>(
      dismissible: dismissible,
      builder: (routeContext, animation, close) => CsTheme(
        data: theme,
        child: CsLocale(
          strings: strings,
          child: _CsModalFrame(
            animation: animation,
            onDismiss: (reason) {
              if (reason == CsModalDismissReason.closeButton || dismissible) close();
            },
            modal: CsModal(
              visible: true,
              header: header,
              headerWidget: headerWidget,
              size: size,
              position: position,
              hideDismissButton: hideDismissButton,
              closeAriaLabel: closeAriaLabel,
              disableContentPaddings: disableContentPaddings,
              width: width,
              height: height,
              footer: footerBuilder == null ? null : Builder(builder: footerBuilder),
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CsModalRoute<T> extends PopupRoute<T> {
  _CsModalRoute({required this.builder, required this.dismissible});

  final Widget Function(BuildContext context, Animation<double> animation, VoidCallback close) builder;
  final bool dismissible;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => CsDurations.responsive;

  @override
  RoutePopDisposition get popDisposition => dismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context, animation, () {
      if (isActive && isCurrent) navigator?.pop();
    });
  }
}
