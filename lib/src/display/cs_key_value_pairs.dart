import 'package:flutter/widgets.dart';

import '../layout/cs_box.dart';
import '../navigation/cs_link.dart';
import '../theme/theme.dart';

/// One entry of [CsKeyValuePairs.items]: a [CsKeyValuePair] or a
/// [CsKeyValueGroup] of pairs.
sealed class CsKeyValueItem {
  const CsKeyValueItem();
}

/// A label and its value (Cloudscape `KeyValuePairsProps.Pair`).
///
/// ```dart
/// const CsKeyValuePair(label: 'Instance ID', value: 'i-0abc123')
/// CsKeyValuePair(
///   label: 'Status',
///   valueWidget: const CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
///   info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: openHelp),
/// )
/// ```
class CsKeyValuePair extends CsKeyValueItem {
  const CsKeyValuePair({required this.label, this.value, this.valueWidget, this.labelWidget, this.info, this.id})
    : assert(value != null || valueWidget != null, 'Pass value or valueWidget');

  /// The key. Also the semantic label of the pair.
  final String label;

  /// Custom content in place of [label], such as a label with an icon.
  final Widget? labelWidget;

  /// The value as text.
  final String? value;

  /// The value as a widget (a status indicator, a link, a copy-to-clipboard
  /// control). Takes precedence over [value].
  final Widget? valueWidget;

  /// Area next to the label, usually an "Info" link
  /// (`CsLink(variant: CsLinkVariant.info)`).
  final Widget? info;

  /// Identifier of the pair, used as its widget key so state in a value
  /// survives reordering.
  final String? id;
}

/// A titled column of pairs (Cloudscape `KeyValuePairsProps.Group`). Groups
/// and plain pairs can be mixed in one [CsKeyValuePairs].
class CsKeyValueGroup extends CsKeyValueItem {
  const CsKeyValueGroup({required this.items, this.title});

  /// Optional title shown above the pairs as an h3 heading.
  final String? title;
  final List<CsKeyValuePair> items;
}

/// Cloudscape's `KeyValuePairs`: labeled values of a resource laid out in
/// up to four columns, such as the details section of an instance.
///
/// ```dart
/// const CsKeyValuePairs(
///   columns: 3,
///   items: [
///     CsKeyValuePair(label: 'Distribution ID', value: 'd111111abcdef8'),
///     CsKeyValuePair(label: 'Price class', value: 'Use all edge locations'),
///     CsKeyValuePair(label: 'Domain name', value: 'd111111abcdef8.cloudfront.example'),
///   ],
/// )
/// ```
///
/// The number of columns adapts to the width: it is [columns] at most, and
/// each column is at least [minColumnWidth] wide. When it has to drop
/// columns it keeps an even count (4 becomes 2, never 3), like Cloudscape,
/// so on a 390px phone four columns become two and then one. Columns are
/// separated by a vertical divider in the middle of the grid gutter.
///
/// Links inside the values default to [CsLinkVariant.primary] (underlined).
class CsKeyValuePairs extends StatelessWidget {
  const CsKeyValuePairs({super.key, required this.items, this.columns = 1, this.minColumnWidth = 150, this.ariaLabel})
    : assert(columns >= 1, 'columns must be at least 1');

  /// Pairs and groups, laid out in rows from the start.
  final List<CsKeyValueItem> items;

  /// Maximum number of columns, 1 to 4. Values above 4 use 4.
  final int columns;

  /// Minimum width of a column in logical pixels. Defaults to 150.
  final double minColumnWidth;

  /// Accessible name of the whole list, such as "Distribution details".
  final String? ariaLabel;

  /// Cloudscape's maximum number of columns.
  static const int maxColumns = 4;

