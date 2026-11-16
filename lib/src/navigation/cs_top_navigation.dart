import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../system/cs_focus_trap.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_nav_menu.dart';

/// The product identity at the start of [CsTopNavigation].
@immutable
class CsTopNavigationIdentity {
  const CsTopNavigationIdentity({required this.href, this.title, this.logo, this.logoWidth = 32, this.onFollow});

  /// The home page of the product. Used for semantics; navigate in [onFollow].
  final String href;

  /// Product name.
  final String? title;

  /// Product logo, at most 32px tall (24px on narrow screens). Never an AWS
  /// logo.
  final Widget? logo;

  /// Width the logo takes, used to decide when the bar collapses.
  final double logoWidth;

  /// Called when the identity is activated.
  final VoidCallback? onFollow;
}

/// A utility at the end of [CsTopNavigation]: a [CsTopNavigationButton] or
/// a [CsTopNavigationMenuDropdown].
@immutable
sealed class CsTopNavigationUtility {
  const CsTopNavigationUtility({
    this.text,
    this.title,
    this.icon,
    this.iconWidget,
    this.ariaLabel,
    this.badge = false,
    this.disableTextCollapse = false,
    this.disableUtilityCollapse = false,
  });

  /// Visible text. Hidden on narrow screens when the utility has an icon.
  final String? text;

  /// Title inside the dropdown and the overflow menu; defaults to [text].
  final String? title;
  final CsIconData? icon;

  /// Custom icon (Cloudscape `iconSvg` / `iconUrl`).
  final Widget? iconWidget;

  /// Accessible name. Recommended when there is no [text].
  final String? ariaLabel;

  /// A dot on the icon, for unread notifications.
  final bool badge;

  /// Keep the text visible on narrow screens.
  final bool disableTextCollapse;

  /// Keep the utility in the bar instead of moving it to the overflow menu.
  final bool disableUtilityCollapse;

  bool get _hasIcon => icon != null || iconWidget != null;
}

/// Style of a [CsTopNavigationButton].
enum CsTopNavigationButtonVariant {
  /// Bold interactive text with an optional icon. The default.
  link,

  /// A primary button.
  primaryButton,
}

/// A button or link utility (Cloudscape `type: 'button'`).
class CsTopNavigationButton extends CsTopNavigationUtility {
  const CsTopNavigationButton({
    super.text,
    super.title,
    super.icon,
    super.iconWidget,
    super.ariaLabel,
    super.badge,
    super.disableTextCollapse,
    super.disableUtilityCollapse,
    this.variant = CsTopNavigationButtonVariant.link,
    this.href,
    this.external = false,
    this.externalIconAriaLabel,
    this.onClick,
    this.onFollow,
  });

  final CsTopNavigationButtonVariant variant;

  /// Where the utility links to, for semantics.
  final String? href;

  /// Adds the external icon.
  final bool external;
  final String? externalIconAriaLabel;

  /// Called on every activation.
  final VoidCallback? onClick;

  /// Called on activation when [href] is set. Navigate here.
  final VoidCallback? onFollow;
}

/// A menu utility (Cloudscape `type: 'menu-dropdown'`), such as the user
/// profile or settings menu.
class CsTopNavigationMenuDropdown extends CsTopNavigationUtility {
  const CsTopNavigationMenuDropdown({
    required this.items,
    super.text,
    super.title,
    super.icon,
    super.iconWidget,
    super.ariaLabel,
    super.badge,
    super.disableTextCollapse,
    super.disableUtilityCollapse,
    this.description,
    this.expandableGroups = false,
    this.onItemClick,
    this.onItemFollow,
  });

  final List<CsTopNavigationMenuItem> items;

  /// Shown under the title at the top of the menu.
  final String? description;

  /// Groups in the overflow menu collapse under their heading.
  final bool expandableGroups;

  /// Called when an item is chosen.
  final ValueChanged<CsTopNavigationMenuItem>? onItemClick;

  /// Called when an item with an [CsTopNavigationMenuItem.href] is chosen.
  final ValueChanged<CsTopNavigationMenuItem>? onItemFollow;
}

/// An item of a [CsTopNavigationMenuDropdown] (Cloudscape button dropdown
/// item). With [items] it is a group.
@immutable
class CsTopNavigationMenuItem {
  const CsTopNavigationMenuItem({
    required this.id,
    required this.text,
    this.href,
    this.external = false,
    this.externalIconAriaLabel,
    this.disabled = false,
    this.description,
    this.icon,
    this.items,
  });

