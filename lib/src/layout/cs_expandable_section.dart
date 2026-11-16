import 'package:flutter/widgets.dart';

import '../icons/icons.dart';
import '../system/cs_pressable.dart';
import '../system/cs_size_reveal.dart';
import '../theme/theme.dart';
import 'cs_container.dart';
import 'cs_header.dart';

/// Expandable section styles (Cloudscape `variant`).
enum CsExpandableSectionVariant {
  /// A caret and a 16px bold title over the content, with a divider under
  /// the header while expanded.
  defaultVariant,

  /// Like [defaultVariant] without the divider, for "Additional settings"
  /// at the end of a form or container.
  footer,

  /// A container whose header expands and collapses its content. Takes
  /// [CsExpandableSection.headerCounter], `headerDescription`, `headerInfo`
  /// and `headerActions`.
  container,

  /// Like [container], for sections stacked one under another; set
  /// [CsExpandableSection.stackPosition].
  stacked,

  /// Only the caret toggles; the title stays plain text. Used in side
  /// navigation for groups of links.
  navigation,

  /// Like [defaultVariant] without the expanded divider or content
  /// padding, for use inside other text.
  inline,
}

/// Cloudscape's `ExpandableSection`: a header that shows and hides its
/// content.
///
/// ```dart
/// CsExpandableSection(
///   headerText: 'Additional settings',
///   child: const CsBox(text: 'Instance metadata options'),
/// )
/// ```
///
/// Uncontrolled by default ([defaultExpanded]); pass [expanded] and
/// [onChange] to control it. The content reveals with Cloudscape's
/// `motion-duration-expandable-content-enter` (180ms) and fades in a third
/// of the way through; the caret turns with `motion-duration-rotate-90`.
/// Under reduced motion it snaps.
class CsExpandableSection extends StatefulWidget {
  const CsExpandableSection({
    super.key,
    this.child,
    this.headerText,
    this.header,
    this.variant = CsExpandableSectionVariant.defaultVariant,
    this.expanded,
    this.defaultExpanded = false,
    this.onChange,
    this.headerCounter,
    this.headerDescription,
    this.headerInfo,
    this.headerActions,
    this.headerSecondaryContent,
    this.headingTagOverride,
    this.headerAriaLabel,
    this.hideHeaderText = false,
    this.disableContentPaddings = false,
    this.stackPosition = CsStackPosition.only,
  }) : assert(headerText != null || header != null || headerAriaLabel != null, 'Pass headerText or header');

  /// The content shown while expanded (Cloudscape `children`).
  final Widget? child;

  /// The header title.
  final String? headerText;

  /// Custom header content in place of [headerText] (Cloudscape `header`,
  /// deprecated there but useful for rich titles).
  final Widget? header;
  final CsExpandableSectionVariant variant;

  /// Controlled expanded state. Null makes the section manage it, starting
  /// at [defaultExpanded].
  final bool? expanded;
  final bool defaultExpanded;

  /// Called with the next expanded state.
  final ValueChanged<bool>? onChange;

  /// "(12)" after the title. Container and stacked variants only.
  final String? headerCounter;

  /// Text under the title. Container, stacked and default variants.
  final String? headerDescription;

  /// An info link after the title. Container and stacked variants only.
  final Widget? headerInfo;

  /// Buttons at the end of the header. Container and stacked variants only;
  /// pressing them does not toggle the section.
  final Widget? headerActions;

  /// Content between the title and the actions.
  final Widget? headerSecondaryContent;

  /// Heading level announced for the title, 1 to 5.
  final int? headingTagOverride;

  /// Label for the toggle when the visible title is not enough.
  final String? headerAriaLabel;

  /// Hides the title visually and keeps it for screen readers. Needs
  /// [headerAriaLabel] or [headerText].
  final bool hideHeaderText;
  final bool disableContentPaddings;

  /// Position in a stack of [CsExpandableSectionVariant.stacked] sections.
  final CsStackPosition stackPosition;

  @override
  State<CsExpandableSection> createState() => _CsExpandableSectionState();
}

class _CsExpandableSectionState extends State<CsExpandableSection> with TickerProviderStateMixin {
  late bool _open;
  late final AnimationController _reveal;
  late final AnimationController _caret;

