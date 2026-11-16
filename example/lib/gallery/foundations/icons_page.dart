import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../page_frame.dart';

/// Every built-in icon, filtered by name, at the chosen size.
class IconsPage extends StatefulWidget {
  const IconsPage({super.key});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class _IconsPageState extends State<IconsPage> {
  String _query = '';
  CsIconSize _size = CsIconSize.medium;

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final icons = CsIcons.all.where((i) => i.name.contains(q)).toList();
    return PageFrame(
      title: 'Icons',
      description: '${CsIcons.all.length} Cloudscape icons, drawn as vector outlines.',
      children: [
        CsInput(
          type: CsInputType.search,
          value: _query,
          placeholder: 'Find an icon, like "status"',
          onChange: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: CsSpace.s),
        Wrap(
          spacing: CsSpace.xs,
          children: [
            for (final s in [CsIconSize.normal, CsIconSize.medium, CsIconSize.big])
              CsButton(
                text: s.name,
                variant: _size == s ? CsButtonVariant.primary : CsButtonVariant.normal,
                onPress: () => setState(() => _size = s),
              ),
          ],
        ),
        const SizedBox(height: CsSpace.m),
        CsContainer(
          child: Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            children: [
              for (final icon in icons)
                SizedBox(
                  width: 96,
                  child: Column(
                    spacing: CsSpace.xxs,
                    children: [
                      SizedBox(height: 36, child: Center(child: CsIcon(icon, size: _size))),
                      Text(
                        icon.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: context.cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
