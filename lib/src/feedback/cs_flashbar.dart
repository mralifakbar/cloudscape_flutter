import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../navigation/cs_link.dart';
import '../system/cs_pressable.dart';
import '../system/cs_size_reveal.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_live_region.dart';
import 'cs_message_layout.dart';
import 'cs_spinner.dart';

/// Flash message types (Cloudscape `type`).
enum CsFlashbarType { success, error, warning, info, inProgress }

/// How a flash added after the page loaded is announced (Cloudscape
/// `ariaRole`).
enum CsFlashbarAriaRole {
  /// Interrupts the screen reader. For messages that need attention now.
  alert,

  /// Waits for the screen reader to finish. For status updates.
  status,
}

/// One flash message (Cloudscape `FlashbarProps.MessageDefinition`).
///
/// ```dart
/// CsFlashbarItem(
///   id: 'launch-1',
///   type: CsFlashbarType.success,
///   header: 'Instance launched',
///   content: 'i-0abc123 is starting.',
///   dismissible: true,
///   onDismiss: () => setState(() => _items.removeWhere((i) => i.id == 'launch-1')),
/// )
/// ```
@immutable
class CsFlashbarItem {
  const CsFlashbarItem({
    this.id,
    this.type = CsFlashbarType.info,
    this.header,
    this.headerWidget,
    this.content,
    this.contentWidget,
    this.loading = false,
    this.dismissible = false,
    this.dismissLabel,
    this.onDismiss,
    this.statusIconAriaLabel,
    this.ariaRole,
    this.action,
    this.buttonText,
    this.onButtonPress,
  });

  /// Identifies the message across rebuilds, so the right one animates out
  /// when it is removed. Give every item an id.
  final String? id;
  final CsFlashbarType type;

  /// Heading text, in bold.
  final String? header;
  final Widget? headerWidget;

  /// The message text.
  final String? content;

  /// Rich message content in place of [content], such as a
  /// `CsProgressBar(variant: CsProgressBarVariant.flash)`.
  final Widget? contentWidget;

  /// Replaces the status icon with a spinner and uses the info colors.
  final bool loading;

  /// Shows a close button that calls [onDismiss].
  final bool dismissible;

  /// Accessible name of the close button. Defaults to "Dismiss".
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  /// Accessible name of the status icon. Defaults to the flashbar's
  /// `i18nStrings` label for [type].
  final String? statusIconAriaLabel;

  /// How the message is announced when it appears after the flashbar first
  /// renders. Null announces politely, like [CsFlashbarAriaRole.status].
  final CsFlashbarAriaRole? ariaRole;

  /// An action next to the message. Cloudscape's guidelines allow a button
  /// only.
  final Widget? action;

  /// Shows a normal button with this text as the action. Ignored when
  /// [action] is set (Cloudscape deprecates it in favor of `action`).
  final String? buttonText;
  final VoidCallback? onButtonPress;

  /// The type after [loading] is applied: a loading message counts as in
  /// progress.
  CsFlashbarType get effectiveType => loading ? CsFlashbarType.inProgress : type;
}

/// Copy for [CsFlashbar] (Cloudscape `i18nStrings`).
@immutable
class CsFlashbarI18nStrings {
  const CsFlashbarI18nStrings({
    this.ariaLabel = 'Notifications',
    this.notificationBarAriaLabel = 'All notifications',
    this.notificationBarText = 'Notifications',
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    this.successIconAriaLabel,
    this.infoIconAriaLabel,
    this.inProgressIconAriaLabel,
  });

  /// Accessible name of the list of messages.
  final String ariaLabel;

  /// Accessible name of the expand button of a stacked flashbar.
  final String notificationBarAriaLabel;

  /// Text shown in the notification bar of a stacked flashbar.
  final String notificationBarText;

  /// Status icon names. Unset ones fall back to [CsStrings].
  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;
  final String? successIconAriaLabel;
  final String? infoIconAriaLabel;
  final String? inProgressIconAriaLabel;

  /// The status icon name for [type].
  String iconLabel(CsFlashbarType type, CsStrings strings) => switch (type) {
    CsFlashbarType.error => errorIconAriaLabel ?? strings.error,
    CsFlashbarType.warning => warningIconAriaLabel ?? strings.warning,
    CsFlashbarType.success => successIconAriaLabel ?? strings.success,
    CsFlashbarType.info => infoIconAriaLabel ?? strings.info,
    CsFlashbarType.inProgress => inProgressIconAriaLabel ?? strings.inProgress,
  };
}

