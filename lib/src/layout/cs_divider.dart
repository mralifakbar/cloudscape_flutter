import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Orientation of a [CsDivider] (Cloudscape `orientation`).
enum CsDividerOrientation {
  /// A full-width line between stacked blocks.
  horizontal,

  /// A full-height line between blocks in a row.
  vertical,
}

/// Cloudscape's `Divider` (`src/divider`): a 1px
/// `color-border-divider-default` line that separates content, optionally
/// with a label in the middle of a horizontal line.
///
/// ```dart
/// const CsDivider()
/// const CsDivider(label: 'or')
/// const SizedBox(height: 24, child: CsDivider(orientation: CsDividerOrientation.vertical))
/// ```
///
/// A vertical divider stretches to the height its parent gives it; inside a
/// [Row] wrap the row in an [IntrinsicHeight] or give it a fixed height.
class CsDivider extends StatelessWidget {
  const CsDivider({
    super.key,
    this.orientation = CsDividerOrientation.horizontal,
    this.label,
    this.labelWidget,
    this.dangerouslySetLineColor,
    this.lineWidth = CsBorderLine.dividerSectionWidth,
  });

  final CsDividerOrientation orientation;

  /// Text in the middle of a horizontal divider (Cloudscape `children`).
  final String? label;

  /// Custom content in the middle of a horizontal divider, in place of [label].
  final Widget? labelWidget;

  /// Escape hatch for the line color (Cloudscape `style.root.lineColor`).
  final Color? dangerouslySetLineColor;

  /// Line thickness (Cloudscape `style.root.lineWidth`). Defaults to
  /// `border-divider-section-width`, 1px.
  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = dangerouslySetLineColor ?? cs.colors.borderDividerDefault;
    if (orientation == CsDividerOrientation.vertical) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: SizedBox(
          width: lineWidth,
          child: ColoredBox(color: color),
        ),
      );
    }
    final line = SizedBox(
      height: lineWidth,
      child: ColoredBox(color: color),
    );
    final content = labelWidget ?? (label == null ? null : Text(label!, style: cs.body));
    if (content == null) return SizedBox(width: double.infinity, child: line);
    return Row(
      spacing: CsSpace.xs,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: CsSpace.m),
            child: line,
          ),
        ),
        Flexible(
          child: DefaultTextStyle.merge(style: cs.body, child: content),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: CsSpace.m),
            child: line,
          ),
        ),
      ],
    );
  }
}
