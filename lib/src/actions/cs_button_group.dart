import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../icons/cs_icon_data.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_tooltip.dart';
import '../status/cs_status_indicator.dart';
import '../theme/theme.dart';
import 'cs_button_dropdown.dart';
import 'cs_toggle_button.dart';

/// An entry in [CsButtonGroup.items] (Cloudscape `ItemOrGroup`).
sealed class CsButtonGroupItemOrGroup {
  const CsButtonGroupItemOrGroup();
}

/// A button in a [CsButtonGroup] (Cloudscape `Item`).
sealed class CsButtonGroupItem extends CsButtonGroupItemOrGroup {
  const CsButtonGroupItem({required this.id, required this.text});

  /// Reported in [CsButtonGroupItemClickDetails.id].
  final String id;

  /// Accessible name and tooltip.
  final String text;
}

/// An icon button (Cloudscape `icon-button`).
class CsButtonGroupIconButton extends CsButtonGroupItem {
  const CsButtonGroupIconButton({
    required super.id,
    required super.text,
    this.icon,
    this.iconWidget,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
    this.popoverFeedback,
  });

  final CsIconData? icon;
  final Widget? iconWidget;
  final bool disabled;
  final String? disabledReason;
  final bool loading;
  final String? loadingText;

  /// Shown briefly in place of the tooltip after a click, such as "Copied".
  final String? popoverFeedback;
}

/// An icon toggle button (Cloudscape `icon-toggle-button`).
class CsButtonGroupIconToggleButton extends CsButtonGroupItem {
  const CsButtonGroupIconToggleButton({
    required super.id,
    required super.text,
    required this.pressed,
    this.icon,
    this.pressedIcon,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
    this.popoverFeedback,
    this.pressedPopoverFeedback,
  });

  final bool pressed;
  final CsIconData? icon;
  final CsIconData? pressedIcon;
  final bool disabled;
  final String? disabledReason;
  final bool loading;
  final String? loadingText;

  /// Feedback after turning it off.
  final String? popoverFeedback;

  /// Feedback after turning it on.
  final String? pressedPopoverFeedback;
}

/// An icon button that opens a menu (Cloudscape `menu-dropdown`), for
/// overflow actions.
class CsButtonGroupMenuDropdown extends CsButtonGroupItem {
  const CsButtonGroupMenuDropdown({
    required super.id,
    required super.text,
    required this.items,
    this.icon,
    this.disabled = false,
    this.disabledReason,
    this.loading = false,
    this.loadingText,
  });

  final List<CsButtonDropdownItemOrGroup> items;

  /// Defaults to an ellipsis.
  final CsIconData? icon;
  final bool disabled;
  final String? disabledReason;
  final bool loading;
  final String? loadingText;
}

/// A copy button (Cloudscape `icon-copy-to-clipboard`).
class CsButtonGroupCopyToClipboard extends CsButtonGroupItem {
  const CsButtonGroupCopyToClipboard({
    required super.id,
    required super.text,
    required this.textToCopy,
    required this.copySuccessText,
    required this.copyErrorText,
    this.disabled = false,
    this.disabledReason,
  });

  final String textToCopy;
  final String copySuccessText;
  final String copyErrorText;
  final bool disabled;
  final String? disabledReason;
}

/// A labelled set of items, separated from its neighbors by a divider
/// (Cloudscape `group`).
class CsButtonGroupGroup extends CsButtonGroupItemOrGroup {
  const CsButtonGroupGroup({required this.text, required this.items});

  /// Accessible name of the group.
  final String text;
  final List<CsButtonGroupItem> items;
}

/// What a click reports (Cloudscape `ItemClickDetails`).
@immutable
class CsButtonGroupItemClickDetails {
  const CsButtonGroupItemClickDetails({required this.id, this.pressed, this.checked});

  /// The item id, or the menu item id for a menu dropdown.
  final String id;

  /// The next pressed state of a toggle.
  final bool? pressed;

  /// The next checked state of a menu checkbox item.
  final bool? checked;
}

/// Cloudscape's `ButtonGroup`: a compact row of icon actions, such as the
/// feedback, copy and more buttons under a chat message.
///
/// ```dart
/// CsButtonGroup(
///   ariaLabel: 'Message actions',
///   items: [
///     CsButtonGroupGroup(text: 'Vote', items: [
///       CsButtonGroupIconToggleButton(id: 'like', text: 'Like', icon: CsIcons.thumbsUp,
///           pressedIcon: CsIcons.thumbsUpFilled, pressed: liked, pressedPopoverFeedback: 'Liked'),
///     ]),
///     const CsButtonGroupCopyToClipboard(id: 'copy', text: 'Copy', textToCopy: 'i-0abc123',
///         copySuccessText: 'Copied', copyErrorText: 'Failed to copy'),
///     const CsButtonGroupMenuDropdown(id: 'more', text: 'More actions', items: [
///       CsButtonDropdownItem(id: 'share', text: 'Share'),
///     ]),
///   ],
///   onItemClick: (d) => handle(d),
/// )
/// ```
///
/// Each button shows its [CsButtonGroupItem.text] in a tooltip; after a
/// click, the item's feedback (or the copy result) shows in its place for a
/// moment. Groups are separated by a divider; rows wrap on narrow screens.
class CsButtonGroup extends StatelessWidget {
  const CsButtonGroup({
    super.key,
    required this.items,
    this.ariaLabel,
    this.onItemClick,
    this.onCopySuccess,
    this.onCopyFailure,
  });

  final List<CsButtonGroupItemOrGroup> items;

  /// Accessible name of the whole group.
  final String? ariaLabel;
  final ValueChanged<CsButtonGroupItemClickDetails>? onItemClick;