/// Cloudscape's `Flashbar`: page-level messages about the result of an
/// action (an instance launched, a deletion failed) or an ongoing process,
/// shown at the top of the page.
///
/// ```dart
/// CsFlashbar(
///   items: [
///     CsFlashbarItem(
///       id: 'deleted',
///       type: CsFlashbarType.success,
///       content: 'Bucket example-bucket deleted.',
///       dismissible: true,
///       onDismiss: () => setState(() => _items.removeWhere((i) => i.id == 'deleted')),
///     ),
///   ],
/// )
/// ```
///
/// Messages added later slide down 20px and fade in over Cloudscape's 250ms
/// complex motion; removed ones fade and slide up over 115ms, then the space
/// closes. Messages added after the first render are announced to screen
/// readers (assertively for [CsFlashbarAriaRole.alert]).
///
/// With [stackItems], two or more messages collapse into a stack: the
/// newest on top, up to three colored edges peeking out below it (more when
/// more message colors are present, so every color shows), and a
/// notification bar with a count per type. The bar expands the stack into
/// the full list and collapses it again, with every message moving between
/// its stacked and listed position over 115ms. Reduced motion makes all of
/// it instant.
class CsFlashbar extends StatefulWidget {
  const CsFlashbar({
    super.key,
    required this.items,
    this.stackItems = false,
    this.i18nStrings = const CsFlashbarI18nStrings(),
  });

  /// The messages, newest first.
  final List<CsFlashbarItem> items;

  /// Collapse two or more messages into a stack with a notification bar.
  final bool stackItems;
  final CsFlashbarI18nStrings i18nStrings;

  @override
  State<CsFlashbar> createState() => _CsFlashbarState();
}

class _Entry {
  _Entry(this.key, this.item, {required this.animateIn});

  final Object key;
  CsFlashbarItem item;
  bool exiting = false;
  final bool animateIn;
  final GlobalKey flashKey = GlobalKey();
}

