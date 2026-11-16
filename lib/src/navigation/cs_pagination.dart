import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../overlays/cs_anchored_overlay.dart';
import '../overlays/cs_popup_surface.dart';
import '../system/cs_pressable.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';

/// How pages are shown (Cloudscape `pagesVariant`).
enum CsPaginationPagesVariant {
  /// Page number buttons, truncated with ellipses for long ranges.
  normal,

  /// "3 of 12" between the previous and next arrows ("3 of 12+" when open
  /// ended).
  compact,
}

/// Detail of [CsPagination.onNextPageClick] and
/// [CsPagination.onPreviousPageClick].
@immutable
class CsPaginationPageClickDetail {
  const CsPaginationPageClickDetail({required this.requestedPageIndex, required this.requestedPageAvailable});

  /// The page the arrow asked for (1-based).
  final int requestedPageIndex;

  /// False only for the next arrow of an open-ended pagination on its last
  /// known page: load more items, then raise `pagesCount`.
  final bool requestedPageAvailable;

  @override
  String toString() => 'CsPaginationPageClickDetail($requestedPageIndex, available: $requestedPageAvailable)';
}

/// Accessible labels of [CsPagination] (Cloudscape `ariaLabels`).
@immutable
class CsPaginationAriaLabels {
  const CsPaginationAriaLabels({
    this.nextPageLabel = 'Next page',
    this.previousPageLabel = 'Previous page',
    this.paginationLabel,
    this.pageLabel,
    this.jumpToPageButton = 'Jump to page',
  });

  final String nextPageLabel;
  final String previousPageLabel;

  /// Name of the whole group, to tell several paginations apart. Defaults to
  /// `CsStrings.pagination`.
  final String? paginationLabel;

  /// Label of each page button. Defaults to "Page N of all pages".
  final String Function(int pageNumber)? pageLabel;
  final String jumpToPageButton;

  String labelForPage(int page) => pageLabel?.call(page) ?? 'Page $page of all pages';
}

/// Copy for [CsPagination] (Cloudscape `i18nStrings`).
@immutable
class CsPaginationI18nStrings {
  const CsPaginationI18nStrings({
    this.jumpToPageInputLabel = 'Page',
    this.jumpToPageError = 'Page out of range. Showing last available page.',
    this.jumpToPageLoadingText = 'Loading',
    this.pagesCompactText,
  });

  final String jumpToPageInputLabel;
  final String jumpToPageError;
  final String jumpToPageLoadingText;

  /// Visible text of the compact variant. Defaults to "3 of 12" and
  /// "3 of 12+" when open ended.
  final String Function(int currentPage, int pagesCount, bool openEnd)? pagesCompactText;

  String compactText(int current, int count, bool openEnd) =>
      pagesCompactText?.call(current, count, openEnd) ?? '$current of $count${openEnd ? '+' : ''}';
}

/// The jump-to-page field (Cloudscape `jumpToPage`).
@immutable
class CsPaginationJumpToPage {
  const CsPaginationJumpToPage({this.loading = false});

  /// Shows a spinner on the jump button while you load the requested page.
  final bool loading;
}

/// The visible controls of a normal pagination, from Cloudscape's
/// `getPaginationState`: up to 7 page controls with the first and last page
/// always shown and dots for the gaps.
@immutable
class CsPaginationWindow {
  const CsPaginationWindow({
    required this.leftDots,
    required this.rightDots,
    required this.leftIndex,
    required this.rightIndex,
  });

  /// Computes the window around [currentPageIndex].
  factory CsPaginationWindow.of(int currentPageIndex, int pagesCount, {bool openEnd = false}) {
    const controls = 7;
    const leftDelta = controls ~/ 2;
    var rightDelta = leftDelta;
    const lowerLimit = 2;
    var upperLimit = pagesCount - 1;
    if (openEnd) {
      rightDelta++;
      upperLimit = pagesCount + 1;
    }
    var left = currentPageIndex - leftDelta;
    var right = currentPageIndex + rightDelta;
    if (left < lowerLimit) {
      right += lowerLimit - left;
      left = lowerLimit;
    }
    if (right > upperLimit) {
      left -= right - upperLimit;
      right = upperLimit;
    }
    if (left < 2) left = 2;
    if (right > upperLimit) right = upperLimit;
    final leftDots = left > 2;
    final rightDots = openEnd || right < upperLimit;
    if (leftDots) left++;
    if (rightDots) right--;
    return CsPaginationWindow(leftDots: leftDots, rightDots: rightDots, leftIndex: left, rightIndex: right);
  }

