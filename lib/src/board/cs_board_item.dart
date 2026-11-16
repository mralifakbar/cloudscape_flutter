import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// Copy for [CsBoardItem] (Cloudscape `BoardItemProps.I18nStrings`).
@immutable
class CsBoardItemI18nStrings {
  const CsBoardItemI18nStrings({
    this.dragHandleAriaLabel = 'Drag handle',
    this.dragHandleAriaDescription =
        'Use Space or Enter to activate drag, arrow keys to move, Space or Enter to submit, or Escape to discard.',
    this.resizeHandleAriaLabel = 'Resize handle',
    this.resizeHandleAriaDescription =
        'Use Space or Enter to activate resize, arrow keys to resize, Space or Enter to submit, or Escape to discard.',
    this.dragHandleTooltipText,
    this.resizeHandleTooltipText,
    this.addButtonAriaLabel = 'Add to board',
  });

  final String dragHandleAriaLabel;
  final String? dragHandleAriaDescription;
  final String resizeHandleAriaLabel;
  final String? resizeHandleAriaDescription;

  /// Tooltip on the drag handle (hover, focus, long press).
  final String? dragHandleTooltipText;

  /// Tooltip on the resize handle.
  final String? resizeHandleTooltipText;

  /// Label of the add button shown on items inside a [CsItemsPalette] that
  /// has `onItemAdd`: the keyboard and screen reader alternative to dragging.
  final String addButtonAriaLabel;
}

/// Which handle of an item an interaction comes from.
enum CsBoardHandle { drag, resize }

/// Wiring between a [CsBoardItem] and the board or palette that hosts it.
/// The item reads it to drive its handles; app code does not use it.
class CsBoardItemScope extends InheritedWidget {
  const CsBoardItemScope({
    super.key,
    required super.child,
    this.active = false,
    this.keyboardHandle,
    this.showResizeHandle = true,
    this.onDragStart,
    this.onActivate,
    this.onKey,
    this.onBlur,
    this.wrapDragHandle,
    this.onAdd,
  });

  /// The item is being dragged or resized: it lifts with the active shadow.
  final bool active;

  /// The handle in keyboard move or resize mode, if any.
  final CsBoardHandle? keyboardHandle;
  final bool showResizeHandle;

  /// Pointer down on a handle; returns the drag that follows the pointer.
  final Drag? Function(CsBoardHandle handle, Offset globalPosition)? onDragStart;

  /// Enter or Space on a handle.
  final void Function(CsBoardHandle handle)? onActivate;

  /// Key presses while a handle has focus.
  final KeyEventResult Function(CsBoardHandle handle, KeyEvent event)? onKey;

  /// A handle lost focus.
  final void Function(CsBoardHandle handle)? onBlur;

  /// Lets the palette turn the drag handle into a drag source.
  final Widget Function(Widget handle)? wrapDragHandle;

  /// Shows the add button (palette items with `onItemAdd`).
  final VoidCallback? onAdd;

  static CsBoardItemScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsBoardItemScope>();

  @override
  bool updateShouldNotify(CsBoardItemScope old) =>
      active != old.active ||
      keyboardHandle != old.keyboardHandle ||
      showResizeHandle != old.showResizeHandle ||
      onDragStart != old.onDragStart ||
      onActivate != old.onActivate ||
      onKey != old.onKey ||
      onBlur != old.onBlur ||
      wrapDragHandle != old.wrapDragHandle ||
      onAdd != old.onAdd;
}

/// Cloudscape's `BoardItem`: the container every item on a [CsBoard] and in
/// a [CsItemsPalette] renders. It has a drag handle before the [header], an
/// optional [settings] slot after it, the content, an optional [footer] and
/// a resize handle in the bottom end corner.
///
/// On a board the item fills its grid cells and the content area clips; in
/// a palette or on its own it takes its natural height.
///
/// ```dart
/// CsBoardItem(
///   header: const CsHeader(title: 'Instance health'),
///   settings: CsButton(variant: CsButtonVariant.icon, icon: CsIcons.ellipsis, semanticLabel: 'Settings', onPress: () {}),
///   child: const Text('12 of 12 instances healthy'),
/// )
/// ```
class CsBoardItem extends StatelessWidget {
  const CsBoardItem({
    super.key,
    this.header,
    this.child,
    this.footer,
    this.settings,
    this.disableContentPaddings = false,
    this.i18nStrings = const CsBoardItemI18nStrings(),
  });

  /// Heading of the item. Use `CsHeader`.
  final Widget? header;

  /// Main content.
  final Widget? child;

  /// Footer below a divider.
  final Widget? footer;

  /// Slot next to the header, for an overflow actions menu.
  final Widget? settings;