class _CsFlashbarState extends State<CsFlashbar> with SingleTickerProviderStateMixin {
  final List<_Entry> _entries = [];
  late final AnimationController _expand;
  bool _expanded = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(vsync: this, duration: CsDurations.responsive);
    _sync(animate: false);
    _initialized = true;
  }

  @override
  void didUpdateWidget(CsFlashbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(animate: true);
    if (_visibleItems.length <= 1 && _expanded) {
      _expanded = false;
      _expand.value = 0;
    }
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  static Object _keyOf(CsFlashbarItem item, int index) => item.id ?? 'cs-flash-index-$index';

  List<CsFlashbarItem> get _visibleItems => widget.items;

  void _sync({required bool animate}) {
    final next = <Object, CsFlashbarItem>{};
    for (var i = 0; i < widget.items.length; i++) {
      next[_keyOf(widget.items[i], i)] = widget.items[i];
    }
    for (final e in _entries) {
      final updated = next[e.key];
      if (updated != null) {
        e.item = updated;
        e.exiting = false;
      } else {
        e.exiting = true;
      }
    }
    // Rebuild the order from the new list, keeping exiting entries next to
    // the neighbors they had.
    final byKey = {for (final e in _entries) e.key: e};
    final ordered = <_Entry>[];
    final added = <_Entry>[];
    for (final key in next.keys) {
      final existing = byKey[key];
      if (existing != null) {
        ordered.add(existing);
      } else {
        final entry = _Entry(key, next[key]!, animateIn: animate);
        ordered.add(entry);
        added.add(entry);
      }
    }
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (!e.exiting || ordered.contains(e)) continue;
      // Insert after the previous surviving neighbor.
      var at = 0;
      for (var j = i - 1; j >= 0; j--) {
        final idx = ordered.indexOf(_entries[j]);
        if (idx >= 0) {
          at = idx + 1;
          break;
        }
      }
      ordered.insert(at, e);
    }
    _entries
      ..clear()
      ..addAll(ordered);
    if (animate && _initialized && added.isNotEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _announce(added));
    }
  }

  void _announce(List<_Entry> added) {
    if (!mounted) return;
    for (final e in added) {
      final context = e.flashKey.currentContext;
      if (context == null) continue;
      final text = CsLiveRegion.textOf(context);
      CsLiveRegion.announce(this.context, text, assertive: e.item.ariaRole == CsFlashbarAriaRole.alert);
    }
  }

  void _removeEntry(_Entry entry) {
    if (!mounted || !entry.exiting) return;
    setState(() => _entries.remove(entry));
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (CsMotion.reduceMotion(context)) {
      _expand.value = _expanded ? 1 : 0;
    } else {
      _expanded ? _expand.forward() : _expand.reverse();
    }
  }

  Widget _flash(_Entry e, {double contentOpacity = 1, bool interactive = true}) {
    return _AnimatedEntry(
      key: ValueKey(e.key),
      exiting: e.exiting,
      animateIn: e.animateIn,
      onExited: () => _removeEntry(e),
      child: IgnorePointer(
        ignoring: !interactive || e.exiting,
        child: ExcludeSemantics(
          excluding: !interactive || e.exiting,
          child: _Flash(key: e.flashKey, item: e.item, i18nStrings: widget.i18nStrings, contentOpacity: contentOpacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = _entries.where((e) => !e.exiting).toList();
    final stacked = widget.stackItems && live.length > 1;
    if (!stacked) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.i18nStrings.ariaLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _entries.length; i++)
              Padding(
                key: ValueKey(_entries[i].key),
                // styles.scss: `.flash-list > li:not(:last-child)` adds space-xxxs.
                padding: EdgeInsets.only(bottom: i == _entries.length - 1 ? 0 : CsSpace.xxxs),
                child: _flash(_entries[i]),
              ),
          ],
        ),
      );
    }
    return _buildStack(context, live);
  }

  Widget _buildStack(BuildContext context, List<_Entry> live) {
    final items = live.map((e) => e.item).toList();
    final colors = items.map((i) => _colorGroup(i.effectiveType)).toSet().length;
    final depth = math.min(math.max(colors, 3), items.length);
    final selection = csCollapsedFlashSelection(items, depth);
    final slotOf = <Object, int>{};
    for (var c = 0; c < selection.length; c++) {
      slotOf[live[selection[c]].key] = c;
    }
    final counts = {for (final t in CsFlashbarType.values) t: 0};
    for (final i in items) {
      counts[i.effectiveType] = counts[i.effectiveType]! + 1;
    }

    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final t = _expand.value;
        final children = <Widget>[];
        final slots = <int?>[];
        for (final e in _entries) {
          final slot = e.exiting ? null : slotOf[e.key];
          final isTop = slot == 0;
          final interactive = isTop || t >= 1;
          children.add(_flash(e, contentOpacity: isTop ? 1 : t, interactive: interactive));
          slots.add(slot);
        }
        children.add(
          _NotificationBar(
            expanded: _expanded,
            counts: counts,
            i18nStrings: widget.i18nStrings,
            onToggle: _toggleExpanded,
          ),
        );
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.i18nStrings.ariaLabel,
          child: _FlashStack(
            t: t,
            slots: slots,
            depth: depth,
            placeholderHeight:
                CsFontTokens.lineHeightBodyM + (context.cs.space.scaledXs + 1 + context.cs.space.scaledXxs) * 2,
            collapsedOverlap: context.cs.space.scaledXl + 3,
            expandedOverlap: context.cs.space.scaledS,
            children: children,
          ),
        );
      },
    );
  }
}

int _colorGroup(CsFlashbarType type) => switch (type) {
  CsFlashbarType.error => 0,
  CsFlashbarType.warning => 1,
  CsFlashbarType.success => 2,
  CsFlashbarType.info || CsFlashbarType.inProgress => 3,
};

/// Which items a collapsed stack shows, as indexes into [items] (newest
/// first), so every message color present is represented
/// (`getVisibleCollapsedItems` in Cloudscape's `flashbar/utils.ts`).
@visibleForTesting
List<int> csCollapsedFlashSelection(List<CsFlashbarItem> items, int desiredLength) {
  final onTop = <({int index, bool repeated})>[];
  final toPromote = <int>[];
  final added = <int>{};
  final finalLength = math.min(items.length, desiredLength);
  for (var i = 0; i < items.length; i++) {
    final color = _colorGroup(items[i].effectiveType);
    final repeated = added.contains(color);
    if (i < finalLength) {
      onTop.add((index: i, repeated: repeated));
    } else {
      if (added.length == 4) break;
      if (!repeated) toPromote.add(i);
    }
    added.add(color);
  }
  final reversed = <int>[];
  var reserved = 0;
  for (var j = onTop.length - 1; j >= 0; j--) {
    if (onTop[j].repeated && reserved < toPromote.length) {
      reserved++;
    } else {
      reversed.add(onTop[j].index);
    }
  }
  final selected = reversed.reversed.toList();
  for (var k = 0; selected.length < finalLength && k < toPromote.length; k++) {
    selected.add(toPromote[k]);
  }
  return selected;
}