  final bool leftDots;
  final bool rightDots;

  /// First page number shown between the dots (inclusive).
  final int leftIndex;

  /// Last page number shown between the dots (inclusive).
  final int rightIndex;
}

/// Cloudscape's `Pagination`: moves through pages of a table or list.
///
/// ```dart
/// CsPagination(
///   currentPageIndex: page,
///   pagesCount: 12,
///   onChange: (next) => setState(() => page = next),
/// )
/// ```
///
/// Controlled: it shows [currentPageIndex] (1-based) and reports the page a
/// person picks through [onChange]. With [openEnd] the last page is
/// unknown: dots always follow the pages, the next arrow is never
/// disabled, and [onNextPageClick] reports `requestedPageAvailable: false`
/// on the last loaded page so you can fetch more.
///
/// Narrow layouts: when [pagesVariant] is null the normal page buttons are
/// used while they fit and the compact "3 of 12" form when they do not
/// (on phones, where every control needs a 44px touch target). Pass a
/// variant to fix it.
///
/// For [jumpToPage] errors, call [CsPaginationState.setError] through a
/// `GlobalKey<CsPaginationState>` (Cloudscape `ref.setError`).
class CsPagination extends StatefulWidget {
  const CsPagination({
    super.key,
    required this.currentPageIndex,
    required this.pagesCount,
    this.onChange,
    this.onNextPageClick,
    this.onPreviousPageClick,
    this.openEnd = false,
    this.disabled = false,
    this.pagesVariant,
    this.ariaLabels = const CsPaginationAriaLabels(),
    this.i18nStrings = const CsPaginationI18nStrings(),
    this.jumpToPage,
  }) : assert(pagesCount >= 0);

  /// The current page, starting at 1.
  final int currentPageIndex;

  /// Total number of pages (the number known so far when [openEnd]).
  final int pagesCount;

  /// Called with the page a person picks, from a page button, an arrow or
  /// the jump field.
  final ValueChanged<int>? onChange;
  final ValueChanged<CsPaginationPageClickDetail>? onNextPageClick;
  final ValueChanged<CsPaginationPageClickDetail>? onPreviousPageClick;

  /// The total is unknown: for lazy loading.
  final bool openEnd;

  /// Disables every control, for example while items load.
  final bool disabled;

  /// Normal or compact. Null picks normal when it fits and compact when not.
  final CsPaginationPagesVariant? pagesVariant;
  final CsPaginationAriaLabels ariaLabels;
  final CsPaginationI18nStrings i18nStrings;

  /// Adds a page number field and a jump button after the arrows.
  final CsPaginationJumpToPage? jumpToPage;

  @override
  State<CsPagination> createState() => CsPaginationState();
}

/// State of [CsPagination], reachable through a `GlobalKey` to show the jump
/// to page error.
class CsPaginationState extends State<CsPagination> {
  late String _jumpValue = '${widget.currentPageIndex}';
  bool _hasError = false;
  final FocusNode _jumpFocus = FocusNode(debugLabel: 'CsPagination jump');

  /// Shows (or clears) the jump to page error popover. It clears itself when
  /// the person types or navigates.
  void setError(bool hasError) {
    if (mounted) setState(() => _hasError = hasError);
  }

  @override
  void didUpdateWidget(CsPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    final finishedLoading = (oldWidget.jumpToPage?.loading ?? false) && !(widget.jumpToPage?.loading ?? false);
    if (finishedLoading || oldWidget.currentPageIndex != widget.currentPageIndex) {
      _jumpValue = '${widget.currentPageIndex}';
    }
  }

  @override
  void dispose() {
    _jumpFocus.dispose();
    super.dispose();
  }