  bool get _expanded => widget.expanded ?? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.defaultExpanded;
    _reveal = AnimationController(
      vsync: this,
      duration: CsDurations.expandableContentEnter,
      reverseDuration: CsDurations.showQuick,
      value: _expanded ? 1 : 0,
    )..addStatusListener((_) => setState(() {}));
    _caret = AnimationController(vsync: this, duration: CsDurations.rotate90, value: _expanded ? 1 : 0);
  }

  @override
  void didUpdateWidget(CsExpandableSection old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final target = _expanded ? 1.0 : 0.0;
    if (CsMotion.reduceMotion(context)) {
      _reveal.value = target;
      _caret.value = target;
      return;
    }
    if (_reveal.value != target) target == 1 ? _reveal.forward() : _reveal.reverse();
    if (_caret.value != target) target == 1 ? _caret.forward() : _caret.reverse();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _caret.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onChange?.call(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
    _sync();
  }

  bool get _isContainer =>
      widget.variant == CsExpandableSectionVariant.container || widget.variant == CsExpandableSectionVariant.stacked;

  Widget _caretIcon(BuildContext context, {required bool medium, Color? color}) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _caret,
      builder: (context, child) {
        final t = CsCurves.rotate90.transform(_caret.value);
        // Collapsed carets point to the end of the line: -90deg in LTR.
        final turns = (1 - t) * (rtl ? 0.25 : -0.25);
        return Transform.rotate(angle: turns * 2 * 3.141592653589793, child: child);
      },
      child: CsIcon(
        CsIcons.caretDownFilled,
        size: medium ? CsIconSize.medium : CsIconSize.normal,
        dangerouslySetColor: color,
      ),
    );
  }

  Widget _title(BuildContext context, TextStyle style) {
    final cs = context.cs;
    Widget t = widget.header ?? Text(widget.headerText ?? '', style: style);
    if (widget.hideHeaderText) t = const SizedBox.shrink();
    return Semantics(
      header: true,
      headingLevel: widget.headingTagOverride ?? (_isContainer ? 2 : 3),
      child: DefaultTextStyle.merge(
        style: style,
        child: widget.headerCounter == null
            ? t
            : Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(child: t, alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic),
                    TextSpan(
                      text: ' ${widget.headerCounter}',
                      style: TextStyle(color: cs.colors.textCounter, fontWeight: CsTypography.normal),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String get _label => widget.headerAriaLabel ?? widget.headerText ?? '';

  Widget _buildHeader(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final variant = widget.variant;

    if (_isContainer) {
      final title = CsPressable(
        onPress: _toggle,
        expanded: _expanded,
        semanticLabel: _label,
        excludeChildSemantics: widget.headerAriaLabel != null,
        scaleOnPress: false,
        borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: cs.space.expandableSectionIconOffsetTop, end: CsSpace.xs),
              child: _caretIcon(context, medium: true, color: c.textHeadingDefault),
            ),
            Flexible(child: _title(context, cs.text(CsTypeScale.headingL))),
          ],
        ),
      );
      return Padding(
        padding: EdgeInsets.only(
          top: CsSpace.containerHeaderTop,
          bottom: _expanded ? cs.space.containerHeaderBottom : CsSpace.containerHeaderTop,
          left: CsSpace.containerHorizontal,
          right: CsSpace.containerHorizontal,
        ),
        child: CsHeader(
          titleWidget: title,
          info: widget.headerInfo,
          description: widget.headerDescription,
          actions: widget.headerActions,
          secondaryContent: widget.headerSecondaryContent,
        ),
      );
    }

    final textStyle = cs
        .text(CsTypeScale.headingS, color: CsColor.textExpandableSectionDefault)
        .copyWith(fontSize: CsFontTokens.fontSizeExpandableHeading);

    if (variant == CsExpandableSectionVariant.navigation) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CsPressable(
            onPress: _toggle,
            expanded: _expanded,
            semanticLabel: _label,
            excludeChildSemantics: true,
            scaleOnPress: false,
            borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
            builder: (context, state) => Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs),
              child: _caretIcon(
                context,
                medium: false,
                color: state.active ? c.textExpandableSectionHover : c.textExpandableSectionNavigationIconDefault,
              ),
            ),
          ),
          Expanded(child: _title(context, textStyle)),
        ],
      );
    }

    final dividerVisible = _expanded && (variant == CsExpandableSectionVariant.defaultVariant);
    return CsPressable(
      onPress: _toggle,
      expanded: _expanded,
      semanticLabel: widget.headerAriaLabel,
      excludeChildSemantics: widget.headerAriaLabel != null,
      scaleOnPress: false,
      builder: (context, state) => AnimatedContainer(
        duration: CsMotion.duration(
          context,
          dividerVisible ? CsDurations.expandableContentEnter : CsDurations.showQuick,
        ),
        curve: CsCurves.expandableContentEnter,
        padding: EdgeInsetsDirectional.only(
          top: variant == CsExpandableSectionVariant.inline ? 0 : cs.space.scaledXxs,
          bottom: variant == CsExpandableSectionVariant.inline ? 0 : cs.space.scaledXxs,
          end: variant == CsExpandableSectionVariant.defaultVariant ? CsSpace.xxs : 0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: dividerVisible ? c.borderExpandableSectionDefault : c.borderExpandableSectionDefault.withAlpha(0),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `$icon-margin-right-normal`: 4px plus the 1px list border.
            Padding(
              padding: const EdgeInsetsDirectional.only(end: CsSpace.xxs + 1),
              child: _caretIcon(
                context,
                medium: false,
                color: state.active ? c.textExpandableSectionHover : c.textExpandableSectionDefault,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(color: state.active ? c.textExpandableSectionHover : null),
                    child: _title(
                      context,
                      textStyle.copyWith(color: state.active ? c.textExpandableSectionHover : null),
                    ),
                  ),
                  if (widget.headerDescription != null)
                    Text(
                      widget.headerDescription!,
                      style: cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  EdgeInsetsGeometry _contentPadding(BuildContext context) {
    if (widget.disableContentPaddings) return EdgeInsets.zero;
    final cs = context.cs;
    return switch (widget.variant) {
      CsExpandableSectionVariant.container || CsExpandableSectionVariant.stacked => EdgeInsets.only(
        top: CsSpace.containerContentTop,
        bottom: cs.space.scaledL,
        left: CsSpace.containerHorizontal,
        right: CsSpace.containerHorizontal,
      ),
      CsExpandableSectionVariant.footer => const EdgeInsets.symmetric(vertical: CsSpace.xs),
      CsExpandableSectionVariant.navigation => EdgeInsets.zero,
      CsExpandableSectionVariant.defaultVariant ||
      CsExpandableSectionVariant.inline => EdgeInsets.symmetric(vertical: cs.space.scaledXs),
    };
  }

  @override
  Widget build(BuildContext context) {
    final showContent = _expanded || _reveal.status != AnimationStatus.dismissed;
    Widget? content;
    if (showContent && widget.child != null) {
      final inner = Padding(
        padding: _contentPadding(context),
        child: DefaultTextStyle.merge(style: context.cs.body, child: widget.child!),
      );
      if (CsMotion.reduceMotion(context)) {
        content = inner;
      } else {
        // Enter: size grows over 180ms; fade and the 4px slide start a third
        // of the way in (`$reveal-enter-delay`). Exit: all together, 135ms.
        final size = CurvedAnimation(parent: _reveal, curve: CsCurves.expandableContentEnter);
        final fade = CurvedAnimation(
          parent: _reveal,
          curve: const Interval(1 / 3, 1, curve: CsCurves.expandableContentEnter),
          reverseCurve: CsCurves.expandableContentEnter,
        );
        content = CsSizeReveal(
          sizeFactor: size,
          child: AnimatedBuilder(
            animation: fade,
            builder: (context, child) => Opacity(
              opacity: fade.value,
              child: Transform.translate(offset: Offset(0, -4 * (1 - fade.value)), child: child),
            ),
            child: inner,
          ),
        );
      }
    }

    final header = _buildHeader(context);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, ?content],
    );

    if (_isContainer) {
      return CsContainer(
        variant: widget.variant == CsExpandableSectionVariant.stacked
            ? CsContainerVariant.stacked
            : CsContainerVariant.defaultVariant,
        stackPosition: widget.stackPosition,
        disableHeaderPaddings: true,
        disableContentPaddings: true,
        child: body,
      );
    }
    return body;
  }
}