/// A single flash message, the building block of [CsFlashbar], for places
/// that show one message on their own.
///
/// ```dart
/// const CsFlash(item: CsFlashbarItem(type: CsFlashbarType.warning, content: 'Quota at 90%.'))
/// ```
class CsFlash extends StatelessWidget {
  const CsFlash({super.key, required this.item, this.i18nStrings = const CsFlashbarI18nStrings()});

  final CsFlashbarItem item;
  final CsFlashbarI18nStrings i18nStrings;

  @override
  Widget build(BuildContext context) => _Flash(item: item, i18nStrings: i18nStrings);
}

class _Flash extends StatelessWidget {
  const _Flash({super.key, required this.item, required this.i18nStrings, this.contentOpacity = 1});

  final CsFlashbarItem item;
  final CsFlashbarI18nStrings i18nStrings;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    final strings = context.csStrings;
    final type = item.effectiveType;
    final warning = type == CsFlashbarType.warning;
    final outer = context.cs.colors;
    final (background, border) = switch (type) {
      CsFlashbarType.success => (outer.backgroundFlashbarSuccess, outer.borderStatusSuccess),
      CsFlashbarType.error => (outer.backgroundFlashbarError, outer.borderStatusError),
      CsFlashbarType.warning => (outer.backgroundFlashbarWarning, outer.borderStatusWarning),
      CsFlashbarType.info || CsFlashbarType.inProgress => (outer.backgroundFlashbarInfo, outer.borderStatusInfo),
    };
    final iconLabel = item.statusIconAriaLabel ?? i18nStrings.iconLabel(type, strings);

    final flash = CsVisualContext(
      context: warning ? CsVisualContextName.flashbarWarning : CsVisualContextName.flashbar,
      child: Builder(
        builder: (context) {
          final cs = context.cs;
          final c = cs.colors;
          final textColor = warning ? c.textNotificationYellow : c.textNotificationDefault;
          final iconColor = switch (type) {
            CsFlashbarType.success => c.textFlashbarIconSuccess,
            CsFlashbarType.error => c.textFlashbarIconError,
            CsFlashbarType.warning => c.textFlashbarIconWarning,
            CsFlashbarType.info || CsFlashbarType.inProgress => c.textFlashbarIconInfo,
          };
          final textStyle = cs.text(CsTypeScale.bodyM).copyWith(color: textColor);
          // styles.scss `.flash-text`: border-item-width margin plus
          // space-scaled-xxs padding above and below each text column.
          final textPadding = EdgeInsets.symmetric(vertical: CsBorderLine.itemWidth + cs.space.scaledXxs);

          final Widget icon = item.loading
              ? Semantics(
                  label: iconLabel,
                  child: CsSpinner(semanticLabel: '', dangerouslySetColor: iconColor),
                )
              : CsIcon(_iconFor(type), semanticLabel: iconLabel, dangerouslySetColor: iconColor);

          final headerSlot = item.headerWidget ?? (item.header != null ? Text(item.header!) : null);
          final contentSlot = item.contentWidget ?? (item.content != null ? Text(item.content!) : null);

          final message = Padding(
            padding: textPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: CsFontTokens.lineHeightBodyM,
                  child: Center(child: icon),
                ),
                const SizedBox(width: CsSpace.xxs * 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (headerSlot != null)
                          DefaultTextStyle(
                            style: textStyle.copyWith(fontWeight: CsFontTokens.fontWeightFlashbarHeader),
                            child: Semantics(header: true, child: headerSlot),
                          ),
                        ?contentSlot,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final action =
              item.action ??
              (item.buttonText != null ? CsButton(text: item.buttonText, onPress: item.onButtonPress) : null);

          Widget body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CsMessageActionLayout(
                  gap: CsSpace.flashbarActionLeft,
                  wrappedIndent: CsSpace.l + CsSpace.xxs,
                  wrappedBottom: CsSpace.xxs,
                  message: Semantics(container: true, explicitChildNodes: true, child: message),
                  action: action == null
                      ? null
                      : Padding(
                          padding: EdgeInsets.symmetric(vertical: cs.space.scaledXxs),
                          child: action,
                        ),
                ),
              ),
              if (item.dismissible)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.s, end: CsSpace.flashbarDismissRight),
                  child: Transform.translate(
                    offset: Offset(CsSpace.xxs * (Directionality.of(context) == TextDirection.rtl ? -1 : 1), 0),
                    child: CsButton(
                      variant: CsButtonVariant.flashbarIcon,
                      icon: CsIcons.close,
                      semanticLabel: item.dismissLabel ?? strings.dismiss,
                      onPress: item.onDismiss,
                    ),
                  ),
                ),
            ],
          );
          if (contentOpacity < 1) {
            body = Opacity(opacity: contentOpacity.clamp(0.0, 1.0), child: body);
          }

          return Container(
            padding: EdgeInsets.symmetric(vertical: cs.space.flashbarVertical, horizontal: CsSpace.flashbarHorizontal),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(CsBorderRadius.flashbar),
              border: CsBorderWidth.flashbarInlineStart > 0
                  ? BorderDirectional(
                      start: BorderSide(color: border, width: CsBorderWidth.flashbarInlineStart),
                    )
                  : null,
              boxShadow: cs.shadows.flashSticky,
            ),
            child: DefaultTextStyle(style: textStyle, child: body),
          );
        },
      ),
    );
    // Cloudscape underlines links inside flash messages.
    return CsLinkDefaults(variant: CsLinkVariant.primary, child: flash);
  }

  static CsIconData _iconFor(CsFlashbarType type) => switch (type) {
    CsFlashbarType.success => CsIcons.statusPositive,
    CsFlashbarType.error => CsIcons.statusNegative,
    CsFlashbarType.warning => CsIcons.statusWarning,
    CsFlashbarType.info => CsIcons.statusInfo,
    CsFlashbarType.inProgress => CsIcons.statusInProgress,
  };
}

