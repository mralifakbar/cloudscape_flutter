import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_nav_reveal.dart';

/// An item of [CsSideNavigation] (Cloudscape `SideNavigationProps.Item`).
///
/// One of [CsSideNavigationLink], [CsSideNavigationDivider],
/// [CsSideNavigationSection], [CsSideNavigationSectionGroup],
/// [CsSideNavigationLinkGroup] and [CsSideNavigationExpandableLinkGroup].
@immutable
sealed class CsSideNavigationItem {
  const CsSideNavigationItem();
}

/// Items that link somewhere and can show an icon.
sealed class CsSideNavigationLinkLike extends CsSideNavigationItem {
  const CsSideNavigationLinkLike();

  String get text;
  String get href;
  Widget? get info;
  CsIconData? get icon;
  Widget? get iconWidget;
  bool get _hasIcon => icon != null || iconWidget != null;
}

/// A link (Cloudscape `type: 'link'`).
class CsSideNavigationLink extends CsSideNavigationLinkLike {
  const CsSideNavigationLink({
    required this.text,
    required this.href,
    this.external = false,
    this.externalIconAriaLabel,
    this.info,
    this.icon,
    this.iconWidget,
  });

  @override
  final String text;

  /// The page this link opens; compared with [CsSideNavigation.activeHref].
  @override
  final String href;

  /// Shows the external icon. External links never become active.
  final bool external;
  final String? externalIconAriaLabel;

  /// Content after the text, such as a badge or a "New" label.
  @override
  final Widget? info;

  /// Icon before the text. Items with icons stay visible when the
  /// navigation is [CsSideNavigation.collapsed].
  @override
  final CsIconData? icon;

  /// Custom icon widget in place of [icon].
  @override
  final Widget? iconWidget;
}

/// A horizontal divider (Cloudscape `type: 'divider'`).
class CsSideNavigationDivider extends CsSideNavigationItem {
  const CsSideNavigationDivider();
}

/// A collapsible section with a title (Cloudscape `type: 'section'`).
class CsSideNavigationSection extends CsSideNavigationItem {
  const CsSideNavigationSection({required this.text, required this.items, this.defaultExpanded, this.info});

  final String text;
  final List<CsSideNavigationItem> items;

  /// Expanded on first build. Defaults to true.
  final bool? defaultExpanded;
  final Widget? info;
}

/// A heading over related items (Cloudscape `type: 'section-group'`). Not
/// collapsible.
class CsSideNavigationSectionGroup extends CsSideNavigationItem {
  const CsSideNavigationSectionGroup({required this.title, required this.items, this.info});

  final String title;
  final List<CsSideNavigationItem> items;
  final Widget? info;
}

/// A link with always-visible children indented under it
/// (Cloudscape `type: 'link-group'`).
class CsSideNavigationLinkGroup extends CsSideNavigationLinkLike {
  const CsSideNavigationLinkGroup({
    required this.text,
    required this.href,
    required this.items,
    this.info,
    this.icon,
    this.iconWidget,
  });

  @override
  final String text;
  @override
  final String href;
  final List<CsSideNavigationItem> items;
  @override
  final Widget? info;
  @override
  final CsIconData? icon;
  @override
  final Widget? iconWidget;
}

/// A link with collapsible children (Cloudscape
/// `type: 'expandable-link-group'`). Following the link also expands it.
class CsSideNavigationExpandableLinkGroup extends CsSideNavigationLinkLike {
  const CsSideNavigationExpandableLinkGroup({
    required this.text,
    required this.href,
    required this.items,
    this.defaultExpanded,
    this.info,
    this.icon,
    this.iconWidget,
  });

  @override
  final String text;
  @override
  final String href;
  final List<CsSideNavigationItem> items;

  /// Expanded on first build. When null it is expanded only while it or one
  /// of its links is active.
  final bool? defaultExpanded;
  @override
  final Widget? info;
  @override
  final CsIconData? icon;
  @override
  final Widget? iconWidget;
}

/// The header of [CsSideNavigation] (Cloudscape `SideNavigationProps.Header`).
@immutable
class CsSideNavigationHeader {
  const CsSideNavigationHeader({required this.href, this.text, this.logo});

  final String href;

  /// Usually the service name.
  final String? text;

  /// A logo before the text (Cloudscape `logo`). Never an AWS logo.
  final Widget? logo;
}

/// Kinds of items reported by [CsSideNavigation.onFollow].
enum CsSideNavigationFollowType { link, linkGroup, expandableLinkGroup, header }

