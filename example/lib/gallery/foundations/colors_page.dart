import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../page_frame.dart';

/// Every color token with its light and dark value, filtered by name.
class ColorsPage extends StatefulWidget {
  const ColorsPage({super.key});

  @override
  State<ColorsPage> createState() => _ColorsPageState();
}

class _ColorsPageState extends State<ColorsPage> {
  String _query = '';

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}${c.a < 1 ? ' ${(c.a * 100).round()}%' : ''}';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final tokens = CsColor.values.where((t) => t.name.toLowerCase().contains(q)).toList();
    return PageFrame(
      title: 'Colors',
      description: '${CsColor.values.length} tokens from the Cloudscape visual refresh theme.',
      children: [
        CsInput(
          type: CsInputType.search,
          value: _query,
          placeholder: 'Find a token, like "button"',
          onChange: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: CsSpace.m),
        CsContainer(
          disableContentPaddings: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in tokens.take(300))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CsSpace.l, vertical: CsSpace.xs),
                  child: Row(
                    spacing: CsSpace.s,
                    children: [
                      _Swatch(CsColorSchemes.light[t]),
                      _Swatch(CsColorSchemes.dark[t]),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: context.cs.code(scale: CsTypeScale.bodyS)),
                            CsBox(
                              variant: CsBoxVariant.small,
                              color: CsBoxColor.textBodySecondary,
                              text: '${_hex(CsColorSchemes.light[t])} / ${_hex(CsColorSchemes.dark[t])}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (tokens.length > 300)
                const Padding(
                  padding: EdgeInsets.all(CsSpace.l),
                  child: CsBox(
                    color: CsBoxColor.textBodySecondary,
                    text: 'Showing the first 300 matches. Refine the search.',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(CsBorderRadius.badge),
      border: Border.all(color: context.cs.colors.borderDividerDefault),
    ),
  );
}