/// Enter: fade in while sliding 20px down, 250ms expressive. Exit: fade out
/// while sliding 20px up, 115ms, then the space closes.
class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({
    super.key,
    required this.exiting,
    required this.animateIn,
    required this.onExited,
    required this.child,
  });

  final bool exiting;
  final bool animateIn;
  final VoidCallback onExited;
  final Widget child;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> with TickerProviderStateMixin {
  late final AnimationController _appear;
  late final AnimationController _size;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(vsync: this, duration: CsDurations.complex, value: widget.animateIn ? 0 : 1);
    _size = AnimationController(vsync: this, duration: CsDurations.responsive, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animateIn && _appear.value == 0 && !_appear.isAnimating && !widget.exiting) {
      if (CsMotion.reduceMotion(context)) {
        _appear.value = 1;
      } else {
        // constant.ts: entering waits for a concurrent exit (115ms) to finish.
        _appear.animateTo(1, duration: CsDurations.complex, curve: CsCurves.expressive);
      }
    }
    if (widget.exiting) _exit();
  }

  @override
  void didUpdateWidget(_AnimatedEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) _exit();
    if (!widget.exiting && oldWidget.exiting) {
      _size.value = 1;
      _appear.animateTo(1, duration: CsMotion.duration(context, CsDurations.responsive));
    }
  }

  Future<void> _exit() async {
    if (CsMotion.reduceMotion(context)) {
      _appear.value = 0;
      _size.value = 0;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.exiting) widget.onExited();
      });
      return;
    }
    await _appear
        .animateBack(0, duration: CsDurations.responsive, curve: CsCurves.expressive)
        .orCancel
        .catchError((_) {});
    if (!mounted || !widget.exiting) return;
    await _size.animateBack(0, curve: CsCurves.responsive).orCancel.catchError((_) {});
    if (mounted && widget.exiting) widget.onExited();
  }

  @override
  void dispose() {
    _appear.dispose();
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CsSizeReveal(
      sizeFactor: _size,
      child: AnimatedBuilder(
        animation: _appear,
        child: widget.child,
        builder: (context, child) {
          final v = _appear.value;
          if (v >= 1) return child!;
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, -20 * (1 - v)), child: child),
          );
        },
      ),
    );
  }
}

