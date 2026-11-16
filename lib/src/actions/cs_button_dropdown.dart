import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../feedback/cs_spinner.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_dropdown.dart';
import '../overlays/cs_menu_parts.dart';
import '../overlays/cs_tooltip.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// An entry in [CsButtonDropdown.items]: an action, a checkbox item or a
/// group (Cloudscape `ItemOrGroup`).
sealed class CsButtonDropdownItemOrGroup {
  const CsButtonDropdownItemOrGroup();
}

/// An action in a button dropdown (Cloudscape `Item`).
@immutable
class CsButtonDropdownItem extends CsButtonDropdownItemOrGroup {
  const CsButtonDropdownItem({
    required this.id,
    required this.text,
    this.secondaryText,
    this.description,
    this.labelTag,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.disabledReason,
    this.external = false,
    this.externalIconAriaLabel,
    this.isLink = false,
    this.ariaLabel,
  });

  /// Reported in [CsButtonDropdownItemClickDetails.id].
  final String id;
  final String text;

  /// Small text under the item text.
  final String? secondaryText;

  /// Shown in a tooltip (Cloudscape `description`).
  final String? description;

  /// Short text at the end of the row, such as a shortcut.
  final String? labelTag;
  final CsIconData? icon;
  final Widget? iconWidget;
  final bool disabled;

  /// Why the item is disabled, shown in a tooltip.
  final String? disabledReason;

  /// Opens outside the app: adds an external icon and calls
  /// [CsButtonDropdown.onItemFollow].
  final bool external;
  final String? externalIconAriaLabel;

  /// Navigates (Cloudscape `href`): announced as a link and reported through
  /// [CsButtonDropdown.onItemFollow].
  final bool isLink;
  final String? ariaLabel;
}

/// A checkbox item (Cloudscape `CheckboxItem`): shows a check while
/// [checked] and reports the next state on click.
@immutable
class CsButtonDropdownCheckboxItem extends CsButtonDropdownItemOrGroup {
  const CsButtonDropdownCheckboxItem({
    required this.id,
    required this.text,
    required this.checked,
    this.secondaryText,
    this.labelTag,
    this.icon,
    this.disabled = false,
    this.disabledReason,
    this.ariaLabel,
  });

  final String id;
  final String text;
  final bool checked;
  final String? secondaryText;
  final String? labelTag;
  final CsIconData? icon;
  final bool disabled;
  final String? disabledReason;
  final String? ariaLabel;
}

/// A group of items with a heading (Cloudscape `ItemGroup`). With
/// [CsButtonDropdown.expandableGroups] (or [expandable]) it collapses behind
/// its heading.
@immutable
class CsButtonDropdownGroup extends CsButtonDropdownItemOrGroup {
  const CsButtonDropdownGroup({
    required this.items,
    this.text,
    this.id,
    this.icon,
    this.disabled = false,
    this.disabledReason,
    this.expandable,
  });

  final List<CsButtonDropdownItemOrGroup> items;
  final String? text;
  final String? id;
  final CsIconData? icon;
  final bool disabled;
  final String? disabledReason;

  /// Overrides [CsButtonDropdown.expandableGroups] for this group.
  final bool? expandable;
}

/// What a click reports (Cloudscape `ItemClickDetails`).
@immutable
class CsButtonDropdownItemClickDetails {
  const CsButtonDropdownItemClickDetails({required this.id, this.checked, this.external = false});

  final String id;

  /// The next checked state of a checkbox item.
  final bool? checked;
  final bool external;
}

/// Button dropdown variants (Cloudscape `variant`).
enum CsButtonDropdownVariant { normal, primary, icon, inlineIcon }

/// The main action of a split button (Cloudscape `mainAction`).
@immutable
class CsButtonDropdownMainAction {
  const CsButtonDropdownMainAction({
    required this.text,
    this.onPress,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
    this.icon,
    this.external = false,
    this.ariaLabel,
  });

  final String text;
  final VoidCallback? onPress;
  final bool disabled;
  final String? disabledReason;
  final bool loading;
  final String? loadingText;
  final CsIconData? icon;
  final bool external;
  final String? ariaLabel;
}

