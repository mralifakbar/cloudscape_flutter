import 'package:flutter/widgets.dart';

import 'cs_box.dart';

/// Direction of a [CsSpaceBetween].
enum CsSpaceBetweenDirection { vertical, horizontal }

/// Cross-axis alignment of a [CsSpaceBetween] (Cloudscape `alignItems`).
enum CsSpaceBetweenAlign { start, center, end }

/// Cloudscape's `SpaceBetween`: puts a token-sized gap between its children,
/// stacked vertically or in a horizontal row that wraps. Children that are
/// [SizedBox.shrink] (Cloudscape skips null children) take no gap.
///
/// ```dart
/// CsSpaceBetween(
///   size: CsSpacingSize.xs,
///   direction: CsSpaceBetweenDirection.horizontal,
///   children: [
///     CsButton(text: 'Cancel', onPress: () {}),
///     CsButton(text: 'Create', variant: CsButtonVariant.primary, onPress: () {}),
///   ],
/// )
/// ```
class CsSpaceBetween extends StatelessWidget {
  const CsSpaceBetween({
    super.key,
    required this.children,
    this.size = CsSpacingSize.m,
    this.direction = CsSpaceBetweenDirection.vertical,
    this.alignItems,
  });

  final List<Widget> children;

  /// Gap between children: `xxxs` (2px) to `xxl` (32px).
  final CsSpacingSize size;
  final CsSpaceBetweenDirection direction;
  final CsSpaceBetweenAlign? alignItems;

  @override
  Widget build(BuildContext context) {
    final items = children.where((c) => !(c is SizedBox && c.width == 0 && c.height == 0 && c.child == null)).toList();
    if (direction == CsSpaceBetweenDirection.horizontal) {
      return Wrap(
        spacing: size.value,
        runSpacing: size.value,
        crossAxisAlignment: switch (alignItems) {
          CsSpaceBetweenAlign.center => WrapCrossAlignment.center,
          CsSpaceBetweenAlign.end => WrapCrossAlignment.end,
          _ => WrapCrossAlignment.start,
        },
        children: items,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: switch (alignItems) {
        CsSpaceBetweenAlign.center => CrossAxisAlignment.center,
        CsSpaceBetweenAlign.end => CrossAxisAlignment.end,
        CsSpaceBetweenAlign.start => CrossAxisAlignment.start,
        null => CrossAxisAlignment.stretch,
      },
      spacing: size.value,
      children: items,
    );
  }
}