/// Detail of [CsSideNavigation.onFollow].
@immutable
class CsSideNavigationFollowDetail {
  const CsSideNavigationFollowDetail({
    required this.href,
    required this.type,
    this.text,
    this.external = false,
    this.item,
  });

  final String href;
  final String? text;
  final CsSideNavigationFollowType type;
  final bool external;

  /// The followed item; null for the header.
  final CsSideNavigationLinkLike? item;

  @override
  String toString() => 'CsSideNavigationFollowDetail($href, $type)';
}

/// Detail of [CsSideNavigation.onChange].
@immutable
class CsSideNavigationChangeDetail {
  const CsSideNavigationChangeDetail({required this.item, required this.expanded, required this.expandableParents});

  /// The section or expandable link group that changed.
  final CsSideNavigationItem item;
  final bool expanded;

  /// Its section and expandable link group ancestors, outermost first.
  final List<CsSideNavigationItem> expandableParents;
}

/// Cloudscape's `SideNavigation`: the list of pages of a service, shown in
/// the navigation drawer of the app layout.
///
/// ```dart
/// CsSideNavigation(
///   header: const CsSideNavigationHeader(text: 'Service', href: '/'),
///   activeHref: active,
///   onFollow: (d) => setState(() => active = d.href),
///   items: const [
///     CsSideNavigationLink(text: 'Dashboard', href: '/dashboard'),
///     CsSideNavigationSection(text: 'Storage', items: [
///       CsSideNavigationLink(text: 'Buckets', href: '/buckets'),
///       CsSideNavigationLink(text: 'Access points', href: '/access-points'),
///     ]),
///     CsSideNavigationDivider(),
///     CsSideNavigationLink(text: 'Documentation', href: 'docs', external: true),
///   ],
/// )
/// ```
///
/// Links whose href equals [activeHref] are bold in the accent color.
/// Sections are expanded by default and expandable link groups expand while
/// they hold the active link; a person can toggle both, which calls
/// [onChange]. With [collapsed] only items with an icon remain, as round
/// icon buttons with their text in a tooltip.
///
/// On phones the app layout shows the navigation in a drawer; the list
/// itself wraps long titles and needs no separate mobile layout.
class CsSideNavigation extends StatefulWidget {
  const CsSideNavigation({
    super.key,
    this.items = const [],
    this.header,
    this.activeHref,
    this.itemsControl,
    this.onFollow,
    this.onChange,
    this.collapsed = false,
    this.ariaLabel,
  });

  final List<CsSideNavigationItem> items;
  final CsSideNavigationHeader? header;

  /// The href of the current page. Every link with this href is highlighted.
  final String? activeHref;

  /// A slot between the header and the items, such as a select to switch
  /// regions.
  final Widget? itemsControl;

  /// Called when a link, group link or the header is followed. Set
  /// [activeHref] here (external links excepted) and navigate.
  final ValueChanged<CsSideNavigationFollowDetail>? onFollow;

  /// Called when a person expands or collapses a section or an expandable
  /// link group.
  final ValueChanged<CsSideNavigationChangeDetail>? onChange;

  /// Icon-only rail: hides text, the header, the items control and every
  /// item without an icon.
  final bool collapsed;

  /// Accessible name of the navigation. Defaults to `CsStrings.navigation`.
  final String? ariaLabel;

  @override
  State<CsSideNavigation> createState() => _CsSideNavigationState();
}

// Cloudscape's side-navigation/styles.scss values.
const double _itemPaddingInline = CsSpace.xs;
const double _iconTextGap = CsSpace.xs;
const double _itemIndent = CsSize.iconNormal + _iconTextGap - _itemPaddingInline;
const double _expandableIconNegativeMargin = CsSpace.l;

// Cloudscape nests lists with `$item-indent` plus the list item padding, so
// child link text sits 24px in from its parent's text.
const double _nestedIndent = _itemIndent + _itemPaddingInline;

// Sections pull their header 20px toward the start (the caret hangs into
// the gutter); list items add 8px back.
const double _sectionHeaderShift = _expandableIconNegativeMargin - _itemPaddingInline;

class _CsSideNavigationState extends State<CsSideNavigation> {
  /// Expansion a person chose, by item identity. Cleared when items change.
  final Map<CsSideNavigationItem, bool> _userExpanded = {};

