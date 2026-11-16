import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/icons.dart';
import '../system/cs_focus_trap.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';
import 'cs_content_layout.dart';
import 'cs_split_panel.dart';
import 'internal/cs_layout_insets.dart';
import 'internal/cs_resize_handle.dart';
import 'internal/cs_split_panel_scope.dart';

/// Page types (Cloudscape `contentType`). They set whether the navigation
/// starts open and the default maximum content width.
enum CsAppLayoutContentType {
  /// Navigation open, no width cap.
  defaultVariant(true, null),

  /// Forms: navigation closed, content capped at 800px.
  form(false, 800),

  /// Full-page tables: navigation open.
  table(true, null),

  /// Card collections: navigation open.
  cards(true, null),

  /// Wizards: navigation closed, content capped at 1080px.
  wizard(false, 1080),

  /// Dashboards: navigation open.
  dashboard(true, null);

  const CsAppLayoutContentType(this.navigationOpen, this.maxContentWidth);

  /// Whether the navigation starts open on wide screens.
  final bool navigationOpen;

  /// Default content width cap.
  final double? maxContentWidth;
}

/// Style of the area behind breadcrumbs and the content header (Cloudscape
/// `headerVariant`).
enum CsAppLayoutHeaderVariant {
  defaultVariant,

  /// A dark band behind breadcrumbs, notifications and the content header.
  highContrast,
}

/// Accessible names for one drawer (Cloudscape `DrawerAriaLabels`).
@immutable
class CsAppLayoutDrawerLabels {
  const CsAppLayoutDrawerLabels({required this.drawerName, this.closeButton, this.triggerButton, this.resizeHandle});

  /// Name of the drawer region.
  final String drawerName;

  /// Defaults to "Close [drawerName]".
  final String? closeButton;

  /// Defaults to [drawerName].
  final String? triggerButton;

  /// Defaults to "Resize [drawerName]".
  final String? resizeHandle;
}

/// One drawer of the app layout (Cloudscape `AppLayoutProps.Drawer`): a
/// panel at the end of the layout opened from its trigger icon.
@immutable
class CsAppLayoutDrawer {
  const CsAppLayoutDrawer({
    required this.id,
    required this.content,
    required this.ariaLabels,
    this.icon,
    this.iconWidget,
    this.badge = false,
    this.resizable = false,
    this.defaultSize,
    this.onResize,
  });

  final String id;

  /// The drawer content, usually a `CsDrawer` or `CsHelpPanel`.
  final Widget content;
  final CsAppLayoutDrawerLabels ariaLabels;

  /// Trigger icon (Cloudscape `trigger.iconName`).
  final CsIconData? icon;

  /// Custom trigger icon (Cloudscape `trigger.iconSvg`).
  final Widget? iconWidget;

  /// A dot on the trigger for unread content.
  final bool badge;

  /// Shows a resize handle on the drawer's start edge.
  final bool resizable;

  /// Starting width. Defaults to 290px.
  final double? defaultSize;
  final ValueChanged<double>? onResize;
}

/// Accessible names of the app layout (Cloudscape `ariaLabels`).
@immutable
class CsAppLayoutLabels {
  const CsAppLayoutLabels({
    this.notifications = 'Notifications',
    this.navigation = 'Navigation drawer',
    this.navigationToggle = 'Open navigation drawer',
    this.navigationClose = 'Close navigation drawer',
    this.tools = 'Help panel',
    this.toolsToggle = 'Open help panel',
    this.toolsClose = 'Close help panel',
    this.drawers = 'Drawers',
    this.splitPanelToggle = 'Open split panel',
  });

  final String notifications;
  final String navigation;
  final String navigationToggle;
  final String navigationClose;
  final String tools;
  final String toolsToggle;
  final String toolsClose;
  final String drawers;

  /// Trigger shown for a hidden split panel (`closeBehavior: hide`).
  final String splitPanelToggle;
}