class _NotificationBar extends StatelessWidget {
  const _NotificationBar({
    required this.expanded,
    required this.counts,
    required this.i18nStrings,
    required this.onToggle,
  });

  final bool expanded;
  final Map<CsFlashbarType, int> counts;
  final CsFlashbarI18nStrings i18nStrings;
  final VoidCallback onToggle;

  // utils.ts `counterTypes`: the order counts appear in.
  static const _order = [
    CsFlashbarType.error,
    CsFlashbarType.warning,
    CsFlashbarType.success,
    CsFlashbarType.info,
    CsFlashbarType.inProgress,
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.csStrings;
    final summary = [
      i18nStrings.notificationBarText,
      for (final t in _order) '${i18nStrings.iconLabel(t, strings)} ${counts[t]}',
    ].join(', ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CsPressable(
          onPress: onToggle,
          expanded: expanded,
          semanticLabel: i18nStrings.notificationBarAriaLabel,
          semanticValue: summary,
          excludeChildSemantics: true,
          borderRadius: BorderRadius.circular(CsBorderRadius.button),
          focusRingColor: CsColor.borderNotificationStackBarFocused,
          builder: (context, state) {
            final cs = context.cs;
            final c = cs.colors;
            final bg = state.pressed
                ? c.backgroundNotificationStackBarActive
                : state.hovered
                ? c.backgroundNotificationStackBarHover
                : c.backgroundNotificationStackBar;
            final border = state.pressed
                ? c.borderNotificationStackBarActive
                : state.hovered
                ? c.borderNotificationStackBarHover
                : c.borderNotificationStackBar;
            final style = cs.text(CsTypeScale.bodyM).copyWith(color: c.textNotificationStackBar);
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: CsSpace.l,
                vertical: cs.space.buttonVertical + CsBorderWidth.notificationStackBar,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(CsBorderRadius.button),
                boxShadow: cs.shadows.panelToggle,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CsBorderRadius.button),
                border: CsRing.inside(border, width: CsBorderWidth.notificationStackBar),
              ),
              child: DefaultTextStyle(
                style: style,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: CsSpace.m + CsSpace.xxs,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: CsSpace.m,
                      children: [
                        if (i18nStrings.notificationBarText.isNotEmpty)
                          Text(
                            i18nStrings.notificationBarText,
                            style: style.copyWith(fontWeight: CsFontTokens.fontWeightButton),
                          ),
                        Wrap(
                          spacing: CsSpace.s,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final t in _order)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CsIcon(_Flash._iconFor(t), dangerouslySetColor: c.textNotificationStackBar),
                                  const SizedBox(width: CsSpace.xxs),
                                  Text('${counts[t]}'),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: CsMotion.duration(context, CsDurations.rotate90),
                      curve: CsCurves.rotate90,
                      child: CsIcon(CsIcons.angleDown, dangerouslySetColor: c.textNotificationStackBar),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        CsLiveRegion(hidden: true, preventInitialAnnouncement: true, message: summary),
      ],
    );
  }
}

/// Lays out a stacked flashbar between its collapsed (t = 0) and expanded
/// (t = 1) geometry. The last child is the notification bar.
class _FlashStack extends MultiChildRenderObjectWidget {
  const _FlashStack({
    required this.t,
    required this.slots,
    required this.depth,
    required this.placeholderHeight,
    required this.collapsedOverlap,
    required this.expandedOverlap,
    required super.children,
  });

  final double t;
  final List<int?> slots;
  final int depth;
  final double placeholderHeight;
  final double collapsedOverlap;
  final double expandedOverlap;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFlashStack()
    ..t = t
    ..slots = slots
    ..stackDepth = depth
    ..placeholderHeight = placeholderHeight
    ..collapsedOverlap = collapsedOverlap
    ..expandedOverlap = expandedOverlap;

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderFlashStack)
      ..t = t
      ..slots = slots
      ..stackDepth = depth
      ..placeholderHeight = placeholderHeight
      ..collapsedOverlap = collapsedOverlap
      ..expandedOverlap = expandedOverlap
      ..markNeedsLayout();
  }
}

class _StackParentData extends ContainerBoxParentData<RenderBox> {
  Rect clip = Rect.zero;
  double opacity = 1;
}

