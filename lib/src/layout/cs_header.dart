import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Heading levels (Cloudscape `variant`).
enum CsHeaderVariant {
  /// Page title: heading-xl (24/30).
  h1(CsTypeScale.headingXl, 1),

  /// Container or section title: heading-l (20/24).
  h2(CsTypeScale.headingL, 2),

  /// Smaller section title: heading-m (18/22).
  h3(CsTypeScale.headingM, 3),

  /// A page title for full-page tables and cards: h1 size, shrinking to h2
  /// size while the header is stuck to the top (see [CsHeaderStickyScope]).
  awsuiH1Sticky(CsTypeScale.headingXl, 1);

  const CsHeaderVariant(this.scale, this.level);

  /// Type scale of the title.
  final CsTypeScale scale;

  /// Default heading level announced to assistive technology.
  final int level;
}

/// Tells [CsHeader]s with [CsHeaderVariant.awsuiH1Sticky] below it whether
/// their sticky container is currently stuck. Tables and cards with a sticky
/// header set this; while stuck the title shrinks to h2 size, the
/// description hides and the vertical padding tightens, like Cloudscape.
class CsHeaderStickyScope extends InheritedWidget {
  const CsHeaderStickyScope({super.key, required this.stuck, required super.child});

  final bool stuck;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CsHeaderStickyScope>()?.stuck ?? false;

  @override
  bool updateShouldNotify(CsHeaderStickyScope oldWidget) => oldWidget.stuck != stuck;
}

/// Cloudscape's `Header`: the title of a page, container or section, with an
/// optional counter, info link, description, secondary content and actions.
///
/// ```dart
/// CsHeader(
///   variant: CsHeaderVariant.h1,
///   title: 'Instances',
///   counter: '(12)',
///   info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
///   description: 'Virtual servers in the cloud.',
///   actions: CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: () {}),
/// )
/// ```
///
/// The title and actions share a row when both fit at their natural width
/// and the actions wrap under the title otherwise (CSS `flex-wrap`, the way
/// Cloudscape lays them out). In visual refresh the title is centered on the
/// 32px row of buttons.
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
    this.secondaryContent,
    this.headingTagOverride,
  }) : assert(title != null || titleWidget != null, 'Pass title or titleWidget'),
       assert(headingTagOverride == null || (headingTagOverride >= 1 && headingTagOverride <= 6));

  /// The heading text (Cloudscape `children`).
  final String? title;

  /// Custom heading content in place of [title].
  final Widget? titleWidget;
  final CsHeaderVariant variant;

  /// A count after the title, such as "(12)" or "(2/12)", in
  /// `color-text-counter` and normal weight.
  final String? counter;

  /// An info link, usually `CsLink(variant: CsLinkVariant.info)`.
  final Widget? info;

  /// Supporting text under the title in `color-text-heading-secondary`.
  final String? description;
  final Widget? descriptionWidget;

  /// Buttons for the page or container, at the end of the title row.
  final Widget? actions;

  /// Content between the title and the actions, such as a status indicator
  /// or a segmented control (Cloudscape `secondaryContent`).
  final Widget? secondaryContent;

  /// Heading level announced to screen readers when it should differ from
  /// the visual [variant] (Cloudscape `headingTagOverride`), 1 to 6.
  final int? headingTagOverride;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final stuck = variant == CsHeaderVariant.awsuiH1Sticky && CsHeaderStickyScope.of(context);
    final scale = stuck ? CsTypeScale.headingL : variant.scale;
    final titleStyle = cs.text(scale);
    final inputHeight = cs.space.sizeVerticalInput;
    // `space-heading-button-diff`: center the heading line on the 32px buttons.
    final titlePad = math.max(0.0, (inputHeight - scale.lineHeight) / 2);

    final heading = Semantics(
      header: true,
      headingLevel: headingTagOverride ?? variant.level,
      child: DefaultTextStyle(
        style: titleStyle,
        child: Text.rich(
          TextSpan(
            children: [
              if (titleWidget != null)
                WidgetSpan(child: titleWidget!, alignment: PlaceholderAlignment.middle)
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
    );

    final titleRow = Padding(
      padding: EdgeInsets.only(top: actions != null || secondaryContent != null ? titlePad : 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CsSpace.xs,
        runSpacing: CsSpace.xxs,
        children: [heading, ?info],
      ),
    );

    Widget top = titleRow;
    final trailing = <Widget>[];
    if (secondaryContent != null) {
      trailing.add(
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: inputHeight),
          child: Align(alignment: AlignmentDirectional.centerStart, widthFactor: 1, child: secondaryContent),
        ),
      );
    }
    if (actions != null) {
      trailing.add(
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: inputHeight),
          child: Align(alignment: AlignmentDirectional.topEnd, widthFactor: 1, heightFactor: 1, child: actions),
        ),
      );
    }
    if (trailing.isNotEmpty) {
      top = _CsFlexWrapRow(
        gap: CsSpace.xs,
        runGap: CsSpace.xxs,
        children: [
          titleRow,
          if (trailing.length == 1)
            trailing.first
          else
            _CsFlexWrapRow(gap: CsSpace.xs, runGap: CsSpace.xxs, children: trailing),
        ],
      );
    }

    final desc =
        descriptionWidget ??
        (description == null
            ? null
            : Text(description!, style: cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingSecondary)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        top,
        if (desc != null && !stuck) ...[
          SizedBox(height: variant == CsHeaderVariant.h1 ? cs.space.scaled2xXxs : CsSpace.xxxs),
          DefaultTextStyle.merge(
            style: cs.text(CsTypeScale.bodyM, color: CsColor.textHeadingSecondary),
            child: desc,
          ),
        ],
      ],
    );
  }
}

