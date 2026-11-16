import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../page_frame.dart';

/// The Cloudscape type scale in Open Sans.
class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return PageFrame(
      title: 'Typography',
      description: 'Open Sans on the Cloudscape type scale. Content text is body-m, 14px on 20px.',
      children: [
        CsContainer(
          child: CsSpaceBetween(
            size: CsSpacingSize.l,
            children: [
              for (final s in CsTypeScale.values)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.name}  ${s.fontSize.toInt()}/${s.lineHeight.toInt()}  w${s.weight.value}',
                      style: cs.code(scale: CsTypeScale.bodyS, color: CsColor.textBodySecondary),
                    ),
                    Text(
                      s.index >= CsTypeScale.displayL.index ? '1,284' : 'Launch an instance',
                      style: cs.text(s),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('monospace', style: cs.code(scale: CsTypeScale.bodyS, color: CsColor.textBodySecondary)),
                  Text('i-0abcd1234efgh5678', style: cs.code()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
