import 'package:flutter/widgets.dart';

import '../icons/cs_icon_data.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_token.dart';
import 'internal/token_limit_toggle.dart';

/// One token in a [CsTokenGroup] (Cloudscape `TokenGroupProps.Item`).
@immutable
class CsTokenGroupItem {
  const CsTokenGroupItem({
    required this.label,
    this.labelTag,
    this.description,
    this.tags,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.dismissLabel,
  });

  final String label;
  final String? labelTag;
  final String? description;
  final List<String>? tags;
  final CsIconData? icon;
  final Widget? iconWidget;

  /// A disabled token cannot be dismissed.
  final bool disabled;

  /// Accessible name of the dismiss button. Defaults to "Remove" followed by the label.
  final String? dismissLabel;
}

/// How tokens are laid out (Cloudscape `alignment`).
enum CsTokenGroupAlignment {
  /// Tokens wrap in rows.
  horizontal,

  /// One token per line.
  vertical,
}

/// Copy for [CsTokenGroup] (Cloudscape `i18nStrings`).
@immutable
class CsTokenGroupI18nStrings {
  const CsTokenGroupI18nStrings({this.limitShowMore = 'Show more', this.limitShowFewer = 'Show fewer'});

  final String limitShowMore;
  final String limitShowFewer;
}

/// Cloudscape's `TokenGroup`: a list of dismissible tokens, such as the
/// chosen options of a multiselect or applied filters.
///
/// ```dart
/// CsTokenGroup(
///   items: const [
///     CsTokenGroupItem(label: 'example-bucket', description: 'us-east-1'),
///     CsTokenGroupItem(label: 'logs-bucket', description: 'eu-west-1'),
///   ],
///   onDismiss: (index) => setState(() => buckets.removeAt(index)),
/// )
/// ```
///
/// With [limit], only that many tokens show, followed by a "Show more (+N)"
/// toggle.
class CsTokenGroup extends StatefulWidget {
  const CsTokenGroup({
    super.key,
    required this.items,
    this.onDismiss,
    this.limit,
    this.alignment = CsTokenGroupAlignment.horizontal,
    this.disableOuterPadding = false,
    this.readOnly = false,
    this.i18nStrings = const CsTokenGroupI18nStrings(),
    this.limitShowMoreAriaLabel,
    this.limitShowFewerAriaLabel,
  });

  final List<CsTokenGroupItem> items;

  /// Called with the index of the dismissed token. Without it tokens have no
  /// dismiss button.
  final ValueChanged<int>? onDismiss;

  /// Number of tokens shown before "Show more".
  final int? limit;
  final CsTokenGroupAlignment alignment;

  /// Drops the `space-xs` padding above the tokens.
  final bool disableOuterPadding;

  /// Tokens show their read-only style and cannot be dismissed.
  final bool readOnly;
  final CsTokenGroupI18nStrings i18nStrings;
  final String? limitShowMoreAriaLabel;
  final String? limitShowFewerAriaLabel;

  @override
  State<CsTokenGroup> createState() => _CsTokenGroupState();
}

class _CsTokenGroupState extends State<CsTokenGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final limit = widget.limit;
    final hasHidden = limit != null && items.length > limit;
    final visible = hasHidden && !_expanded ? items.sublist(0, limit) : items;
    final strings = context.csStrings;

    final tokens = <Widget>[
      for (var i = 0; i < visible.length; i++)
        CsToken(
          key: ValueKey('cs-token-$i-${visible[i].label}'),
          label: visible[i].label,
          labelTag: visible[i].labelTag,
          description: visible[i].description,
          tags: visible[i].tags,
          icon: visible[i].icon,
          iconWidget: visible[i].iconWidget,
          disabled: visible[i].disabled,
          readOnly: widget.readOnly,
          dismissLabel: visible[i].dismissLabel ?? strings.removeItem(visible[i].label),
          onDismiss: widget.onDismiss == null ? null : () => widget.onDismiss!(i),
        ),
    ];
    final toggle = hasHidden
        ? TokenLimitToggle(
            expanded: _expanded,
            hiddenCount: items.length - limit,
            allHidden: limit == 0,
            showMoreText: widget.i18nStrings.limitShowMore,
            showFewerText: widget.i18nStrings.limitShowFewer,
            showMoreAriaLabel: widget.limitShowMoreAriaLabel,
            showFewerAriaLabel: widget.limitShowFewerAriaLabel,
            onPress: () => setState(() => _expanded = !_expanded),
          )
        : null;

    final Widget list = widget.alignment == CsTokenGroupAlignment.horizontal
        ? Wrap(
            spacing: CsSpace.xs,
            runSpacing: CsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [...tokens, ?toggle],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CsSpace.xs,
            children: [...tokens, ?toggle],
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: EdgeInsets.only(top: widget.disableOuterPadding ? 0 : CsSpace.xs),
        child: list,
      ),
    );
  }
}