  final String id;
  final String text;
  final String? href;
  final bool external;
  final String? externalIconAriaLabel;
  final bool disabled;

  /// Secondary text under the item.
  final String? description;
  final CsIconData? icon;

  /// Children: this item is a group heading.
  final List<CsTopNavigationMenuItem>? items;
}

/// Copy for [CsTopNavigation].
@immutable
class CsTopNavigationI18nStrings {
  const CsTopNavigationI18nStrings({
    this.searchIconAriaLabel = 'Search',
    this.searchDismissIconAriaLabel = 'Close search',
    this.overflowMenuTriggerText = 'More',
    this.overflowMenuTitleText = 'All',
    this.overflowMenuBackIconAriaLabel = 'Back',
    this.overflowMenuDismissIconAriaLabel = 'Close menu',
  });

  final String searchIconAriaLabel;
  final String searchDismissIconAriaLabel;
  final String overflowMenuTriggerText;
  final String overflowMenuTitleText;
  final String overflowMenuBackIconAriaLabel;
  final String overflowMenuDismissIconAriaLabel;
}

/// Colors of [CsTopNavigation] (Cloudscape `visualContext`).
enum CsTopNavigationVisualContext {
  /// Always dark, whatever the page mode. The default.
  topNavigation,

  /// Uses the page colors.
  none,
}

/// One step of collapsing the bar as space runs out (Cloudscape's
/// responsive states).
@immutable
class CsTopNavigationResponsiveState {
  const CsTopNavigationResponsiveState({
    this.hideUtilityText = false,
    this.hideSearch = false,
    this.hideUtilities = const [],
    this.hideTitle = false,
  });

  final bool hideUtilityText;
  final bool hideSearch;

  /// Indexes of utilities moved to the overflow menu.
  final List<int> hideUtilities;
  final bool hideTitle;

  /// The states to try in order, from Cloudscape's
  /// `generateResponsiveStateKeys`.
  static List<CsTopNavigationResponsiveState> statesFor(
    List<CsTopNavigationUtility> utilities, {
    required bool hasSearch,
    required bool hasTitleWithLogo,
  }) {
    final states = <CsTopNavigationResponsiveState>[const CsTopNavigationResponsiveState()];
    if (utilities.any((u) => u.text != null)) states.add(const CsTopNavigationResponsiveState(hideUtilityText: true));
    if (hasSearch) states.add(const CsTopNavigationResponsiveState(hideUtilityText: true, hideSearch: true));
    final hidden = <int>[];
    for (var i = 0; i < utilities.length; i++) {
      if (utilities[i].disableUtilityCollapse) continue;
      hidden.add(i);
      states.add(
        CsTopNavigationResponsiveState(hideUtilityText: true, hideSearch: hasSearch, hideUtilities: List.of(hidden)),
      );
    }
    if (hasTitleWithLogo) {
      states.add(
        CsTopNavigationResponsiveState(
          hideUtilityText: true,
          hideSearch: hasSearch,
          hideUtilities: List.of(hidden),
          hideTitle: true,
        ),
      );
    }
    return states;
  }
}

/// Cloudscape's `TopNavigation`: the global bar above the app layout with
/// the product identity, a search field and utilities (notifications,
/// settings, the user menu).
///
/// ```dart
/// CsTopNavigation(
///   identity: CsTopNavigationIdentity(href: '/', title: 'Cloud console', onFollow: goHome),
///   search: CsInput(value: query, type: CsInputType.search, placeholder: 'Search', onChange: setQuery),
///   utilities: [
///     CsTopNavigationButton(icon: CsIcons.notification, ariaLabel: 'Notifications', badge: true, onClick: openInbox),
///     CsTopNavigationMenuDropdown(
///       text: 'Account',
///       icon: CsIcons.userProfile,
///       items: const [
///         CsTopNavigationMenuItem(id: 'profile', text: 'Profile'),
///         CsTopNavigationMenuItem(id: 'signout', text: 'Sign out'),
///       ],
///       onItemClick: (item) {},
///     ),
///   ],
/// )
/// ```
///
/// The bar is dark in both modes ([CsVisualContextName.topNavigation]).
/// As the width shrinks it collapses step by step like Cloudscape: utility
/// texts hide (icons stay), the search field becomes a search button that
/// expands it over the bar, utilities move into a "More" overflow menu that
/// opens full screen, and finally the title hides next to a logo. Pass
/// [child] for custom content instead.
class CsTopNavigation extends StatefulWidget {
  const CsTopNavigation({
    super.key,
    this.identity,
    this.search,
    this.utilities = const [],
    this.i18nStrings = const CsTopNavigationI18nStrings(),
    this.visualContext = CsTopNavigationVisualContext.topNavigation,
    this.safeAreaTop = true,
    this.child,
  });