/// Two children on one row when both fit at their natural widths, the second
/// pushed to the end; otherwise the second wraps onto its own line. This is
/// CSS `display: flex; flex-wrap: wrap; justify-content: space-between`.
class _CsFlexWrapRow extends MultiChildRenderObjectWidget {
  const _CsFlexWrapRow({required this.gap, required this.runGap, required super.children})
    : assert(children.length == 2);

  final double gap;
  final double runGap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFlexWrapRow(gap: gap, runGap: runGap, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderFlexWrapRow renderObject) {
    renderObject
      ..gap = gap
      ..runGap = runGap
      ..textDirection = Directionality.of(context);
  }
}

class _FlexWrapParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFlexWrapRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FlexWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FlexWrapParentData> {
  _RenderFlexWrapRow({required double gap, required double runGap, required TextDirection textDirection})
    : _gap = gap,
      _runGap = runGap,
      _textDirection = textDirection;

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FlexWrapParentData) child.parentData = _FlexWrapParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(firstChild!.getMinIntrinsicWidth(height), lastChild!.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild!.getMaxIntrinsicWidth(height) + _gap + lastChild!.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final first = firstChild!;
    final second = lastChild!;
    final maxW = constraints.maxWidth;
    final rtl = _textDirection == TextDirection.rtl;
    Size measure(RenderBox child, BoxConstraints c) {
      if (dry) return child.getDryLayout(c);
      child.layout(c, parentUsesSize: true);
      return child.size;
    }

    final b0 = measure(second, BoxConstraints(maxWidth: maxW));
    final titleMax = first.getMaxIntrinsicWidth(double.infinity);
    if (maxW.isFinite && titleMax + _gap + b0.width > maxW) {
      final a = measure(first, BoxConstraints(maxWidth: maxW));
      if (!dry) {
        (first.parentData! as _FlexWrapParentData).offset = Offset(rtl ? maxW - a.width : 0, 0);
        (second.parentData! as _FlexWrapParentData).offset = Offset(rtl ? maxW - b0.width : 0, a.height + _runGap);
      }
      return constraints.constrain(Size(maxW, a.height + _runGap + b0.height));
    }
    final aMax = maxW.isFinite ? math.max(0.0, maxW - b0.width - _gap) : double.infinity;
    final a = measure(first, BoxConstraints(maxWidth: aMax));
    final width = maxW.isFinite ? maxW : a.width + _gap + b0.width;
    final height = math.max(a.height, b0.height);
    if (!dry) {
      (first.parentData! as _FlexWrapParentData).offset = Offset(rtl ? width - a.width : 0, 0);
      (second.parentData! as _FlexWrapParentData).offset = Offset(rtl ? 0 : width - b0.width, 0);
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