  @override
  void didUpdateWidget(CsSideNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) _userExpanded.clear();
  }

  static bool _containsActive(List<CsSideNavigationItem> items, String? href) {
    if (href == null) return false;
    for (final item in items) {
      if (item is CsSideNavigationLinkLike && item.href == href) return true;
      final children = switch (item) {
        CsSideNavigationSection(:final items) => items,
        CsSideNavigationLinkGroup(:final items) => items,
        CsSideNavigationExpandableLinkGroup(:final items) => items,
        CsSideNavigationSectionGroup(:final items) => items,
        _ => const <CsSideNavigationItem>[],
      };
      if (_containsActive(children, href)) return true;
    }
    return false;
  }

  bool _expanded(CsSideNavigationItem item) {
    final user = _userExpanded[item];
    if (user != null) return user;
    return switch (item) {
      CsSideNavigationSection(:final defaultExpanded) => defaultExpanded ?? true,
      CsSideNavigationExpandableLinkGroup(:final defaultExpanded, :final href, :final items) =>
        defaultExpanded ?? (href == widget.activeHref || _containsActive(items, widget.activeHref)),
      _ => true,
    };
  }

  void _setExpanded(CsSideNavigationItem item, bool expanded, List<CsSideNavigationItem> parents) {
    setState(() => _userExpanded[item] = expanded);
    widget.onChange?.call(
      CsSideNavigationChangeDetail(item: item, expanded: expanded, expandableParents: List.unmodifiable(parents)),
    );
  }

  void _follow(CsSideNavigationLinkLike item) {
    widget.onFollow?.call(
      CsSideNavigationFollowDetail(
        href: item.href,
        text: item.text,
        type: switch (item) {
          CsSideNavigationLink() => CsSideNavigationFollowType.link,
          CsSideNavigationLinkGroup() => CsSideNavigationFollowType.linkGroup,
          CsSideNavigationExpandableLinkGroup() => CsSideNavigationFollowType.expandableLinkGroup,
        },
        external: item is CsSideNavigationLink && item.external,
        item: item,
      ),
    );
  }

  bool get _withIcons => widget.items.any((i) => i is CsSideNavigationLinkLike && i._hasIcon);

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final collapsed = widget.collapsed;
    final header = widget.header;
    final withIcons = _withIcons;
    final itemPaddingBlock = (cs.space.sizeSideNavigationItemHeight - CsTypeScale.bodyM.lineHeight) / 2;
    final rootStart = collapsed
        ? (CsSize.sideNavigationCollapsedWidth - cs.space.sizeSideNavigationItemCollapsed) / 2
        : withIcons
        ? cs.space.scaledL - _itemPaddingInline
        : CsSpace.panelNavLeft - _itemPaddingInline;
    final rootEnd = collapsed
        ? rootStart
        : withIcons
        ? rootStart
        : cs.space.panelSideRight - _itemPaddingInline;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel ?? context.csStrings.navigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null && !collapsed) ...[
            _Header(
              header: header,
              active: header.href == widget.activeHref,
              withIcons: withIcons,
              onFollow: () {
                widget.onFollow?.call(
                  CsSideNavigationFollowDetail(
                    href: header.href,
                    text: header.text,
                    type: CsSideNavigationFollowType.header,
                  ),
                );
              },
            ),
            Container(height: CsBorderLine.dividerSectionWidth, color: cs.colors.borderPanelHeader),
          ],
          if (widget.itemsControl != null && !collapsed)
            Padding(
              padding: EdgeInsetsDirectional.only(start: CsSpace.l, end: CsSpace.l, top: cs.space.panelContentTop),
              child: widget.itemsControl,
            ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: rootStart,
              end: rootEnd,
              top: header == null && widget.itemsControl == null ? 0 : cs.space.panelContentTop - itemPaddingBlock,
              bottom: cs.space.panelContentBottom,
            ),
            child: _list(context, widget.items, parents: const [], variant: _ListVariant.root, withIcons: withIcons),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<CsSideNavigationItem> items, {
    required List<CsSideNavigationItem> parents,
    required _ListVariant variant,
    required bool withIcons,
  }) {
    final cs = context.cs;
    final collapsed = widget.collapsed;
    final itemPaddingBlock = (cs.space.sizeSideNavigationItemHeight - CsTypeScale.bodyM.lineHeight) / 2;
    final gap = collapsed || withIcons ? CsSpace.sideNavigationItemIconGap : CsSpace.sideNavigationItemDefaultGap;

    final children = <Widget>[];
    CsSideNavigationItem? previous;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      Widget? child;
      switch (item) {
        case CsSideNavigationDivider():
          // Skip doubled dividers and dividers at the edges, as Cloudscape does.
          if (previous == null || previous is CsSideNavigationDivider || i == items.length - 1) break;
          child = Padding(
            padding: EdgeInsets.symmetric(
              vertical: collapsed ? cs.space.scaled2xM : cs.space.scaled2xXl - itemPaddingBlock,
              horizontal: collapsed ? 0 : _itemPaddingInline,
            ),
            child: Container(height: CsBorderLine.dividerSectionWidth, color: cs.colors.borderDividerDefault),
          );
        case CsSideNavigationLink():
          if (collapsed && !item._hasIcon) break;
          child = _ItemPadding(
            collapsed: collapsed,
            child: _link(context, item, withIcons: withIcons),
          );
        case CsSideNavigationLinkGroup():
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!collapsed || item._hasIcon)
                _ItemPadding(
                  collapsed: collapsed,
                  child: _link(context, item, withIcons: withIcons),
                ),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: _nestedIndent),
                  child: _list(
                    context,
                    item.items,
                    parents: parents,
                    variant: _ListVariant.linkGroup,
                    withIcons: withIcons,
                  ),
                ),
            ],
          );
        case CsSideNavigationExpandableLinkGroup():
          child = _expandableLinkGroup(context, item, parents: parents, variant: variant, withIcons: withIcons);
        case CsSideNavigationSection():
          child = _section(context, item, parents: parents, variant: variant, withIcons: withIcons);
        case CsSideNavigationSectionGroup():
          child = _sectionGroup(context, item, parents: parents, withIcons: withIcons);
      }
      if (child == null) continue;
      previous = item;
      if (children.isNotEmpty && gap > 0) children.add(SizedBox(height: gap));
      children.add(child);
    }
    final double start = switch (variant) {
      _ListVariant.root || _ListVariant.section || _ListVariant.sectionGroup => 0,
      _ListVariant.expandableLinkGroup => collapsed ? 0 : _nestedIndent,
      _ListVariant.linkGroup => 0,
    };
    return Padding(
      padding: EdgeInsetsDirectional.only(start: start),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _link(BuildContext context, CsSideNavigationLinkLike item, {required bool withIcons, VoidCallback? onFollow}) {
    final active = !(item is CsSideNavigationLink && item.external) && item.href == widget.activeHref;
    return _NavLink(
      item: item,
      active: active,
      collapsed: widget.collapsed,
      withIcons: withIcons,
      onFollow: onFollow ?? () => _follow(item),
    );
  }

  Widget _expandableLinkGroup(
    BuildContext context,
    CsSideNavigationExpandableLinkGroup item, {
    required List<CsSideNavigationItem> parents,
    required _ListVariant variant,
    required bool withIcons,
  }) {
    final collapsed = widget.collapsed;
    if (collapsed) {
      return item._hasIcon
          ? _ItemPadding(collapsed: true, child: _link(context, item, withIcons: withIcons))
          : const SizedBox.shrink();
    }
    final expanded = _expanded(item);
    final c = context.cs.colors;
    final toggle = _Caret(
      expanded: expanded,
      color: c.textExpandableSectionNavigationIconDefault,
      label: item.text,
      onPress: () => _setExpanded(item, !expanded, parents),
    );
    final link = _link(
      context,
      item,
      withIcons: withIcons,
      onFollow: () {
        _follow(item);
        if (!expanded) _setExpanded(item, true, parents);
      },
    );
    final noIndent = variant == _ListVariant.sectionGroup || withIcons;
    return _ItemPadding(
      collapsed: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(
              noIndent
                  ? 0
                  : -_expandableIconNegativeMargin * (Directionality.of(context) == TextDirection.rtl ? -1 : 1),
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: withIcons ? [Expanded(child: link), toggle] : [toggle, Expanded(child: link)],
            ),
          ),
          CsNavReveal(
            expanded: expanded,
            child: _list(
              context,
              item.items,
              parents: [...parents, item],
              variant: _ListVariant.expandableLinkGroup,
              withIcons: withIcons,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    CsSideNavigationSection item, {
    required List<CsSideNavigationItem> parents,
    required _ListVariant variant,
    required bool withIcons,
  }) {
    final cs = context.cs;
    final collapsed = widget.collapsed;
    final list = _list(
      context,
      item.items,
      parents: [...parents, item],
      variant: _ListVariant.section,
      withIcons: withIcons,
    );
    if (collapsed) return list;
    final expanded = _expanded(item);
    final margin = cs.space.scaledXs - CsBorderLine.dividerSectionWidth;
    final noIndent = variant == _ListVariant.sectionGroup || withIcons;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(
              noIndent ? 0 : -_sectionHeaderShift * (Directionality.of(context) == TextDirection.rtl ? -1 : 1),
              0,
            ),
            child: _ItemPadding(
              collapsed: false,
              child: _SectionHeader(
                text: item.text,
                info: item.info,
                expanded: expanded,
                iconAtEnd: withIcons,
                onPress: () => _setExpanded(item, !expanded, parents),
              ),
            ),
          ),
          CsNavReveal(
            expanded: expanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CsSpace.xs),
              child: list,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionGroup(
    BuildContext context,
    CsSideNavigationSectionGroup item, {
    required List<CsSideNavigationItem> parents,
    required bool withIcons,
  }) {
    final cs = context.cs;
    final list = _list(context, item.items, parents: parents, variant: _ListVariant.sectionGroup, withIcons: withIcons);
    if (widget.collapsed) return list;
    final itemPaddingBlock = (cs.space.sizeSideNavigationItemHeight - CsTypeScale.bodyM.lineHeight) / 2;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: cs.space.scaledXs - CsBorderLine.dividerSectionWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _itemPaddingInline, vertical: itemPaddingBlock),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Semantics(header: true, child: Text(item.title, style: cs.text(CsTypeScale.headingM))),
                ),
                if (item.info != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
                    child: item.info,
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledXs - itemPaddingBlock),
            child: list,
          ),
        ],
      ),
    );
  }
}

