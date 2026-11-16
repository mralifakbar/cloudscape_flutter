// Parts shared by the collection components. Not exported from the package:
// the radio, toggle and dialog panel here are private stand-ins so the
// collections do not depend on components built elsewhere.
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../controls/cs_checkbox.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_routes.dart';
import '../system/cs_focus_ring.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_collection_types.dart';

/// Sends a polite screen reader announcement from [context]'s view.
void csCollectionAnnounce(BuildContext context, String message) {
  if (message.isEmpty) return;
  final view = View.maybeOf(context);
  if (view == null) return;
  SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
}

/// Cloudscape's radio button circle: a 2px ring that fills with the checked
/// color and leaves a white dot when checked.
class _RadioGlyph extends StatelessWidget {
  const _RadioGlyph({required this.checked, this.disabled = false});

  final bool checked;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final ring = disabled ? c.borderControlDisabled : (checked ? c.backgroundControlChecked : c.borderControlDefault);
    final fill = disabled ? c.backgroundControlDisabled : c.backgroundControlDefault;
    final dot = disabled ? c.foregroundControlDisabled : c.foregroundControlDefault;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: checked ? 1 : 0),
      duration: CsMotion.duration(context, CsDurations.responsive),
      curve: CsCurves.responsive,
      builder: (context, t, _) => SizedBox.square(
        dimension: CsSize.control,
        child: CustomPaint(
          painter: _RadioPainter(ring: ring, fill: fill, dot: dot, progress: t),
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter({required this.ring, required this.fill, required this.dot, required this.progress});

  final Color ring;
  final Color fill;
  final Color dot;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(center, r, Paint()..color = progress > 0 ? Color.lerp(fill, ring, progress)! : fill);
    if (progress < 1) {
      canvas.drawCircle(
        center,
        r - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring,
      );
    }
    if (progress > 0) {
      // The checked state is a 5px ring around a 6px dot.
      canvas.drawCircle(center, 3 * progress, Paint()..color = dot);
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      old.ring != ring || old.fill != fill || old.dot != dot || old.progress != progress;
}

/// The checkbox or radio in a table selection cell or a card header. The hit
/// area fills [size], so the whole cell selects, as in Cloudscape where the
/// label covers the cell.
class CsCollectionSelectionControl extends StatelessWidget {
  const CsCollectionSelectionControl({
    super.key,
    required this.selectionType,
    required this.checked,
    required this.onChange,
    this.indeterminate = false,
    this.disabled = false,
    this.semanticLabel,
    this.width,
    this.minHeight = 0,
    this.alignment = Alignment.center,
    this.focusNode,
  });

  final CsSelectionType selectionType;
  final bool checked;
  final bool indeterminate;
  final bool disabled;

  /// Called with whether Shift was held, for range selection.
  final ValueChanged<bool>? onChange;
  final String? semanticLabel;

  /// Width of the hit area; null hugs the control.
  final double? width;

  /// Minimum height of the hit area. It grows with a taller row.
  final double minHeight;
  final AlignmentGeometry alignment;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final inactive = disabled || onChange == null;
    final multi = selectionType == CsSelectionType.multi;
    return CsPressable(
      onPress: inactive ? null : () => onChange!(HardwareKeyboard.instance.isShiftPressed),
      disabled: inactive,
      focusNode: focusNode,
      scaleOnPress: false,
      showFocusRing: false,
      isButton: false,
      checked: multi ? (indeterminate ? null : checked) : checked,
      mixed: multi && indeterminate ? true : null,
      inMutuallyExclusiveGroup: multi ? null : true,
      semanticLabel: semanticLabel,
      minTapTargetSize: 0,
      builder: (context, state) {
        Widget icon = multi
            ? CsCheckboxIcon(checked: checked, indeterminate: indeterminate, disabled: inactive)
            : _RadioGlyph(checked: checked, disabled: inactive);
        icon = CsFocusRing(
          visible: state.focused,
          offset: 2,
          borderRadius: BorderRadius.circular(multi ? CsBorderRadius.controlDefaultFocusRing : CsSize.control),
          child: icon,
        );
        if (width == null) return icon;
        return SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Align(alignment: alignment, child: icon),
          ),
        );
      },
    );
  }
}

