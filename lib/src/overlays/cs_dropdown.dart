import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'cs_anchored_overlay.dart';
import 'cs_sheet.dart';

/// How a dropdown opens.
enum CsPresentation {
  /// An anchored dropdown on wide screens, a bottom sheet below Cloudscape's
  /// mobile breakpoint (688px).
  auto,

  /// Always an anchored dropdown.
  popover,

  /// Always a bottom sheet.
  sheet;

  /// Resolves [auto] for the current window.
  bool usesSheet(BuildContext context) => switch (this) {
    CsPresentation.auto => context.csIsNarrow,
    CsPresentation.popover => false,
    CsPresentation.sheet => true,
  };
}

/// Builds dropdown content. [inSheet] is true when it shows in a bottom
/// sheet, where content should fill the width and may add a title.
typedef CsDropdownBuilder = Widget Function(BuildContext context, bool inSheet);

/// The floating part of selects, multiselects, autosuggests, button
/// dropdowns and date pickers: Cloudscape's dropdown container (2px
/// `color-border-dropdown-container` border, 8px radius, `shadow-dropdown`),
/// at least as wide as its trigger, flipping above it when there is no room
/// below. On phones it opens as a bottom sheet instead.
///
/// It is controlled: set [open], and close it in [onDismiss] (outside tap,
/// Escape, or the sheet being swiped away). In a sheet, content that closes
/// on a pick calls `CsSheetScope.closeFrom(context)` as well.
///
/// ```dart
/// CsDropdown(
///   open: open,
///   onDismiss: () => setState(() => open = false),
///   contentBuilder: (context, inSheet) => CsMenuPanel(children: rows),
///   child: trigger,
/// )
/// ```
class CsDropdown extends StatefulWidget {
  const CsDropdown({
    super.key,
    required this.open,
    required this.child,
    required this.contentBuilder,
    this.onDismiss,
    this.presentation = CsPresentation.auto,
    this.matchTriggerWidth = true,
    this.align = CsAlign.start,
    this.preferredHeight = 300,
    this.trapFocus = false,
    this.sheetLabel,
    this.tapRegionGroupId,
  });

  final bool open;

  /// The trigger the dropdown attaches to.
  final Widget child;
  final CsDropdownBuilder contentBuilder;
  final VoidCallback? onDismiss;
  final CsPresentation presentation;

  /// Make the dropdown at least as wide as its trigger (Cloudscape default).
  final bool matchTriggerWidth;
  final CsAlign align;

  /// Room the dropdown would like below the trigger before flipping up.
  final double preferredHeight;

  /// Move focus into the dropdown (menus). Selects and autosuggests keep
  /// focus on their trigger and drive the highlight from it.
  final bool trapFocus;

  /// Accessible name of the sheet on phones.
  final String? sheetLabel;
  final Object? tapRegionGroupId;

  @override
  State<CsDropdown> createState() => _CsDropdownState();
}

class _CsDropdownState extends State<CsDropdown> {
  bool _sheetShowing = false;

  @override
  void didUpdateWidget(CsDropdown old) {
    super.didUpdateWidget(old);
    _maybeOpenSheet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeOpenSheet();
  }

  void _maybeOpenSheet() {
    if (!widget.open || _sheetShowing || !widget.presentation.usesSheet(context)) return;
    _sheetShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showCsSheet<void>(
        context: context,
        semanticLabel: widget.sheetLabel,
        builder: (context) => SafeArea(top: false, child: widget.contentBuilder(context, true)),
      );
      _sheetShowing = false;
      if (mounted && widget.open) widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.presentation.usesSheet(context);
    // On phones the trigger stays in place and the content opens in a sheet
    // (see _maybeOpenSheet). Content closes the sheet after a pick with
    // `CsSheetScope.closeFrom(context)`.
    if (sheet) return widget.child;
    return CsAnchoredOverlay(
      open: widget.open,
      onDismiss: widget.onDismiss,
      side: CsSide.bottom,
      align: widget.align,
      sideOffset: CsSpace.xxs,
      preferredExtent: widget.preferredHeight,
      matchAnchorWidth: widget.matchTriggerWidth,
      trapFocus: widget.trapFocus,
      focusPopupWhenUnfocused: widget.trapFocus,
      tapRegionGroupId: widget.tapRegionGroupId,
      overlayBuilder: (context, placement) => widget.contentBuilder(context, false),
      child: widget.child,
    );
  }
}