enum _ListVariant { root, section, sectionGroup, linkGroup, expandableLinkGroup }

/// A list item: `padding-inline: space-xs`, which links cancel with a
/// negative margin so their hover background reaches the edges.
class _ItemPadding extends StatelessWidget {
  const _ItemPadding({required this.collapsed, required this.child});

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      collapsed ? Align(alignment: AlignmentDirectional.centerStart, child: child) : child;
}

class _Header extends StatelessWidget {
  const _Header({required this.header, required this.active, required this.withIcons, required this.onFollow});

  final CsSideNavigationHeader header;
  final bool active;
  final bool withIcons;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final style = cs.typography.style(
      CsTypeScale.headingM,
      weight: CsFontTokens.fontWeightHeadingL,
      color: cs.colors.textHeadingDefault,
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: withIcons ? cs.space.scaledL : CsSpace.panelNavLeft,
        end: cs.space.scaledXxl + CsSpace.xl,
        top: cs.space.panelHeaderVertical,
        bottom: cs.space.panelHeaderVertical,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CsPressable(
          onPress: onFollow,
          isLink: true,
          selected: active,
          scaleOnPress: false,
          minTapTargetSize: 0,
          borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
          builder: (context, state) => Semantics(
            header: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header.logo != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: header.text == null ? 0 : CsSpace.s, top: CsSpace.xxxs),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: header.text == null ? double.infinity : 1.25 * CsSize.iconBig,
                      ),
                      child: header.logo,
                    ),
                  ),
                if (header.text != null)
                  Flexible(
                    child: Text(
                      header.text!,
                      style: style.copyWith(
                        fontWeight: header.logo != null ? CsTypography.normal : null,
                        color: state.active ? cs.colors.textSideNavigationItemActive : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.withIcons,
    required this.onFollow,
  });

  final CsSideNavigationLinkLike item;
  final bool active;
  final bool collapsed;
  final bool withIcons;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final external = item is CsSideNavigationLink && (item as CsSideNavigationLink).external;
    final externalLabel = item is CsSideNavigationLink ? (item as CsSideNavigationLink).externalIconAriaLabel : null;
    final itemHeight = cs.space.sizeSideNavigationItemHeight;
    final collapsedSize = cs.space.sizeSideNavigationItemCollapsed;
    final paddingBlock = (itemHeight - CsTypeScale.bodyM.lineHeight) / 2;

    Widget? iconFor(Color color) {
      if (item.iconWidget != null) return item.iconWidget;
      if (item.icon != null) return CsIcon(item.icon!, dangerouslySetColor: color);
      return null;
    }

    final link = CsPressable(
      onPress: onFollow,
      isLink: true,
      selected: active,
      scaleOnPress: false,
      minTapTargetSize: collapsed ? null : 0,
      semanticLabel: external ? '${item.text}, ${externalLabel ?? context.csStrings.opensInNewWindow}' : item.text,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(collapsed ? collapsedSize / 2 : CsBorderRadius.sideNavigationItem),
      builder: (context, state) {
        if (collapsed) {
          final fg = active
              ? c.textSideNavigationItemActiveCollapsed
              : (state.active ? c.textSideNavigationItemActive : c.textSideNavigationItemDefault);
          final bg = active
              ? c.backgroundSideNavigationItemActiveCollapsed
              : state.active
              ? c.backgroundSideNavigationItemIconHover
              : null;
          return Container(
            width: collapsedSize,
            height: collapsedSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: iconFor(fg),
          );
        }
        final fg = active || state.active ? c.textSideNavigationItemActive : c.textSideNavigationItemDefault;
        final bg = active
            ? c.backgroundSideNavigationItemActive
            : (withIcons && state.active ? c.backgroundSideNavigationItemIconHover : null);
        final icon = iconFor(fg);
        return Container(
          constraints: BoxConstraints(minHeight: itemHeight),
          padding: EdgeInsets.symmetric(horizontal: _itemPaddingInline, vertical: paddingBlock),
          decoration: BoxDecoration(
            color: bg != null && bg.a > 0 ? bg : null,
            borderRadius: BorderRadius.circular(CsBorderRadius.sideNavigationItem),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: _iconTextGap),
                  child: SizedBox(
                    height: CsTypeScale.bodyM.lineHeight,
                    child: Center(widthFactor: 1, child: icon),
                  ),
                ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: item.text),
                      if (external)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                            child: CsIcon(CsIcons.external, size: CsIconSize.small, dangerouslySetColor: fg),
                          ),
                        ),
                    ],
                  ),
                  style: cs.body.copyWith(color: fg, fontWeight: active ? CsTypography.bold : CsTypography.normal),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (collapsed) return CsTooltip(content: item.text, side: CsSide.right, child: link);
    if (item.info == null) return link;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: link),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
          child: item.info,
        ),
      ],
    );
  }
}