  void _go(int page, {bool error = false}) {
    setState(() {
      _jumpValue = '$page';
      _hasError = error;
    });
    widget.onChange?.call(page);
  }

  void _previous() {
    final page = widget.currentPageIndex - 1;
    _go(page);
    widget.onPreviousPageClick?.call(
      CsPaginationPageClickDetail(requestedPageIndex: page, requestedPageAvailable: true),
    );
  }

  void _next() {
    final page = widget.currentPageIndex + 1;
    _go(page);
    widget.onNextPageClick?.call(
      CsPaginationPageClickDetail(
        requestedPageIndex: page,
        requestedPageAvailable: widget.currentPageIndex < widget.pagesCount,
      ),
    );
  }

  bool get _canJump {
    final n = int.tryParse(_jumpValue);
    return !widget.disabled && n != null && n != widget.currentPageIndex;
  }

  void _jump() {
    final requested = int.tryParse(_jumpValue);
    if (requested == null) return;
    final page = requested < 1 ? 1 : requested;
    if (widget.openEnd || page <= widget.pagesCount) {
      _go(page);
    } else {
      _go(widget.pagesCount, error: true);
    }
    _jumpFocus.requestFocus();
  }

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final labels = widget.ariaLabels;
    final current = widget.currentPageIndex;
    final count = widget.pagesCount;
    final disabled = widget.disabled;
    final prevDisabled = disabled || current <= 1;
    final nextDisabled = disabled || (!widget.openEnd && (count == 0 || current >= count));
    final window = CsPaginationWindow.of(current, count, openEnd: widget.openEnd);

    List<int?> pages() => [
      1,
      if (window.leftDots) null,
      for (var i = window.leftIndex; i <= window.rightIndex; i++) i,
      if (window.rightDots) null,
      if (!widget.openEnd && count > 1) count,
    ];

    Widget arrow({required bool next, required bool off}) => _PageButton(
      label: next ? labels.nextPageLabel : labels.previousPageLabel,
      disabled: off,
      onPress: next ? _next : _previous,
      builder: (state) => CsIcon(
        next ? CsIcons.angleRight : CsIcons.angleLeft,
        dangerouslySetColor: off
            ? cs.colors.textInteractiveDisabled
            : state.active
            ? cs.colors.textInteractiveHover
            : cs.colors.textInteractiveDefault,
      ),
    );

    Widget dots() => _Item(
      child: ExcludeSemantics(
        child: Text(
          '...',
          style: cs.body.copyWith(
            color: disabled ? cs.colors.textInteractiveDisabled : cs.colors.textInteractiveDefault,
          ),
        ),
      ),
    );

    Widget number(int page) {
      final isCurrent = page == current;
      return _PageButton(
        label: labels.labelForPage(page),
        disabled: disabled,
        selected: isCurrent,
        onPress: () => _go(page),
        builder: (state) {
          final Color color;
          if (disabled) {
            color = isCurrent ? cs.colors.textPaginationPageNumberActiveDisabled : cs.colors.textInteractiveDisabled;
          } else if (state.active) {
            color = cs.colors.textInteractiveHover;
          } else {
            color = isCurrent ? cs.colors.textInteractiveActive : cs.colors.textPaginationPageNumberDefault;
          }
          return Text(
            '$page',
            textAlign: TextAlign.center,
            style: cs.body.copyWith(color: color, fontWeight: isCurrent ? CsTypography.bold : null),
          );
        },
      );
    }

    Widget compact() => _Item(
      child: Semantics(
        liveRegion: true,
        child: Text(
          widget.i18nStrings.compactText(current, count, widget.openEnd),
          softWrap: false,
          style: cs.body.copyWith(
            color: disabled ? cs.colors.textInteractiveDisabled : cs.colors.textPaginationPageNumberDefault,
          ),
        ),
      ),
    );