/// Cloudscape's toggle: a 24x16 track with a 12px handle.
class CsCollectionToggle extends StatelessWidget {
  const CsCollectionToggle({
    super.key,
    required this.checked,
    required this.onChange,
    this.disabled = false,
    this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool>? onChange;
  final bool disabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final inactive = disabled || onChange == null;
    return CsPressable(
      onPress: inactive ? null : () => onChange!(!checked),
      disabled: inactive,
      scaleOnPress: false,
      showFocusRing: false,
      isButton: false,
      toggled: checked,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final track = inactive
            ? (checked ? c.backgroundToggleCheckedDisabled : c.backgroundControlDisabled)
            : (checked ? c.backgroundControlChecked : c.backgroundToggleDefault);
        final handle = inactive ? c.foregroundControlDisabled : c.foregroundControlDefault;
        return CsFocusRing(
          visible: state.focused,
          offset: 2,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing + 8),
          child: AnimatedContainer(
            duration: CsMotion.duration(context, CsDurations.responsive),
            curve: CsCurves.responsive,
            width: 24,
            height: 16,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(8)),
            child: AnimatedAlign(
              duration: CsMotion.duration(context, CsDurations.responsive),
              curve: CsCurves.responsive,
              alignment: checked ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: handle, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modal widths (Cloudscape modal `size`).
enum CsCollectionDialogSize {
  medium(600),
  large(820),
  max(double.infinity);

  const CsCollectionDialogSize(this.maxWidth);
  final double maxWidth;
}

/// Pushes [panel] in a [CsDialogRoute] centered on the screen with
/// Cloudscape's 12px viewport margin.
Future<R?> showCsCollectionDialog<R>(BuildContext context, {required WidgetBuilder builder, String? semanticLabel}) {
  return Navigator.of(context).push<R>(
    CsDialogRoute<R>(
      semanticLabel: semanticLabel,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CsSpace.s),
          child: Center(child: builder(context)),
        ),
      ),
    ),
  );
}

/// A panel styled like Cloudscape's modal: a header with the title and a
/// close button, scrollable content and a footer separated by a divider.
class CsCollectionDialogPanel extends StatelessWidget {
  const CsCollectionDialogPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onDismiss,
    this.footer,
    this.closeLabel,
    this.size = CsCollectionDialogSize.medium,
    this.disableContentPaddings = false,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final VoidCallback onDismiss;
  final String? closeLabel;
  final CsCollectionDialogSize size;
  final bool disableContentPaddings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.container));
    final screen = MediaQuery.sizeOf(context);
    // Cloudscape `max`: the viewport less 2 x 32px and the 40px gutter.
    final maxWidth = size != CsCollectionDialogSize.max || context.csIsNarrow
        ? size.maxWidth
        : math.max(320.0, screen.width - 104);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: c.backgroundContainerContent,
          borderRadius: radius,
          boxShadow: cs.shadows.modal,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.backgroundContainerHeader,
                border: Border(bottom: BorderSide(color: c.borderContainerDivider)),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: CsSpace.modalHorizontal,
                  end: CsSpace.xs,
                  top: CsSpace.containerHeaderTop,
                  bottom: cs.space.containerHeaderBottom,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: CsSpace.xxs),
                        child: Semantics(header: true, child: Text(title, style: cs.text(CsTypeScale.headingM))),
                      ),
                    ),
                    CsButton(
                      icon: CsIcons.close,
                      variant: CsButtonVariant.modalDismiss,
                      semanticLabel: closeLabel ?? context.csStrings.close,
                      onPress: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: disableContentPaddings
                    ? EdgeInsets.zero
                    : EdgeInsets.only(
                        top: CsSpace.containerContentTop + CsSpace.s,
                        bottom: cs.space.modalContentBottom,
                        left: CsSpace.modalHorizontal,
                        right: CsSpace.modalHorizontal,
                      ),
                child: child,
              ),
            ),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.borderDividerDefault)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: cs.space.scaledS, horizontal: CsSpace.containerHorizontal),
                  child: Align(alignment: AlignmentDirectional.centerEnd, child: footer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selection rules shared by the table and cards (Cloudscape
/// `use-selection.ts`): single selection keeps one item, multi selection
/// toggles, extends a range with Shift, and select-all covers the enabled
/// items in view.
class CsCollectionSelectionModel<T> {
  CsCollectionSelectionModel({required this.items, required this.selectedItems, this.trackBy, this.isItemDisabled}) {
    for (final s in selectedItems) {
      _selected.add(key(s));
    }
  }

  final List<T> items;
  final List<T> selectedItems;
  final CsTrackBy<T>? trackBy;
  final bool Function(T item)? isItemDisabled;
  final Set<Object?> _selected = {};

  Object? key(T item) => trackBy == null ? item : trackBy!(item);

  bool isSelected(T item) => _selected.contains(key(item));

  bool isDisabled(T item) => isItemDisabled?.call(item) ?? false;

  List<T> get _enabled => [
    for (final i in items)
      if (!isDisabled(i)) i,
  ];

  bool get allSelected {
    final enabled = _enabled;
    return enabled.isNotEmpty && enabled.every(isSelected);
  }

  bool get someSelected => items.any(isSelected);

  /// The next selection after the user toggles [item]. [anchor] is the last
  /// toggled item, used for Shift ranges.
  List<T> toggle(T item, {required CsSelectionType type, bool shift = false, T? anchor}) {
    if (isDisabled(item)) return selectedItems;
    if (type == CsSelectionType.single) {
      return isSelected(item) ? selectedItems : [item];
    }
    final selecting = !isSelected(item);
    final targets = <T>[item];
    if (shift && anchor != null) {
      final a = items.indexWhere((i) => key(i) == key(anchor));
      final b = items.indexWhere((i) => key(i) == key(item));
      if (a >= 0 && b >= 0) {
        targets
          ..clear()
          ..addAll(items.sublist(math.min(a, b), math.max(a, b) + 1).where((i) => !isDisabled(i)));
      }
    }
    final targetKeys = {for (final t in targets) key(t)};
    if (selecting) {
      return [
        ...selectedItems,
        for (final t in targets)
          if (!isSelected(t)) t,
      ];
    }
    return [
      for (final s in selectedItems)
        if (!targetKeys.contains(key(s))) s,
    ];
  }

  /// The next selection after the select-all control is toggled.
  List<T> toggleAll() {
    final enabled = _enabled;
    final enabledKeys = {for (final e in enabled) key(e)};
    if (allSelected) {
      return [
        for (final s in selectedItems)
          if (!enabledKeys.contains(key(s))) s,
      ];
    }
    return [
      ...selectedItems,
      for (final e in enabled)
        if (!isSelected(e)) e,
    ];
  }
}

/// A radio button with a label and optional description, for the radio
/// groups inside collection dialogs.
class CsCollectionRadioRow extends StatelessWidget {
  const CsCollectionRadioRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onSelect,
    this.description,
    this.disabled = false,
  });

  final String label;
  final String? description;
  final bool checked;
  final bool disabled;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final inactive = disabled || onSelect == null;
    return CsPressable(
      onPress: inactive ? null : onSelect,
      disabled: inactive,
      scaleOnPress: false,
      showFocusRing: false,
      isButton: false,
      checked: checked,
      inMutuallyExclusiveGroup: true,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (context, state) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: CsFocusRing(
              visible: state.focused,
              offset: 2,
              borderRadius: BorderRadius.circular(CsSize.control),
              child: _RadioGlyph(checked: checked, disabled: inactive),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: cs.text(
                      CsTypeScale.bodyM,
                      color: inactive ? CsColor.textControlDisabled : CsColor.textFormDefault,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: cs.text(
                        CsTypeScale.bodyS,
                        color: inactive ? CsColor.textControlDisabled : CsColor.textFormSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