/// Cloudscape's `AppLayout`: the frame of a console page, with side
/// navigation, breadcrumbs, notifications, the content, a split panel and
/// the tools panel or drawers.
///
/// ```dart
/// CsAppLayout(
///   navigation: const Text('Side navigation'),
///   breadcrumbs: const Text('Instances'),
///   tools: const CsHelpPanel(header: 'Instances', child: Text('Help')),
///   content: const CsContentLayout(
///     header: CsHeader(variant: CsHeaderVariant.h1, title: 'Instances'),
///     child: Text('Table'),
///   ),
/// )
/// ```
///
/// Every open state is controlled when its value is passed (with the
/// matching callback) and kept by the layout otherwise, like Cloudscape.
///
/// On wide screens (visual refresh) the navigation and tools sit beside the
/// content; closed panels leave a column of round toggle buttons
/// (`space-layout-toggle-diameter`, 36px). At or below 688px of the layout's
/// own width (or when [mobile] is true) a top bar holds the navigation,
/// tools and drawer triggers as icon buttons, and each panel opens as a
/// full-screen overlay that Escape closes. Use [CsAppLayoutToolbar] for the
/// toolbar variant.
class CsAppLayout extends StatefulWidget {
  const CsAppLayout({
    super.key,
    this.content,
    this.contentHeader,
    this.navigation,
    this.navigationOpen,
    this.onNavigationChange,
    this.navigationWidth = 280,
    this.navigationHide = false,
    this.tools,
    this.toolsOpen,
    this.onToolsChange,
    this.toolsWidth = 290,
    this.toolsHide = false,
    this.breadcrumbs,
    this.notifications,
    this.stickyNotifications = false,
    this.contentType = CsAppLayoutContentType.defaultVariant,
    this.maxContentWidth,
    this.minContentWidth = 280,
    this.disableContentPaddings = false,
    this.disableContentHeaderOverlap = false,
    this.headerVariant = CsAppLayoutHeaderVariant.defaultVariant,
    this.splitPanel,
    this.splitPanelOpen,
    this.onSplitPanelToggle,
    this.splitPanelSize,
    this.onSplitPanelResize,
    this.splitPanelPosition,
    this.onSplitPanelPreferencesChange,
    this.drawers = const [],
    this.activeDrawerId,
    this.onDrawerChange,
    this.ariaLabels = const CsAppLayoutLabels(),
    this.mobile,
  });

  /// Main page content, often a [CsContentLayout].
  final Widget? content;

  /// A header above the content (Cloudscape `contentHeader`).
  final Widget? contentHeader;

  /// Side navigation, usually a `CsSideNavigation`.
  final Widget? navigation;

  /// Controlled navigation state. Null lets the layout manage it, starting
  /// from [contentType] on wide screens and closed on phones.
  final bool? navigationOpen;
  final ValueChanged<bool>? onNavigationChange;
  final double navigationWidth;

  /// Removes the navigation and its toggle.
  final bool navigationHide;

  /// Help content for the tools panel, usually a `CsHelpPanel`.
  final Widget? tools;
  final bool? toolsOpen;
  final ValueChanged<bool>? onToolsChange;
  final double toolsWidth;
  final bool toolsHide;
  final Widget? breadcrumbs;

  /// Flash messages above the content, usually a `CsFlashbar`.
  final Widget? notifications;

  /// Keeps [notifications] pinned while the content scrolls.
  final bool stickyNotifications;
  final CsAppLayoutContentType contentType;

  /// Caps the content width. Defaults from [contentType].
  final double? maxContentWidth;

  /// Narrowest the content gets before side panels stop opening beside it.
  final double minContentWidth;

  /// Removes the content padding, for full-bleed content.
  final bool disableContentPaddings;

  /// Content starts under the high-contrast header instead of overlapping it.
  final bool disableContentHeaderOverlap;
  final CsAppLayoutHeaderVariant headerVariant;

  /// Usually a [CsSplitPanel].
  final Widget? splitPanel;
  final bool? splitPanelOpen;
  final ValueChanged<bool>? onSplitPanelToggle;

  /// Height of a bottom split panel or width of a side one.
  final double? splitPanelSize;
  final ValueChanged<double>? onSplitPanelResize;

  /// Controlled split panel position (Cloudscape
  /// `splitPanelPreferences.position`).
  final CsSplitPanelPosition? splitPanelPosition;
  final ValueChanged<CsSplitPanelPosition>? onSplitPanelPreferencesChange;

  /// Panels at the end of the layout, opened from their trigger icons. The
  /// tools panel and drawers share that slot.
  final List<CsAppLayoutDrawer> drawers;

  /// Controlled open drawer. Null lets the layout manage it.
  final String? activeDrawerId;

  /// Called with the drawer to open, or null to close.
  final ValueChanged<String?>? onDrawerChange;
  final CsAppLayoutLabels ariaLabels;

  /// Forces the phone (true) or wide (false) layout. Null switches at
  /// 688px of the layout's width.
  final bool? mobile;

  /// Whether this is the toolbar variant. [CsAppLayoutToolbar] overrides it.
  @protected
  bool get toolbarVariant => false;

  @override
  State<CsAppLayout> createState() => _CsAppLayoutState();
}

