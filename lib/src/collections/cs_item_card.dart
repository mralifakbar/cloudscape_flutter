import 'package:flutter/widgets.dart';

import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// Item card sizes (Cloudscape item card `variant`).
enum CsItemCardVariant {
  /// Container radius (16px) and 20px side padding.
  defaultVariant,

  /// Compact radius (8px) and 12px side padding, for cards inside other
  /// surfaces.
  embedded,
}

/// Visual overrides for [CsItemCard] (Cloudscape item card `style`). Every
/// field is optional and falls back to the theme tokens.
@immutable
class CsItemCardStyle {
  const CsItemCardStyle({
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
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? footerPadding;

  /// Draws a divider above the footer in this color.
  final Color? footerDividerColor;
  final double? footerDividerWidth;
}

/// Cloudscape's `ItemCard`: a bordered card for one item, with a header row
/// (icon, title, description, actions), content and a footer. [CsCards]
/// renders each card with it.
///
/// ```dart
/// CsItemCard(
///   icon: const CsIcon(CsIcons.folder),
///   header: const Text('example-bucket'),
///   description: const Text('us-east-1'),
///   actions: CsButton(icon: CsIcons.ellipsis, variant: CsButtonVariant.icon, semanticLabel: 'Actions', onPress: () {}),
///   footer: const Text('Updated 2 hours ago'),
///   child: const Text('Versioning enabled'),
/// )
/// ```
///
/// Visual refresh: `color-background-item-card`, a 1px
/// `color-border-item-card` border drawn inside the edge, 16px radius
/// (8px embedded). A [highlighted] card (a selected card in [CsCards]) turns
/// `color-background-item-selected` with a 2px
/// `color-border-item-card-highlighted` border.
class CsItemCard extends StatelessWidget {
  const CsItemCard({
    super.key,
    this.header,
    this.description,
    this.footer,
    this.actions,
    this.icon,
    this.child,
    this.variant = CsItemCardVariant.defaultVariant,
    this.disableHeaderPaddings = false,
    this.disableContentPaddings = false,
    this.disableFooterPaddings = false,
    this.fitHeight = false,
    this.highlighted = false,
    this.onPress,
    this.semanticLabel,
    this.style,
  });

  /// Title of the card, shown in heading-s (16px bold).
  final Widget? header;

  /// Subtitle under the header, in body-s and `color-text-heading-secondary`.
  final Widget? description;

  /// Content at the bottom of the card.
  final Widget? footer;

  /// Buttons or links at the end of the header row. They wrap below the
  /// title when the card is narrow.
  final Widget? actions;

  /// Shown before the header.
  final Widget? icon;

  /// Main content (Cloudscape `children`).
  final Widget? child;
  final CsItemCardVariant variant;
  final bool disableHeaderPaddings;
  final bool disableContentPaddings;
  final bool disableFooterPaddings;

  /// Stretches the card to the height it is given, pushing the footer to the
  /// bottom, so cards in one row line up. Needs a bounded height.
  final bool fitHeight;

  /// The selected look. Not part of Cloudscape's public item card API; cards
  /// use it for selected items.
  final bool highlighted;

  /// Makes the whole card pressable (Cloudscape's internal `onClick`, used by
  /// cards with `entireCardClickable`).
  final VoidCallback? onPress;

  /// Accessible name of the card when [onPress] is set.
  final String? semanticLabel;
  final CsItemCardStyle? style;

  @override
  Widget build(BuildContext context) {
    // Filling the height needs a bounded height; elsewhere the card hugs
    // its content.
    if (!fitHeight) return _build(context, false);
    return LayoutBuilder(builder: (context, constraints) => _build(context, constraints.hasBoundedHeight));
  }

  Widget _build(BuildContext context, bool fitHeight) {
    final cs = context.cs;
    final c = cs.colors;
    final embedded = variant == CsItemCardVariant.embedded;
    final radiusValue =
        style?.borderRadius ?? (embedded ? CsBorderRadius.itemCardEmbedded : CsBorderRadius.itemCardDefault);
    final radius = BorderRadius.circular(radiusValue);
    final padBlock = embedded ? cs.space.itemCardVerticalEmbedded : cs.space.itemCardVerticalDefault;
    final padInline = embedded ? cs.space.itemCardHorizontalEmbedded : CsSpace.itemCardHorizontalDefault;
    // Cloudscape `$action-padding-*`: a header with actions trims its
    // padding so the 32px buttons do not make the row taller.
    const actionTrimBlock = CsSpace.xxxs;
    const actionTrimInline = CsSpace.xxs;

    final hasHeader = header != null || description != null || icon != null || actions != null;
    final hasBody = child != null;
    final hasFooter = footer != null;

    final sections = <Widget>[];
    if (hasHeader) {
      final next = hasBody || hasFooter;
      final withActions = actions != null;
      final EdgeInsetsGeometry padding =
          style?.headerPadding ??
          (disableHeaderPaddings
              ? EdgeInsets.zero
              : EdgeInsetsDirectional.only(
                  start: padInline,
                  end: withActions ? padInline - actionTrimInline : padInline,
                  top: withActions ? padBlock - actionTrimBlock : padBlock,
                  bottom: next ? CsSpace.xxs : (withActions ? padBlock - actionTrimBlock : padBlock),
                ));
      sections.add(
        Padding(
          padding: padding,
          child: _HeaderRow(
            icon: icon,
            header: header,
            description: description,
            actions: actions,
            disablePaddings: disableHeaderPaddings,
          ),
        ),
      );
    }
    if (hasBody) {
      final EdgeInsetsGeometry padding =
          style?.contentPadding ??
          (disableContentPaddings
              ? EdgeInsets.zero
              : EdgeInsetsDirectional.only(
                  start: padInline,
                  end: padInline,
                  top: hasHeader ? CsSpace.xxs : padBlock,
                  bottom: hasFooter ? CsSpace.xxs : padBlock,
                ));
      Widget body = Padding(padding: padding, child: child);
      if (fitHeight) body = Expanded(child: body);
      sections.add(body);
    } else if (fitHeight && hasFooter) {
      sections.add(const Spacer());
    }
    if (hasFooter) {
      final EdgeInsetsGeometry padding =
          style?.footerPadding ??
          (disableFooterPaddings
              ? EdgeInsets.zero
              : EdgeInsetsDirectional.only(
                  start: padInline,
                  end: padInline,
                  top: (hasHeader || hasBody) ? CsSpace.xxs : padBlock,
                  bottom: padBlock,
                ));
      final divider = style?.footerDividerColor != null || style?.footerDividerWidth != null;
      sections.add(
        DecoratedBox(
          decoration: BoxDecoration(
            border: divider
                ? Border(
                    top: BorderSide(
                      color: style?.footerDividerColor ?? c.borderDividerDefault,
                      width: style?.footerDividerWidth ?? CsBorderLine.dividerSectionWidth,
                    ),
                  )
                : null,
          ),
          child: Padding(padding: padding, child: footer),
        ),
      );
    }

    final background = highlighted ? c.backgroundItemSelected : (style?.background ?? c.backgroundItemCard);
    final borderColor = highlighted ? c.borderItemCardHighlighted : (style?.borderColor ?? c.borderItemCard);
    final borderWidth = highlighted ? CsBorderWidth.cardSelected : (style?.borderWidth ?? CsBorderWidth.itemCard);
    final duration = CsMotion.duration(context, CsDurations.showPaced);

    Widget card = AnimatedContainer(
      duration: duration,
      curve: CsCurves.showPaced,
      decoration: BoxDecoration(color: background, borderRadius: radius, boxShadow: style?.boxShadow),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth, strokeAlign: BorderSide.strokeAlignInside),
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(
        style: cs.body,
        child: Column(
          mainAxisSize: fitHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections,
        ),
      ),
    );

    if (onPress != null) {
      final inner = card;
      card = CsPressable(
        onPress: onPress,
        borderRadius: radius,
        scaleOnPress: false,
        focusRingOffset: 2,
        selected: highlighted,
        semanticLabel: semanticLabel,
        mergeChildSemantics: false,
        minTapTargetSize: 0,
        child: inner,
      );
    }
    return Semantics(container: true, explicitChildNodes: true, child: card);
  }
}

/// Cloudscape's structured item: icon, then title and description stacked,
/// then actions that wrap below when there is no room.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.header,
    required this.description,
    required this.actions,
    required this.disablePaddings,
  });

  final Widget? icon;
  final Widget? header;
  final Widget? description;
  final Widget? actions;
  final bool disablePaddings;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gap = disablePaddings ? 0.0 : CsSpace.xs;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Semantics(
            header: true,
            child: DefaultTextStyle.merge(style: cs.text(CsTypeScale.headingS), child: header!),
          ),
        if (description != null)
          DefaultTextStyle.merge(
            style: cs.text(CsTypeScale.bodyS, color: CsColor.textHeadingSecondary),
            child: description!,
          ),
      ],
    );
    Widget main = title;
    if (actions != null) {
      main = _ActionsRow(title: title, actions: actions!, gap: gap);
    }
    if (icon == null) return main;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: CsSpace.xxxs),
          child: icon,
        ),
        Expanded(child: main),
      ],
    );
  }
}

/// Title and actions side by side when they fit; otherwise actions move to
/// a second line, aligned to the end.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.title, required this.actions, required this.gap});

  final Widget title;
  final Widget actions;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below about 200px there is no room for both on one line.
        if (constraints.maxWidth < 200) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: CsSpace.xxxs),
                child: title,
              ),
              Align(alignment: AlignmentDirectional.centerEnd, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: CsSpace.xxxs),
                child: title,
              ),
            ),
            actions,
          ],
        );
      },
    );
  }
}
