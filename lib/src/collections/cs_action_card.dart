import 'package:flutter/widgets.dart';

import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// Action card sizes (Cloudscape action card `variant`).
enum CsActionCardVariant {
  /// Container radius (16px) and 20px side padding.
  defaultVariant,

  /// Compact radius (8px) and 12px side padding.
  embedded,
}

/// Where the icon sits vertically (Cloudscape `iconVerticalAlignment`).
enum CsActionCardIconVerticalAlignment {
  /// Level with the header.
  top,

  /// Centered on the whole card.
  center,
}

/// Cloudscape's `ActionCard`: a whole card that is one button (or link), for
/// choosing between a few actions or destinations ("Create bucket", "Import
/// from a template").
///
/// ```dart
/// CsActionCard(
///   header: const Text('Launch instance'),
///   description: const Text('Start a virtual server from an image.'),
///   icon: const CsIcon(CsIcons.angleRight),
///   onPress: () {},
/// )
/// ```
///
/// Visual refresh: `color-background-action-card-*` and
/// `color-border-action-card-*` per state (default, hover, active,
/// disabled), a 1px border drawn inside the edge and a 16px radius (8px
/// embedded). The icon sits at the end of the card. Hover colors switch at
/// once; pressing scales the card to 0.98 with a spring.
class CsActionCard extends StatelessWidget {
  const CsActionCard({
    super.key,
    this.header,
    this.description,
    this.child,
    this.onPress,
    this.onFollow,
    this.isLink = false,
    this.ariaLabel,
    this.disabled = false,
    this.disableHeaderPaddings = false,
    this.disableContentPaddings = false,
    this.fitHeight = false,
    this.icon,
    this.iconVerticalAlignment = CsActionCardIconVerticalAlignment.top,
    this.variant = CsActionCardVariant.defaultVariant,
    this.focusNode,
    this.autofocus = false,
  });

  /// Title, in heading-s (16px bold). It names the button.
  final Widget? header;

  /// Text under the header in body-s.
  final Widget? description;

  /// More content under the header and description.
  final Widget? child;

  /// Called when the card is pressed (Cloudscape `onClick`).
  final VoidCallback? onPress;

  /// Called when a link card ([isLink]) is followed (Cloudscape `onFollow`).
  final VoidCallback? onFollow;

  /// Announce the card as a link (Cloudscape `href`).
  final bool isLink;

  /// Accessible name; defaults to the header text.
  final String? ariaLabel;

  /// Disabled cards keep their content readable in the disabled text color
  /// and ignore presses.
  final bool disabled;
  final bool disableHeaderPaddings;
  final bool disableContentPaddings;

  /// Stretches to the height it is given, so cards in a row line up. Needs a
  /// bounded height.
  final bool fitHeight;

  /// Shown at the end of the card, such as an arrow.
  final Widget? icon;
  final CsActionCardIconVerticalAlignment iconVerticalAlignment;
  final CsActionCardVariant variant;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final embedded = variant == CsActionCardVariant.embedded;
    final radius = BorderRadius.circular(
      embedded ? CsBorderRadius.actionCardEmbedded : CsBorderRadius.actionCardDefault,
    );
    final padBlock = embedded ? cs.space.actionCardVerticalEmbedded : cs.space.actionCardVerticalDefault;
    final padInline = embedded ? cs.space.actionCardHorizontalEmbedded : CsSpace.actionCardHorizontalDefault;
    final interactive = !disabled && (onPress != null || onFollow != null);

    return CsPressable(
      onPress: interactive
          ? () {
              onPress?.call();
              if (isLink) onFollow?.call();
            }
          : null,
      disabled: disabled,
      isLink: isLink,
      focusNode: focusNode,
      autofocus: autofocus,
      borderRadius: radius,
      focusRingOffset: 2,
      minTapTargetSize: 0,
      semanticLabel: ariaLabel,
      // Cloudscape names the card with `ariaLabel` when given; the content
      // then stays out of the name.
      excludeChildSemantics: ariaLabel != null,
      builder: (context, state) => fitHeight
          ? LayoutBuilder(
              builder: (context, constraints) =>
                  _surface(context, state, radius, padBlock, padInline, constraints.hasBoundedHeight),
            )
          : _surface(context, state, radius, padBlock, padInline, false),
    );
  }

  Widget _surface(
    BuildContext context,
    CsPressState state,
    BorderRadius radius,
    double padBlock,
    double padInline,
    bool fitHeight,
  ) {
    final cs = context.cs;
    final c = cs.colors;
    final Color background;
    final Color border;
    final Color iconColor;
    if (disabled) {
      background = c.backgroundActionCardDisabled;
      border = c.borderActionCardDisabled;
      iconColor = c.textActionCardIconDisabled;
    } else if (state.pressed) {
      background = c.backgroundActionCardActive;
      border = c.borderActionCardActive;
      iconColor = c.textActionCardIconActive;
    } else if (state.hovered) {
      background = c.backgroundActionCardHover;
      border = c.borderActionCardHover;
      iconColor = c.textActionCardIconHover;
    } else {
      background = c.backgroundActionCardDefault;
      border = c.borderActionCardDefault;
      iconColor = c.textActionCardIconDefault;
    }

    final hasIcon = icon != null;
    // `icon-align-end`: content keeps 8px from the icon instead of the full
    // side padding.
    final endPad = hasIcon ? CsSpace.xs : padInline;
    final hasHeaderRow = header != null || description != null;

    Widget? headerSection;
    if (hasHeaderRow) {
      headerSection = Padding(
        padding: disableHeaderPaddings
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.only(
                start: padInline,
                end: endPad,
                top: padBlock,
                bottom: child != null ? CsSpace.xxs : padBlock,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null)
              DefaultTextStyle.merge(
                style: cs.text(
                  CsTypeScale.headingS,
                  color: disabled ? CsColor.textActionCardDisabled : CsColor.textHeadingDefault,
                ),
                child: header!,
              ),
            if (description != null)
              Padding(
                padding: EdgeInsets.only(top: header != null ? cs.space.actionCardDescriptionPaddingTop : 0),
                child: DefaultTextStyle.merge(
                  style: cs.text(
                    CsTypeScale.bodyS,
                    color: disabled ? CsColor.textActionCardDisabled : CsColor.textBodySecondary,
                  ),
                  child: description!,
                ),
              ),
          ],
        ),
      );
    }

    Widget? body;
    if (child != null) {
      body = Padding(
        padding: disableContentPaddings
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.only(
                start: padInline,
                end: endPad,
                top: hasHeaderRow ? CsSpace.xxs : padBlock,
                bottom: padBlock,
              ),
        child: DefaultTextStyle.merge(
          style: disabled ? TextStyle(color: c.textActionCardDisabled) : const TextStyle(),
          child: child!,
        ),
      );
      if (fitHeight) body = Expanded(child: body);
    }

    final iconWidget = hasIcon
        ? ExcludeSemantics(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: padBlock, end: padInline, bottom: padBlock),
              child: IconTheme.merge(
                data: IconThemeData(color: iconColor),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: iconColor),
                  child: icon!,
                ),
              ),
            ),
          )
        : null;

    final inner = Column(
      mainAxisSize: fitHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?headerSection, ?body],
    );

    Widget content = inner;
    if (iconWidget != null) {
      content = Row(
        crossAxisAlignment: iconVerticalAlignment == CsActionCardIconVerticalAlignment.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(child: inner),
          iconWidget,
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(color: background, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: border,
          width: CsBorderWidth.actionCardDefault,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(style: cs.body, child: content),
    );
  }
}
