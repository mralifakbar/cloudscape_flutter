import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// One entry of [CsAnchorNavigation] (Cloudscape `AnchorNavigationProps.Anchor`).
@immutable
class CsAnchorNavigationAnchor {
  const CsAnchorNavigationAnchor({required this.text, required this.href, this.level = 1, this.info});

  /// The link text.
  final String text;

  /// Identifies the section, such as `'#pricing'`. Pair it with a key in
  /// [CsAnchorScrollSpy.sections].
  final String href;

  /// Nesting level, starting at 1. Each level indents the text 16px.
  final int level;

  /// A short tag after the text, such as "New" or "Updated".
  final String? info;

  @override
  bool operator ==(Object other) =>
      other is CsAnchorNavigationAnchor &&
      other.text == text &&
      other.href == href &&
      other.level == level &&
      other.info == info;

  @override
  int get hashCode => Object.hash(text, href, level, info);

  @override
  String toString() => 'CsAnchorNavigationAnchor($href)';
}

/// Tracks which section of a scroll view is in view, for
/// [CsAnchorNavigation]: Cloudscape's scroll spy for a [ScrollController].
///
/// Give every section a [GlobalKey] and map its anchor href to the key. The
/// active href follows Cloudscape's rules: at the bottom of the scroll view
/// the last section is active; otherwise the first section that is fully
/// below [offset] and above the bottom of the viewport; otherwise (once
/// scrolled) the last section whose bottom is above the viewport bottom.
///
/// ```dart
/// final spy = CsAnchorScrollSpy(
///   controller: scrollController,
///   sections: {'#overview': overviewKey, '#pricing': pricingKey},
/// );
/// CsAnchorNavigation(anchors: anchors, scrollSpy: spy)
/// ```
///
/// Dispose it when done. It listens to [controller] and notifies when
/// [activeHref] changes; [scrollTo] brings a section to the top.
class CsAnchorScrollSpy extends ChangeNotifier {
  CsAnchorScrollSpy({required this.controller, required Map<String, GlobalKey> sections, this.offset = 0})
    : _sections = Map.of(sections) {
    controller.addListener(update);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) update();
    });
  }

  /// The scroll view the sections live in.
  final ScrollController controller;

  /// Height of anything covering the top of the viewport (a sticky header).
  /// Sections above it do not count as in view (`scrollSpyOffset`).
  final double offset;

  Map<String, GlobalKey> _sections;
  String? _activeHref;
  bool _disposed = false;

  /// The section in view, or null before any is.
  String? get activeHref => _activeHref;

  /// Section hrefs in page order.
  List<String> get hrefs => _sections.keys.toList(growable: false);

  /// Replaces the tracked sections (keep them in page order).
  set sections(Map<String, GlobalKey> value) {
    _sections = Map.of(value);
    update();
  }

  Rect? _rectOf(String href, RenderBox viewport) {
    final box = _sections[href]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: viewport);
    return topLeft & box.size;
  }

  /// Recomputes [activeHref] from the current scroll position.
  void update() {
    if (_disposed || !controller.hasClients || _sections.isEmpty) return;
    final position = controller.position;
    final viewport = position.context.notificationContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final height = viewport.size.height;
    final hrefs = this.hrefs;
    String? next;
    final atBottom =
        position.maxScrollExtent > 0 && position.pixels.ceilToDouble() >= position.maxScrollExtent.floorToDouble();
    if (atBottom && _rectOf(hrefs.last, viewport) != null) {
      next = hrefs.last;
    } else {
      for (final href in hrefs) {
        final r = _rectOf(href, viewport);
        if (r != null && r.bottom <= height && r.top >= offset) {
          next = href;
          break;
        }
      }
      if (next == null && position.pixels > 0) {
        for (final href in hrefs.reversed) {
          final r = _rectOf(href, viewport);
          if (r != null && r.bottom <= height) {
            next = href;
            break;
          }
        }
      }
    }
    if (next != _activeHref) {
      _activeHref = next;
      notifyListeners();
    }
  }

  /// Scrolls the section of [href] to the top of the viewport (below
  /// [offset]). Instant when [duration] is zero.
  Future<void> scrollTo(
    String href, {
    Duration duration = CsDurations.complex,
    Curve curve = CsCurves.easeOutQuart,
  }) async {
    final context = _sections[href]?.currentContext;
    if (context == null || !controller.hasClients) return;
    final box = context.findRenderObject();
    if (box is! RenderObject) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final target = viewport.getOffsetToReveal(box, 0).offset - offset;
    final position = controller.position;
    final clamped = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (duration == Duration.zero) {
      position.jumpTo(clamped);
    } else {
      await position.animateTo(clamped, duration: duration, curve: curve);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    controller.removeListener(update);
    super.dispose();
  }
}

