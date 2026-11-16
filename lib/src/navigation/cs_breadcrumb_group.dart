import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_link.dart';
import 'cs_nav_menu.dart';

/// One breadcrumb (Cloudscape `BreadcrumbGroupProps.Item`).
@immutable
class CsBreadcrumbGroupItem {
  const CsBreadcrumbGroupItem({required this.text, required this.href, this.data});

  /// The title of the page.
  final String text;

  /// The page's path or route name. Flutter never opens it; it identifies
  /// the item in [CsBreadcrumbGroup.onFollow].
  final String href;

  /// Any value of yours to carry along (a route argument, a resource id).
  final Object? data;

  @override
  bool operator ==(Object other) =>
      other is CsBreadcrumbGroupItem && other.text == text && other.href == href && other.data == data;

  @override
  int get hashCode => Object.hash(text, href, data);

  @override
  String toString() => 'CsBreadcrumbGroupItem($text, $href)';
}

/// Copy for [CsBreadcrumbGroup].
@immutable
class CsBreadcrumbGroupI18nStrings {
  const CsBreadcrumbGroupI18nStrings({this.expandAriaLabel = 'Show path', this.ariaLabel});

  /// Accessible name of the ellipsis button that lists the hidden items
  /// (Cloudscape `expandAriaLabel`).
  final String expandAriaLabel;

  /// Accessible name of the whole group. Defaults to
  /// `CsStrings.breadcrumbs`.
  final String? ariaLabel;
}

/// Cloudscape's `BreadcrumbGroup`: the path from the top of the hierarchy to
/// the current page.
///
/// ```dart
/// CsBreadcrumbGroup(
///   items: const [
///     CsBreadcrumbGroupItem(text: 'Service', href: '/'),
///     CsBreadcrumbGroupItem(text: 'Buckets', href: '/buckets'),
///     CsBreadcrumbGroupItem(text: 'example-bucket', href: '/buckets/example-bucket'),
///   ],
///   onFollow: (item) => Navigator.of(context).pushNamed(item.href),
/// )
/// ```
///
/// The last item is the current page: bold, not a link, announced as the
/// current page. When the items do not fit the width, the ones after the
/// first collapse into an ellipsis button that lists them in a dropdown
/// (a bottom sheet on phones). When only the first item would remain, the
/// whole path becomes one button with the current page title that opens the
/// full list, as Cloudscape does on narrow screens. A truncated last item
/// shows its full text in a tooltip.
class CsBreadcrumbGroup extends StatelessWidget {
  const CsBreadcrumbGroup({
    super.key,
    required this.items,
    this.onFollow,
    this.onClick,
    this.ariaLabel,
    this.expandAriaLabel,
    this.i18nStrings = const CsBreadcrumbGroupI18nStrings(),
    this.presentation = CsPresentation.auto,
  });

  /// The path, root first. The last item is the current page.
  final List<CsBreadcrumbGroupItem> items;

  /// Called when an item (not the current page) is followed. Navigate here.
  final ValueChanged<CsBreadcrumbGroupItem>? onFollow;

  /// Called on every item activation before [onFollow]; for side effects.
  final ValueChanged<CsBreadcrumbGroupItem>? onClick;

  /// Accessible name of the group. Overrides [i18nStrings].
  final String? ariaLabel;

  /// Accessible name of the ellipsis button. Overrides [i18nStrings].
  final String? expandAriaLabel;
  final CsBreadcrumbGroupI18nStrings i18nStrings;

  /// How the list of collapsed items opens: a dropdown on wide screens and a
  /// bottom sheet on phones by default.
  final CsPresentation presentation;

  // Cloudscape's MIN_BREADCRUMB_WIDTH and ELLIPSIS_WIDTH (breadcrumb-group/utils.ts).
  static const double _minLastWidth = 70;
  static const double _ellipsisWidth = 50;

  void _follow(CsBreadcrumbGroupItem item) {
    onClick?.call(item);
    onFollow?.call(item);
  }

