import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'internal/cs_grid_render.dart';

/// Placement of one [CsGrid] child (Cloudscape `GridProps.ElementDefinition`).
///
/// Each field maps breakpoints to a number of the 12 columns. Use
/// [CsBreakpoint.base] for Cloudscape's `default` key. A breakpoint without a
/// value uses the nearest smaller one that has a value.
///
/// ```dart
/// const CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 6})
/// const CsGridDefinition.all(colspan: 4, offset: 2)
/// ```
@immutable
class CsGridDefinition {
  const CsGridDefinition({this.colspan, this.offset, this.push, this.pull})
    : _colspan = null,
      _offset = null,
      _push = null,
      _pull = null;

  /// The same values at every breakpoint.
  const CsGridDefinition.all({int colspan = 12, int offset = 0, int push = 0, int pull = 0})
    : colspan = const {},
      offset = const {},
      push = const {},
      pull = const {},
      _colspan = colspan,
      _offset = offset,
      _push = push,
      _pull = pull;

  /// Columns the element spans, 1 to 12. Defaults to 12.
  final Map<CsBreakpoint, int>? colspan;

  /// Empty columns before the element, 0 to 11.
  final Map<CsBreakpoint, int>? offset;

  /// Moves the element towards the end by this many columns without
  /// affecting its neighbours (reorders visually).
  final Map<CsBreakpoint, int>? push;

  /// Moves the element towards the start by this many columns.
  final Map<CsBreakpoint, int>? pull;

  final int? _colspan;
  final int? _offset;
  final int? _push;
  final int? _pull;

  /// The placement at [breakpoint].
  CsGridCell resolve(CsBreakpoint breakpoint) {
    int pick(int? fixed, Map<CsBreakpoint, int>? map, int fallback) =>
        fixed ?? (map == null ? null : CsBreakpoint.match(map, breakpoint)) ?? fallback;
    return CsGridCell(
      span: pick(_colspan, colspan, 12),
      offset: pick(_offset, offset, 0),
      push: pick(_push, push, 0),
      pull: pick(_pull, pull, 0),
    );
  }
}

/// Cloudscape's `Grid`: a 12-column responsive grid. Each child takes a
/// [CsGridDefinition] that sets its span, offset, push and pull per
/// breakpoint.
///
/// ```dart
/// CsGrid(
///   gridDefinition: const [
///     CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 8}),
///     CsGridDefinition(colspan: {CsBreakpoint.base: 12, CsBreakpoint.xs: 4}),
///   ],
///   children: const [Text('Main'), Text('Aside')],
/// )
/// ```
///
/// Like Cloudscape, breakpoints follow the grid's own width (a container
/// query), not the window width, so a grid inside a narrow panel collapses
/// even on a wide screen. Children that do not fit on a row wrap to the next
/// one; children in a row stretch to the tallest. Gutters are
/// `space-grid-gutter` (20px comfortable, 16px compact).
class CsGrid extends StatelessWidget {
  const CsGrid({super.key, required this.children, this.gridDefinition = const [], this.disableGutters = false});

  /// One definition per child, in order. Children without one span 12.
  final List<CsGridDefinition> gridDefinition;

  /// Removes the gutters between columns and rows.
  final bool disableGutters;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gutter = disableGutters ? 0.0 : context.cs.space.gridGutter;
    return CsGridLayout(
      hGap: gutter,
      vGap: gutter,
      resolver: (width) {
        final bp = CsBreakpoint.of(width);
        return CsGridSpec([
          for (var i = 0; i < children.length; i++)
            i < gridDefinition.length ? gridDefinition[i].resolve(bp) : const CsGridCell(),
        ]);
      },
      children: children,
    );
  }
}