/// Cloudscape's `AppLayoutToolbar`: the app layout with a toolbar row
/// along the top that holds the navigation trigger, breadcrumbs and the
/// tools and drawer triggers. Same API as [CsAppLayout].
///
/// ```dart
/// CsAppLayoutToolbar(
///   navigation: const Text('Side navigation'),
///   breadcrumbs: const Text('Buckets'),
///   content: const Text('Bucket list'),
/// )
/// ```
///
/// The toolbar is 42px high on `color-background-layout-toolbar` with a
/// `color-border-layout` line under it; triggers are 30px rounded buttons
/// that turn `color-background-layout-toggle-selected-default` while their
/// panel is open. Panels open under the toolbar on wide screens and as
/// full-screen overlays on phones.
class CsAppLayoutToolbar extends CsAppLayout {
  const CsAppLayoutToolbar({
    super.key,
    super.content,
    super.contentHeader,
    super.navigation,
    super.navigationOpen,
    super.onNavigationChange,
    super.navigationWidth,
    super.navigationHide,
    super.tools,
    super.toolsOpen,
    super.onToolsChange,
    super.toolsWidth,
    super.toolsHide,
    super.breadcrumbs,
    super.notifications,
    super.stickyNotifications,
    super.contentType,
    super.maxContentWidth,
    super.minContentWidth,
    super.disableContentPaddings,
    super.disableContentHeaderOverlap,
    super.headerVariant,
    super.splitPanel,
    super.splitPanelOpen,
    super.onSplitPanelToggle,
    super.splitPanelSize,
    super.onSplitPanelResize,
    super.splitPanelPosition,
    super.onSplitPanelPreferencesChange,
    super.drawers,
    super.activeDrawerId,
    super.onDrawerChange,
    super.ariaLabels,
    super.mobile,
  });

  @override
  bool get toolbarVariant => true;
}

const String _toolsId = r'$tools';
const double _minDrawerSize = 290;
const double _splitMinHeight = 160;
const double _splitMinWidth = 280;

class _CsAppLayoutState extends State<CsAppLayout> {
  bool? _navOwn;
  bool _toolsOwn = false;
  String? _drawerOwn;
  bool _splitOwn = false;
  double? _splitSizeOwn;
  CsSplitPanelPosition _splitPosOwn = CsSplitPanelPosition.bottom;
  final Map<String, double> _drawerSizes = {};
  bool _lastNarrow = false;

  bool _navOpen(bool narrow) => widget.navigationOpen ?? _navOwn ?? (!narrow && widget.contentType.navigationOpen);

  bool get _hasNav => widget.navigation != null && !widget.navigationHide;
  bool get _hasTools => widget.tools != null && !widget.toolsHide;

  /// The open end panel: [_toolsId] for tools, a drawer id, or null.
  String? get _activeEnd {
    if (widget.drawers.isNotEmpty) {
      final id = widget.activeDrawerId ?? _drawerOwn;
      if (id == _toolsId && _hasTools) return id;
      if (id != null && widget.drawers.any((d) => d.id == id)) return id;
    }
    final tools = widget.toolsOpen ?? _toolsOwn;
    return tools && _hasTools ? _toolsId : null;
  }

  bool get _splitOpen => widget.splitPanelOpen ?? _splitOwn;
  CsSplitPanelPosition get _splitPos => widget.splitPanelPosition ?? _splitPosOwn;

  bool get _splitHides {
    final p = widget.splitPanel;
    return p is CsSplitPanel && p.closeBehavior == CsSplitPanelCloseBehavior.hide;
  }

  void _setNav(bool open) {
    if (widget.navigationOpen == null) setState(() => _navOwn = open);
    widget.onNavigationChange?.call(open);
  }

  void _setEnd(String? id) {
    final current = _activeEnd;
    if (id == current) return;
    final toolsWas = current == _toolsId;
    final toolsNow = id == _toolsId;
    setState(() {
      _drawerOwn = id;
      _toolsOwn = toolsNow;
    });
    if (toolsWas != toolsNow) widget.onToolsChange?.call(toolsNow);
    if (widget.drawers.isNotEmpty) widget.onDrawerChange?.call(id);
  }

  void _toggleEnd(String id) => _setEnd(_activeEnd == id ? null : id);

  void _setSplit(bool open) {
    if (widget.splitPanelOpen == null) setState(() => _splitOwn = open);
    widget.onSplitPanelToggle?.call(open);
  }

  void _setSplitSize(double size) {
    if (widget.splitPanelSize == null) setState(() => _splitSizeOwn = size);
    widget.onSplitPanelResize?.call(size);
  }

