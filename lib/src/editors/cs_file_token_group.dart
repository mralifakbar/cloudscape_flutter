import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../feedback/cs_spinner.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_editor_utils.dart';
import 'cs_file.dart';

/// Layout of a [CsFileTokenGroup] (Cloudscape `alignment`).
enum CsFileTokenGroupAlignment {
  /// One full-width token per line.
  vertical,

  /// A grid of 230px tokens. Below 688px it falls back to [vertical].
  horizontal,
}

/// One token of a [CsFileTokenGroup] (Cloudscape `FileTokenGroupProps.Item`).
@immutable
class CsFileTokenGroupItem {
  const CsFileTokenGroupItem({required this.file, this.loading = false, this.errorText, this.warningText});

  final CsFile file;

  /// Shows a spinner in the token and grays its border (uploading).
  final bool loading;

  /// Marks the token invalid and shows the message under it.
  final String? errorText;

  /// Marks the token with a warning when there is no [errorText].
  final String? warningText;
}

/// Copy and formatters for [CsFileTokenGroup] (Cloudscape
/// `FileTokenGroupProps.I18nStrings`).
@immutable
class CsFileTokenGroupI18nStrings {
  const CsFileTokenGroupI18nStrings({
    this.limitShowFewer = 'Show fewer',
    this.limitShowMore = 'Show more',
    this.removeFileAriaLabel,
    this.errorIconAriaLabel,
    this.warningIconAriaLabel,
    this.formatFileSize,
    this.formatFileLastModified,
  });

  final String limitShowFewer;
  final String limitShowMore;

  /// Accessible name of a token's dismiss button. Gets the zero-based index
  /// and file name. Defaults to "Remove file 1, report.pdf".
  final String Function(int fileIndex, String fileName)? removeFileAriaLabel;
  final String? errorIconAriaLabel;
  final String? warningIconAriaLabel;

  /// Defaults to [CsFileFormat.size].
  final String Function(int sizeInBytes)? formatFileSize;

  /// Defaults to [CsFileFormat.lastModified].
  final String Function(DateTime date)? formatFileLastModified;

  String removeLabel(int index, String name) =>
      removeFileAriaLabel?.call(index, name) ?? 'Remove file ${index + 1}, $name';
}

/// Cloudscape's `FileTokenGroup`: the chosen files as tokens, each with its
/// name, optional size, date and image thumbnail, a dismiss button, and a
/// loading, error or warning state.
///
/// ```dart
/// CsFileTokenGroup(
///   items: [for (final f in files) CsFileTokenGroupItem(file: f)],
///   showFileSize: true,
///   onDismiss: (i) => setState(() => files.removeAt(i)),
/// )
/// ```
///
/// Tokens are not removed by the group: update [items] in [onDismiss]. After
/// a dismiss, focus moves to the token that took its place, or to the
/// previous one. With a [limit], a "Show more (+N)" toggle reveals the rest.
class CsFileTokenGroup extends StatefulWidget {
  const CsFileTokenGroup({
    super.key,
    required this.items,
    this.onDismiss,
    this.showFileSize = false,
    this.showFileLastModified = false,
    this.showFileThumbnail = false,
    this.thumbnailBuilder,
    this.limit,
    this.alignment = CsFileTokenGroupAlignment.vertical,
    this.readOnly = false,
    this.limitShowFewerAriaLabel,
    this.limitShowMoreAriaLabel,
    this.i18nStrings = const CsFileTokenGroupI18nStrings(),
  });

  final List<CsFileTokenGroupItem> items;

  /// Called with the index of the dismissed token.
  final ValueChanged<int>? onDismiss;
  final bool showFileSize;
  final bool showFileLastModified;

  /// Shows a 48px preview for image files ([CsFile.thumbnail], or
  /// [thumbnailBuilder]).
  final bool showFileThumbnail;

  /// Custom thumbnail for an image file (a cached network preview).
  final Widget Function(BuildContext context, CsFile file)? thumbnailBuilder;

  /// Maximum number of tokens shown before the "Show more" toggle.
  final int? limit;
  final CsFileTokenGroupAlignment alignment;

  /// Tokens stay focusable but cannot be dismissed.
  final bool readOnly;
  final String? limitShowFewerAriaLabel;
  final String? limitShowMoreAriaLabel;
  final CsFileTokenGroupI18nStrings i18nStrings;