  /// Columns used at [width]: at most [columns], each at least
  /// [minColumnWidth] wide, and an even count when it has to wrap.
  static int columnCountFor(int columns, double minColumnWidth, double width) {
    if (!width.isFinite || width <= 0) return columns;
    final fit = minColumnWidth <= 0 ? columns : (width / minColumnWidth).floor();
    final target = fit < columns ? fit : columns;
    final count = target < columns && target.isOdd ? target - 1 : target;
    return count < 1 ? 1 : count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gutter = cs.space.gridGutter;
    final maxCols = columns > maxColumns ? maxColumns : columns;
    Widget grid = LayoutBuilder(
      builder: (context, constraints) {
        final n = columnCountFor(maxCols, minColumnWidth, constraints.maxWidth);
        final rows = <Widget>[];
        for (var start = 0; start < items.length; start += n) {
          final end = start + n > items.length ? items.length : start + n;
          rows.add(
            _GridRow(
              columns: n,
              gutter: gutter,
              dividerColor: cs.colors.borderDividerDefault,
              children: [for (var i = start; i < end; i++) _item(context, items[i])],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: gutter,
          children: rows,
        );
      },
    );
    grid = CsLinkDefaults(variant: CsLinkVariant.primary, child: grid);
    return Semantics(container: true, explicitChildNodes: true, label: ariaLabel, child: grid);
  }

  Widget _item(BuildContext context, CsKeyValueItem item) => switch (item) {
    CsKeyValuePair() => _Pair(pair: item, key: item.id == null ? null : ValueKey(item.id)),
    CsKeyValueGroup() => _Group(group: item),
  };
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final CsKeyValueGroup group;

  @override
  Widget build(BuildContext context) {
    final gap = context.cs.space.scaledM;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (group.title != null)
          Padding(
            // `.group-title`: padding-block-end space-scaled-m.
            padding: EdgeInsets.only(bottom: gap),
            child: CsBox(
              variant: CsBoxVariant.h3,
              text: group.title,
              padding: const CsBoxSpacing(top: CsSpacingSize.n, bottom: CsSpacingSize.n),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [for (final p in group.items) _Pair(pair: p, key: p.id == null ? null : ValueKey(p.id))],
        ),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({super.key, required this.pair});

  final CsKeyValuePair pair;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    // `.key-label`: font-label with the key-value-pairs label tokens (body-m, bold).
    final labelStyle = cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textLabel);
    final label = DefaultTextStyle(style: labelStyle, child: pair.labelWidget ?? Text(pair.label));
    final term = pair.info == null
        ? label
        : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // `info-link-spacing`: the label keeps space-xs before the info area.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: CsSpace.xs),
                child: label,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: cs.colors.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
                  child: DefaultTextStyle(style: labelStyle, child: pair.info!),
                ),
              ),
            ],
          );
    final valueStyle = cs.text(CsTypeScale.bodyM, color: CsColor.textKeyValuePairsValue);
    final value = DefaultTextStyle(style: valueStyle, child: pair.valueWidget ?? Text(pair.value!));
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          term,
          // `space-key-value-gap` is 0 in both densities.
          if (CsSpace.keyValueGap > 0) const SizedBox(height: CsSpace.keyValueGap),
          value,
        ],
      ),
    );
  }
}

/// One row of the text grid: equal columns, each item padded by the gutter
/// on both sides except the first column's start, with a divider in the
/// middle of each gap (`column-layout` `grid-variant-text-grid`).
class _GridRow extends StatelessWidget {
  const _GridRow({required this.columns, required this.gutter, required this.dividerColor, required this.children});

  final int columns;
  final double gutter;
  final Color dividerColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) return children.single;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final col = (width - gutter * (columns - 1)) / columns;
        final cells = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) cells.add(SizedBox(width: gutter));
          cells.add(
            SizedBox(
              width: col,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : gutter, end: gutter),
                child: children[i],
              ),
            ),
          );
        }
        return CustomPaint(
          painter: _DividerPainter(
            count: children.length,
            column: col,
            gutter: gutter,
            color: dividerColor,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells),
        );
      },
    );
  }
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter({
    required this.count,
    required this.column,
    required this.gutter,
    required this.color,
    required this.rtl,
  });

  final int count;
  final double column;
  final double gutter;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const w = CsBorderLine.dividerSectionWidth;
    for (var i = 1; i < count; i++) {
      final start = i * (column + gutter) - gutter / 2;
      final x = rtl ? size.width - start : start;
      canvas.drawRect(Rect.fromLTWH(x - w / 2, 0, w, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DividerPainter old) =>
      old.count != count || old.column != column || old.gutter != gutter || old.color != color || old.rtl != rtl;
}