class _RenderFlashStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StackParentData> {
  double t = 0;
  List<int?> slots = const [];
  int stackDepth = 1;
  double placeholderHeight = 46;
  double collapsedOverlap = 27;
  double expandedOverlap = 12;

  // collapsible.scss: each stacked item is inset 10px per side per level and
  // peeks 8px below the one above; the bar keeps 30px from each edge.
  static const double _inset = 10;
  static const double _peek = 8;
  static const double _barMargin = 30;
  static const double _gap = CsSpace.xxxs;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StackParentData) child.parentData = _StackParentData();
  }

  List<RenderBox> get _items {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null && child != lastChild) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => lastChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(Size(constraints.maxWidth, 0));

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final items = _items;
    final bar = lastChild!;
    final expandedTops = <double>[];

    // Natural height of every item at full width, for the expanded layout.
    // Items are laid out (not measured intrinsically) so any content works.
    final natural = <double>[];
    for (final item in items) {
      item.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      natural.add(item.size.height);
    }
    var y = 0.0;
    for (var i = 0; i < items.length; i++) {
      expandedTops.add(y);
      y += natural[i] + (i == items.length - 1 ? 0 : _gap);
    }
    final listBottom = y;

    var topIndex = slots.indexOf(0);
    if (topIndex < 0) topIndex = 0;
    final h0 = natural.isEmpty ? 0.0 : natural[topIndex];
    final lastSlot = math.max(0, stackDepth - 1);
    final stackBottom = h0 + _peek * lastSlot;

    for (var i = 0; i < items.length; i++) {
      final slot = slots[i];
      final c = slot ?? lastSlot;
      final inset = lerpDouble(c * _inset, 0, t)!;
      final itemWidth = math.max(0.0, width - inset * 2);
      final item = items[i];
      if (itemWidth != width) item.layout(BoxConstraints.tightFor(width: itemWidth), parentUsesSize: true);
      final h = item.size.height;
      final cHeight = c == 0 ? h0 : math.min(h, placeholderHeight);
      final cBottom = h0 + _peek * c;
      final cTop = math.max(0.0, cBottom - cHeight);
      final top = lerpDouble(cTop, expandedTops[i], t)!;
      final visible = lerpDouble(cHeight, h, t)!;
      final data = item.parentData! as _StackParentData;
      data.offset = Offset(inset, top);
      data.clip = Rect.fromLTWH(0, 0, itemWidth, visible);
      data.opacity = slot == null ? t : 1;
    }

    bar.layout(BoxConstraints(maxWidth: math.max(0.0, width - _barMargin * 2)), parentUsesSize: true);
    final barTop = lerpDouble(stackBottom - collapsedOverlap, listBottom - expandedOverlap, t)!;
    (bar.parentData! as _StackParentData).offset = Offset((width - bar.size.width) / 2, math.max(0, barTop));
    size = constraints.constrain(Size(width, math.max(0, barTop) + bar.size.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final items = _items;
    // Older messages sit under newer ones while stacked.
    for (var i = items.length - 1; i >= 0; i--) {
      final item = items[i];
      final data = item.parentData! as _StackParentData;
      if (data.opacity <= 0) continue;
      final origin = offset + data.offset;
      final rrect = RRect.fromRectAndRadius(data.clip.shift(origin), const Radius.circular(CsBorderRadius.flashbar));
      void paintItem(PaintingContext ctx, Offset o) {
        ctx.pushClipRRect(needsCompositing, o, data.clip, rrect.shift(-o), (c, p) => c.paintChild(item, p));
      }

      if (data.opacity < 1) {
        context.pushOpacity(origin, (data.opacity * 255).round(), (c, p) => paintItem(c, p));
      } else {
        paintItem(context, origin);
      }
    }
    final bar = lastChild!;
    context.paintChild(bar, offset + (bar.parentData! as _StackParentData).offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final bar = lastChild!;
    final barData = bar.parentData! as _StackParentData;
    final hitBar = result.addWithPaintOffset(
      offset: barData.offset,
      position: position,
      hitTest: (r, p) => bar.hitTest(r, position: p),
    );
    if (hitBar) return true;
    for (final item in _items) {
      final data = item.parentData! as _StackParentData;
      if (data.opacity <= 0) continue;
      final local = position - data.offset;
      if (!data.clip.contains(local)) continue;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (r, p) => item.hitTest(r, position: p),
      );
      if (hit) return true;
    }
    return false;
  }
}
