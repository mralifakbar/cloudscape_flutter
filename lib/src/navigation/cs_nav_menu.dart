import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../overlays/cs_sheet.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// One row of a navigation menu (the breadcrumb ellipsis, top navigation
/// menus and overflow). Internal to the navigation category.
@immutable
class CsNavMenuEntry {
  const CsNavMenuEntry({
    required this.text,
    this.onPress,
    this.description,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.external = false,
    this.externalIconAriaLabel,
    this.current = false,
    this.checked,
    this.isGroupLabel = false,
    this.isSeparator = false,
    this.isLink = true,
    this.trailing,
  });

  /// A bold group heading.
  const CsNavMenuEntry.group(this.text)
    : onPress = null,
      description = null,
      icon = null,
      iconWidget = null,
      disabled = false,
      external = false,
      externalIconAriaLabel = null,
      current = false,
      checked = null,
      isGroupLabel = true,
      isSeparator = false,
      isLink = false,
      trailing = null;

  /// A divider between groups.
  const CsNavMenuEntry.separator()
    : text = '',
      onPress = null,
      description = null,
      icon = null,
      iconWidget = null,
      disabled = false,
      external = false,
      externalIconAriaLabel = null,
      current = false,
      checked = null,
      isGroupLabel = false,
      isSeparator = true,
      isLink = false,
      trailing = null;

  final String text;
  final VoidCallback? onPress;
  final String? description;
  final CsIconData? icon;
  final Widget? iconWidget;
  final bool disabled;
  final bool external;
  final String? externalIconAriaLabel;

  /// The current page: drawn bold in the current color and not activatable.
  final bool current;
  final bool? checked;
  final bool isGroupLabel;
  final bool isSeparator;
  final bool isLink;
  final Widget? trailing;
}

/// Builds the rows of [entries]; [close] closes the menu (or its sheet).
List<Widget> csNavMenuRows(BuildContext context, List<CsNavMenuEntry> entries, VoidCallback close) {
  final cs = context.cs;
  return [
    for (final e in entries)
      if (e.isSeparator)
        const CsMenuSeparator()
      else if (e.isGroupLabel)
        CsMenuGroupLabel(e.text)
      else if (e.current)
        Semantics(
          link: true,
          enabled: false,
          selected: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CsSpace.fieldHorizontal,
              vertical: CsSpace.optionPaddingVertical + CsBorderWidth.itemSelected,
            ),
            child: Text(
              e.text,
              style: cs.text(
                CsTypeScale.bodyM,
                weight: CsFontTokens.fontWeightBreadcrumbCurrent,
                color: CsColor.textBreadcrumbCurrent,
              ),
            ),
          ),
        )
      else
        CsMenuRow(
          label: e.text,
          description: e.description,
          icon: e.icon,
          leading: e.iconWidget,
          disabled: e.disabled,
          isLink: e.isLink,
          checked: e.checked,
          semanticLabel: e.external
              ? '${e.text}, ${e.externalIconAriaLabel ?? context.csStrings.opensInNewWindow}'
              : null,
          trailing:
              e.trailing ??
              (e.external
                  ? const CsIcon(CsIcons.external, size: CsIconSize.small, variant: CsIconVariant.subtle)
                  : null),
          onPress: e.onPress == null
              ? null
              : () {
                  close();
                  e.onPress!();
                },
        ),
  ];
}

/// A trigger that opens [entries] in a dropdown, or a bottom sheet on phones.
class CsNavMenu extends StatefulWidget {
  const CsNavMenu({
    super.key,
    required this.entries,
    required this.triggerBuilder,
    this.label,
    this.presentation = CsPresentation.auto,
    this.align = CsAlign.start,
    this.matchTriggerWidth = false,
    this.onOpenChange,
    this.header,
  });

  final List<CsNavMenuEntry> entries;

  /// Shown above the rows (a title and description).
  final Widget? header;

  /// Builds the trigger from the open state; call `toggle` to open or close.
  final Widget Function(BuildContext context, bool open, VoidCallback toggle) triggerBuilder;

  /// Accessible name of the menu and its sheet.
  final String? label;
  final CsPresentation presentation;
  final CsAlign align;
  final bool matchTriggerWidth;
  final ValueChanged<bool>? onOpenChange;

  @override
  State<CsNavMenu> createState() => _CsNavMenuState();
}

class _CsNavMenuState extends State<CsNavMenu> {
  bool _open = false;

  void _set(bool v) {
    if (_open == v) return;
    setState(() => _open = v);
    widget.onOpenChange?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return CsDropdown(
      open: _open,
      onDismiss: () => _set(false),
      presentation: widget.presentation,
      align: widget.align,
      matchTriggerWidth: widget.matchTriggerWidth,
      trapFocus: true,
      sheetLabel: widget.label,
      contentBuilder: (context, inSheet) {
        void close() {
          if (inSheet) CsSheetScope.closeFrom(context);
          _set(false);
        }

        final rows = [?widget.header, ...csNavMenuRows(context, widget.entries, close)];
        if (inSheet) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs, vertical: CsSpace.xs),
            child: CsMenuKeyboard(
              child: Semantics(
                label: widget.label,
                container: true,
                explicitChildNodes: true,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows,
                  ),
                ),
              ),
            ),
          );
        }
        return CsMenuPanel(semanticLabel: widget.label, maxHeight: 400, children: rows);
      },
      child: widget.triggerBuilder(context, _open, () => _set(!_open)),
    );
  }
}