  final CsTopNavigationIdentity? identity;

  /// A search field (`CsInput` with `CsInputType.search`, or an
  /// autosuggest).
  final Widget? search;
  final List<CsTopNavigationUtility> utilities;
  final CsTopNavigationI18nStrings i18nStrings;
  final CsTopNavigationVisualContext visualContext;

  /// Pad the bar's content below the status bar and notch while its dark
  /// background extends under them. Turn off when the bar is not at the top
  /// of the screen.
  final bool safeAreaTop;

  /// Custom content. When set, [identity], [search] and [utilities] are
  /// ignored.
  final Widget? child;

  @override
  State<CsTopNavigation> createState() => _CsTopNavigationState();
}

enum _Breakpoint { narrow, medium, large }

class _CsTopNavigationState extends State<CsTopNavigation> {
  bool _searchExpanded = false;
  final FocusScopeNode _searchScope = FocusScopeNode(debugLabel: 'CsTopNavigation search');
  final FocusNode _moreFocus = FocusNode(debugLabel: 'CsTopNavigation more');
  bool _overflowOpen = false;

  @override
  void dispose() {
    _searchScope.dispose();
    _moreFocus.dispose();
    super.dispose();
  }

  // Cloudscape's container breakpoints xxs (465) and s (912).
  _Breakpoint _breakpointFor(double width) => width >= 912
      ? _Breakpoint.large
      : width >= 465
      ? _Breakpoint.medium
      : _Breakpoint.narrow;

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

