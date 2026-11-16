import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Heading levels (Cloudscape `variant`).
enum CsHeaderVariant {
  /// Page title: heading-xl.
  h1(CsTypeScale.headingXl),

  /// Container or section title: heading-l.
  h2(CsTypeScale.headingL),

  /// Smaller section title: heading-m.
  h3(CsTypeScale.headingM),

  /// A page title that shrinks to h2 size when stuck under the top bar.
  awsuiH1Sticky(CsTypeScale.headingXl);

  const CsHeaderVariant(this.scale);
  final CsTypeScale scale;
}

/// Cloudscape's `Header`: the title of a page, container or section, with an
/// optional counter, info link, description and actions.
///
/// ```dart
/// CsHeader(
///   variant: CsHeaderVariant.h1,
///   title: 'Instances',
///   counter: '(12)',
///   info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: openHelp),
///   description: 'Virtual servers in the cloud.',
///   actions: CsSpaceBetween(
///     direction: CsSpaceBetweenDirection.horizontal,
///     size: CsSpacingSize.xs,
///     children: [
///       CsButton(text: 'Actions', onPress: () {}),
///       CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: () {}),
///     ],
///   ),
/// )
/// ```
///
/// Actions sit at the end of the title row and wrap under it when there is
/// not enough room.
class CsHeader extends StatelessWidget {
  const CsHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.variant = CsHeaderVariant.h2,
    this.counter,
    this.info,
    this.description,
    this.descriptionWidget,
    this.actions,
    this.headingTagOverride,
  }) : assert(title != null || titleWidget != null, 'Pass title or titleWidget');

  final String? title;
  final Widget? titleWidget;
  final CsHeaderVariant variant;

  /// A count after the title, such as "(12)" or "(2/12)".
  final String? counter;

  /// An info link, usually `CsLink(variant: CsLinkVariant.info)`.
  final Widget? info;
  final String? description;
  final Widget? descriptionWidget;

  /// Buttons for the page or container, at the end of the title row.
  final Widget? actions;

  /// Heading level announced to screen readers when it should differ from
  /// the visual [variant] (Cloudscape `headingTagOverride`), 1 to 5.
  final int? headingTagOverride;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final titleStyle = cs.text(variant.scale);
    final lineHeight = variant.scale.lineHeight;
    final inputHeight = cs.space.sizeVerticalInput;
    // Visual refresh centers the title on the 32px row of buttons.
    final titlePad = ((inputHeight - lineHeight) / 2).clamp(0.0, 8.0);

    final titleRow = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CsSpace.xs,
      runSpacing: CsSpace.xxs,
      children: [
        Semantics(
          header: true,
          child: DefaultTextStyle(
            style: titleStyle,
            child: Text.rich(
              TextSpan(
                children: [
                  if (titleWidget != null)
                    WidgetSpan(child: titleWidget!, alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic)
                  else
                    TextSpan(text: title),
                  if (counter != null)
                    TextSpan(
                      text: ' $counter',
                      style: TextStyle(color: cs.colors.textCounter, fontWeight: CsTypography.normal),
                    ),
                ],
              ),
            ),
          ),
        ),
        ?info,
      ],
    );

    final desc = descriptionWidget ??
        (description == null
            ? null
            : Text(
                description!,
                style: cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingSecondary),
              ));

    final main = Padding(
      padding: EdgeInsets.only(top: actions != null ? titlePad : 0),
      child: titleRow,
    );

    Widget top;
    if (actions == null) {
      top = main;
    } else {
      // Prefer title and actions on one row; let the title take the space.
      top = LayoutBuilder(
        builder: (context, constraints) => _HeaderRow(
          maxWidth: constraints.maxWidth,
          title: main,
          actions: ConstrainedBox(constraints: BoxConstraints(minHeight: inputHeight), child: actions),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        top,
        if (desc != null) ...[
          SizedBox(height: variant == CsHeaderVariant.h1 ? cs.space.scaled2xXxs : CsSpace.xxxs),
          DefaultTextStyle.merge(style: cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingSecondary), child: desc),
        ],
      ],
    );
  }
}

/// Lays the title and actions out on one row when both fit, and the actions
/// under the title otherwise.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.maxWidth, required this.title, required this.actions});

  final double maxWidth;
  final Widget title;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    // Cloudscape wraps the actions under the title on narrow screens.
    if (maxWidth < 420) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CsSpace.xs,
        children: [title, actions],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: CsSpace.xs),
        Flexible(child: Align(alignment: AlignmentDirectional.topEnd, child: actions)),
      ],
    );
  }
}