  @override
  State<CsFileTokenGroup> createState() => _CsFileTokenGroupState();
}

class _CsFileTokenGroupState extends State<CsFileTokenGroup> {
  bool _expanded = false;
  final List<FocusNode> _nodes = [];
  final FocusNode _toggleNode = FocusNode(debugLabel: 'CsFileTokenGroup toggle');

  FocusNode _node(int i) {
    while (_nodes.length <= i) {
      _nodes.add(FocusNode(debugLabel: 'CsFileTokenGroup dismiss ${_nodes.length}'));
    }
    return _nodes[i];
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    _toggleNode.dispose();
    super.dispose();
  }

  void _dismiss(int index) {
    widget.onDismiss?.call(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final visible = _visibleCount;
      if (index < visible) {
        _node(index).requestFocus();
      } else if (index > 0 && visible > 0) {
        _node(visible - 1).requestFocus();
      } else if (_hasHidden) {
        _toggleNode.requestFocus();
      }
    });
  }

  bool get _hasHidden => widget.limit != null && widget.items.length > widget.limit!;

  int get _visibleCount => _hasHidden && !_expanded ? widget.limit! : widget.items.length;

  @override
  Widget build(BuildContext context) {
    final narrow = context.csIsNarrow;
    final horizontal = widget.alignment == CsFileTokenGroupAlignment.horizontal && !narrow;
    final groupHasImage = widget.items.any((i) => i.file.isImage);
    final tokens = <Widget>[
      for (var i = 0; i < _visibleCount; i++)
        _FileToken(
          key: ValueKey(i),
          item: widget.items[i],
          index: i,
          setSize: widget.items.length,
          group: widget,
          horizontal: horizontal,
          groupContainsImage: groupHasImage,
          focusNode: _node(i),
          onDismiss: widget.readOnly || widget.onDismiss == null ? null : () => _dismiss(i),
        ),
    ];
    final list = horizontal
        ? Wrap(spacing: CsSpace.xs, runSpacing: CsSpace.xs, children: tokens)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.xs,
            children: tokens,
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: context.cs.space.scaledXs,
        children: [
          if (tokens.isNotEmpty) list,
          if (_hasHidden)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _TokenLimitToggle(
                expanded: _expanded,
                hiddenCount: widget.items.length - _visibleCount,
                allHidden: widget.limit == 0,
                showMoreText: widget.i18nStrings.limitShowMore,
                showFewerText: widget.i18nStrings.limitShowFewer,
                showMoreAriaLabel: widget.limitShowMoreAriaLabel,
                showFewerAriaLabel: widget.limitShowFewerAriaLabel,
                focusNode: _toggleNode,
                onPress: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cloudscape's token list "Show more (+N)" / "Show fewer" toggle: a link
/// colored button with a tree-view expand icon.
class _TokenLimitToggle extends StatelessWidget {
  const _TokenLimitToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onPress,
    this.allHidden = false,
    this.showMoreText = 'Show more',
    this.showFewerText = 'Show fewer',
    this.showMoreAriaLabel,
    this.showFewerAriaLabel,
    this.focusNode,
  });

  final bool expanded;
  final int hiddenCount;
  final bool allHidden;
  final VoidCallback onPress;
  final String showMoreText;
  final String showFewerText;
  final String? showMoreAriaLabel;
  final String? showFewerAriaLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cs.colors;
    final text = expanded ? showFewerText : '$showMoreText (${allHidden ? hiddenCount : '+$hiddenCount'})';
    return CsPressable(
      onPress: onPress,
      focusNode: focusNode,
      expanded: expanded,
      semanticLabel: (expanded ? showFewerAriaLabel : showMoreAriaLabel) ?? text,
      excludeChildSemantics: true,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) {
        final color = state.active ? c.textLinkHover : c.textLinkDefault;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: CsSpace.xxs,
          children: [
            CsIcon(expanded ? CsIcons.treeviewCollapse : CsIcons.treeviewExpand, dangerouslySetColor: color),
            Flexible(
              child: Text(
                text,
                style: context.cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FileToken extends StatelessWidget {
  const _FileToken({
    super.key,
    required this.item,
    required this.index,
    required this.setSize,
    required this.group,
    required this.horizontal,
    required this.groupContainsImage,
    required this.focusNode,
    required this.onDismiss,
  });

  final CsFileTokenGroupItem item;
  final int index;
  final int setSize;
  final CsFileTokenGroup group;
  final bool horizontal;
  final bool groupContainsImage;
  final FocusNode focusNode;
  final VoidCallback? onDismiss;

  // file-token-group/constants.scss
  static const double _imageSize = 48;
  static const double _compactTokenWidth = 230;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final file = item.file;
    final i18n = group.i18nStrings;
    final error = item.errorText;
    final warning = error == null ? item.warningText : null;
    final status = error != null || warning != null;

    final Color border = group.readOnly
        ? c.borderInputDisabled
        : item.loading
        ? c.borderControlDisabled
        : error != null
        ? c.borderStatusError
        : warning != null
        ? c.borderStatusWarning
        : c.borderItemSelected;
    final Color background = group.readOnly || item.loading ? c.backgroundContainerContent : c.backgroundItemSelected;
    final startWidth = status && !item.loading ? CsBorderWidth.fieldStatusInlineStart : CsBorderWidth.token;

    final secondary = cs.text(CsTypeScale.bodyS, color: CsColor.textBodySecondary);
    final metadata = <Widget>[
      CsTooltip(
        content: file.name,
        child: Text(file.name, style: cs.body, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      if (group.showFileSize && file.size > 0)
        Text(
          (i18n.formatFileSize ?? CsFileFormat.size)(file.size),
          style: secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      if (group.showFileLastModified && file.lastModified != null)
        Text(
          (i18n.formatFileLastModified ?? CsFileFormat.lastModified)(file.lastModified!),
          style: secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ];
    final showThumb = group.showFileThumbnail && file.isImage;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: cs.space.scaledXs,
      children: [
        if (showThumb)
          Padding(
            padding: const EdgeInsets.only(top: CsSpace.staticXxs),
            child: ExcludeSemantics(
              child: SizedBox.square(dimension: _imageSize, child: _thumbnail(context, file)),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.xxxs,
            children: metadata,
          ),
        ),
        if (item.loading)
          const Padding(
            padding: EdgeInsets.only(top: CsSpace.xxxs),
            child: CsSpinner(),
          ),
        if (onDismiss != null || group.readOnly)
          CsButton(
            icon: CsIcons.close,
            variant: CsButtonVariant.inlineIcon,
            semanticLabel: i18n.removeLabel(index, file.name),
            focusNode: focusNode,
            disabled: group.readOnly,
            onPress: onDismiss,
          ),
      ],
    );

    final dir = Directionality.of(context);
    final side = BorderSide(color: border, width: CsBorderWidth.token);
    final start = BorderSide(color: border, width: startWidth);
    final Widget box = Container(
      constraints: BoxConstraints(minHeight: groupContainsImage && group.showFileThumbnail ? 68 : 0),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(CsBorderRadius.token)),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CsBorderRadius.token),
        border: dir == TextDirection.rtl
            ? Border(top: side, bottom: side, left: side, right: start)
            : Border(top: side, bottom: side, left: start, right: side),
      ),
      padding: EdgeInsetsDirectional.only(
        start: startWidth + CsSpace.fieldHorizontal - CsBorderWidth.token,
        end: CsSpace.xxs + CsBorderWidth.token,
        top: cs.space.tokenVertical + CsBorderWidth.token,
        bottom: cs.space.tokenVertical + CsBorderWidth.token,
      ),
      child: content,
    );

    Widget token = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CsSpace.xxs,
      children: [
        box,
        if (error != null) CsEditorsMessage(text: error, warning: false, iconLabel: i18n.errorIconAriaLabel),
        if (warning != null) CsEditorsMessage(text: warning, warning: true, iconLabel: i18n.warningIconAriaLabel),
      ],
    );
    if (horizontal) token = SizedBox(width: _compactTokenWidth, child: token);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '${file.name}, ${index + 1} of $setSize${item.loading ? ', ${context.csStrings.loading}' : ''}',
      child: token,
    );
  }

  Widget _thumbnail(BuildContext context, CsFile file) {
    final custom = group.thumbnailBuilder?.call(context, file);
    if (custom != null) return custom;
    if (file.thumbnail != null) {
      return Image(
        image: file.thumbnail!,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => const Center(child: CsIcon(CsIcons.file, variant: CsIconVariant.subtle)),
      );
    }
    return const Center(
      child: CsIcon(CsIcons.file, size: CsIconSize.medium, variant: CsIconVariant.subtle),
    );
  }
}