  /// Removes the content padding, for full-bleed charts or tables.
  final bool disableContentPaddings;
  final CsBoardItemI18nStrings i18nStrings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final scope = CsBoardItemScope.maybeOf(context);
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.container));

    Widget dragHandle = _Handle(
      handle: CsBoardHandle.drag,
      icon: CsIcons.dragIndicator,
      label: i18nStrings.dragHandleAriaLabel,
      hint: i18nStrings.dragHandleAriaDescription,
      tooltip: i18nStrings.dragHandleTooltipText,
      cursor: SystemMouseCursors.grab,
    );
    if (scope?.wrapDragHandle != null) dragHandle = scope!.wrapDragHandle!(dragHandle);

    final headerRow = Padding(
      // `.header`: padding-block scaled-s, padding-inline
      // container-horizontal minus scaled-xs.
      padding: EdgeInsets.symmetric(
        vertical: cs.space.scaledS,
        horizontal: CsSpace.containerHorizontal - cs.space.scaledXs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dragHandle,
          SizedBox(width: cs.space.scaledXxs),
          Expanded(child: header ?? const SizedBox.shrink()),
          if (scope?.onAdd != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.staticXs),
              child: CsButton(
                variant: CsButtonVariant.icon,
                icon: CsIcons.addPlus,
                semanticLabel: i18nStrings.addButtonAriaLabel,
                onPress: scope!.onAdd,
              ),
            ),
          if (settings != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.staticXs),
              child: settings,
            ),
        ],
      ),
    );

    final contentPadding = disableContentPaddings
        ? EdgeInsets.zero
        : EdgeInsets.only(
            top: CsSpace.containerContentTop,
            bottom: cs.space.containerContentVertical,
            left: CsSpace.containerHorizontal,
            right: CsSpace.containerHorizontal,
          );
    final footerPart = footer == null
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderDividerSecondary)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: cs.space.scaledS, horizontal: CsSpace.containerHorizontal),
              child: footer,
            ),
          );
    final showResize = scope != null && scope.showResizeHandle && scope.wrapDragHandle == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fill = constraints.hasTightHeight;
        final content = Padding(padding: contentPadding, child: child ?? const SizedBox.shrink());
        final column = Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerRow,
            // Cloudscape's item content has `overflow: auto`: content taller
            // than the item (large text, a long list) scrolls inside it.
            if (fill)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: content,
                    ),
                  ),
                ),
              )
            else
              content,
            ?footerPart,
            // Keeps the resize handle off the last line of content.
            if (showResize && footerPart == null) const SizedBox(height: CsSpace.staticXs),
          ],
        );
        return AnimatedContainer(
          duration: CsMotion.duration(context, CsDurations.responsive),
          curve: CsCurves.responsive,
          decoration: BoxDecoration(
            color: c.backgroundContainerContent,
            borderRadius: radius,
            boxShadow: scope?.active == true ? cs.shadows.containerActive : const [],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DefaultTextStyle.merge(
              style: cs.body,
              child: Stack(
                children: [
                  if (fill) Positioned.fill(child: column) else column,
                  if (showResize)
                    PositionedDirectional(
                      // `.resizer`: static-xs minus static-xxxs from the corner.
                      bottom: CsSpace.staticXs - CsSpace.staticXxxs,
                      end: CsSpace.staticXs - CsSpace.staticXxxs,
                      child: _Handle(
                        handle: CsBoardHandle.resize,
                        icon: CsIcons.resizeArea,
                        label: i18nStrings.resizeHandleAriaLabel,
                        hint: i18nStrings.resizeHandleAriaDescription,
                        tooltip: i18nStrings.resizeHandleTooltipText,
                        cursor: Directionality.of(context) == TextDirection.rtl
                            ? SystemMouseCursors.resizeUpRightDownLeft
                            : SystemMouseCursors.resizeUpLeftDownRight,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A drag or resize handle: an icon that starts a pointer drag on contact,
/// and a keyboard mode on Enter or Space.
class _Handle extends StatelessWidget {
  const _Handle({
    required this.handle,
    required this.icon,
    required this.label,
    required this.hint,
    required this.tooltip,
    required this.cursor,
  });

  final CsBoardHandle handle;
  final CsIconData icon;
  final String label;
  final String? hint;
  final String? tooltip;
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    final scope = CsBoardItemScope.maybeOf(context);
    final c = context.cs.colors;
    final keyboardActive = scope?.keyboardHandle == handle;
    final interactive = scope?.onActivate != null || scope?.wrapDragHandle != null;
    Widget result = CsPressable(
      onPress: scope?.onActivate == null ? null : () => scope!.onActivate!(handle),
      semanticLabel: label,
      semanticHint: hint,
      excludeChildSemantics: true,
      scaleOnPress: false,
      // A handle in keyboard mode keeps a visible ring while focused.
      borderRadius: const BorderRadius.all(Radius.circular(CsBorderRadius.controlDefaultFocusRing)),
      mouseCursor: interactive ? cursor : null,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(CsSpace.staticXxxs),
        child: CsIcon(
          icon,
          dangerouslySetColor: keyboardActive || state.active ? c.textInteractiveHover : c.textInteractiveDefault,
        ),
      ),
    );
    // Always wrapped, so entering keyboard mode never rebuilds the
    // pressable (and drops its focus).
    result = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: keyboardActive ? Border.all(color: c.borderItemFocused, width: 2) : null,
        borderRadius: const BorderRadius.all(Radius.circular(CsBorderRadius.controlDefaultFocusRing)),
      ),
      child: result,
    );
    if (scope?.onKey != null || scope?.onBlur != null) {
      result = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: scope?.onKey == null ? null : (node, event) => scope!.onKey!(handle, event),
        onFocusChange: (v) {
          if (!v) scope?.onBlur?.call(handle);
        },
        child: result,
      );
    }
    if (scope?.onDragStart != null) {
      result = RawGestureDetector(
        gestures: {
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                ImmediateMultiDragGestureRecognizer.new,
                (r) => r.onStart = (position) => scope!.onDragStart!(handle, position),
              ),
        },
        child: result,
      );
    }
    if (tooltip != null) result = CsTooltip(content: tooltip!, child: result);
    return result;
  }
}