/// Cloudscape's `ButtonDropdown`: a button that opens a menu of actions.
///
/// ```dart
/// CsButtonDropdown(
///   text: 'Actions',
///   items: const [
///     CsButtonDropdownItem(id: 'start', text: 'Start instance'),
///     CsButtonDropdownItem(id: 'stop', text: 'Stop instance', disabled: true, disabledReason: 'Already stopped'),
///     CsButtonDropdownGroup(text: 'Networking', items: [
///       CsButtonDropdownItem(id: 'ip', text: 'Associate IP address'),
///     ]),
///     CsButtonDropdownItem(id: 'docs', text: 'Documentation', external: true),
///   ],
///   onItemClick: (d) => handle(d.id),
/// )
/// ```
///
/// * Variants: normal and primary buttons with a caret, and icon and inline
///   icon buttons (an ellipsis by default). With [mainAction] it is a split
///   button: the main action and a caret that opens the menu.
/// * Items can be grouped, carry checkboxes, show a disabled reason, open
///   external links, and nest in expandable groups ([expandableGroups]),
///   which expand in place.
/// * The menu opens under the trigger (a bottom sheet on phones), takes
///   focus, and supports Up and Down, Home and End, Enter and Escape. Focus
///   returns to the trigger when it closes.
class CsButtonDropdown extends StatefulWidget {
  const CsButtonDropdown({
    super.key,
    required this.items,
    this.text,
    this.variant = CsButtonDropdownVariant.normal,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
    this.expandableGroups = false,
    this.ariaLabel,
    this.onItemClick,
    this.onItemFollow,
    this.mainAction,
    this.fullWidth = false,
    this.filteringType = false,
    this.filteringPlaceholder,
    this.filteringAriaLabel,
    this.noMatch,
    this.presentation = CsPresentation.auto,
  });

  final List<CsButtonDropdownItemOrGroup> items;

  /// Trigger text (Cloudscape `children`). Ignored by the icon variants.
  final String? text;
  final CsButtonDropdownVariant variant;

  /// Icon of the icon variants (defaults to an ellipsis) or before the text.
  final CsIconData? icon;
  final Widget? iconWidget;
  final bool disabled;
  final String? disabledReason;

  /// Shows a spinner in the trigger and blocks opening.
  final bool loading;
  final String? loadingText;

  /// Groups collapse behind their heading.
  final bool expandableGroups;

  /// Accessible name, required for the icon variants.
  final String? ariaLabel;

  /// Called when an action or checkbox item is clicked.
  final ValueChanged<CsButtonDropdownItemClickDetails>? onItemClick;

  /// Called when a link or external item is followed.
  final ValueChanged<CsButtonDropdownItemClickDetails>? onItemFollow;

  /// Makes it a split button.
  final CsButtonDropdownMainAction? mainAction;
  final bool fullWidth;

  /// Adds a filter input above the items (Cloudscape `filteringType: 'auto'`).
  final bool filteringType;
  final String? filteringPlaceholder;
  final String? filteringAriaLabel;

  /// Shown when the filter matches nothing.
  final Widget? noMatch;

  /// Anchored menu or bottom sheet. [CsPresentation.auto] uses a sheet at or
  /// below 688px.
  final CsPresentation presentation;

  @override
  State<CsButtonDropdown> createState() => _CsButtonDropdownState();
}

class _CsButtonDropdownState extends State<CsButtonDropdown> {
  bool _open = false;
  final FocusNode _trigger = FocusNode(debugLabel: 'ButtonDropdown trigger');

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  bool get _blocked => widget.disabled || widget.loading;

  void _toggle() {
    if (_blocked) return;
    setState(() => _open = !_open);
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _trigger.requestFocus();
  }