  /// Number of items after the first that collapse into the ellipsis, as
  /// Cloudscape's `computeNumberOfCollapsedItems`.
  static int collapsedCount(List<double> widths, double available) {
    if (widths.isEmpty || !available.isFinite) return 0;
    final w = [...widths];
    w[w.length - 1] = math.min(w.last, _minLastWidth);
    var used = w.fold<double>(0, (a, b) => a + b);
    var collapsed = 0;
    while (collapsed < w.length - 1) {
      if (used <= available) break;
      collapsed += 1;
      used -= w[collapsed];
      if (collapsed == 1) used += _ellipsisWidth;
    }
    return collapsed;
  }

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final label = ariaLabel ?? i18nStrings.ariaLabel ?? context.csStrings.breadcrumbs;
    final expandLabel = expandAriaLabel ?? i18nStrings.expandAriaLabel;
    if (items.isEmpty) return const SizedBox.shrink();
    final linkStyle = cs.body;
    final currentStyle = cs.text(
      CsTypeScale.bodyM,
      weight: CsFontTokens.fontWeightBreadcrumbCurrent,
      color: CsColor.textBreadcrumbCurrent,
    );
    // Separator: a 16px icon with space-xs on both sides.
    const separator = CsSize.iconNormal + 2 * CsSpace.xs;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widths = [
              for (var i = 0; i < items.length; i++)
                i == items.length - 1
                    ? _textWidth(context, items[i].text, currentStyle)
                    : _textWidth(context, items[i].text, linkStyle) + separator,
            ];
            final collapsed = collapsedCount(widths, constraints.maxWidth);
            if (items.length > 1 && collapsed == items.length - 1) {
              return _AllItemsDropdown(items: items, presentation: presentation, onFollow: _follow, label: label);
            }
            final children = <Widget>[];
            for (var i = 0; i < items.length; i++) {
              final last = i == items.length - 1;
              if (i > 0 && i <= collapsed) {
                if (i == 1) {
                  children.add(
                    _Ellipsis(
                      label: expandLabel,
                      presentation: presentation,
                      entries: [
                        for (var j = 1; j <= collapsed; j++)
                          CsNavMenuEntry(text: items[j].text, onPress: () => _follow(items[j])),
                      ],
                    ),
                  );
                  children.add(const _Separator());
                }
                continue;
              }
              if (last) {
                children.add(
                  Flexible(
                    child: _Current(text: items[i].text, style: currentStyle),
                  ),
                );
              } else {
                final item = items[i];
                children.add(
                  CsLink(
                    text: item.text,
                    href: item.href,
                    variant: CsLinkVariant.primary,
                    fontSize: CsLinkFontSize.bodyM,
                    maxLines: 1,
                    onFollow: () => _follow(item),
                  ),
                );
                children.add(const _Separator());
              }
            }
            return Row(mainAxisSize: MainAxisSize.min, children: children);
          },
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs),
      child: CsIcon(CsIcons.angleRight, dangerouslySetColor: context.cs.colors.textBreadcrumbIcon),
    ),
  );
}

/// The current page: bold, not a link, focusable so the tooltip of a
/// truncated title is reachable by keyboard.
class _Current extends StatelessWidget {
  const _Current({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final truncated = painter.width > constraints.maxWidth;
        painter.dispose();
        Widget label = Text(text, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
        if (truncated) label = CsTooltip(content: text, child: label);
        return Semantics(link: true, enabled: false, selected: true, label: text, excludeSemantics: true, child: label);
      },
    );
  }
}

class _Ellipsis extends StatelessWidget {
  const _Ellipsis({required this.label, required this.entries, required this.presentation});

  final String label;
  final List<CsNavMenuEntry> entries;
  final CsPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    return CsNavMenu(
      entries: entries,
      label: label,
      presentation: presentation,
      triggerBuilder: (context, open, toggle) => CsPressable(
        onPress: toggle,
        semanticLabel: label,
        excludeChildSemantics: true,
        expanded: open,
        scaleOnPress: false,
        focusRingOffset: CsSpace.buttonFocusOutlineGutter,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        builder: (context, state) {
          final fg = state.active ? c.textLinkHover : c.textLinkDefault;
          return Text(
            '...',
            style: context.cs.body.copyWith(
              color: fg,
              decoration: state.hovered ? TextDecoration.underline : null,
              decorationColor: fg,
            ),
          );
        },
      ),
    );
  }
}

/// The narrow-screen form: a caret and the current page title that opens
/// the whole path (Cloudscape's `AllItemsDropdown`).
class _AllItemsDropdown extends StatelessWidget {
  const _AllItemsDropdown({
    required this.items,
    required this.presentation,
    required this.onFollow,
    required this.label,
  });

  final List<CsBreadcrumbGroupItem> items;
  final CsPresentation presentation;
  final ValueChanged<CsBreadcrumbGroupItem> onFollow;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    return CsNavMenu(
      label: label,
      presentation: presentation,
      entries: [
        for (var i = 0; i < items.length; i++)
          CsNavMenuEntry(
            text: items[i].text,
            current: i == items.length - 1,
            onPress: i == items.length - 1 ? null : () => onFollow(items[i]),
          ),
      ],
      triggerBuilder: (context, open, toggle) => CsPressable(
        onPress: toggle,
        expanded: open,
        semanticLabel: items.last.text,
        semanticHint: label,
        excludeChildSemantics: true,
        scaleOnPress: false,
        focusRingOffset: CsSpace.buttonFocusOutlineGutter,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        builder: (context, state) {
          final iconColor = state.active ? c.textInteractiveHover : c.textInteractiveDefault;
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.xxs,
            children: [
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: CsMotion.duration(context, CsDurations.responsive),
                curve: CsCurves.responsive,
                child: CsIcon(CsIcons.caretDownFilled, dangerouslySetColor: iconColor),
              ),
              Flexible(
                child: Text(
                  items.last.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: cs.text(
                    CsTypeScale.bodyM,
                    weight: CsFontTokens.fontWeightBreadcrumbCurrent,
                    color: state.active ? CsColor.textInteractiveHover : CsColor.textBreadcrumbCurrent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