  double _utilityWidth(BuildContext context, CsTopNavigationUtility u, {required bool hideText}) {
    final cs = context.cs;
    final bold = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold);
    final showText = u.text != null && !(hideText && !u.disableTextCollapse && u._hasIcon);
    final textW = showText ? _textWidth(context, u.text!, bold) : 0.0;
    final iconW = u._hasIcon ? CsSize.iconNormal : 0.0;
    final minTarget = cs.minTapTarget;
    double atLeast(double w) => w < minTarget ? minTarget : w;
    return switch (u) {
      CsTopNavigationButton(variant: CsTopNavigationButtonVariant.primaryButton) =>
        2 * CsSpace.m +
            atLeast(2 * cs.space.buttonHorizontal + iconW + textW + (showText && u._hasIcon ? CsSpace.xxs : 0)),
      CsTopNavigationButton() =>
        2 * CsSpace.l + atLeast(iconW + textW + (showText && u._hasIcon ? CsSpace.xxs : 0) + (u.external ? 20 : 0)),
      CsTopNavigationMenuDropdown() =>
        2 * CsSpace.s + atLeast(2 * CsSpace.xs + iconW + (showText ? textW + CsSpace.xs * 2 : 0) + CsSize.iconNormal),
    };
  }

  CsTopNavigationResponsiveState _fit(BuildContext context, double available, _Breakpoint bp) {
    final identity = widget.identity;
    final hasSearch = widget.search != null;
    final states = CsTopNavigationResponsiveState.statesFor(
      widget.utilities,
      hasSearch: hasSearch,
      hasTitleWithLogo: identity?.logo != null && identity?.title != null,
    );
    final cs = context.cs;
    final titleW = identity?.title == null
        ? 0.0
        : _textWidth(context, identity!.title!, cs.text(CsTypeScale.headingM, weight: CsTypography.bold));
    final logoW = identity?.logo == null ? 0.0 : identity!.logoWidth + CsSpace.s;
    final identityW = identity == null ? 0.0 : (identity.logo == null && titleW < 100 ? 100.0 : logoW + titleW);
    final withText = [for (final u in widget.utilities) _utilityWidth(context, u, hideText: false)];
    final withoutText = [for (final u in widget.utilities) _utilityWidth(context, u, hideText: true)];
    final searchSlot = hasSearch ? 340.0 + 2 * CsSpace.m : 0.0;
    final searchUtility = hasSearch
        ? 2 * CsSpace.l + (cs.minTapTarget > CsSize.iconNormal ? cs.minTapTarget : CsSize.iconNormal)
        : 0.0;
    final more =
        2 * CsSpace.s +
        2 * CsSpace.xs +
        _textWidth(
          context,
          widget.i18nStrings.overflowMenuTriggerText,
          cs.text(CsTypeScale.bodyM, weight: CsTypography.bold),
        ) +
        CsSpace.xs * 2 +
        CsSize.iconNormal;
    // Cloudscape's RESPONSIVENESS_BUFFER.
    const buffer = 20.0;
    for (final s in states) {
      final searchW = hasSearch ? (s.hideSearch ? searchUtility : searchSlot) : 0.0;
      var utilitiesW = 0.0;
      final widths = s.hideUtilityText ? withoutText : withText;
      for (var i = 0; i < widths.length; i++) {
        if (!s.hideUtilities.contains(i)) utilitiesW += widths[i];
      }
      final moreW = s.hideUtilities.isNotEmpty ? more : 0.0;
      final idW = s.hideTitle ? identityW - titleW : identityW;
      if (idW + searchW + utilitiesW + moreW <= available - buffer) return s;
    }
    return states.last;
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
    if (_searchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final first = _searchScope.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal);
        if (first.isNotEmpty) first.first.requestFocus();
      });
    }
  }

  Future<void> _openOverflow(List<CsTopNavigationUtility> hidden) async {
    setState(() => _overflowOpen = true);
    final strings = widget.i18nStrings;
    final reduce = CsMotion.reduceMotion(context);
    final visualContext = widget.visualContext;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: reduce ? Duration.zero : CsDurations.showPaced,
        reverseTransitionDuration: reduce ? Duration.zero : CsDurations.showQuick,
        pageBuilder: (context, animation, secondary) {
          final menu = _OverflowMenu(utilities: hidden, strings: strings);
          return visualContext == CsTopNavigationVisualContext.none
              ? menu
              : CsVisualContext(context: CsVisualContextName.topNavigation, child: menu);
        },
        transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: CsCurves.showPaced),
          child: child,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _overflowOpen = false);
    _moreFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Widget bar = widget.child != null ? _frame(context, child: widget.child!) : _structured(context);
    if (widget.visualContext == CsTopNavigationVisualContext.topNavigation) {
      bar = CsVisualContext(context: CsVisualContextName.topNavigation, child: bar);
    }
    return Semantics(container: true, explicitChildNodes: true, child: bar);
  }

  Widget _frame(BuildContext context, {required Widget child, double? height}) {
    final c = context.cs.colors;
    // The dark bar runs under the status bar and notch; its content starts
    // below them.
    final inset = widget.safeAreaTop ? MediaQuery.paddingOf(context).top : 0.0;
    // Status bar icons follow the bar's own background, which is dark in
    // the top navigation context.
    final dark = context.cs.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Container(
        constraints: height == null ? null : BoxConstraints(minHeight: height + inset),
        padding: EdgeInsets.only(top: inset),
        decoration: BoxDecoration(
          color: c.backgroundContainerContent,
          border: Border(
            bottom: BorderSide(color: c.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _structured(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cs = context.cs;
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final bp = _breakpointFor(width);
        final height = switch (bp) {
          _Breakpoint.large => CsSpace.xxxl + cs.space.scaledM,
          _Breakpoint.medium => CsSpace.xxxl + cs.space.scaledXs,
          _Breakpoint.narrow => CsSpace.xxxl,
        };
        final paddingStart = bp == _Breakpoint.large ? CsSpace.xxl : CsSpace.l;
        final state = _fit(context, width - paddingStart, bp);
        if (!state.hideSearch && _searchExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _searchExpanded = false);
          });
        }
        final searchExpanded = _searchExpanded && state.hideSearch && widget.search != null;
        final identity = widget.identity;
        final strings = widget.i18nStrings;
        final utilities = widget.utilities;
        final hidden = [
          for (var i = 0; i < utilities.length; i++)
            if (state.hideUtilities.contains(i) && !utilities[i].disableUtilityCollapse) utilities[i],
        ];
        final visible = [
          for (var i = 0; i < utilities.length; i++)
            if (!state.hideUtilities.contains(i)) utilities[i],
        ];
        final showMore = !searchExpanded && hidden.isNotEmpty;

        final children = <Widget>[];
        if (identity != null && !searchExpanded) {
          children.add(
            Flexible(
              child: _Identity(identity: identity, showTitle: !state.hideTitle, narrow: bp == _Breakpoint.narrow),
            ),
          );
        }
        if (widget.search != null && (!state.hideSearch || searchExpanded)) {
          children.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.m),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: searchExpanded ? double.infinity : 340),
                    child: FocusScope(node: _searchScope, child: widget.search!),
                  ),
                ),
              ),
            ),
          );
        }

        final utilityWidgets = <Widget>[];
        if (widget.search != null && state.hideSearch) {
          utilityWidgets.add(
            _UtilityWrapper(
              padding: CsSpace.l,
              divider: !searchExpanded && (visible.isNotEmpty || showMore),
              child: _LinkUtility(
                utility: CsTopNavigationButton(
                  icon: searchExpanded ? CsIcons.close : CsIcons.search,
                  ariaLabel: searchExpanded ? strings.searchDismissIconAriaLabel : strings.searchIconAriaLabel,
                  onClick: _toggleSearch,
                ),
                hideText: true,
              ),
            ),
          );
        }
        if (!searchExpanded) {
          for (var i = 0; i < visible.length; i++) {
            final u = visible[i];
            final last = i == visible.length - 1 && !showMore;
            final endOffset = !last ? 0.0 : (bp == _Breakpoint.large ? CsSpace.m : CsSpace.xxs);
            final primary = u is CsTopNavigationButton && u.variant == CsTopNavigationButtonVariant.primaryButton;
            final nextIsPrimary =
                i + 1 < visible.length &&
                visible[i + 1] is CsTopNavigationButton &&
                (visible[i + 1] as CsTopNavigationButton).variant == CsTopNavigationButtonVariant.primaryButton;
            utilityWidgets.add(
              _UtilityWrapper(
                padding: switch (u) {
                  CsTopNavigationButton(variant: CsTopNavigationButtonVariant.link) => CsSpace.l,
                  CsTopNavigationButton() => CsSpace.m,
                  CsTopNavigationMenuDropdown() => CsSpace.s,
                },
                endPadding: u is CsTopNavigationMenuDropdown && last && bp != _Breakpoint.narrow ? 0 : null,
                divider: !last && !primary && !nextIsPrimary,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: u is CsTopNavigationMenuDropdown && last
                        ? (bp == _Breakpoint.large ? CsSpace.xl : CsSpace.s)
                        : endOffset,
                  ),
                  child: switch (u) {
                    CsTopNavigationButton() => _LinkUtility(utility: u, hideText: state.hideUtilityText),
                    CsTopNavigationMenuDropdown() => _MenuUtility(utility: u, hideText: state.hideUtilityText),
                  },
                ),
              ),
            );
          }
          if (showMore) {
            utilityWidgets.add(
              _UtilityWrapper(
                padding: CsSpace.s,
                divider: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: CsSpace.s),
                  child: _MenuTrigger(
                    text: strings.overflowMenuTriggerText,
                    expanded: _overflowOpen,
                    focusNode: _moreFocus,
                    onPress: () => _openOverflow(hidden),
                  ),
                ),
              ),
            );
          }
        }
        children.add(
          // The measured states fit in practice; at extreme text sizes the
          // utilities scale down instead of overflowing.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  (width -
                          paddingStart -
                          (identity == null || searchExpanded
                              ? 0
                              : identity.logo != null
                              ? identity.logoWidth
                              : 100))
                      .clamp(0, double.infinity),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                height: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: utilityWidgets,
                ),
              ),
            ),
          ),
        );

        return _frame(
          context,
          height: height,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: paddingStart),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.identity, required this.showTitle, required this.narrow});

  final CsTopNavigationIdentity identity;
  final bool showTitle;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: CsPressable(
        onPress: identity.onFollow ?? () {},
        isLink: true,
        scaleOnPress: false,
        minTapTargetSize: 0,
        semanticLabel: identity.title,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        builder: (context, state) {
          final color = state.active ? cs.colors.textAccent : cs.colors.textTopNavigationTitle;
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: identity.logo == null ? 100 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (identity.logo != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: showTitle && identity.title != null ? CsSpace.s : 0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: narrow ? CsSpace.xl : CsSpace.xxl),
                      child: identity.logo,
                    ),
                  ),
                if (showTitle && identity.title != null)
                  Flexible(
                    child: Text(
                      identity.title!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: cs.typography.style(
                        CsTypeScale.headingM,
                        weight: identity.logo == null ? CsTypography.bold : CsFontTokens.fontWeightHeadingM,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// `.utility-wrapper`: horizontal padding and a 1px divider at the end,
/// inset `space-s` from the top and bottom.
class _UtilityWrapper extends StatelessWidget {
  const _UtilityWrapper({required this.padding, required this.divider, required this.child, this.endPadding});

  final double padding;
  final double? endPadding;
  final bool divider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: padding, end: endPadding ?? padding),
          child: Center(widthFactor: 1, child: child),
        ),
        if (divider)
          PositionedDirectional(
            end: 0,
            top: CsSpace.s,
            bottom: CsSpace.s,
            width: 1,
            child: ColoredBox(color: context.cs.colors.borderDividerDefault),
          ),
      ],
    );
  }
}

