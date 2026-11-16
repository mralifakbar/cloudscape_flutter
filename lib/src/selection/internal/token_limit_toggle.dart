import 'package:flutter/widgets.dart';

import '../../icons/cs_icon.dart';
import '../../icons/cs_icons.g.dart';
import '../../system/cs_pressable.dart';
import '../../theme/theme.dart';

/// The "Show more (+3)" / "Show fewer" toggle under a limited token list
/// (Cloudscape `TokenLimitToggle`): a link-colored button with a tree view
/// expand or collapse icon.
class TokenLimitToggle extends StatelessWidget {
  const TokenLimitToggle({
    super.key,
    required this.expanded,
    required this.hiddenCount,
    required this.allHidden,
    required this.showMoreText,
    required this.showFewerText,
    required this.onPress,
    this.showMoreAriaLabel,
    this.showFewerAriaLabel,
  });

  final bool expanded;
  final int hiddenCount;
  final bool allHidden;
  final String showMoreText;
  final String showFewerText;
  final VoidCallback onPress;
  final String? showMoreAriaLabel;
  final String? showFewerAriaLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final count = allHidden ? '$hiddenCount' : '+$hiddenCount';
    final text = expanded ? showFewerText : '$showMoreText ($count)';
    return CsPressable(
      onPress: onPress,
      expanded: expanded,
      semanticLabel: expanded ? (showFewerAriaLabel ?? text) : (showMoreAriaLabel ?? text),
      excludeChildSemantics: true,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final color = state.active ? cs.colors.textLinkHover : cs.colors.textLinkDefault;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsIcon(expanded ? CsIcons.treeviewCollapse : CsIcons.treeviewExpand, dangerouslySetColor: color),
            const SizedBox(width: CsSpace.xxs),
            Flexible(
              child: Text(text, style: cs.body.copyWith(color: color)),
            ),
          ],
        );
      },
    );
  }
}
