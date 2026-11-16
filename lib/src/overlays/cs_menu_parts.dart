import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../system/cs_pressable.dart';
import '../theme/theme.dart';

/// The surface of dropdowns and option lists: Cloudscape's dropdown
/// container (`color-background-dropdown-item-default`, a 2px
/// `color-border-dropdown-container` border, 8px radius, `shadow-dropdown`).
/// Scrolls when its content is taller than the room it was given.
///
/// Used by dropdown menus, select and combobox lists and the command palette.
class CsMenuPanel extends StatelessWidget {
  const CsMenuPanel({
    super.key,
    required this.children,
    this.minWidth = 144,
    this.maxHeight,
    this.padding = const EdgeInsets.symmetric(vertical: CsSpace.xxs),
    this.scrollController,
    this.semanticLabel,
  });

  final List<Widget> children;

  /// Cloudscape dropdowns are at least as wide as their trigger; this is
  /// the floor when there is no trigger width.
  final double minWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;
  final ScrollController? scrollController;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.dropdown));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, maxHeight: maxHeight ?? double.infinity),
        decoration: BoxDecoration(
          color: c.backgroundDropdownItemDefault,
          borderRadius: radius,
          border: CsRing.inside(c.borderDropdownContainer, width: CsBorderWidth.dropdown),
          boxShadow: cs.shadows.dropdown,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CsMenuKeyboard(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: padding,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arrow-key movement between the focusable rows inside [child]: Up and Down
/// move, Home and End jump to the ends. Wrap any custom list of
/// [CsMenuRow]s with it.
class CsMenuKeyboard extends StatelessWidget {
  const CsMenuKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: Actions(
          actions: {
            _EdgeIntent: CallbackAction<_EdgeIntent>(
              onInvoke: (intent) {
                final scope = FocusManager.instance.primaryFocus?.nearestScope;
                final nodes = scope?.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal).toList();
                if (nodes == null || nodes.isEmpty) return null;
                (intent.last ? nodes.last : nodes.first).requestFocus();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(last: false),
              SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(last: true),
            },
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EdgeIntent extends Intent {
  const _EdgeIntent({required this.last});
  final bool last;
}

/// One row of a dropdown or option list, drawn like Cloudscape's selectable
/// item: while hovered or keyboard-highlighted it gets
/// `color-background-dropdown-item-hover` inside a 2px
/// `color-border-dropdown-item-hover` outline; a selected row gets
/// `color-background-dropdown-item-selected` and a
/// `color-border-dropdown-item-selected` outline. Optional leading icon,
/// description and trailing content (a check, a shortcut, a submenu caret).
///
/// ```dart
/// CsMenuRow(label: 'Edit', icon: CsIcons.edit, onPress: edit)
/// CsMenuRow(label: 'Delete', icon: CsIcons.remove, destructive: true, onPress: delete)
/// ```
class CsMenuRow extends StatelessWidget {
  const CsMenuRow({
    super.key,
    required this.label,
    this.onPress,
    this.icon,
    this.leading,
    this.description,
    this.trailing,
    this.shortcut,
    this.selected,
    this.highlighted = false,
    this.disabled = false,
    this.destructive = false,
    this.inset = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.checked,
    this.inMutuallyExclusiveGroup,
    this.expanded,
    this.isLink = false,
    this.onHover,
    this.canRequestFocus = true,
  });

  final String label;
  final VoidCallback? onPress;
  final CsIconData? icon;

  /// Custom leading widget (an avatar, a checkbox box) in place of [icon].
  final Widget? leading;
  final String? description;
  final Widget? trailing;

  /// Keyboard shortcut hint shown at the end, such as `⌘K`.
  final String? shortcut;

  /// Marks the row as the current option (announced as selected).
  final bool? selected;

  /// Force the highlight (an option list that tracks highlight separately
  /// from focus, such as a combobox driven from its text field).
  final bool highlighted;
  final bool disabled;

  /// Danger text, for delete and revoke.
  final bool destructive;

  /// Leaves room for a leading indicator so labels line up with checkable rows.
  final bool inset;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final bool? checked;
  final bool? inMutuallyExclusiveGroup;
  final bool? expanded;

  /// Announce as a link (navigation items).
  final bool isLink;

  /// Pointer entered (true) or left (false) the row, for lists that move a
  /// highlight with the mouse while focus stays in a text field.
  final ValueChanged<bool>? onHover;

  /// False keeps the row out of focus traversal (option lists driven from a
  /// text field).
  final bool canRequestFocus;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final Widget row = CsPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      minTapTargetSize: 0,
      borderRadius: BorderRadius.circular(CsBorderRadius.item),
      showFocusRing: false,
      semanticLabel: semanticLabel,
      selected: selected,
      checked: checked,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      expanded: expanded,
      isLink: isLink,
      canRequestFocus: canRequestFocus,
      builder: (context, state) {
        final lit = !disabled && (highlighted || state.active || state.focused);
        final isSelected = selected ?? false;
        final fgColor = disabled
            ? c.textDropdownItemDisabled
            : destructive
            ? c.textStatusError
            : (lit || isSelected)
            ? c.textDropdownItemHighlighted
            : c.textDropdownItemDefault;
        final lead =
            leading ?? (icon != null ? CsIcon(icon!, dangerouslySetColor: fgColor) : null);
        // Cloudscape draws the outline as inset box-shadows: selected first,
        // then the hover or keyboard outline inside it.
        final outline = isSelected
            ? c.borderDropdownItemSelected
            : lit
            ? (state.focused ? c.borderDropdownItemFocused : c.borderDropdownItemHover)
            : null;
        return Container(
          constraints: BoxConstraints(minHeight: cs.minTapTarget > 0 ? 40 : 0),
          padding: const EdgeInsets.symmetric(
            horizontal: CsSpace.fieldHorizontal,
            vertical: CsSpace.optionPaddingVertical + CsBorderWidth.itemSelected,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? c.backgroundDropdownItemSelected
                : lit
                ? c.backgroundDropdownItemHover
                : null,
            borderRadius: BorderRadius.circular(CsBorderRadius.item),
            border: outline == null ? null : CsRing.inside(outline, width: CsBorderWidth.itemSelected),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fgColor),
            child: Row(
              spacing: CsSpace.xs,
              children: [
                if (lead != null) lead else if (inset) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: cs.body.copyWith(color: fgColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: cs.text(
                            CsTypeScale.bodyS,
                            color: disabled ? CsColor.textDropdownItemDisabled : CsColor.textDropdownItemSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: cs.text(CsTypeScale.bodyS, color: CsColor.textDropdownItemSecondary),
                  ),
                ?trailing,
              ],
            ),
          ),
        );
      },
    );
    if (onHover == null) return row;
    return MouseRegion(onEnter: (_) => onHover!(true), onExit: (_) => onHover!(false), child: row);
  }
}

/// A 1px `color-border-dropdown-group` divider between groups of rows.
class CsMenuSeparator extends StatelessWidget {
  const CsMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CsSpace.xxs),
    child: SizedBox(height: 1, child: ColoredBox(color: context.cs.colors.borderDropdownGroup)),
  );
}

/// The heading of a group of options: bold `color-text-dropdown-group-label`
/// text, as Cloudscape draws option group labels.
class CsMenuGroupLabel extends StatelessWidget {
  const CsMenuGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: CsSpace.fieldHorizontal, vertical: CsSpace.xs),
      child: Text(
        text,
        style: context.cs.text(CsTypeScale.bodyM, weight: CsTypography.bold, color: CsColor.textDropdownGroupLabel),
      ),
    ),
  );
}
