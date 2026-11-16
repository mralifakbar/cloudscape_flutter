import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Container styles (Cloudscape `variant`).
enum CsContainerVariant {
  /// A rounded panel with a 1px border.
  defaultVariant,

  /// Containers placed one under another: inner corners are square and
  /// the stack reads as one panel.
  stacked,
}

/// Where a stacked container sits in its stack, so its corners match.
enum CsStackPosition { first, middle, last, only }

/// Cloudscape's `Container`: the standard panel for a block of related
/// content, with an optional header, footer and media.
///
/// ```dart
/// CsContainer(
///   header: const CsHeader(variant: CsHeaderVariant.h2, title: 'General configuration'),
///   footer: CsButton(text: 'Edit', onPress: () {}),
///   child: const CsBox(text: 'Distribution content'),
/// )
/// ```
///
/// Visual refresh: `color-background-container-content`, a 1px
/// `color-border-divider-default` border and a 16px radius; the header has
/// no fill and sits 12px from the top; content and footer are padded 20px
/// on the sides.
class CsContainer extends StatelessWidget {
  const CsContainer({
    super.key,
    this.header,
    this.footer,
    this.media,
    this.mediaPosition = AxisDirection.up,
    this.mediaExtent,
    this.variant = CsContainerVariant.defaultVariant,
    this.stackPosition = CsStackPosition.only,
    this.disableHeaderPaddings = false,
    this.disableContentPaddings = false,
    this.fitHeight = false,
    this.footerDivider = true,
    this.child,
  });

  final Widget? header;
  final Widget? footer;

  /// An image or video at the top or start of the container.
  final Widget? media;

  /// [AxisDirection.up] for top media, [AxisDirection.left] for side media
  /// (which moves to the top below 688px).
  final AxisDirection mediaPosition;

  /// Height of top media or width of side media.
  final double? mediaExtent;
  final CsContainerVariant variant;
  final CsStackPosition stackPosition;
  final bool disableHeaderPaddings;
  final bool disableContentPaddings;

  /// Fill the height of the parent (dashboards with equal-height panels).
  final bool fitHeight;

  /// A divider above the footer.
  final bool footerDivider;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const r = Radius.circular(CsBorderRadius.container);
    final stacked = variant == CsContainerVariant.stacked;
    final topRound = !stacked || stackPosition == CsStackPosition.first || stackPosition == CsStackPosition.only;
    final bottomRound = !stacked || stackPosition == CsStackPosition.last || stackPosition == CsStackPosition.only;
    final radius = BorderRadius.only(
      topLeft: topRound ? r : Radius.zero,
      topRight: topRound ? r : Radius.zero,
      bottomLeft: bottomRound ? r : Radius.zero,
      bottomRight: bottomRound ? r : Radius.zero,
    );
    final side = BorderSide(color: c.borderDividerDefault, width: CsBorderLine.dividerSectionWidth);
    final border = stacked && !bottomRound
        ? Border(top: side, left: side, right: side)
        : Border.fromBorderSide(side);

    final hasHeader = header != null;
    final parts = <Widget>[];
    if (hasHeader) {
      parts.add(
        Padding(
          padding: disableHeaderPaddings
              ? EdgeInsets.zero
              : EdgeInsets.only(
                  top: CsSpace.containerHeaderTop,
                  bottom: cs.space.containerHeaderBottom,
                  left: CsSpace.containerHorizontal,
                  right: CsSpace.containerHorizontal,
                ),
          child: header,
        ),
      );
    }
    if (child != null) {
      Widget content = Padding(
        padding: disableContentPaddings
            ? EdgeInsets.zero
            : EdgeInsets.only(
                top: hasHeader ? CsSpace.containerContentTop : cs.space.containerContentVertical,
                bottom: cs.space.containerContentVertical,
                left: CsSpace.containerHorizontal,
                right: CsSpace.containerHorizontal,
              ),
        child: child,
      );
      if (fitHeight) content = Expanded(child: content);
      parts.add(content);
    } else if (hasHeader && !disableHeaderPaddings) {
      parts.add(SizedBox(height: cs.space.containerContentVertical - cs.space.containerHeaderBottom));
    }
    if (footer != null) {
      parts.add(
        DecoratedBox(
          decoration: BoxDecoration(
            border: footerDivider ? Border(top: BorderSide(color: c.borderDividerSecondary)) : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledS, horizontal: CsSpace.containerHorizontal),
            child: footer,
          ),
        ),
      );
    }

    Widget body = Column(
      mainAxisSize: fitHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );

    if (media != null) {
      final side = mediaPosition == AxisDirection.left || mediaPosition == AxisDirection.right;
      final useSide = side && !context.csIsNarrow;
      final m = SizedBox(
        width: useSide ? (mediaExtent ?? 200) : null,
        height: useSide ? null : mediaExtent,
        child: media,
      );
      body = useSide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: mediaPosition == AxisDirection.right
                    ? [Expanded(child: body), m]
                    : [m, Expanded(child: body)],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [m, body],
            );
    }

    return Container(
      decoration: BoxDecoration(color: c.backgroundContainerContent, borderRadius: radius),
      foregroundDecoration: BoxDecoration(borderRadius: radius, border: border),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(style: cs.body, child: body),
    );
  }
}