  void _setSplitPos(CsSplitPanelPosition p) {
    if (widget.splitPanelPosition == null) setState(() => _splitPosOwn = p);
    widget.onSplitPanelPreferencesChange?.call(p);
  }

  double _endSize(String id) {
    if (id == _toolsId) return _drawerSizes[id] ?? widget.toolsWidth;
    final d = widget.drawers.firstWhere((d) => d.id == id);
    return _drawerSizes[id] ?? d.defaultSize ?? _minDrawerSize;
  }

  CsAppLayoutDrawer? _drawer(String? id) {
    for (final d in widget.drawers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Widget _endContent(String id) => id == _toolsId ? widget.tools! : _drawer(id)!.content;

  String _endName(String id) => id == _toolsId ? widget.ariaLabels.tools : _drawer(id)!.ariaLabels.drawerName;

  String _endCloseLabel(String id) {
    if (id == _toolsId) return widget.ariaLabels.toolsClose;
    final d = _drawer(id)!;
    return d.ariaLabels.closeButton ?? 'Close ${d.ariaLabels.drawerName}';
  }

  /// Triggers for the end slot: tools first, then drawers, then a hidden
  /// split panel.
  List<_TriggerSpec> _endTriggers() {
    final active = _activeEnd;
    return [
      if (_hasTools)
        _TriggerSpec(
          icon: CsIcons.statusInfo,
          label: widget.ariaLabels.toolsToggle,
          selected: active == _toolsId,
          onPress: () => _toggleEnd(_toolsId),
        ),
      for (final d in widget.drawers)
        _TriggerSpec(
          icon: d.icon ?? CsIcons.menu,
          iconWidget: d.iconWidget,
          label: d.ariaLabels.triggerButton ?? d.ariaLabels.drawerName,
          selected: active == d.id,
          badge: d.badge,
          onPress: () => _toggleEnd(d.id),
        ),
      if (widget.splitPanel != null && _splitHides && !_splitOpen)
        _TriggerSpec(
          icon: _splitPos == CsSplitPanelPosition.side ? CsIcons.viewVertical : CsIcons.viewHorizontal,
          label: widget.ariaLabels.splitPanelToggle,
          selected: false,
          onPress: () => _setSplit(true),
        ),
    ];
  }

  Widget _closeButton(String label, VoidCallback onPress) =>
      CsButton(variant: CsButtonVariant.icon, icon: CsIcons.close, semanticLabel: label, onPress: onPress);

  /// The open panel shell for navigation, tools and drawers.
  Widget _panel({
    required Widget child,
    required String label,
    String? closeLabel,
    VoidCallback? onClose,
    required bool start,
    bool border = true,
  }) {
    final cs = context.cs;
    final c = cs.colors;
    final side = BorderSide(color: c.borderLayout);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.backgroundContainerContent,
          border: border ? (start ? BorderDirectional(end: side) : BorderDirectional(start: side)) : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                child: DefaultTextStyle.merge(style: cs.body, child: child),
              ),
            ),
            if (onClose != null)
              PositionedDirectional(
                top: cs.space.sizeVerticalPanelIconOffset - 6,
                end: CsSpace.s,
                child: _closeButton(closeLabel ?? label, onClose),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mainArea({required bool narrow, required double width, required double height}) {
    final cs = context.cs;
    final horizontal = widget.disableContentPaddings ? 0.0 : (narrow ? CsSpace.l : cs.space.layoutContentHorizontal);
    final maxWidth = widget.maxContentWidth ?? widget.contentType.maxContentWidth;
    final highContrast = widget.headerVariant == CsAppLayoutHeaderVariant.highContrast;
    final topGap = widget.disableContentPaddings ? 0.0 : cs.space.scaledS;

    final sticky = widget.stickyNotifications && widget.notifications != null;
    final Widget? notifications = widget.notifications == null
        ? null
        : Semantics(
            container: true,
            label: widget.ariaLabels.notifications,
            liveRegion: true,
            child: widget.notifications,
          );

    Widget? scrolled;
    final content = widget.content;
    if (content is CsContentLayout || highContrast || widget.contentHeader != null) {
      // The content layout paints the header band edge to edge and pads its
      // own header and content.
      final layout = content is CsContentLayout && widget.contentHeader == null && !highContrast
          ? content
          : CsContentLayout(
              headerVariant: highContrast
                  ? CsContentLayoutHeaderVariant.highContrast
                  : CsContentLayoutHeaderVariant.defaultVariant,
              header: widget.contentHeader,
              disableOverlap: widget.disableContentHeaderOverlap,
              maxContentWidth: maxWidth,
              breadcrumbs: narrow || widget.toolbarVariant ? null : widget.breadcrumbs,
              notifications: sticky ? null : notifications,
              child: content,
            );
      final takesCrumbs = layout != content;
      scrolled = CsLayoutContentInsets(
        horizontal: horizontal,
        top: topGap,
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.disableContentPaddings ? 0 : cs.space.layoutContentBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!takesCrumbs && !sticky && notifications != null)
                Padding(padding: EdgeInsets.fromLTRB(horizontal, topGap, horizontal, 0), child: notifications),
              if (!takesCrumbs && !narrow && !widget.toolbarVariant && widget.breadcrumbs != null)
                Padding(padding: EdgeInsets.fromLTRB(horizontal, topGap, horizontal, 0), child: widget.breadcrumbs),
              layout,
            ],
          ),
        ),
      );
    } else {
      Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CsSpace.xs,
        children: [
          if (!sticky && notifications != null) notifications,
          if (!narrow && !widget.toolbarVariant && widget.breadcrumbs != null) widget.breadcrumbs!,
          DefaultTextStyle.merge(style: cs.body, child: content ?? const SizedBox()),
        ],
      );
      if (maxWidth != null) {
        body = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        );
      }
      scrolled = Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          topGap,
          horizontal,
          widget.disableContentPaddings ? 0 : cs.space.layoutContentBottom,
        ),
        child: body,
      );
    }

    final main = Semantics(container: true, explicitChildNodes: true, child: SingleChildScrollView(child: scrolled));

    // Bottom split panel.
    Widget? bottomSplit;
    final splitOnBottom = widget.splitPanel != null && (narrow || _splitPos == CsSplitPanelPosition.bottom);
    if (splitOnBottom && !(narrow && _splitOpen)) {
      final maxH = math.max(_splitMinHeight, height - 120);
      final size = (_splitSizeOwn ?? widget.splitPanelSize ?? math.max(_splitMinHeight, height / 3))
          .clamp(_splitMinHeight, maxH)
          .toDouble();
      final closedHidden = !_splitOpen && _splitHides;
      if (!closedHidden) {
        bottomSplit = _splitScope(
          narrow: narrow,
          size: size,
          minSize: _splitMinHeight,
          maxSize: maxH,
          sideAvailable: width >= _splitMinWidth + widget.minContentWidth,
          child: _splitOpen ? SizedBox(height: size, child: widget.splitPanel) : widget.splitPanel!,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sticky) Padding(padding: EdgeInsets.fromLTRB(horizontal, topGap, horizontal, 0), child: notifications),
        Expanded(child: main),
        ?bottomSplit,
      ],
    );
  }

  Widget _splitScope({
    required bool narrow,
    required double size,
    required double minSize,
    required double maxSize,
    required bool sideAvailable,
    required Widget child,
  }) => CsSplitPanelScope(
    open: _splitOpen,
    position: narrow ? CsSplitPanelPosition.bottom : _splitPos,
    size: size,
    minSize: minSize,
    maxSize: maxSize,
    sideAvailable: sideAvailable,
    narrow: narrow,
    onToggle: () => _setSplit(!_splitOpen),
    onResize: _setSplitSize,
    onPositionChange: _setSplitPos,
    child: child,
  );

  Widget _wide(BoxConstraints constraints) {
    final cs = context.cs;
    final toolbar = widget.toolbarVariant;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final navOpen = _navOpen(false);
    final active = _activeEnd;
    final reduce = CsMotion.reduceMotion(context);
    final dur = reduce ? Duration.zero : CsDurations.complex;
    const toggleColumn = CsSpace.layoutTogglePadding * 2 + CsSpace.layoutToggleDiameter;

    final row = <Widget>[];

    // Navigation.
    if (_hasNav) {
      final closedWidth = toolbar ? 0.0 : toggleColumn;
      row.add(
        AnimatedContainer(
          duration: dur,
          curve: CsCurves.expressive,
          width: navOpen ? widget.navigationWidth : closedWidth,
          child: ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              minWidth: navOpen ? widget.navigationWidth : closedWidth,
              maxWidth: navOpen ? widget.navigationWidth : closedWidth,
              child: navOpen
                  ? _panel(
                      child: widget.navigation!,
                      label: widget.ariaLabels.navigation,
                      closeLabel: widget.ariaLabels.navigationClose,
                      onClose: toolbar ? null : () => _setNav(false),
                      start: true,
                    )
                  : toolbar
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(top: cs.space.scaledS),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _Trigger(
                          style: _TriggerStyle.circle,
                          spec: _TriggerSpec(
                            icon: CsIcons.menu,
                            label: widget.ariaLabels.navigationToggle,
                            selected: false,
                            onPress: () => _setNav(true),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // Main and split panel.
    final navW = _hasNav ? (navOpen ? widget.navigationWidth : (toolbar ? 0 : toggleColumn)) : 0.0;
    final endW = active != null ? _endSize(active) : 0.0;
    final triggers = _endTriggers();
    final triggerColW = !toolbar && triggers.isNotEmpty ? toggleColumn : 0.0;
    final available = width - navW - endW - triggerColW;
    final sideSplit = widget.splitPanel != null && _splitPos == CsSplitPanelPosition.side;
    row.add(
      Expanded(
        child: _mainArea(narrow: false, width: available, height: height),
      ),
    );

    if (sideSplit && !(_splitHides && !_splitOpen)) {
      final maxW = math.max(_splitMinWidth, available - widget.minContentWidth);
      final size = (_splitSizeOwn ?? widget.splitPanelSize ?? _splitMinWidth).clamp(_splitMinWidth, maxW).toDouble();
      row.add(
        _splitScope(
          narrow: false,
          size: size,
          minSize: _splitMinWidth,
          maxSize: maxW,
          sideAvailable: true,
          child: _splitOpen ? SizedBox(width: size, child: widget.splitPanel) : widget.splitPanel!,
        ),
      );
    }

    // Tools or drawer.
    if (active != null) {
      final drawer = _drawer(active);
      final size = _endSize(active);
      final resizable = drawer?.resizable ?? false;
      final maxSize = math.max(_minDrawerSize, width - navW - widget.minContentWidth - triggerColW);
      row.add(
        SizedBox(
          width: size,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resizable)
                DecoratedBox(
                  decoration: BoxDecoration(color: cs.colors.backgroundContainerContent),
                  child: CsResizeHandle(
                    axis: CsResizeAxis.horizontal,
                    size: size,
                    min: _minDrawerSize,
                    max: maxSize,
                    growDirection: -1,
                    semanticLabel: drawer!.ariaLabels.resizeHandle ?? 'Resize ${drawer.ariaLabels.drawerName}',
                    onResizeTo: (v) => _resizeDrawer(active, v, maxSize),
                    onDrag: (dx) {
                      final rtl = Directionality.of(context) == TextDirection.rtl;
                      _resizeDrawer(active, size - (rtl ? -dx : dx), maxSize);
                    },
                  ),
                ),
              Expanded(
                child: _panel(
                  child: _endContent(active),
                  label: _endName(active),
                  closeLabel: _endCloseLabel(active),
                  onClose: () => _setEnd(null),
                  start: false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (triggerColW > 0) {
      row.add(
        Semantics(
          container: true,
          label: widget.ariaLabels.drawers,
          explicitChildNodes: true,
          child: SizedBox(
            width: triggerColW,
            child: Padding(
              padding: EdgeInsets.only(top: cs.space.scaledS),
              child: Column(
                spacing: CsSpace.xs,
                children: [for (final t in triggers) _Trigger(style: _TriggerStyle.circle, spec: t)],
              ),
            ),
          ),
        ),
      );
    }

    final body = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: row);
    if (!toolbar) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(narrow: false, triggers: triggers, navOpen: navOpen),
        Expanded(child: body),
      ],
    );
  }

  void _resizeDrawer(String id, double v, double maxSize) {
    final next = v.clamp(_minDrawerSize, maxSize).toDouble();
    setState(() => _drawerSizes[id] = next);
    _drawer(id)?.onResize?.call(next);
  }

  /// The toolbar of [CsAppLayoutToolbar] (all widths) and the phone bar of
  /// [CsAppLayout].
  Widget _toolbar({required bool narrow, required List<_TriggerSpec> triggers, required bool navOpen}) {
    final cs = context.cs;
    final c = cs.colors;
    final toolbar = widget.toolbarVariant;
    final navTrigger = _hasNav
        ? _TriggerSpec(
            icon: CsIcons.menu,
            label: widget.ariaLabels.navigationToggle,
            selected: navOpen && toolbar && !narrow,
            onPress: () => _setNav(!navOpen),
          )
        : null;
    if (toolbar) {
      return Container(
        height: 42,
        decoration: BoxDecoration(
          color: c.backgroundLayoutToolbar,
          border: Border(bottom: BorderSide(color: c.borderLayout)),
        ),
        padding: const EdgeInsetsDirectional.only(start: CsSpace.s, end: CsSpace.s),
        child: Row(
          spacing: CsSpace.xs,
          children: [
            if (navTrigger != null) _Trigger(style: _TriggerStyle.toolbar, spec: navTrigger),
            Expanded(child: widget.breadcrumbs ?? const SizedBox()),
            for (final t in triggers) _Trigger(style: _TriggerStyle.toolbar, spec: t),
          ],
        ),
      );
    }
    // `.mobile-bar`: 2 * space-m + space-scaled-xs high, panel shadow.
    // A fixed height (grown with the text size) rather than IntrinsicHeight:
    // breadcrumbs measure themselves with a LayoutBuilder, which cannot
    // report intrinsic sizes.
    final barHeight = math.max(
      2 * CsSpace.m + cs.space.scaledXs,
      MediaQuery.textScalerOf(context).scale(CsTypeScale.bodyM.lineHeight) + 2 * CsSpace.s,
    );
    return Container(
      height: barHeight,
      decoration: BoxDecoration(color: c.backgroundLayoutMobilePanel, boxShadow: cs.shadows.panel),
      child: SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (navTrigger != null) _Trigger(style: _TriggerStyle.mobile, spec: navTrigger, borderEnd: true),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: CsSpace.m),
                child: Align(alignment: AlignmentDirectional.centerStart, child: widget.breadcrumbs),
              ),
            ),
            for (final t in triggers) _Trigger(style: _TriggerStyle.mobile, spec: t, borderStart: true),
          ],
        ),
      ),
    );
  }

  Widget _narrow(BoxConstraints constraints) {
    final navOpen = _navOpen(true);
    final active = _activeEnd;
    final triggers = _endTriggers();
    final height = constraints.maxHeight;
    final narrowSplitOpen = widget.splitPanel != null && _splitOpen;

    final base = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(narrow: true, triggers: triggers, navOpen: navOpen),
        Expanded(
          child: _mainArea(narrow: true, width: constraints.maxWidth, height: height),
        ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(child: base),
        _MobileOverlay(
          open: _hasNav && navOpen,
          fromStart: true,
          onClose: () => _setNav(false),
          child: _hasNav
              ? _panel(
                  child: widget.navigation!,
                  label: widget.ariaLabels.navigation,
                  closeLabel: widget.ariaLabels.navigationClose,
                  onClose: () => _setNav(false),
                  start: true,
                  border: false,
                )
              : const SizedBox(),
        ),
        _MobileOverlay(
          open: active != null,
          fromStart: false,
          onClose: () => _setEnd(null),
          child: active == null
              ? const SizedBox()
              : _panel(
                  child: _endContent(active),
                  label: _endName(active),
                  closeLabel: _endCloseLabel(active),
                  onClose: () => _setEnd(null),
                  start: false,
                  border: false,
                ),
        ),
        _MobileOverlay(
          open: narrowSplitOpen,
          fromStart: false,
          fromBottom: true,
          onClose: () => _setSplit(false),
          child: widget.splitPanel == null
              ? const SizedBox()
              : _splitScope(
                  narrow: true,
                  size: height,
                  minSize: _splitMinHeight,
                  maxSize: height,
                  sideAvailable: false,
                  child: widget.splitPanel!,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = widget.mobile ?? constraints.maxWidth <= CsBreakpoint.xs.minWidth;
        if (narrow != _lastNarrow) {
          // Moving to the phone layout closes the overlays the wide layout
          // had open, like Cloudscape's `closeNavigationIfNecessary`.
          _lastNarrow = narrow;
          if (narrow && widget.navigationOpen == null) _navOwn = false;
          if (!narrow && widget.navigationOpen == null) _navOwn = null;
        }
        final body = narrow ? _narrow(constraints) : _wide(constraints);
        // The app layout is the page frame: it fills the space it is given,
        // even under loose constraints (a Column, a Center), instead of
        // shrinking around its Stack to nothing.
        return SizedBox(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          child: ColoredBox(
            color: context.cs.colors.backgroundLayoutMain,
            child: DefaultTextStyle.merge(style: context.cs.body, child: body),
          ),
        );
      },
    );
  }
}

