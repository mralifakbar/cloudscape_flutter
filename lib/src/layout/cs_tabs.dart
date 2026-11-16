import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/icons.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_container.dart';

/// Tabs styles (Cloudscape `variant`).
enum CsTabsVariant {
  /// Tabs over plain content.
  defaultVariant,

  /// Tabs as the header of a container.
  container,

  /// Like [container], for tabs stacked with other containers.
  stacked,
}

/// When arrow keys activate a tab (Cloudscape `keyboardActivationMode`).
enum CsTabsKeyboardActivation {
  /// Moving focus with the arrows also selects the tab.
  automatic,

  /// Arrows move focus; Enter or Space selects.
  manual,
}

/// One tab (Cloudscape `TabsProps.Tab`).
@immutable
class CsTab {
  const CsTab({
    required this.id,
    required this.label,
    this.labelWidget,
    this.content,
    this.disabled = false,
    this.disabledReason,
    this.dismissible = false,
    this.dismissLabel,
    this.dismissDisabled = false,
    this.onDismiss,
    this.action,
  });

  final String id;

  /// Tab text, also its accessible name.
  final String label;

  /// Custom label content in place of [label].
  final Widget? labelWidget;

  /// The panel shown while the tab is active.
  final Widget? content;
  final bool disabled;

  /// Tooltip explaining why the tab is disabled. Keeps it focusable.
  final String? disabledReason;

  /// Shows a dismiss (close) button after the label.
  final bool dismissible;

  /// Accessible name of the dismiss button. Defaults to "Close [label]".
  final String? dismissLabel;
  final bool dismissDisabled;
  final VoidCallback? onDismiss;

  /// A small control after the label, such as an icon button dropdown.
  final Widget? action;
}

/// Copy for [CsTabs].
@immutable
class CsTabsI18nStrings {
  const CsTabsI18nStrings({this.scrollLeftAriaLabel, this.scrollRightAriaLabel});

  /// Defaults to the shared "Scroll to start" string.
  final String? scrollLeftAriaLabel;

  /// Defaults to the shared "Scroll to end" string.
  final String? scrollRightAriaLabel;
}

/// Cloudscape's `Tabs`: switches between panels of related content.
///
/// ```dart
/// CsTabs(
///   activeTabId: tab,
///   onChange: (id) => setState(() => tab = id),
///   tabs: const [
///     CsTab(id: 'details', label: 'Details', content: Text('Instance details')),
///     CsTab(id: 'monitoring', label: 'Monitoring', content: Text('Metrics')),
///     CsTab(id: 'tags', label: 'Tags', disabled: true, disabledReason: 'No tags yet.'),
///   ],
/// )
/// ```
///
/// Uncontrolled when [activeTabId] is null (starts on the first enabled
/// tab). Labels are 16px bold `color-text-interactive-default`, the active
/// one `color-text-accent` over a 4px rounded `color-border-tabs-underline`
/// indicator that slides between tabs (`motion-duration-expressive`).
/// The tab row scrolls when it overflows and shows start and end arrow
/// buttons, which matters most on phones. Arrow keys, Home and End move
/// between tabs. Set [swipeable] to change tabs with a horizontal swipe on
/// the content.
class CsTabs extends StatefulWidget {
  const CsTabs({
    super.key,
    required this.tabs,
    this.activeTabId,
    this.onChange,
    this.variant = CsTabsVariant.defaultVariant,
    this.actions,
    this.disableContentPaddings = false,
    this.fitHeight = false,
    this.keyboardActivationMode = CsTabsKeyboardActivation.automatic,
    this.i18nStrings = const CsTabsI18nStrings(),
    this.semanticLabel,
    this.swipeable = false,
    this.stackPosition = CsStackPosition.only,
  });

  final List<CsTab> tabs;

  /// Controlled active tab. Null makes the tabs manage it.
  final String? activeTabId;

  /// Called with the id of the tab the user selects.
  final ValueChanged<String>? onChange;
  final CsTabsVariant variant;

  /// Controls at the end of the tab row.
  final Widget? actions;
  final bool disableContentPaddings;

  /// Fill the parent's height; the panel scrolls. Needs a bounded height.
  final bool fitHeight;
  final CsTabsKeyboardActivation keyboardActivationMode;
  final CsTabsI18nStrings i18nStrings;

  /// Name of the tab list (Cloudscape `ariaLabel`).
  final String? semanticLabel;

  /// Change tabs with a horizontal swipe on the content.
  final bool swipeable;

  /// Position in a stack of [CsTabsVariant.stacked] containers.
  final CsStackPosition stackPosition;

  @override
  State<CsTabs> createState() => _CsTabsState();
}

class _CsTabsState extends State<CsTabs> {
  String? _ownActive;
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  final Map<String, FocusNode> _focus = {};
  final GlobalKey _rowKey = GlobalKey();
  Rect? _indicator;
  bool _canScrollStart = false;
  bool _canScrollEnd = false;

  String? get _active {
    final id = widget.activeTabId ?? _ownActive;
    if (id != null && widget.tabs.any((t) => t.id == id)) return id;
    for (final t in widget.tabs) {
      if (!t.disabled) return t.id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateScroll);
    _schedule();
  }

