import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Container styles (Cloudscape `variant`).
enum CsContainerVariant {
  /// A rounded panel with a 1px border.
  defaultVariant,

  /// Containers placed one under another: inner corners are square and the
  /// stack reads as one panel. Set [CsContainer.stackPosition] on each one.
  stacked,
}

/// Where a stacked container sits in its stack, so its corners and borders
/// match its neighbours (Cloudscape works this out with CSS sibling
/// selectors; Flutter needs it spelled out).
enum CsStackPosition { first, middle, last, only }

/// Where container media sits (Cloudscape `media.position`).
enum CsContainerMediaPosition {
  /// Above the header, full width.
  top,

  /// At the start edge, full height. Moves to the top at or below 688px.
  side,
}

/// An image, video or other visual shown with a container (Cloudscape
/// `ContainerProps.Media`).
@immutable
class CsContainerMedia {
  const CsContainerMedia({
    required this.content,
    this.position = CsContainerMediaPosition.top,
    this.width,
    this.height,
  });

  /// The media itself, usually an [Image] with `fit: BoxFit.cover`.
  final Widget content;
  final CsContainerMediaPosition position;

  /// Width of side media. Cloudscape caps it at 66% of the container.
  final double? width;

  /// Height of top media. Cloudscape caps it at 66% of the container.
  final double? height;
}

/// Style overrides (Cloudscape `style`). Every field is optional and falls
/// back to the token value.
@immutable
class CsContainerStyle {
  const CsContainerStyle({
    this.background,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    this.contentPadding,
    this.headerPadding,
    this.footerPadding,
    this.footerDividerColor,
    this.footerDividerWidth,
  });

  final Color? background;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  /// A shadow under the container. Only use it with an opaque [background].
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? footerPadding;
  final Color? footerDividerColor;
  final double? footerDividerWidth;
}

/// Cloudscape's `Container`: the standard panel for a block of related
/// content, with an optional header, footer and media.
///
/// ```dart
/// CsContainer(
///   header: const CsHeader(title: 'General configuration'),
///   footer: CsButton(text: 'Edit', onPress: () {}),
///   child: const CsBox(text: 'Distribution content'),
/// )
/// ```
///
/// Visual refresh: `color-background-container-content`, a 1px
/// `color-border-divider-default` border drawn inside the box and a 16px
/// radius. The header has no fill and sits 12px from the top
/// (`space-container-header-top`); content and footer are padded 20px on the
/// sides (`space-container-horizontal`); the footer sits under a 1px divider.
class CsContainer extends StatelessWidget {
  const CsContainer({
    super.key,
    this.header,
    this.footer,
    this.media,
    this.variant = CsContainerVariant.defaultVariant,
    this.stackPosition = CsStackPosition.only,
    this.disableHeaderPaddings = false,
    this.disableContentPaddings = false,
    this.disableFooterPaddings = false,
    this.fitHeight = false,
    this.footerDivider = true,
    this.style,
    this.semanticLabel,
    this.child,
  });

  /// Usually a [CsHeader] with `variant: CsHeaderVariant.h2`.
  final Widget? header;

  /// Actions or summary under the content, separated by a divider.
  final Widget? footer;

  /// An image or video at the top or start of the container.
  final CsContainerMedia? media;
  final CsContainerVariant variant;

  /// Position in a stack of [CsContainerVariant.stacked] containers.
  final CsStackPosition stackPosition;
  final bool disableHeaderPaddings;

  /// Removes the content padding, for content that brings its own (tables,
  /// maps, full-bleed charts).
  final bool disableContentPaddings;
  final bool disableFooterPaddings;

  /// Fill the height of the parent and let the content take the remaining
  /// space, for equal-height panels in a dashboard row. The parent must give
  /// a bounded height.
  final bool fitHeight;

  /// The divider line above the footer.
  final bool footerDivider;
  final CsContainerStyle? style;

  /// Announced name of the container region.
  final String? semanticLabel;