Widget _utilityIcon(CsTopNavigationUtility u, Color color) {
  if (u.iconWidget != null) return CsIcon.custom(u.iconWidget!, badge: u.badge);
  return CsIcon(u.icon!, badge: u.badge, dangerouslySetColor: color);
}

class _LinkUtility extends StatelessWidget {
  const _LinkUtility({required this.utility, required this.hideText});

  final CsTopNavigationButton utility;
  final bool hideText;

  @override
  Widget build(BuildContext context) {
    final u = utility;
    final cs = context.cs;
    final showText = u.text != null && !(hideText && !u.disableTextCollapse && u._hasIcon);
    final label =
        u.ariaLabel ??
        [
          u.text,
          if (u.external) u.externalIconAriaLabel ?? context.csStrings.opensInNewWindow,
        ].whereType<String>().join(', ');
    void activate() {
      if (u.href != null) u.onFollow?.call();
      u.onClick?.call();
    }

    if (u.variant == CsTopNavigationButtonVariant.primaryButton) {
      return CsButton(
        variant: CsButtonVariant.primary,
        icon: u.icon,
        iconWidget: u.iconWidget,
        text: showText ? u.text : null,
        external: showText && u.external,
        semanticLabel: label.isEmpty ? null : label,
        isLink: u.href != null,
        onPress: activate,
      );
    }
    return CsPressable(
      onPress: activate,
      isLink: u.href != null,
      semanticLabel: label.isEmpty ? null : label,
      excludeChildSemantics: true,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final color = state.pressed
            ? cs.colors.textInteractiveActive
            : state.hovered
            ? cs.colors.textInteractiveHover
            : cs.colors.textInteractiveDefault;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (u._hasIcon) _utilityIcon(u, color),
            if (showText)
              Padding(
                padding: EdgeInsetsDirectional.only(start: u._hasIcon ? CsSpace.xxs : 0),
                child: Text(
                  u.text!,
                  softWrap: false,
                  style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: color),
                ),
              ),
            if (showText && u.external)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.xxs),
                child: CsIcon(CsIcons.external, size: CsIconSize.small, dangerouslySetColor: color),
              ),
          ],
        );
      },
    );
  }
}

