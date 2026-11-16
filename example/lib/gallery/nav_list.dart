import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

/// One destination in a [NavList].
class NavEntry {
  const NavEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPress,
    this.count,
  });

  final String title;
  final String description;
  final CsIconData icon;
  final VoidCallback onPress;

  /// Number of demos behind the row.
  final int? count;
}

/// A list of destinations inside one container, rows separated by dividers.
class NavList extends StatelessWidget {
  const NavList({super.key, required this.entries});

  final List<NavEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        rows.add(SizedBox(height: 1, child: ColoredBox(color: cs.colors.borderDividerDefault)));
      }
      rows.add(_NavRow(entry: entries[i]));
    }
    return CsContainer(
      disableContentPaddings: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.entry});

  final NavEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return CsPressable(
      onPress: entry.onPress,
      scaleOnPress: false,
      semanticLabel: entry.title,
      semanticHint: entry.description,
      excludeChildSemantics: true,
      builder: (context, state) => Container(
        color: state.active ? cs.colors.backgroundDropdownItemHover : null,
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.s),
        child: Row(
          spacing: CsSpace.s,
          children: [
            CsVisualAccent(
              color: CsVisualAccentColor.indigo,
              equalAspect: true,
              child: CsIcon(entry.icon),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CsBox(variant: CsBoxVariant.strong, text: entry.title),
                  CsBox(
                    variant: CsBoxVariant.small,
                    color: CsBoxColor.textBodySecondary,
                    text: entry.description,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (entry.count != null)
              CsBox(variant: CsBoxVariant.small, color: CsBoxColor.textBodySecondary, text: '${entry.count}'),
            const CsIcon(CsIcons.angleRight, variant: CsIconVariant.subtle),
          ],
        ),
      ),
    );
  }
}