/// Cloudscape's `AnchorNavigation`: a table of contents for a long page
/// that highlights the section in view.
///
/// ```dart
/// CsAnchorNavigation(
///   anchors: const [
///     CsAnchorNavigationAnchor(text: 'Overview', href: '#overview'),
///     CsAnchorNavigationAnchor(text: 'Pricing', href: '#pricing'),
///     CsAnchorNavigationAnchor(text: 'On-demand', href: '#on-demand', level: 2, info: 'Updated'),
///   ],
///   scrollSpy: spy,
/// )
/// ```
///
/// Pass [activeHref] to control the highlight yourself; leave it null and
/// pass a [scrollSpy] to follow the scroll position. Following an anchor
/// calls [onFollow] and, with a scroll spy and [scrollOnFollow], scrolls to
/// the section. [onActiveHrefChange] fires whenever the active anchor
/// changes, from scrolling or from [activeHref].
///
/// Anchors are a flat list in page order; [CsAnchorNavigationAnchor.level]
/// nests them. The accent bar of the active anchor also covers its nested
/// anchors, as in Cloudscape.
class CsAnchorNavigation extends StatefulWidget {
  const CsAnchorNavigation({
    super.key,
    required this.anchors,
    this.activeHref,
    this.scrollSpy,
    this.scrollOnFollow = true,
    this.onFollow,
    this.onActiveHrefChange,
    this.ariaLabel,
  });

  /// The anchors in page order.
  final List<CsAnchorNavigationAnchor> anchors;

  /// The active anchor. When set, the component is controlled and ignores
  /// [scrollSpy] for the highlight.
  final String? activeHref;

  /// Follows the scroll position when [activeHref] is null, and scrolls to a
  /// section on follow.
  final CsAnchorScrollSpy? scrollSpy;

  /// Scroll to the section through [scrollSpy] when an anchor is followed.
  final bool scrollOnFollow;

  /// Called when an anchor is followed (tap, Enter or Space).
  final ValueChanged<CsAnchorNavigationAnchor>? onFollow;

  /// Called when the active anchor changes.
  final ValueChanged<CsAnchorNavigationAnchor>? onActiveHrefChange;

  /// Accessible name of the list (Cloudscape `ariaLabelledby`). Defaults to
  /// `CsStrings.tableOfContents`.
  final String? ariaLabel;

  @override
  State<CsAnchorNavigation> createState() => _CsAnchorNavigationState();
}

class _CsAnchorNavigationState extends State<CsAnchorNavigation> {
  String? _lastReported;

  @override
  void initState() {
    super.initState();
    widget.scrollSpy?.addListener(_onSpy);
    _scheduleReport();
  }