/// A full-screen panel that slides in over the layout on phones.
class _MobileOverlay extends StatefulWidget {
  const _MobileOverlay({
    required this.open,
    required this.fromStart,
    required this.onClose,
    required this.child,
    this.fromBottom = false,
  });

  final bool open;
  final bool fromStart;
  final bool fromBottom;
  final VoidCallback onClose;
  final Widget child;

  @override
  State<_MobileOverlay> createState() => _MobileOverlayState();
}

class _MobileOverlayState extends State<_MobileOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: CsDurations.complex, value: widget.open ? 1 : 0)
      ..addStatusListener((_) => setState(() {}));
  }

  @override
  void didUpdateWidget(_MobileOverlay old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) {
      if (CsMotion.reduceMotion(context)) {
        _c.value = widget.open ? 1 : 0;
      } else {
        widget.open ? _c.forward() : _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open && _c.isDismissed) return const SizedBox.shrink();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final begin = widget.fromBottom ? const Offset(0, 1) : Offset((widget.fromStart ? -1 : 1) * (rtl ? -1 : 1), 0);
    return Positioned.fill(
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
        child: CsFocusTrap(
          onEscPress: widget.onClose,
          disableFocusTrap: !widget.open,
          child: SlideTransition(
            position: Tween(
              begin: begin,
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _c, curve: CsCurves.expressive)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum _TriggerStyle { circle, toolbar, mobile }

class _TriggerSpec {
  const _TriggerSpec({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPress,
    this.iconWidget,
    this.badge = false,
  });

  final CsIconData icon;
  final Widget? iconWidget;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onPress;
}

/// A panel trigger: the round visual refresh toggle, the 30px toolbar
/// trigger or the 40px phone bar button.
class _Trigger extends StatelessWidget {
  const _Trigger({required this.style, required this.spec, this.borderStart = false, this.borderEnd = false});

  final _TriggerStyle style;
  final _TriggerSpec spec;
  final bool borderStart;
  final bool borderEnd;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final icon = spec.iconWidget ?? CsIcon(spec.icon);
    return CsPressable(
      onPress: spec.onPress,
      semanticLabel: spec.label,
      excludeChildSemantics: true,
      toggled: spec.selected,
      scaleOnPress: style != _TriggerStyle.mobile,
      borderRadius: BorderRadius.circular(style == _TriggerStyle.mobile ? 0 : CsBorderRadius.button),
      builder: (context, state) {
        switch (style) {
          case _TriggerStyle.circle:
            final bg = spec.selected
                ? (state.pressed
                      ? c.backgroundLayoutToggleSelectedActive
                      : state.hovered
                      ? c.backgroundLayoutToggleSelectedHover
                      : c.backgroundLayoutToggleSelectedDefault)
                : (state.pressed
                      ? c.backgroundLayoutToggleActive
                      : state.hovered
                      ? c.backgroundLayoutToggleHover
                      : c.backgroundLayoutToggleDefault);
            final fg = spec.selected
                ? c.textLayoutToggleSelected
                : state.active
                ? c.textLayoutToggleHover
                : c.textLayoutToggle;
            return _withBadge(
              Container(
                width: CsSpace.layoutToggleDiameter,
                height: CsSpace.layoutToggleDiameter,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg, boxShadow: cs.shadows.panelToggle),
                alignment: Alignment.center,
                child: _tint(icon, fg),
              ),
              9,
              0,
            );
          case _TriggerStyle.toolbar:
            final bg = spec.selected
                ? (state.pressed
                      ? c.backgroundLayoutToggleSelectedActive
                      : state.hovered
                      ? c.backgroundLayoutToggleSelectedHover
                      : c.backgroundLayoutToggleSelectedDefault)
                : (state.pressed
                      ? c.backgroundControlDisabled
                      : state.hovered
                      ? c.backgroundInputDisabled
                      : null);
            final fg = spec.selected
                ? c.textLayoutToggleSelected
                : state.active
                ? c.textInteractiveHover
                : c.textInteractiveDefault;
            return _withBadge(
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CsBorderRadius.button)),
                alignment: Alignment.center,
                child: _tint(icon, fg),
              ),
              8,
              -1,
            );
          case _TriggerStyle.mobile:
            final side = BorderSide(color: c.borderLayout);
            return Container(
              width: 40,
              decoration: BoxDecoration(
                color: state.active ? c.backgroundLayoutPanelHover : null,
                border: BorderDirectional(
                  start: borderStart ? side : BorderSide.none,
                  end: borderEnd ? side : BorderSide.none,
                ),
              ),
              alignment: Alignment.center,
              child: _withBadge(_tint(icon, spec.selected ? c.textAccent : c.textInteractiveDefault), 8, -2),
            );
        }
      },
    );
  }

  Widget _tint(Widget icon, Color color) => IconTheme.merge(
    data: IconThemeData(color: color),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: color),
      child: icon,
    ),
  );

  Widget _withBadge(Widget child, double dot, double inset) {
    if (!spec.badge) return child;
    return Builder(
      builder: (context) => Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          PositionedDirectional(
            top: inset,
            end: inset,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(shape: BoxShape.circle, color: context.cs.colors.backgroundBadgeIcon),
            ),
          ),
        ],
      ),
    );
  }
}
