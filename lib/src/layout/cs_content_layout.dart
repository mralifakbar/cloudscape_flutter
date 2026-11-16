import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'internal/cs_layout_insets.dart';

/// Header styles of a [CsContentLayout] (Cloudscape `headerVariant`).
enum CsContentLayoutHeaderVariant {
  /// The header on the page background.
  defaultVariant,

  /// A dark header band (`awsui-context-content-header`) that the first
  /// container overlaps. Always dark, also in light mode.
  highContrast,

  /// The header on the page background with a divider under it.
  divider,
}

/// Builds the header background from the current brightness (Cloudscape
/// `headerBackgroundStyle`, which takes a CSS background or a function of
/// the color mode).
typedef CsHeaderBackgroundBuilder = Decoration Function(Brightness brightness);

/// Cloudscape's `ContentLayout`: the page frame inside the app layout's
/// content area, with notifications, breadcrumbs, a page header and the
/// page content.
///
/// ```dart
/// CsContentLayout(
///   headerVariant: CsContentLayoutHeaderVariant.highContrast,
///   header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Distributions'),
///   child: const CsContainer(child: Text('d111111abcdef8')),
/// )
/// ```
///
/// The header area gets its own background ([headerVariant] high contrast
/// or [headerBackgroundStyle]); the content then overlaps the bottom of
/// that background by `space-dark-header-overlap-distance` (36px), unless
/// [disableOverlap]. Inside a `CsAppLayout` the background reaches the edges
/// of the content area.
class CsContentLayout extends StatelessWidget {
  const CsContentLayout({
    super.key,
    this.child,
    this.header,
    this.headerVariant = CsContentLayoutHeaderVariant.defaultVariant,
    this.headerBackgroundStyle,
    this.maxContentWidth,
    this.disableOverlap = false,
    this.secondaryHeader,
    this.breadcrumbs,
    this.notifications,
    this.defaultPadding = false,
  });

  /// The page content (Cloudscape `children`).
  final Widget? child;

  /// Usually a `CsHeader` with the h1 variant.
  final Widget? header;
  final CsContentLayoutHeaderVariant headerVariant;

  /// A custom header background, such as a gradient or an image.
  final CsHeaderBackgroundBuilder? headerBackgroundStyle;

  /// Caps and centers the header and content width.
  final double? maxContentWidth;

  /// Content starts under the header instead of overlapping its background.
  final bool disableOverlap;

  /// Content next to the header, such as a summary container. Sits at the
  /// end of the header on wide screens and under it at or below 688px.
  final Widget? secondaryHeader;

  /// Breadcrumbs above the header, for pages outside an app layout.
  final Widget? breadcrumbs;

  /// Flash messages above the header, for pages outside an app layout.
  final Widget? notifications;

  /// Adds the app layout's horizontal content padding and top gap, for
  /// pages that do not sit in a `CsAppLayout`.
  final bool defaultPadding;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final narrow = context.csIsNarrow;
    final highContrast = headerVariant == CsContentLayoutHeaderVariant.highContrast;
    final hasHeader = header != null || secondaryHeader != null;
    final hasBackground = highContrast || headerBackgroundStyle != null;
    final overlap = hasHeader && !disableOverlap && hasBackground ? cs.space.darkHeaderOverlapDistance : 0.0;
    final insets = CsLayoutContentInsets.maybeOf(context);
    final horizontal = defaultPadding
        ? (narrow ? CsSpace.l : cs.space.layoutContentHorizontal)
        : (insets?.horizontal ?? 0.0);
    final topGap = defaultPadding ? cs.space.scaledM : (insets?.top ?? 0.0);

    Widget constrain(Widget w) {
      final padded = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: w,
      );
      if (maxContentWidth == null) return padded;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth! + horizontal * 2),
          child: padded,
        ),
      );
    }

    Widget? headerRow;
    if (hasHeader) {
      Widget h = header ?? const SizedBox();
      if (secondaryHeader != null) {
        h = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: cs.space.gridGutter,
                children: [h, secondaryHeader!],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: cs.space.gridGutter,
                children: [
                  Expanded(flex: 2, child: h),
                  Expanded(child: secondaryHeader!),
                ],
              );
      }
      headerRow = Container(
        padding: EdgeInsets.only(bottom: cs.space.contentHeaderPaddingBottom),
        decoration: headerVariant == CsContentLayoutHeaderVariant.divider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.colors.borderDividerDefault)),
              )
            : null,
        child: h,
      );
    }

    final top = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topGap > 0) SizedBox(height: topGap),
        if (notifications != null)
          constrain(
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.xs),
              child: notifications,
            ),
          ),
        if (breadcrumbs != null)
          constrain(
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.xs),
              child: breadcrumbs,
            ),
          ),
        if (headerRow != null) constrain(headerRow),
        SizedBox(height: overlap),
      ],
    );

    Widget topArea = top;
    if (hasBackground) {
      final decoration =
          headerBackgroundStyle?.call(highContrast ? Brightness.dark : cs.brightness) ??
          BoxDecoration(color: cs.withVisualContext(CsVisualContextName.header).colors.backgroundLayoutMain);
      topArea = DecoratedBox(decoration: decoration, child: top);
    }
    if (highContrast) {
      topArea = CsVisualContext(context: CsVisualContextName.header, child: topArea);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        topArea,
        if (child != null)
          _CsOverlap(
            overlap: overlap,
            child: constrain(DefaultTextStyle.merge(style: cs.body, child: child!)),
          ),
      ],
    );
  }
}

/// Paints its child [overlap] pixels higher than its slot and takes that
/// much less height, so content overlaps the header background above it
/// (a negative top margin).
class _CsOverlap extends SingleChildRenderObjectWidget {
  const _CsOverlap({required this.overlap, super.child});

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOverlap(overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderOverlap renderObject) => renderObject.overlap = overlap;
}

class _RenderOverlap extends RenderShiftedBox {
  _RenderOverlap(this._overlap) : super(null);

  double _overlap;
  set overlap(double v) {
    if (v == _overlap) return;
    _overlap = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints.loosen().copyWith(minWidth: constraints.minWidth), parentUsesSize: true);
    (c.parentData! as BoxParentData).offset = Offset(0, -_overlap);
    size = constraints.constrain(Size(c.size.width, (c.size.height - _overlap).clamp(0, double.infinity)));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      ((child?.getMinIntrinsicHeight(width) ?? 0) - _overlap).clamp(0, double.infinity);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      ((child?.getMaxIntrinsicHeight(width) ?? 0) - _overlap).clamp(0, double.infinity);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
