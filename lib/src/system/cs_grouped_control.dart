import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_field_box.dart';

/// A control's place in a `CsControlGroup` (Cloudscape
/// `GroupedControlPosition`).
enum CsGroupedControlPosition { first, middle, last, only }

/// Tells a field inside a `CsControlGroup` where it sits, so its chrome
/// joins its neighbors: only the group's outer corners are rounded, the
/// border between two controls is a single 1px seam, the border takes
/// `color-border-control-group-default`, and the group's validation colors
/// the outer edges with the thick start edge on the leading control.
///
/// `CsFieldBox` (and so `CsInput`, `CsSelect`, `CsMultiselect`,
/// `CsTextarea` and the other field-based controls) reads it. A custom
/// control can read it with [maybeOf] and [radius] to join a group too.
class CsGroupedControl extends InheritedWidget {
  const CsGroupedControl({
    super.key,
    required this.position,
    required this.direction,
    this.hasAction = false,
    this.status = CsFieldStatus.none,
    required super.child,
  });

  final CsGroupedControlPosition position;

  /// The axis the group lays its controls out along.
  final Axis direction;

  /// Whether an action button is joined to the group's end edge; the
  /// controls then square the corners that face it.
  final bool hasAction;

  /// The group's validation state. It replaces the control's own.
  final CsFieldStatus status;

  /// The nearest grouped-control placement, or null outside a control group.
  static CsGroupedControl? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsGroupedControl>();

  /// Whether this control draws the group's thick validation start edge.
  bool get leading =>
      direction == Axis.vertical ||
      position == CsGroupedControlPosition.first ||
      position == CsGroupedControlPosition.only;

  /// Whether the border on the start (horizontal) or top (vertical) edge is
  /// dropped because the previous control's border forms the seam.
  bool get joinsPrevious => position == CsGroupedControlPosition.middle || position == CsGroupedControlPosition.last;

  /// The corner radii of this control: [r] on the group's outer corners,
  /// square everywhere else (Cloudscape `grouped-control-*` mixins).
  BorderRadiusDirectional radius(double r) {
    final round = Radius.circular(r);
    var topStart = round, topEnd = round, bottomStart = round, bottomEnd = round;
    if (direction == Axis.horizontal) {
      if (position == CsGroupedControlPosition.first || position == CsGroupedControlPosition.middle) {
        topEnd = bottomEnd = Radius.zero;
      }
      if (position == CsGroupedControlPosition.last || position == CsGroupedControlPosition.middle) {
        topStart = bottomStart = Radius.zero;
      }
    } else {
      if (position == CsGroupedControlPosition.first || position == CsGroupedControlPosition.middle) {
        bottomStart = bottomEnd = Radius.zero;
      }
      if (position == CsGroupedControlPosition.last || position == CsGroupedControlPosition.middle) {
        topStart = topEnd = Radius.zero;
      }
    }
    if (hasAction) topEnd = bottomEnd = Radius.zero;
    return BorderRadiusDirectional.only(
      topStart: topStart,
      topEnd: topEnd,
      bottomStart: bottomStart,
      bottomEnd: bottomEnd,
    );
  }

  /// Default border color of a grouped control.
  static Color borderColor(BuildContext context) => context.cs.colors.borderControlGroupDefault;

  @override
  bool updateShouldNotify(CsGroupedControl old) =>
      old.position != position || old.direction != direction || old.hasAction != hasAction || old.status != status;
}
