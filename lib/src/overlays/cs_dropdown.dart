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
/// Escape, or the sheet being swiped away). Setting [open] to false closes
/// the sheet too, and the sheet content rebuilds whenever the dropdown does,
/// so a multiselect can toggle options while its sheet stays up.
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
    this.dismissOnOutsideTap = true,
  });

  /// Shows the dropdown (or the sheet on phones) while true.
  final bool open;

  /// The trigger the dropdown attaches to.
  final Widget child;

  /// Builds the content; called again whenever the dropdown rebuilds.
  final CsDropdownBuilder contentBuilder;

  /// Outside tap, Escape, or the sheet swiped away. Set [open] to false.
  final VoidCallback? onDismiss;

  /// Anchored dropdown, bottom sheet, or [CsPresentation.auto] (sheet at or
  /// below 688px).
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

  /// False keeps an anchored dropdown open on outside taps (content with
  /// its own nested dropdowns, such as a filter editor); Escape still closes.
  final bool dismissOnOutsideTap;

  @override
  State<CsDropdown> createState() => _CsDropdownState();
}

class _CsDropdownState extends State<CsDropdown> {
  bool _sheetShowing = false;
  BuildContext? _sheetContext;
  // Ticks after the dropdown rebuilds so sheet content, which lives in its
  // own route, rebuilds with the owner's latest state.
  final _SheetRefresh _refresh = _SheetRefresh();

  @override
  void didUpdateWidget(CsDropdown old) {
    super.didUpdateWidget(old);
    if (_sheetShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sheetShowing) return;
        final sheet = _sheetContext;
        // Controlled: the owner closed the dropdown (a pick), so close the sheet.
        if (!widget.open && sheet != null && sheet.mounted) {
          CsSheetScope.closeFrom(sheet);
        } else {
          _refresh.tick();
        }
      });
    }
    _maybeOpenSheet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeOpenSheet();
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  void _maybeOpenSheet() {
    if (!widget.open || _sheetShowing || !widget.presentation.usesSheet(context)) return;
    _sheetShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!widget.open) {
        _sheetShowing = false;
        return;
      }
      await showCsSheet<void>(
        context: context,
        semanticLabel: widget.sheetLabel,
        builder: (sheetContext) {
          _sheetContext = sheetContext;
          return ListenableBuilder(
            listenable: _refresh,
            builder: (context, _) => SafeArea(top: false, child: widget.contentBuilder(context, true)),
          );
        },
      );
      _sheetShowing = false;
      _sheetContext = null;
      if (mounted && widget.open) widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.presentation.usesSheet(context);
    // On phones the trigger stays in place and the content opens in a sheet
    // (see _maybeOpenSheet); setting `open` to false closes it.
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
      dismissOnOutsideTap: widget.dismissOnOutsideTap,
      overlayBuilder: (context, placement) => widget.contentBuilder(context, false),
      child: widget.child,
    );
  }
}

class _SheetRefresh extends ChangeNotifier {
  void tick() => notifyListeners();
}
