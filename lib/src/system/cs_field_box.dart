import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_grouped_control.dart';

/// Validation state of a field, drawn by [CsFieldBox].
enum CsFieldStatus {
  none,

  /// Cloudscape `invalid`: red border with a thick 8px start edge.
  invalid,

  /// Cloudscape `warning`: yellow border with a thick 8px start edge.
  warning,
}

/// The chrome of every Cloudscape text field: `color-background-input-default`,
/// a 1px `color-border-input-default` border, 8px radius and a 32px minimum
/// height (28px compact). Focus colors the border `color-border-input-focused`
/// and adds a 1px ring; invalid and warning states color the border and
/// thicken its start edge to 8px; disabled and read-only fields get their
/// own fills.
///
/// Use it with `CsEditable` (or any content) to build a field that matches
/// `CsInput`:
///
/// ```dart
/// CsFieldBox(
///   focused: focusNode.hasFocus,
///   child: CsEditable(controller: controller, focusNode: focusNode),
/// )
/// ```
class CsFieldBox extends StatelessWidget {
  const CsFieldBox({
    super.key,
    required this.child,
    this.focused = false,
    this.status = CsFieldStatus.none,
    this.disabled = false,
    this.readOnly = false,
    this.leading,
    this.trailing,
    this.padding,
    this.minHeight,
    this.borderRadius = CsBorderRadius.input,
    this.multiline = false,
  });

  final Widget child;
  final bool focused;
  final CsFieldStatus status;
  final bool disabled;
  final bool readOnly;

  /// An icon before the content (a search icon), 12px from the start edge.
  final Widget? leading;

  /// Content after the field text (a clear button, a caret).
  final Widget? trailing;

  /// Overrides the default `space-field-vertical` / `space-field-horizontal`.
  final EdgeInsetsGeometry? padding;

  /// Defaults to `size-vertical-input` (32px, 28px compact).
  final double? minHeight;
  final double borderRadius;

  /// Align content to the top (text areas).
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    // Inside a CsControlGroup the group's placement shapes the chrome.
    final group = CsGroupedControl.maybeOf(context);
    final status = group != null && group.status != CsFieldStatus.none ? group.status : this.status;
    final statusColor = switch (status) {
      CsFieldStatus.invalid => c.textStatusError,
      CsFieldStatus.warning => c.textStatusWarning,
      CsFieldStatus.none => null,
    };
    final Color borderColor = disabled || readOnly
        ? c.borderInputDisabled
        : statusColor ??
              (focused ? c.borderInputFocused : (group != null ? c.borderControlGroupDefault : c.borderInputDefault));
    final Color background = disabled ? c.backgroundInputDisabled : c.backgroundInputDefault;
    final thickStart = statusColor != null && (group == null || group.leading);
    final dir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final joinStart = group != null && group.direction == Axis.horizontal && group.joinsPrevious;
    final joinTop = group != null && group.direction == Axis.vertical && group.joinsPrevious;
    final startWidth = joinStart
        ? 0.0
        : thickStart
        ? CsBorderWidth.fieldStatusInlineStart
        : CsBorderWidth.field;
    final topWidth = joinTop ? 0.0 : CsBorderWidth.field;
    final radius = group?.radius(borderRadius).resolve(dir) ?? BorderRadius.circular(borderRadius);

    final vertical = cs.space.fieldVertical;
    // The thick start border eats into the start padding so text stays put.
    final startPad = CsSpace.fieldHorizontal - (startWidth - CsBorderWidth.field);
    final topPad = vertical + CsBorderWidth.field - topWidth;
    final resolvedPadding =
        padding ??
        EdgeInsetsDirectional.only(
          start: leading != null ? 0 : startPad,
          end: trailing != null ? 0 : CsSpace.fieldHorizontal,
          top: topPad,
          bottom: vertical,
        );

    Widget content = Padding(padding: resolvedPadding, child: child);
    if (leading != null || trailing != null) {
      content = Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (leading != null)
            Padding(
              padding: EdgeInsetsDirectional.only(start: startPad, end: CsSpace.xs),
              child: leading,
            ),
          Expanded(child: content),
          if (trailing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
              child: trailing,
            ),
        ],
      );
    }

    // Focus ring: Cloudscape's `box-shadow: 0 0 0 1px` (2px when invalid) in
    // `color-border-item-focused`, drawn outside without moving layout.
    final ringSpread = statusColor != null
        ? CsBorderLine.controlInvalidFocusRingShadowSpread
        : CsBorderLine.controlFocusRingShadowSpread;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? cs.space.sizeVerticalInput),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        boxShadow: focused && !disabled && !readOnly
            ? [BoxShadow(color: statusColor ?? c.borderItemFocused, spreadRadius: ringSpread)]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: _border(dir, borderColor, startWidth, topWidth),
      ),
      padding: EdgeInsetsDirectional.only(
        start: startWidth,
        top: topWidth,
        end: CsBorderWidth.field,
        bottom: CsBorderWidth.field,
      ),
      // Align with height factor 1 instead of Container.alignment, which would
      // make the field fill any height limit from above.
      child: Align(
        alignment: multiline ? AlignmentDirectional.topStart : AlignmentDirectional.centerStart,
        heightFactor: 1,
        child: content,
      ),
    );
  }

  static Border _border(TextDirection dir, Color color, double startWidth, double topWidth) {
    final side = BorderSide(color: color, width: CsBorderWidth.field);
    // A grouped control drops the edge its neighbor's border already draws.
    final start = startWidth == 0 ? BorderSide.none : BorderSide(color: color, width: startWidth);
    final top = topWidth == 0 ? BorderSide.none : side;
    return dir == TextDirection.rtl
        ? Border(top: top, bottom: side, left: side, right: start)
        : Border(top: top, bottom: side, left: start, right: side);
  }
}