  @override
  void didUpdateWidget(CsTabs old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _updateScroll();
    });
  }

  void _measure() {
    final id = _active;
    final row = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    final tab = id == null ? null : _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    Rect? next;
    if (row != null && tab != null && row.attached && tab.attached) {
      final o = tab.localToGlobal(Offset.zero, ancestor: row);
      next = o & tab.size;
    }
    if (next != _indicator) setState(() => _indicator = next);
  }

  void _updateScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final start = p.pixels > p.minScrollExtent + 0.5;
    final end = p.pixels < p.maxScrollExtent - 0.5;
    if (start != _canScrollStart || end != _canScrollEnd) {
      setState(() {
        _canScrollStart = start;
        _canScrollEnd = end;
      });
    }
  }

  FocusNode _node(String id) => _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'CsTab $id'));

  void _select(CsTab tab) {
    if (tab.disabled) return;
    if (widget.activeTabId == null) setState(() => _ownActive = tab.id);
    if (tab.id != _active || widget.activeTabId == null) widget.onChange?.call(tab.id);
    _reveal(tab.id);
    _schedule();
  }

  void _reveal(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: CsMotion.duration(context, CsDurations.expressive),
        curve: CsCurves.expressive,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        ctx,
        duration: CsMotion.duration(context, CsDurations.expressive),
        curve: CsCurves.expressive,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  List<CsTab> get _focusable => [
    for (final t in widget.tabs)
      if (!t.disabled || t.disabledReason != null) t,
  ];

  KeyEventResult _onKey(CsTab tab, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final list = _focusable;
    final i = list.indexWhere((t) => t.id == tab.id);
    if (i < 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    int? next;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight) next = rtl ? i - 1 : i + 1;
    if (k == LogicalKeyboardKey.arrowLeft) next = rtl ? i + 1 : i - 1;
    if (k == LogicalKeyboardKey.home) next = 0;
    if (k == LogicalKeyboardKey.end) next = list.length - 1;
    if (next == null) return KeyEventResult.ignored;
    final target = list[(next + list.length) % list.length];
    _node(target.id).requestFocus();
    _reveal(target.id);
    if (widget.keyboardActivationMode == CsTabsKeyboardActivation.automatic && !target.disabled) _select(target);
    return KeyEventResult.handled;
  }

  void _scrollBy(int dir) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final target = (p.pixels + dir * p.viewportDimension * 0.75).clamp(p.minScrollExtent, p.maxScrollExtent);
    _scroll.animateTo(target, duration: CsMotion.duration(context, CsDurations.complex), curve: CsCurves.expressive);
  }

  Widget _tab(BuildContext context, CsTab tab, {required bool first, required bool last}) {
    final cs = context.cs;
    final c = cs.colors;
    final active = tab.id == _active;
    final key = _keys.putIfAbsent(tab.id, GlobalKey.new);
    final labelStyle = cs
        .text(CsTypeScale.bodyM)
        .copyWith(
          fontSize: CsFontTokens.fontSizeTabs,
          height: CsFontTokens.lineHeightTabs / CsFontTokens.fontSizeTabs,
          fontWeight: tab.disabled ? CsFontTokens.fontWeightTabsDisabled : CsFontTokens.fontWeightTabs,
        );
    final rovingFocus = active || (_active == null && first);

    Widget link = CsPressable(
      focusNode: _node(tab.id),
      onPress: tab.disabled ? null : () => _select(tab),
      disabled: tab.disabled && tab.disabledReason == null,
      selected: active,
      semanticLabel: tab.label,
      excludeChildSemantics: tab.labelWidget == null,
      inMutuallyExclusiveGroup: true,
      scaleOnPress: false,
      canRequestFocus: rovingFocus || tab.disabledReason != null,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final color = tab.disabled
            ? c.textInteractiveDisabled
            : active || state.active
            ? c.textAccent
            : c.textInteractiveDefault;
        return Padding(
          // `tabs-tab-link.refresh`: 7px block padding inside a 1px border.
          padding: const EdgeInsetsDirectional.fromSTEB(CsSpace.xxs, CsSpace.staticXs, CsSpace.xxs, CsSpace.staticXs),
          child: DefaultTextStyle(
            style: labelStyle.copyWith(color: color),
            child: tab.labelWidget ?? Text(tab.label, maxLines: 1, softWrap: false),
          ),
        );
      },
    );
    link = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: (_, e) => _onKey(tab, e), child: link);
    if (tab.disabled && tab.disabledReason != null) {
      link = CsTooltip(content: tab.disabledReason!, child: link);
    }

    final dismiss = tab.dismissible
        ? CsButton(
            variant: CsButtonVariant.inlineIcon,
            icon: CsIcons.close,
            semanticLabel: tab.dismissLabel ?? '${context.csStrings.close} ${tab.label}',
            disabled: tab.dismissDisabled || tab.disabled,
            onPress: tab.onDismiss,
          )
        : null;

    return Container(
      key: key,
      padding: EdgeInsetsDirectional.only(
        start: first ? CsSpace.xs - 1 : CsSpace.xs,
        end: last ? CsSpace.xs - 1 : CsSpace.xs,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, spacing: CsSpace.xxs, children: [link, ?tab.action, ?dismiss]),
    );
  }

  Widget _separator(BuildContext context) => Padding(
    // `inset: calc(space-static-s - border-active-width) 0`.
    padding: const EdgeInsets.symmetric(vertical: CsSpace.staticS - CsBorderLine.activeWidth),
    child: SizedBox(width: 1, child: ColoredBox(color: context.cs.colors.borderTabsDivider)),
  );

  Widget _arrow(BuildContext context, {required bool start}) {
    final cs = context.cs;
    final strings = context.csStrings;
    final enabled = start ? _canScrollStart : _canScrollEnd;
    final side = BorderSide(color: cs.colors.borderControlDisabled);
    return Container(
      margin: EdgeInsets.symmetric(vertical: cs.space.scaledS - 6),
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.xxs),
      decoration: BoxDecoration(
        border: start ? BorderDirectional(end: side) : BorderDirectional(start: side),
      ),
      child: CsButton(
        variant: CsButtonVariant.icon,
        icon: start ? CsIcons.angleLeft : CsIcons.angleRight,
        semanticLabel: start
            ? widget.i18nStrings.scrollLeftAriaLabel ?? strings.scrollTabsStart
            : widget.i18nStrings.scrollRightAriaLabel ?? strings.scrollTabsEnd,
        disabled: !enabled,
        onPress: () => _scrollBy(start ? -1 : 1),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final children = <Widget>[];
    for (var i = 0; i < widget.tabs.length; i++) {
      if (i > 0) children.add(_separator(context));
      children.add(_tab(context, widget.tabs[i], first: i == 0, last: i == widget.tabs.length - 1));
    }
    final ind = _indicator;
    final reduce = CsMotion.reduceMotion(context);
    final row = Stack(
      clipBehavior: Clip.none,
      children: [
        IntrinsicHeight(
          child: Row(key: _rowKey, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
        if (ind != null)
          AnimatedPositioned(
            duration: reduce ? Duration.zero : CsDurations.expressive,
            curve: CsCurves.expressive,
            left: ind.left,
            width: math.max(0, ind.width - 1),
            bottom: 0,
            height: CsBorderLine.activeWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.borderTabsUnderline,
                borderRadius: BorderRadius.circular(CsBorderRadius.tabsFocusRing),
              ),
            ),
          ),
      ],
    );
    final overflow = _canScrollStart || _canScrollEnd;
    final list = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _updateScroll();
        return false;
      },
      child: SingleChildScrollView(controller: _scroll, scrollDirection: Axis.horizontal, child: row),
    );
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderTabsDivider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (overflow) _arrow(context, start: true),
            Expanded(
              child: Align(alignment: AlignmentDirectional.centerStart, child: list),
            ),
            if (overflow) _arrow(context, start: false),
            if (widget.actions != null) Padding(padding: const EdgeInsets.all(CsSpace.xs), child: widget.actions),
          ],
        ),
      ),
    );
  }

  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = (v < 0) != rtl;
    final enabled = [
      for (final t in widget.tabs)
        if (!t.disabled) t,
    ];
    final i = enabled.indexWhere((t) => t.id == _active);
    if (i < 0) return;
    final j = forward ? i + 1 : i - 1;
    if (j < 0 || j >= enabled.length) return;
    _select(enabled[j]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final container = widget.variant != CsTabsVariant.defaultVariant;
    CsTab? active;
    for (final t in widget.tabs) {
      if (t.id == _active) active = t;
    }
    final padding = widget.disableContentPaddings
        ? EdgeInsets.zero
        : container
        ? EdgeInsets.only(
            top: cs.space.tabsContentTop,
            bottom: cs.space.scaledL,
            left: CsSpace.containerHorizontal,
            right: CsSpace.containerHorizontal,
          )
        : EdgeInsets.symmetric(vertical: cs.space.scaledM);

    Widget panel = Semantics(
      container: true,
      label: active?.label,
      child: KeyedSubtree(
        key: ValueKey(active?.id),
        child: Padding(
          padding: padding,
          child: DefaultTextStyle.merge(style: cs.body, child: active?.content ?? const SizedBox()),
        ),
      ),
    );
    if (widget.swipeable) {
      panel = GestureDetector(behavior: HitTestBehavior.translucent, onHorizontalDragEnd: _swipe, child: panel);
    }
    if (widget.fitHeight) panel = Expanded(child: SingleChildScrollView(child: panel));

    final header = _header(context);
    if (container) {
      return CsContainer(
        variant: widget.variant == CsTabsVariant.stacked
            ? CsContainerVariant.stacked
            : CsContainerVariant.defaultVariant,
        stackPosition: widget.stackPosition,
        disableHeaderPaddings: true,
        disableContentPaddings: true,
        fitHeight: widget.fitHeight,
        header: header,
        child: Column(
          mainAxisSize: widget.fitHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [panel],
        ),
      );
    }
    return Column(
      mainAxisSize: widget.fitHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, panel],
    );
  }
}