  /// Called with the item id after a copy.
  final ValueChanged<String>? onCopySuccess;
  final ValueChanged<String>? onCopyFailure;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      switch (entry) {
        case CsButtonGroupGroup():
          if (children.isNotEmpty) children.add(const _Divider());
          children.add(
            Semantics(
              container: true,
              label: entry.text,
              explicitChildNodes: true,
              child: Wrap(
                spacing: cs.space.scaledXs,
                runSpacing: cs.space.scaledXs,
                children: [for (final item in entry.items) _ItemButton(item: item, group: this)],
              ),
            ),
          );
          if (i < items.length - 1) children.add(const _Divider());
        case CsButtonGroupItem():
          children.add(_ItemButton(item: entry, group: this));
      }
    }
    // Drop doubled dividers between adjacent groups.
    final out = <Widget>[];
    for (final c in children) {
      if (c is _Divider && (out.isEmpty || out.last is _Divider)) continue;
      out.add(c);
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: ariaLabel,
      child: Wrap(
        spacing: cs.space.scaledXs,
        runSpacing: cs.space.scaledXs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: out,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    // `.divider { margin-block: space-static-xs }`
    padding: const EdgeInsets.symmetric(vertical: CsSpace.staticXs),
    child: SizedBox(width: 1, height: 16, child: ColoredBox(color: context.cs.colors.borderDividerDefault)),
  );
}

class _ItemButton extends StatefulWidget {
  const _ItemButton({required this.item, required this.group});

  final CsButtonGroupItem item;
  final CsButtonGroup group;

  @override
  State<_ItemButton> createState() => _ItemButtonState();
}

class _ItemButtonState extends State<_ItemButton> {
  String? _feedback;
  CsStatusType? _feedbackStatus;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showFeedback(String? text, {CsStatusType? status}) {
    if (text == null) return;
    _timer?.cancel();
    setState(() {
      _feedback = text;
      _feedbackStatus = status;
    });
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  Future<void> _copy(CsButtonGroupCopyToClipboard item) async {
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: item.textToCopy));
    } on Object {
      ok = false;
    }
    if (!mounted) return;
    _showFeedback(
      ok ? item.copySuccessText : item.copyErrorText,
      status: ok ? CsStatusType.success : CsStatusType.error,
    );
    if (ok) {
      widget.group.onCopySuccess?.call(item.id);
    } else {
      widget.group.onCopyFailure?.call(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onClick = widget.group.onItemClick;
    Widget button;
    String? disabledReason;
    var disabled = false;
    switch (item) {
      case CsButtonGroupIconButton():
        disabled = item.disabled;
        disabledReason = item.disabledReason;
        button = CsButton(
          icon: item.icon,
          iconWidget: item.iconWidget,
          variant: CsButtonVariant.icon,
          semanticLabel: item.text,
          disabled: item.disabled,
          loading: item.loading,
          loadingText: item.loadingText,
          onPress: () {
            onClick?.call(CsButtonGroupItemClickDetails(id: item.id));
            _showFeedback(item.popoverFeedback);
          },
        );
      case CsButtonGroupIconToggleButton():
        disabled = item.disabled;
        disabledReason = item.disabledReason;
        button = CsToggleButton(
          variant: CsToggleButtonVariant.icon,
          pressed: item.pressed,
          icon: item.icon,
          pressedIcon: item.pressedIcon,
          ariaLabel: item.text,
          disabled: item.disabled,
          loading: item.loading,
          loadingText: item.loadingText,
          onChange: (next) {
            onClick?.call(CsButtonGroupItemClickDetails(id: item.id, pressed: next));
            _showFeedback(next ? item.pressedPopoverFeedback : item.popoverFeedback);
          },
        );
        // The toggle draws its own label tooltip.
        if (!item.disabled && _feedback == null) return button;
      case CsButtonGroupMenuDropdown():
        disabled = item.disabled;
        disabledReason = item.disabledReason;
        button = CsButtonDropdown(
          variant: CsButtonDropdownVariant.icon,
          icon: item.icon,
          ariaLabel: item.text,
          items: item.items,
          disabled: item.disabled,
          loading: item.loading,
          loadingText: item.loadingText,
          onItemClick: (d) => onClick?.call(CsButtonGroupItemClickDetails(id: d.id, checked: d.checked)),
          onItemFollow: (d) => onClick?.call(CsButtonGroupItemClickDetails(id: d.id)),
        );
      case CsButtonGroupCopyToClipboard():
        disabled = item.disabled;
        disabledReason = item.disabledReason;
        button = CsButton(
          icon: CsIcons.copy,
          variant: CsButtonVariant.icon,
          semanticLabel: item.text,
          disabled: item.disabled,
          onPress: () => _copy(item),
        );
    }

    final feedback = _feedback;
    if (feedback != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned.fill(
            child: IgnorePointer(
              child: CsAnchoredOverlay(
                open: true,
                side: CsSide.top,
                dismissOnOutsideTap: false,
                focusPopupWhenUnfocused: false,
                overlayBuilder: (context, placement) => _Feedback(text: feedback, status: _feedbackStatus),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
    }
    return CsTooltip(content: disabled && disabledReason != null ? disabledReason : item.text, child: button);
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.text, this.status});

  final String text;
  final CsStatusType? status;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.popover));
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CsSpace.s, vertical: CsSpace.xxs),
        decoration: BoxDecoration(
          color: cs.colors.backgroundPopover,
          borderRadius: radius,
          boxShadow: cs.shadows.popover,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: cs.colors.borderPopover, width: CsBorderWidth.popover),
        ),
        child: status == null ? Text(text, style: cs.body) : CsStatusIndicator(type: status!, text: text),
      ),
    );
  }
}