    Widget layout(CsPaginationPagesVariant variant) => Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        arrow(next: false, off: prevDisabled),
        if (variant == CsPaginationPagesVariant.compact)
          compact()
        else
          for (final p in pages()) p == null ? dots() : number(p),
        arrow(next: true, off: nextDisabled),
        if (widget.jumpToPage != null) _jumpField(context),
      ],
    );

    Widget body;
    if (widget.pagesVariant != null) {
      body = layout(widget.pagesVariant!);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.maxWidth.isFinite) return layout(CsPaginationPagesVariant.normal);
          final style = cs.body.copyWith(fontWeight: CsTypography.bold);
          final minTarget = cs.minTapTarget;
          double control(double content) {
            final w = content + 2 * CsBorderWidth.button;
            final box = w < CsSpace.l ? CsSpace.l : w;
            return (box < minTarget ? minTarget : box) + 2 * CsSpace.xxs;
          }

          var total = 2 * control(CsSize.iconNormal);
          for (final p in pages()) {
            total += control(_textWidth(context, p == null ? '...' : '$p', style));
          }
          if (widget.jumpToPage != null) total += 160;
          return layout(
            total <= constraints.maxWidth ? CsPaginationPagesVariant.normal : CsPaginationPagesVariant.compact,
          );
        },
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: labels.paginationLabel ?? context.csStrings.pagination,
      child: FocusTraversalGroup(child: body),
    );
  }

  Widget _jumpField(BuildContext context) {
    final cs = context.cs;
    final strings = widget.i18nStrings;
    final loading = widget.jumpToPage!.loading;
    final button = CsButton(
      icon: CsIcons.arrowRight,
      variant: CsButtonVariant.icon,
      loading: loading,
      loadingText: strings.jumpToPageLoadingText,
      semanticLabel: loading ? strings.jumpToPageLoadingText : widget.ariaLabels.jumpToPageButton,
      disabled: !_canJump,
      onPress: _jump,
    );
    return Container(
      margin: const EdgeInsetsDirectional.only(start: CsSpace.xs),
      padding: const EdgeInsetsDirectional.only(start: CsSpace.xs),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: cs.colors.borderDividerDefault, width: CsBorderLine.dividerSectionWidth),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CsSpace.xxs,
        children: [
          SizedBox(
            width: 87,
            child: CsInput(
              value: _jumpValue,
              type: CsInputType.number,
              disabled: widget.disabled,
              focusNode: _jumpFocus,
              ariaLabel: strings.jumpToPageInputLabel,
              placeholder: strings.jumpToPageInputLabel,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChange: (v) => setState(() {
                _jumpValue = v;
                _hasError = false;
              }),
              onBlur: () {
                if (_hasError) setState(() => _hasError = false);
              },
              onSubmit: (_) {
                if (_canJump) _jump();
              },
            ),
          ),
          CsAnchoredOverlay(
            open: _hasError && !loading,
            onDismiss: () => setState(() => _hasError = false),
            side: CsSide.bottom,
            focusPopupWhenUnfocused: false,
            restoreFocus: false,
            overlayBuilder: (context, placement) => CsPopupSurface(
              placement: placement,
              showArrow: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Semantics(liveRegion: true, child: Text(strings.jumpToPageError, style: context.cs.body)),
              ),
            ),
            child: button,
          ),
        ],
      ),
    );
  }
}

/// One `li`: space-xxs between items and the field's vertical padding.
class _Item extends StatelessWidget {
  const _Item({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: context.cs.space.fieldVertical),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: CsSpace.l),
      child: Padding(
        padding: const EdgeInsets.all(CsBorderWidth.button),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    ),
  );
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.disabled,
    required this.onPress,
    required this.builder,
    this.selected,
  });

  final String label;
  final bool disabled;
  final bool? selected;
  final VoidCallback onPress;
  final Widget Function(CsPressState state) builder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: CsSpace.xxs, vertical: context.cs.space.fieldVertical),
    child: CsPressable(
      onPress: onPress,
      disabled: disabled,
      semanticLabel: label,
      selected: selected,
      excludeChildSemantics: true,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
      builder: (context, state) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: CsSpace.l),
        child: Padding(
          padding: const EdgeInsets.all(CsBorderWidth.button),
          child: Center(widthFactor: 1, heightFactor: 1, child: builder(state)),
        ),
      ),
    ),
  );
}