  Widget _buildTrigger(BuildContext context) {
    final strings = context.csStrings;
    switch (widget.variant) {
      case CsButtonDropdownVariant.icon:
      case CsButtonDropdownVariant.inlineIcon:
        return CsButton(
          icon: widget.icon ?? CsIcons.ellipsis,
          iconWidget: widget.iconWidget,
          variant: widget.variant == CsButtonDropdownVariant.icon ? CsButtonVariant.icon : CsButtonVariant.inlineIcon,
          semanticLabel: widget.ariaLabel ?? widget.text ?? strings.moreActions,
          disabled: widget.disabled,
          disabledReason: widget.disabledReason,
          loading: widget.loading,
          loadingText: widget.loadingText,
          expanded: _open,
          focusNode: _trigger,
          onPress: _toggle,
        );
      case CsButtonDropdownVariant.normal:
      case CsButtonDropdownVariant.primary:
        if (widget.mainAction != null) return _SplitTrigger(state: this);
        return CsButton(
          text: widget.text,
          icon: CsIcons.caretDownFilled,
          iconAlign: CsButtonIconAlign.right,
          variant: widget.variant == CsButtonDropdownVariant.primary ? CsButtonVariant.primary : CsButtonVariant.normal,
          semanticLabel: widget.ariaLabel,
          disabled: widget.disabled,
          disabledReason: widget.disabledReason,
          loading: widget.loading,
          loadingText: widget.loadingText,
          fullWidth: widget.fullWidth,
          expanded: _open,
          focusNode: _trigger,
          onPress: _toggle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CsDropdown(
      open: _open,
      onDismiss: _close,
      trapFocus: true,
      matchTriggerWidth: widget.fullWidth,
      align: widget.variant == CsButtonDropdownVariant.icon || widget.variant == CsButtonDropdownVariant.inlineIcon
          ? CsAlign.end
          : CsAlign.start,
      presentation: widget.presentation,
      sheetLabel: widget.ariaLabel ?? widget.text,
      contentBuilder: (context, inSheet) => CsButtonDropdownMenu(
        items: widget.items,
        expandableGroups: widget.expandableGroups,
        inSheet: inSheet,
        filtering: widget.filteringType,
        filteringPlaceholder: widget.filteringPlaceholder,
        filteringAriaLabel: widget.filteringAriaLabel,
        noMatch: widget.noMatch,
        onActivate: (d, follow) {
          setState(() => _open = false);
          _trigger.requestFocus();
          if (follow) {
            widget.onItemFollow?.call(d);
          } else {
            widget.onItemClick?.call(d);
          }
        },
      ),
      child: _buildTrigger(context),
    );
  }
}

/// A split button: the main action and a caret, joined in one pill with a
/// divider (Cloudscape `mainAction`).
class _SplitTrigger extends StatelessWidget {
  const _SplitTrigger({required this.state});

  final _CsButtonDropdownState state;

  @override
  Widget build(BuildContext context) {
    final w = state.widget;
    final main = w.mainAction!;
    final primary = w.variant == CsButtonDropdownVariant.primary;
    final c = context.cs.colors;
    final divider = primary ? c.textButtonPrimaryDefault : c.borderButtonNormalDefault;
    Widget mainButton = _SplitSegment(
      primary: primary,
      start: true,
      disabled: w.disabled || main.disabled,
      loading: main.loading,
      semanticLabel: main.loading && main.loadingText != null ? main.loadingText : (main.ariaLabel ?? main.text),
      onPress: main.onPress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CsSpace.xxs,
        children: [
          if (main.loading) const CsSpinner(semanticLabel: '') else if (main.icon != null) CsIcon(main.icon!),
          Flexible(child: Text(main.text)),
          if (main.external) const CsIcon(CsIcons.external),
        ],
      ),
    );
    if ((w.disabled || main.disabled) && main.disabledReason != null) {
      mainButton = CsTooltip(content: main.disabledReason!, child: mainButton);
    }
    final outline = primary
        ? (w.disabled ? c.borderButtonPrimaryDisabled : c.borderButtonPrimaryDefault)
        : (w.disabled ? c.borderButtonNormalDisabled : c.borderButtonNormalDefault);
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.button));
    // One pill outline around both segments, with a divider between them.
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: outline, width: CsBorderWidth.button),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(child: mainButton),
            SizedBox(width: 1, child: ColoredBox(color: w.disabled ? c.borderButtonNormalDisabled : divider)),
            _SplitSegment(
              primary: primary,
              start: false,
              disabled: w.disabled,
              loading: w.loading,
              focusNode: state._trigger,
              expanded: state._open,
              semanticLabel: w.ariaLabel ?? context.csStrings.moreActions,
              onPress: state._toggle,
              child: const CsIcon(CsIcons.caretDownFilled),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitSegment extends StatelessWidget {
  const _SplitSegment({
    required this.primary,
    required this.start,
    required this.child,
    required this.disabled,
    this.loading = false,
    this.onPress,
    this.focusNode,
    this.expanded,
    this.semanticLabel,
  });

  final bool primary;
  final bool start;
  final Widget child;
  final bool disabled;
  final bool loading;
  final VoidCallback? onPress;
  final FocusNode? focusNode;
  final bool? expanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    const r = Radius.circular(CsBorderRadius.button);
    final radius = BorderRadiusDirectional.horizontal(
      start: start ? r : Radius.zero,
      end: start ? Radius.zero : r,
    ).resolve(Directionality.of(context));
    return CsPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      loading: loading,
      focusNode: focusNode,
      expanded: expanded,
      semanticLabel: semanticLabel,
      excludeChildSemantics: semanticLabel != null,
      borderRadius: radius,
      builder: (context, state) {
        final (Color bg, Color _, Color fg) = switch ((primary, disabled, state.pressed, state.hovered)) {
          (true, true, _, _) => (
            c.backgroundButtonPrimaryDisabled,
            c.borderButtonPrimaryDisabled,
            c.textButtonPrimaryDisabled,
          ),
          (true, false, true, _) => (
            c.backgroundButtonPrimaryActive,
            c.borderButtonPrimaryActive,
            c.textButtonPrimaryActive,
          ),
          (true, false, false, true) => (
            c.backgroundButtonPrimaryHover,
            c.borderButtonPrimaryHover,
            c.textButtonPrimaryHover,
          ),
          (true, false, false, false) => (
            c.backgroundButtonPrimaryDefault,
            c.borderButtonPrimaryDefault,
            c.textButtonPrimaryDefault,
          ),
          (false, true, _, _) => (
            c.backgroundButtonNormalDisabled,
            c.borderButtonNormalDisabled,
            c.textButtonNormalDisabled,
          ),
          (false, false, true, _) => (
            c.backgroundButtonNormalActive,
            c.borderButtonNormalActive,
            c.textButtonNormalActive,
          ),
          (false, false, false, true) => (
            c.backgroundButtonNormalHover,
            c.borderButtonNormalHover,
            c.textButtonNormalHover,
          ),
          (false, false, false, false) => (
            c.backgroundButtonNormalDefault,
            c.borderButtonNormalDefault,
            c.textButtonNormalDefault,
          ),
        };
        final d = cs.space;
        return Container(
          constraints: BoxConstraints(minHeight: d.sizeVerticalInput),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: start ? d.buttonHorizontal : d.buttonIconOnlyHorizontal,
            vertical: d.buttonVertical,
          ).add(const EdgeInsets.all(CsBorderWidth.button)),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: DefaultTextStyle.merge(
            style: cs.text(CsTypeScale.bodyM, weight: CsTypography.bold).copyWith(color: fg),
            child: IconTheme(
              data: IconThemeData(color: fg),
              child: Center(widthFactor: 1, heightFactor: 1, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// The menu of a [CsButtonDropdown] (also used by the menu dropdown of a
/// button group): rows for actions, checks for checkbox items, headings for
/// groups, and in-place expansion for expandable groups.
class CsButtonDropdownMenu extends StatefulWidget {
  const CsButtonDropdownMenu({
    super.key,
    required this.items,
    required this.onActivate,
    this.expandableGroups = false,
    this.inSheet = false,
    this.filtering = false,
    this.filteringPlaceholder,
    this.filteringAriaLabel,
    this.noMatch,
  });

  final List<CsButtonDropdownItemOrGroup> items;

  /// Called with the click details and whether it is a follow (link or external).
  final void Function(CsButtonDropdownItemClickDetails details, bool follow) onActivate;
  final bool expandableGroups;
  final bool inSheet;
  final bool filtering;
  final String? filteringPlaceholder;
  final String? filteringAriaLabel;
  final Widget? noMatch;

  @override
  State<CsButtonDropdownMenu> createState() => _CsButtonDropdownMenuState();
}

class _CsButtonDropdownMenuState extends State<CsButtonDropdownMenu> {
  final Set<Object> _expanded = {};
  String _filter = '';
  bool _focusedFirst = false;

  bool _matches(String text) => _filter.isEmpty || text.toLowerCase().contains(_filter.toLowerCase());

  List<Widget> _rows(List<CsButtonDropdownItemOrGroup> items, int depth) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      switch (item) {
        case CsButtonDropdownItem():
          if (!_matches(item.text)) continue;
          rows.add(_actionRow(item, depth));
        case CsButtonDropdownCheckboxItem():
          if (!_matches(item.text)) continue;
          rows.add(_checkboxRow(item, depth));
        case CsButtonDropdownGroup():
          final children = _rows(item.items, depth + 1);
          if (children.isEmpty && _filter.isNotEmpty) continue;
          final expandable = (item.expandable ?? widget.expandableGroups) && _filter.isEmpty;
          final key = item.id ?? item;
          if (expandable) {
            final open = _expanded.contains(key);
            rows.add(
              _withReason(
                item.disabled ? item.disabledReason : null,
                CsMenuRow(
                  label: item.text ?? '',
                  icon: item.icon,
                  leading: depth > 0 && item.icon == null ? SizedBox(width: depth * CsSpace.m) : null,
                  disabled: item.disabled,
                  expanded: open,
                  autofocus: _autofocus(item.disabled),
                  trailing: AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: CsMotion.duration(context, CsDurations.rotate180),
                    child: const CsIcon(CsIcons.caretDownFilled),
                  ),
                  onPress: () => setState(() => open ? _expanded.remove(key) : _expanded.add(key)),
                ),
              ),
            );
            if (open) rows.addAll(children);
          } else {
            if (rows.isNotEmpty) rows.add(const CsMenuSeparator());
            if (item.text != null) {
              rows.add(
                Padding(
                  padding: EdgeInsetsDirectional.only(start: depth * CsSpace.m),
                  child: CsMenuGroupLabel(item.text!),
                ),
              );
            }
            rows.addAll(children);
            if (i < items.length - 1) rows.add(const CsMenuSeparator());
          }
      }
    }
    // Drop doubled separators between adjacent groups.
    final out = <Widget>[];
    for (final r in rows) {
      if (r is CsMenuSeparator && (out.isEmpty || out.last is CsMenuSeparator)) continue;
      out.add(r);
    }
    if (out.isNotEmpty && out.last is CsMenuSeparator) out.removeLast();
    return out;
  }

  bool _autofocus(bool disabled) {
    if (_focusedFirst || disabled || widget.filtering) return false;
    _focusedFirst = true;
    return true;
  }

  Widget _withReason(String? reason, Widget row) =>
      reason == null ? row : CsTooltip(content: reason, side: CsSide.right, child: row);

  Widget _indent(int depth) => SizedBox(width: depth * CsSpace.m);

  Widget _actionRow(CsButtonDropdownItem item, int depth) {
    final cs = context.cs;
    final follow = item.external || item.isLink;
    Widget? lead;
    if (item.iconWidget != null) {
      lead = SizedBox.square(dimension: 16, child: item.iconWidget);
    } else if (item.icon != null) {
      lead = CsIcon(item.icon!);
    }
    if (depth > 0) lead = Row(mainAxisSize: MainAxisSize.min, children: [_indent(depth), ?lead]);
    return _withReason(
      item.disabled ? (item.disabledReason ?? item.description) : item.description,
      CsMenuRow(
        label: item.text,
        leading: lead,
        description: item.secondaryText,
        disabled: item.disabled,
        isLink: follow,
        autofocus: _autofocus(item.disabled),
        semanticLabel:
            item.ariaLabel ??
            (item.external
                ? '${item.text}, ${item.externalIconAriaLabel ?? context.csStrings.opensInNewWindow}'
                : null),
        // An empty Row with spacing reports a negative intrinsic width.
        trailing: item.labelTag == null && !item.external
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CsSpace.xs,
                children: [
                  if (item.labelTag != null)
                    Text(item.labelTag!, style: cs.text(CsTypeScale.bodyM, color: CsColor.textDropdownItemSecondary)),
                  if (item.external) const CsIcon(CsIcons.external),
                ],
              ),
        onPress: () =>
            widget.onActivate(CsButtonDropdownItemClickDetails(id: item.id, external: item.external), follow),
      ),
    );
  }

  Widget _checkboxRow(CsButtonDropdownCheckboxItem item, int depth) {
    final c = context.cs.colors;
    final lead = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CsSpace.xs,
      children: [
        if (depth > 0) _indent(depth),
        SizedBox.square(
          dimension: 16,
          child: item.checked
              ? CsIcon(CsIcons.check, dangerouslySetColor: item.disabled ? c.textDropdownItemDisabled : c.itemSelected)
              : null,
        ),
        if (item.icon != null) CsIcon(item.icon!),
      ],
    );
    return _withReason(
      item.disabled ? item.disabledReason : null,
      CsMenuRow(
        label: item.text,
        leading: lead,
        description: item.secondaryText,
        disabled: item.disabled,
        checked: item.checked,
        semanticLabel: item.ariaLabel,
        autofocus: _autofocus(item.disabled),
        trailing: item.labelTag == null ? null : Text(item.labelTag!),
        onPress: () => widget.onActivate(CsButtonDropdownItemClickDetails(id: item.id, checked: !item.checked), false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _focusedFirst = false;
    final rows = _rows(widget.items, 0);
    final children = <Widget>[
      if (widget.filtering)
        Padding(
          padding: const EdgeInsets.all(CsSpace.xs),
          child: CsInput(
            type: CsInputType.search,
            value: _filter,
            autoFocus: !widget.inSheet,
            placeholder: widget.filteringPlaceholder,
            ariaLabel: widget.filteringAriaLabel ?? widget.filteringPlaceholder,
            onChange: (v) => setState(() => _filter = v),
          ),
        ),
      ...rows,
      if (rows.isEmpty && widget.noMatch != null)
        Padding(padding: const EdgeInsets.all(CsSpace.s), child: widget.noMatch),
    ];
    if (widget.inSheet) {
      return CsMenuKeyboard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CsSpace.xs, vertical: CsSpace.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }
    return CsMenuPanel(maxHeight: 400, children: children);
  }
}
