import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../forms/cs_input.dart';
import '../theme/theme.dart';

/// Cloudscape's `TextFilter`: a search input that filters a table or card
/// list by text, with the number of matches next to it.
///
/// ```dart
/// CsTextFilter(
///   filteringText: query,
///   filteringPlaceholder: 'Find instances',
///   countText: '${matches.length} matches',
///   onChange: (text) => setState(() => query = text),
/// )
/// ```
///
/// [onChange] fires on every keystroke; [onDelayedChange] fires once typing
/// pauses for 400ms, for filtering on a server. [countText] shows only while
/// there is filter text, and is announced to screen readers when it changes
/// (unless [loading]).
class CsTextFilter extends StatefulWidget {
  const CsTextFilter({
    super.key,
    required this.filteringText,
    this.onChange,
    this.onDelayedChange,
    this.filteringPlaceholder,
    this.filteringAriaLabel,
    this.filteringClearAriaLabel,
    this.countText,
    this.loading = false,
    this.disabled = false,
    this.focusNode,
    this.autoFocus = false,
  });

  /// The filter text.
  final String filteringText;

  /// Called with the new text on every edit.
  final ValueChanged<String>? onChange;

  /// Called with the text 400ms after the last edit.
  final ValueChanged<String>? onDelayedChange;
  final String? filteringPlaceholder;

  /// Accessible name of the input. Defaults to [filteringPlaceholder].
  final String? filteringAriaLabel;

  /// Accessible name of the clear button.
  final String? filteringClearAriaLabel;

  /// Number of matches, such as "3 matches" or "25+ matches".
  final String? countText;

  /// The collection is loading: the count is not announced.
  final bool loading;
  final bool disabled;
  final FocusNode? focusNode;
  final bool autoFocus;

  /// Delay of [onDelayedChange] (Cloudscape's input debounce).
  static const Duration delay = Duration(milliseconds: 400);

  @override
  State<CsTextFilter> createState() => _CsTextFilterState();
}

class _CsTextFilterState extends State<CsTextFilter> {
  Timer? _debounce;

  @override
  void didUpdateWidget(CsTextFilter old) {
    super.didUpdateWidget(old);
    final show = _showResults;
    if (show && !widget.loading && (old.countText != widget.countText || old.loading != widget.loading)) {
      final view = View.maybeOf(context);
      if (view != null) {
        SemanticsService.sendAnnouncement(view, widget.countText!, Directionality.of(context));
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool get _showResults => widget.filteringText.isNotEmpty && widget.countText != null && !widget.disabled;

  void _onChange(String v) {
    widget.onChange?.call(v);
    if (widget.onDelayedChange != null) {
      _debounce?.cancel();
      _debounce = Timer(CsTextFilter.delay, () => widget.onDelayedChange?.call(v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ConstrainedBox(
      // `.root { max-inline-size: calc(688px - 2 * space-l) }`
      constraints: const BoxConstraints(maxWidth: 688 - 2 * CsSpace.l),
      // The input chrome fills a loose height; size the row to its content.
      child: UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        child: Row(
          children: [
            Expanded(
              child: CsInput(
                type: CsInputType.search,
                value: widget.filteringText,
                onChange: _onChange,
                placeholder: widget.filteringPlaceholder,
                ariaLabel: widget.filteringAriaLabel ?? widget.filteringPlaceholder,
                clearAriaLabel: widget.filteringClearAriaLabel,
                disabled: widget.disabled,
                autoComplete: false,
                focusNode: widget.focusNode,
                autoFocus: widget.autoFocus,
              ),
            ),
            if (_showResults)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: CsSpace.s),
                child: Text(widget.countText!, maxLines: 1, style: cs.body.copyWith(color: cs.colors.textFormLabel)),
              ),
          ],
        ),
      ),
    );
  }
}