/// Cloudscape's menu dropdown trigger (`.button` in menu-dropdown): bold
/// interactive text, optional icon, and a caret that turns when open.
class _TriggerVisual extends StatelessWidget {
  const _TriggerVisual({required this.state, required this.expanded, this.icon, this.text});

  final CsPressState state;
  final bool expanded;
  final Widget? icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = expanded
        ? cs.colors.textAccent
        : state.pressed
        ? cs.colors.textInteractiveActive
        : state.hovered
        ? cs.colors.textInteractiveHover
        : cs.colors.textInteractiveDefault;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs),
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: color),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?icon,
              if (text != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: icon != null ? CsSpace.xs : 0, end: CsSpace.xs),
                  child: Text(
                    text!,
                    softWrap: false,
                    style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: color),
                  ),
                )
              else if (icon != null)
                const SizedBox(width: CsSpace.xxs),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: CsMotion.duration(context, CsDurations.rotate180),
                curve: CsCurves.rotate180,
                child: CsIcon(CsIcons.caretDownFilled, dangerouslySetColor: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTrigger extends StatelessWidget {
  const _MenuTrigger({required this.text, required this.expanded, required this.onPress, this.focusNode});

  final String text;
  final bool expanded;
  final VoidCallback onPress;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => CsPressable(
    onPress: onPress,
    expanded: expanded,
    focusNode: focusNode,
    semanticLabel: text,
    excludeChildSemantics: true,
    scaleOnPress: false,
    borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
    builder: (context, state) => _TriggerVisual(state: state, expanded: expanded, text: text),
  );
}

List<CsNavMenuEntry> _menuEntries(CsTopNavigationMenuDropdown u) {
  CsNavMenuEntry entry(CsTopNavigationMenuItem item) => CsNavMenuEntry(
    text: item.text,
    description: item.description,
    icon: item.icon,
    disabled: item.disabled,
    external: item.external,
    externalIconAriaLabel: item.externalIconAriaLabel,
    isLink: item.href != null,
    onPress: () {
      u.onItemClick?.call(item);
      if (item.href != null) u.onItemFollow?.call(item);
    },
  );
  final entries = <CsNavMenuEntry>[];
  for (var i = 0; i < u.items.length; i++) {
    final item = u.items[i];
    if (item.items != null) {
      if (entries.isNotEmpty) entries.add(const CsNavMenuEntry.separator());
      entries.add(CsNavMenuEntry.group(item.text));
      entries.addAll(item.items!.map(entry));
      if (i < u.items.length - 1) entries.add(const CsNavMenuEntry.separator());
    } else {
      entries.add(entry(item));
    }
  }
  return entries;
}

class _MenuUtility extends StatelessWidget {
  const _MenuUtility({required this.utility, required this.hideText});

  final CsTopNavigationMenuDropdown utility;
  final bool hideText;

  @override
  Widget build(BuildContext context) {
    final u = utility;
    final cs = context.cs;
    final showText = u.text != null && !(hideText && !u.disableTextCollapse && u._hasIcon);
    final title = u.title ?? u.text;
    final showTitle = !showText || u.text == null;
    final header = (showTitle && title != null) || u.description != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: CsSpace.fieldHorizontal, vertical: CsSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showTitle && title != null)
                  Text(
                    title,
                    style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textDropdownGroupLabel),
                  ),
                if (u.description != null)
                  Text(u.description!, style: cs.text(CsTypeScale.bodyS, color: CsColor.textDropdownItemSecondary)),
              ],
            ),
          )
        : null;
    return CsNavMenu(
      entries: _menuEntries(u),
      header: header,
      label: u.ariaLabel ?? title,
      align: CsAlign.end,
      triggerBuilder: (context, open, toggle) => CsPressable(
        onPress: toggle,
        expanded: open,
        semanticLabel: u.ariaLabel ?? u.text ?? title,
        excludeChildSemantics: true,
        scaleOnPress: false,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        builder: (context, state) {
          final color = open
              ? cs.colors.textAccent
              : state.pressed
              ? cs.colors.textInteractiveActive
              : state.hovered
              ? cs.colors.textInteractiveHover
              : cs.colors.textInteractiveDefault;
          return _TriggerVisual(
            state: state,
            expanded: open,
            icon: u._hasIcon ? _utilityIcon(u, color) : null,
            text: showText ? u.text : null,
          );
        },
      ),
    );
  }
}