/// The caret of a section or expandable link group: `caret-down-filled`
/// turned -90 degrees while collapsed.
class _Caret extends StatelessWidget {
  const _Caret({required this.expanded, required this.color, required this.label, required this.onPress});

  final bool expanded;
  final Color color;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final itemHeight = context.cs.space.sizeSideNavigationItemHeight;
    return CsPressable(
      onPress: onPress,
      expanded: expanded,
      semanticLabel: label,
      excludeChildSemantics: true,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) => SizedBox(
        width: _expandableIconNegativeMargin,
        height: itemHeight,
        child: Center(
          child: _CaretIcon(expanded: expanded, color: color),
        ),
      ),
    );
  }
}

class _CaretIcon extends StatelessWidget {
  const _CaretIcon({required this.expanded, required this.color});

  final bool expanded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedRotation(
      turns: expanded ? 0 : (rtl ? 0.25 : -0.25),
      duration: CsMotion.duration(context, CsDurations.rotate90),
      curve: CsCurves.rotate90,
      child: CsIcon(CsIcons.caretDownFilled, dangerouslySetColor: color),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.text,
    required this.expanded,
    required this.iconAtEnd,
    required this.onPress,
    this.info,
  });

  final String text;
  final bool expanded;
  final bool iconAtEnd;
  final VoidCallback onPress;
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    return CsPressable(
      onPress: onPress,
      expanded: expanded,
      semanticLabel: text,
      excludeChildSemantics: true,
      scaleOnPress: false,
      minTapTargetSize: 0,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final color = state.active ? c.textExpandableSectionHover : c.textExpandableSectionDefault;
        final caret = Padding(
          padding: EdgeInsetsDirectional.only(
            start: iconAtEnd ? CsSpace.xs : 0,
            end: iconAtEnd ? 0 : CsSpace.xxs + CsBorderLine.dividerListWidth,
          ),
          child: _CaretIcon(expanded: expanded, color: color),
        );
        final label = Text(text, style: cs.typography.style(CsTypeScale.headingS, color: color));
        return Container(
          constraints: BoxConstraints(minHeight: cs.minTapTarget > 0 ? 36 : 0),
          padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs, horizontal: iconAtEnd ? _itemPaddingInline : 0),
          decoration: BoxDecoration(
            color: iconAtEnd && state.active ? c.backgroundSideNavigationItemIconHover : null,
            borderRadius: BorderRadius.circular(CsBorderRadius.sideNavigationItem),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!iconAtEnd) caret,
              Flexible(fit: iconAtEnd ? FlexFit.tight : FlexFit.loose, child: label),
              if (info != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
                  child: info,
                ),
              if (iconAtEnd) caret,
            ],
          ),
        );
      },
    );
  }
}