  /// The container content (Cloudscape `children`).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final r = Radius.circular(style?.borderRadius ?? CsBorderRadius.container);
    final stacked = variant == CsContainerVariant.stacked;
    final topRound = !stacked || stackPosition == CsStackPosition.first || stackPosition == CsStackPosition.only;
    final bottomRound = !stacked || stackPosition == CsStackPosition.last || stackPosition == CsStackPosition.only;
    final radius = BorderRadius.only(
      topLeft: topRound ? r : Radius.zero,
      topRight: topRound ? r : Radius.zero,
      bottomLeft: bottomRound ? r : Radius.zero,
      bottomRight: bottomRound ? r : Radius.zero,
    );
    final side = BorderSide(
      color: style?.borderColor ?? c.borderDividerDefault,
      width: style?.borderWidth ?? CsBorderLine.dividerSectionWidth,
    );
    // `variant-stacked:not(:last-child)`: no bottom border, the next
    // container's top border is the line between them.
    final border = stacked && !bottomRound ? Border(top: side, left: side, right: side) : Border.fromBorderSide(side);

    final hasHeader = header != null;
    final parts = <Widget>[];
    if (hasHeader) {
      parts.add(
        Padding(
          padding: disableHeaderPaddings
              ? EdgeInsets.zero
              : style?.headerPadding ??
                    EdgeInsets.only(
                      top: CsSpace.containerHeaderTop,
                      bottom: cs.space.containerHeaderBottom,
                      left: CsSpace.containerHorizontal,
                      right: CsSpace.containerHorizontal,
                    ),
          child: Semantics(container: true, child: header),
        ),
      );
    }
    if (child != null) {
      Widget content = Padding(
        padding: disableContentPaddings
            ? EdgeInsets.zero
            : style?.contentPadding ??
                  EdgeInsets.only(
                    top: hasHeader ? CsSpace.containerContentTop : cs.space.containerContentVertical,
                    bottom: cs.space.containerContentVertical,
                    left: CsSpace.containerHorizontal,
                    right: CsSpace.containerHorizontal,
                  ),
        child: child,
      );
      if (fitHeight) content = Expanded(child: content);
      parts.add(content);
    } else {
      if (hasHeader && !disableHeaderPaddings) {
        // `with-hidden-content`: the header alone keeps the container's bottom padding.
        parts.add(SizedBox(height: cs.space.containerContentVertical - cs.space.containerHeaderBottom));
      }
      if (fitHeight) parts.add(const Spacer());
    }
    if (footer != null) {
      parts.add(
        DecoratedBox(
          decoration: BoxDecoration(
            border: footerDivider
                ? Border(
                    top: BorderSide(
                      color: style?.footerDividerColor ?? c.borderDividerDefault,
                      width: style?.footerDividerWidth ?? CsBorderLine.dividerSectionWidth,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: disableFooterPaddings
                ? EdgeInsets.zero
                : style?.footerPadding ??
                      EdgeInsets.symmetric(vertical: cs.space.scaledS, horizontal: CsSpace.containerHorizontal),
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

    final m = media;
    if (m != null) {
      final inner = body;
      body = LayoutBuilder(
        builder: (context, constraints) {
          final useSide = m.position == CsContainerMediaPosition.side && !context.csIsNarrow;
          if (useSide) {
            final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth * 0.66 : double.infinity;
            final w = (m.width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth / 3 : 200)).clamp(0.0, maxW);
            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: w,
                  child: ClipRect(child: m.content),
                ),
                Expanded(child: inner),
              ],
            );
            return fitHeight ? row : IntrinsicHeight(child: row);
          }
          final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight * 0.66 : double.infinity;
          final h = m.height?.clamp(0.0, maxH);
          return Column(
            mainAxisSize: fitHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: h,
                child: ClipRect(child: m.content),
              ),
              if (fitHeight) Expanded(child: inner) else inner,
            ],
          );
        },
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: style?.background ?? c.backgroundContainerContent,
          borderRadius: radius,
          boxShadow: style?.boxShadow,
        ),
        foregroundDecoration: BoxDecoration(borderRadius: radius, border: border),
        clipBehavior: Clip.antiAlias,
        child: DefaultTextStyle.merge(style: cs.body, child: body),
      ),
    );
  }
}