/// The full-screen overflow menu: a list of the collapsed utilities, with
/// menu utilities opening their items in a second view.
class _OverflowMenu extends StatefulWidget {
  const _OverflowMenu({required this.utilities, required this.strings});

  final List<CsTopNavigationUtility> utilities;
  final CsTopNavigationI18nStrings strings;

  @override
  State<_OverflowMenu> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends State<_OverflowMenu> {
  CsTopNavigationMenuDropdown? _submenu;
  final Set<String> _openGroups = {};

  void _close() => Navigator.of(context).pop();

  Widget _header(BuildContext context, {required String title, String? description, VoidCallback? onBack}) {
    final cs = context.cs;
    return Container(
      constraints: const BoxConstraints(minHeight: CsFontTokens.lineHeightHeadingM),
      padding: EdgeInsets.all(cs.space.scaledM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.colors.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null)
            CsButton(
              variant: CsButtonVariant.icon,
              icon: CsIcons.angleLeft,
              semanticLabel: widget.strings.overflowMenuBackIconAriaLabel,
              onPress: onBack,
            )
          else
            const SizedBox(width: 32),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: cs.typography.style(
                      CsTypeScale.headingM,
                      weight: CsFontTokens.fontWeightHeadingL,
                      color: cs.colors.textHeadingDefault,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: cs.text(CsTypeScale.bodyS, color: CsColor.textHeadingDefault),
                    ),
                ],
              ),
            ),
          ),
          CsButton(
            variant: CsButtonVariant.icon,
            icon: CsIcons.close,
            semanticLabel: widget.strings.overflowMenuDismissIconAriaLabel,
            onPress: _close,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required Widget child,
    required VoidCallback? onPress,
    bool isLink = false,
    String? label,
    bool? expanded,
  }) {
    final cs = context.cs;
    return CsPressable(
      onPress: onPress,
      disabled: onPress == null,
      isLink: isLink,
      expanded: expanded,
      semanticLabel: label,
      excludeChildSemantics: label != null,
      scaleOnPress: false,
      minTapTargetSize: 0,
      builder: (context, state) => DefaultTextStyle.merge(
        style: TextStyle(
          color: onPress == null ? cs.colors.textInteractiveDisabled : (state.active ? cs.colors.textAccent : null),
        ),
        child: child,
      ),
    );
  }

  Widget _utilitiesView(BuildContext context) {
    final cs = context.cs;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final u in widget.utilities)
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.colors.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
              ),
            ),
            child: _row(
              context,
              isLink: u is CsTopNavigationButton && u.href != null,
              label: u.ariaLabel ?? u.title ?? u.text,
              expanded: u is CsTopNavigationMenuDropdown ? false : null,
              onPress: () {
                switch (u) {
                  case CsTopNavigationButton():
                    _close();
                    if (u.href != null) u.onFollow?.call();
                    u.onClick?.call();
                  case CsTopNavigationMenuDropdown():
                    setState(() => _submenu = u);
                }
              },
              child: Builder(
                builder: (context) {
                  final color = DefaultTextStyle.of(context).style.color ?? cs.colors.textInteractiveDefault;
                  return Padding(
                    padding: EdgeInsets.all(cs.space.scaledM),
                    child: Row(
                      children: [
                        if (u._hasIcon)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
                            child: _utilityIcon(u, color),
                          ),
                        Expanded(
                          child: Text(
                            u.title ?? u.text ?? u.ariaLabel ?? '',
                            style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: color),
                          ),
                        ),
                        if (u is CsTopNavigationButton && u.external)
                          CsIcon(CsIcons.external, size: CsIconSize.small, dangerouslySetColor: color),
                        if (u is CsTopNavigationMenuDropdown) CsIcon(CsIcons.angleRight, dangerouslySetColor: color),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _itemRow(BuildContext context, CsTopNavigationMenuDropdown u, CsTopNavigationMenuItem item) {
    final cs = context.cs;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cs.space.scaledL, vertical: cs.space.scaledXxs),
      child: _row(
        context,
        isLink: item.href != null,
        label: item.external
            ? '${item.text}, ${item.externalIconAriaLabel ?? context.csStrings.opensInNewWindow}'
            : null,
        onPress: item.disabled
            ? null
            : () {
                _close();
                u.onItemClick?.call(item);
                if (item.href != null) u.onItemFollow?.call(item);
              },
        child: Builder(
          builder: (context) {
            final color = DefaultTextStyle.of(context).style.color ?? cs.colors.textBodyDefault;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
              child: Row(
                children: [
                  if (item.icon != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
                      child: CsIcon(item.icon!, dangerouslySetColor: color),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.text, style: cs.body.copyWith(color: color)),
                        if (item.description != null)
                          Text(item.description!, style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary)),
                      ],
                    ),
                  ),
                  if (item.external) CsIcon(CsIcons.external, size: CsIconSize.small, dangerouslySetColor: color),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _submenuView(BuildContext context, CsTopNavigationMenuDropdown u) {
    final cs = context.cs;
    final children = <Widget>[];
    for (final item in u.items) {
      if (item.items == null) {
        children.add(_itemRow(context, u, item));
        continue;
      }
      final open = !u.expandableGroups || _openGroups.contains(item.id);
      final heading = Padding(
        padding: EdgeInsets.symmetric(horizontal: cs.space.scaledL, vertical: cs.space.scaledXs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.text,
                style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textDropdownGroupLabel),
              ),
            ),
            if (u.expandableGroups)
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: CsMotion.duration(context, CsDurations.rotate180),
                child: const CsIcon(CsIcons.caretDownFilled),
              ),
          ],
        ),
      );
      children.add(
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: u.expandableGroups ? cs.colors.borderDividerDefault : const Color(0x00000000),
                width: CsBorderLine.dividerSectionWidth,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (u.expandableGroups)
                _row(
                  context,
                  label: item.text,
                  expanded: open,
                  onPress: () => setState(() => open ? _openGroups.remove(item.id) : _openGroups.add(item.id)),
                  child: heading,
                )
              else
                Semantics(header: true, child: heading),
              if (open)
                for (final child in item.items!) _itemRow(context, u, child),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final sub = _submenu;
    return CsFocusTrap(
      onEscPress: () {
        if (_submenu != null) {
          setState(() => _submenu = null);
        } else {
          _close();
        }
      },
      child: Builder(
        builder: (context) => Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: sub == null ? widget.strings.overflowMenuTitleText : (sub.title ?? sub.text),
          child: ColoredBox(
            color: cs.colors.backgroundContainerContent,
            child: SafeArea(
              child: DefaultTextStyle(
                style: cs.body,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (sub == null)
                      _header(context, title: widget.strings.overflowMenuTitleText)
                    else
                      _header(
                        context,
                        title: sub.title ?? sub.text ?? sub.ariaLabel ?? '',
                        description: sub.description,
                        onBack: () => setState(() => _submenu = null),
                      ),
                    Expanded(child: sub == null ? _utilitiesView(context) : _submenuView(context, sub)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