  @override
  void didUpdateWidget(CsAnchorNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSpy != widget.scrollSpy) {
      oldWidget.scrollSpy?.removeListener(_onSpy);
      widget.scrollSpy?.addListener(_onSpy);
    }
    _scheduleReport();
  }

  @override
  void dispose() {
    widget.scrollSpy?.removeListener(_onSpy);
    super.dispose();
  }

  String? get _active => widget.activeHref ?? widget.scrollSpy?.activeHref;

  void _onSpy() {
    if (!mounted || widget.activeHref != null) return;
    setState(() {});
    _scheduleReport();
  }

  void _scheduleReport() {
    final active = _active;
    if (active == null || active == _lastReported) return;
    _lastReported = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final a in widget.anchors) {
        if (a.href == active) {
          widget.onActiveHrefChange?.call(a);
          return;
        }
      }
    });
  }

  void _follow(CsAnchorNavigationAnchor anchor) {
    widget.onFollow?.call(anchor);
    if (widget.scrollOnFollow && widget.scrollSpy != null) {
      widget.scrollSpy!.scrollTo(
        anchor.href,
        duration: CsMotion.reduceMotion(context) ? Duration.zero : CsDurations.complex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchors = widget.anchors;
    final active = _active;
    final activeIndex = active == null ? -1 : anchors.indexWhere((a) => a.href == active);
    var activeEnd = activeIndex;
    if (activeIndex >= 0) {
      while (activeEnd + 1 < anchors.length && anchors[activeEnd + 1].level > anchors[activeIndex].level) {
        activeEnd++;
      }
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabel ?? context.csStrings.tableOfContents,
      child: CustomPaint(
        painter: _GuidePainter(
          color: context.cs.colors.borderDividerDefault,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < anchors.length; i++)
              _AnchorRow(
                anchor: anchors[i],
                active: i == activeIndex,
                inActiveBranch: i >= activeIndex && i <= activeEnd && activeIndex >= 0,
                first: i == 0,
                last: i == anchors.length - 1,
                onFollow: () => _follow(anchors[i]),
              ),
          ],
        ),
      ),
    );
  }
}

// Cloudscape's $anchor-nav-inset-inline, $guide-line-width and
// $guide-line-offset (anchor-navigation/styles.scss).
const double _guideInset = 6;
const double _guideWidth = 2;
const double _guideOverhang = 2;

class _GuidePainter extends CustomPainter {
  const _GuidePainter({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final x = rtl ? size.width - _guideInset - _guideWidth : _guideInset;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, -_guideOverhang, _guideWidth, size.height + 2 * _guideOverhang),
        const Radius.circular(CsBorderRadius.tabsFocusRing),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.color != color || old.rtl != rtl;
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({
    required this.anchor,
    required this.active,
    required this.inActiveBranch,
    required this.first,
    required this.last,
    required this.onFollow,
  });

  final CsAnchorNavigationAnchor anchor;
  final bool active;
  final bool inActiveBranch;
  final bool first;
  final bool last;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final gap = cs.space.scaledXxs;
    final indent = anchor.level * 16.0 + 4;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          start: _guideInset,
          width: _guideWidth,
          top: first ? -_guideOverhang : 0,
          bottom: last ? -_guideOverhang : 0,
          child: AnimatedContainer(
            duration: CsMotion.duration(context, CsDurations.slow),
            decoration: BoxDecoration(
              color: inActiveBranch ? c.textAccent : c.textAccent.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(CsBorderRadius.tabsFocusRing),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: gap),
          child: CsPressable(
            onPress: onFollow,
            isLink: true,
            selected: active,
            scaleOnPress: false,
            minTapTargetSize: 0,
            focusRingOffset: 1,
            borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
            semanticLabel: anchor.info == null ? anchor.text : '${anchor.text}, ${anchor.info}',
            excludeChildSemantics: true,
            builder: (context, state) {
              final color = active || state.active ? c.textAccent : c.textBodySecondary;
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: cs.minTapTarget > 0 ? 36 : 0),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: indent),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 1,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: anchor.text),
                          if (anchor.info != null)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
                                child: Text(
                                  anchor.info!,
                                  style: cs.text(
                                    CsTypeScale.bodyS,
                                    weight: CsTypography.bold,
                                    color: CsColor.textLinkDefault,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      style: cs.body.copyWith(
                        color: color,
                        fontWeight: active ? CsTypography.bold : CsTypography.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
