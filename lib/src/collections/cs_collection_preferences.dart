import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/cs_button.dart';
import '../controls/cs_checkbox.dart';
import '../forms/cs_form_field.dart';
import '../forms/cs_input.dart';
import '../icons/cs_icon.dart';
import '../icons/cs_icons.g.dart';
import '../system/cs_focus_ring.dart';
import '../theme/theme.dart';
import 'cs_collection_internal.dart';
import 'cs_collection_types.dart';

/// Current preference values (Cloudscape `CollectionPreferencesProps.Preferences`).
/// [C] is the type of the custom preference.
@immutable
class CsCollectionPreferencesValue<C> {
  const CsCollectionPreferencesValue({
    this.pageSize,
    this.wrapLines,
    this.stripedRows,
    this.contentDensity,
    this.visibleContent,
    this.stickyColumns,
    this.contentDisplay,
    this.custom,
  });

  final int? pageSize;
  final bool? wrapLines;
  final bool? stripedRows;
  final CsDensity? contentDensity;

  /// Visible section or column ids (for cards; tables use [contentDisplay]).
  final List<String>? visibleContent;
  final CsStickyColumns? stickyColumns;

  /// Column order and visibility.
  final List<CsColumnDisplay>? contentDisplay;
  final C? custom;

  CsCollectionPreferencesValue<C> copyWith({
    int? pageSize,
    bool? wrapLines,
    bool? stripedRows,
    CsDensity? contentDensity,
    List<String>? visibleContent,
    CsStickyColumns? stickyColumns,
    List<CsColumnDisplay>? contentDisplay,
    C? custom,
  }) => CsCollectionPreferencesValue<C>(
    pageSize: pageSize ?? this.pageSize,
    wrapLines: wrapLines ?? this.wrapLines,
    stripedRows: stripedRows ?? this.stripedRows,
    contentDensity: contentDensity ?? this.contentDensity,
    visibleContent: visibleContent ?? this.visibleContent,
    stickyColumns: stickyColumns ?? this.stickyColumns,
    contentDisplay: contentDisplay ?? this.contentDisplay,
    custom: custom ?? this.custom,
  );

  @override
  bool operator ==(Object other) =>
      other is CsCollectionPreferencesValue<C> &&
      other.pageSize == pageSize &&
      other.wrapLines == wrapLines &&
      other.stripedRows == stripedRows &&
      other.contentDensity == contentDensity &&
      listEquals(other.visibleContent, visibleContent) &&
      other.stickyColumns == stickyColumns &&
      listEquals(other.contentDisplay, contentDisplay) &&
      other.custom == custom;

  @override
  int get hashCode => Object.hash(
    pageSize,
    wrapLines,
    stripedRows,
    contentDensity,
    visibleContent == null ? null : Object.hashAll(visibleContent!),
    stickyColumns,
    contentDisplay == null ? null : Object.hashAll(contentDisplay!),
    custom,
  );
}

/// One page size choice.
@immutable
class CsPageSizeOption {
  const CsPageSizeOption({required this.value, this.label});

  final int value;

  /// Defaults to the number, such as "10 resources" when given.
  final String? label;
}

/// The page size preference (Cloudscape `pageSizePreference`).
@immutable
class CsPageSizePreference {
  const CsPageSizePreference({required this.options, this.title});

  final String? title;
  final List<CsPageSizeOption> options;
}

/// A checkbox preference: wrap lines, striped rows or compact mode.
@immutable
class CsCheckboxPreference {
  const CsCheckboxPreference({this.label, this.description});

  final String? label;
  final String? description;
}

/// One radio group of the sticky columns preference.
@immutable
class CsStickyColumnPreference {
  const CsStickyColumnPreference({required this.title, required this.description, required this.options});

  final String title;
  final String description;

  /// Label and number of columns.
  final List<({String label, int value})> options;
}

/// The sticky columns preference (Cloudscape `stickyColumnsPreference`).
@immutable
class CsStickyColumnsPreference {
  const CsStickyColumnsPreference({this.firstColumns, this.lastColumns});

  final CsStickyColumnPreference? firstColumns;
  final CsStickyColumnPreference? lastColumns;
}

/// A column in the content display preference.
@immutable
class CsContentDisplayOption {
  const CsContentDisplayOption({required this.id, required this.label, this.alwaysVisible = false});

  final String id;
  final String label;

  /// The visibility toggle is on and cannot be turned off.
  final bool alwaysVisible;
}

/// The column order and visibility preference (Cloudscape
/// `contentDisplayPreference`). Columns reorder by dragging the handle or
/// with the keyboard: focus the handle, press Space or Enter to pick the
/// column up, move it with the arrow keys and press Space or Enter to drop
/// it (Escape puts it back).
@immutable
class CsContentDisplayPreference {
  const CsContentDisplayPreference({
    required this.options,
    this.title,
    this.description,
    this.enableColumnFiltering = false,
  });

  final String? title;
  final String? description;
  final List<CsContentDisplayOption> options;

  /// Adds a filter input above the list. Reordering is off while filtering.
  final bool enableColumnFiltering;
}

/// One option of the visible content preference.
@immutable
class CsVisibleContentOption {
  const CsVisibleContentOption({required this.id, required this.label, this.editable = true});

  final String id;
  final String label;

  /// False keeps the option visible and its toggle disabled.
  final bool editable;
}

/// A group of visible content options.
@immutable
class CsVisibleContentOptionsGroup {
  const CsVisibleContentOptionsGroup({required this.label, required this.options});

  final String label;
  final List<CsVisibleContentOption> options;
}

/// The visible content preference, recommended for cards (Cloudscape
/// `visibleContentPreference`).
@immutable
class CsVisibleContentPreference {
  const CsVisibleContentPreference({required this.title, required this.options});

  final String title;
  final List<CsVisibleContentOptionsGroup> options;
}

/// Copy for [CsCollectionPreferences] (Cloudscape's English messages).
@immutable
class CsCollectionPreferencesI18nStrings {
  const CsCollectionPreferencesI18nStrings({
    this.title = 'Preferences',
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.pageSizeTitle = 'Page size',
    this.wrapLinesLabel = 'Wrap lines',
    this.wrapLinesDescription = 'Select to see all the text and wrap the lines',
    this.stripedRowsLabel = 'Striped rows',
    this.stripedRowsDescription = 'Select to add alternating shaded rows',
    this.contentDensityLabel = 'Compact mode',
    this.contentDensityDescription = 'Select to display content in a denser, more compact mode',
    this.contentDisplayTitle = 'Column preferences',
    this.contentDisplayDescription = 'Customize the visibility and order of the columns.',
    this.columnFilteringPlaceholder = 'Filter columns',
    this.columnFilteringNoMatchText = 'No matches found',
    this.columnFilteringClearFilterText = 'Clear filter',
    this.dragHandleAriaLabel = 'Drag handle',
    this.dragHandleAriaDescription =
        'Use Space or Enter to activate drag for an item, then use the arrow keys to move the item\'s position. '
        'To complete the position move, use Space or Enter, or to discard the move, use Escape.',
    this.liveAnnouncementDndDiscarded = 'Reordering canceled',
    this.columnFilteringCountText = _countText,
    this.liveAnnouncementDndStarted = _started,
    this.liveAnnouncementDndItemReordered = _reordered,
    this.liveAnnouncementDndItemCommitted = _committed,
  });

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String pageSizeTitle;
  final String wrapLinesLabel;
  final String wrapLinesDescription;
  final String stripedRowsLabel;
  final String stripedRowsDescription;
  final String contentDensityLabel;
  final String contentDensityDescription;
  final String contentDisplayTitle;
  final String contentDisplayDescription;
  final String columnFilteringPlaceholder;
  final String columnFilteringNoMatchText;
  final String columnFilteringClearFilterText;
  final String dragHandleAriaLabel;
  final String dragHandleAriaDescription;
  final String liveAnnouncementDndDiscarded;
  final String Function(int count) columnFilteringCountText;
  final String Function(int position, int total) liveAnnouncementDndStarted;
  final String Function(int initialPosition, int currentPosition, int total) liveAnnouncementDndItemReordered;
  final String Function(int initialPosition, int finalPosition, int total) liveAnnouncementDndItemCommitted;

  static String _countText(int count) => count == 1 ? '1 match' : '$count matches';
  static String _started(int position, int total) => 'Picked up item at position $position of $total';
  static String _reordered(int initial, int current, int total) => initial == current
      ? 'Moving item back to position $current of $total'
      : 'Moving item to position $current of $total';
  static String _committed(int initial, int last, int total) => initial == last
      ? 'Item moved back to its original position $initial of $total'
      : 'Item moved from position $initial to position $last of $total';
}

/// Cloudscape's `CollectionPreferences`: a settings button for a table or
/// cards that opens a modal with page size, line wrapping, striped rows,
/// density, sticky columns, column order and visibility, and custom
/// preferences. Changes apply on Confirm.
///
/// ```dart
/// CsCollectionPreferences<void>(
///   preferences: prefs,
///   onConfirm: (next) => setState(() => prefs = next),
///   pageSizePreference: const CsPageSizePreference(options: [
///     CsPageSizeOption(value: 10, label: '10 instances'),
///     CsPageSizeOption(value: 20, label: '20 instances'),
///   ]),
///   wrapLinesPreference: const CsCheckboxPreference(),
///   contentDisplayPreference: const CsContentDisplayPreference(options: [
///     CsContentDisplayOption(id: 'id', label: 'Instance ID', alwaysVisible: true),
///     CsContentDisplayOption(id: 'state', label: 'State'),
///   ]),
/// )
/// ```
///
/// The modal is a [CsDialogRoute] with a panel styled like Cloudscape's
/// modal; on phones it takes the screen width less 12px each side and the
/// two columns stack.
class CsCollectionPreferences<C> extends StatelessWidget {
  const CsCollectionPreferences({
    super.key,
    this.preferences = const CsCollectionPreferencesValue(),
    this.onConfirm,
    this.onCancel,
    this.title,
    this.confirmLabel,
    this.cancelLabel,
    this.closeAriaLabel,
    this.disabled = false,
    this.pageSizePreference,
    this.wrapLinesPreference,
    this.stripedRowsPreference,
    this.contentDensityPreference,
    this.stickyColumnsPreference,
    this.contentDisplayPreference,
    this.visibleContentPreference,
    this.customPreference,
    this.contentBefore,
    this.i18nStrings = const CsCollectionPreferencesI18nStrings(),
  });

  /// Current values; the modal starts from them each time it opens.
  final CsCollectionPreferencesValue<C> preferences;

  /// Called with every configured preference when the user confirms.
  final ValueChanged<CsCollectionPreferencesValue<C>>? onConfirm;

  /// Called when the user cancels or dismisses the modal.
  final VoidCallback? onCancel;

  /// Modal title and the trigger's accessible name.
  final String? title;
  final String? confirmLabel;
  final String? cancelLabel;
  final String? closeAriaLabel;
  final bool disabled;
  final CsPageSizePreference? pageSizePreference;
  final CsCheckboxPreference? wrapLinesPreference;
  final CsCheckboxPreference? stripedRowsPreference;
  final CsCheckboxPreference? contentDensityPreference;
  final CsStickyColumnsPreference? stickyColumnsPreference;

  /// Column order and visibility. Takes precedence over
  /// [visibleContentPreference] when both are set, as in Cloudscape.
  final CsContentDisplayPreference? contentDisplayPreference;
  final CsVisibleContentPreference? visibleContentPreference;

  /// Builds a custom preference from its pending value and a setter.
  final Widget Function(BuildContext context, C? value, ValueChanged<C> setValue)? customPreference;

  /// Shown above the preferences.
  final Widget? contentBefore;
  final CsCollectionPreferencesI18nStrings i18nStrings;

  String get _title => title ?? i18nStrings.title;

  /// Opens the preferences modal, as pressing the trigger does.
  Future<void> open(BuildContext context) async {
    final result = await showCsCollectionDialog<CsCollectionPreferencesValue<C>>(
      context,
      semanticLabel: _title,
      builder: (context) => _PreferencesModal<C>(config: this),
    );
    if (result != null) {
      onConfirm?.call(result);
    } else {
      onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CsButton(
      icon: CsIcons.settings,
      variant: CsButtonVariant.icon,
      semanticLabel: _title,
      disabled: disabled,
      onPress: disabled ? null : () => open(context),
    );
  }
}

class _PreferencesModal<C> extends StatefulWidget {
  const _PreferencesModal({required this.config});

  final CsCollectionPreferences<C> config;

  @override
  State<_PreferencesModal<C>> createState() => _PreferencesModalState<C>();
}

class _PreferencesModalState<C> extends State<_PreferencesModal<C>> {
  late CsCollectionPreferencesValue<C> _value;

  CsCollectionPreferences<C> get _c => widget.config;
  CsCollectionPreferencesI18nStrings get _s => _c.i18nStrings;

  @override
  void initState() {
    super.initState();
    _value = _c.preferences;
  }

  void _set(CsCollectionPreferencesValue<C> next) => setState(() => _value = next);

  void _confirm() {
    final p = _value;
    // Every configured preference is reported, even when unchanged.
    Navigator.of(context).pop(
      CsCollectionPreferencesValue<C>(
        pageSize: _c.pageSizePreference != null ? p.pageSize : null,
        wrapLines: _c.wrapLinesPreference != null ? (p.wrapLines ?? false) : null,
        stripedRows: _c.stripedRowsPreference != null ? (p.stripedRows ?? false) : null,
        contentDensity: _c.contentDensityPreference != null ? (p.contentDensity ?? CsDensity.comfortable) : null,
        visibleContent: _c.visibleContentPreference != null && _c.contentDisplayPreference == null
            ? (p.visibleContent ?? const [])
            : null,
        stickyColumns: _c.stickyColumnsPreference != null ? (p.stickyColumns ?? CsStickyColumns.none) : null,
        contentDisplay: _c.contentDisplayPreference != null ? _contentDisplay() : null,
        custom: _c.customPreference != null ? p.custom : null,
      ),
    );
  }

  List<CsColumnDisplay> _contentDisplay() {
    final options = _c.contentDisplayPreference!.options;
    final current = _value.contentDisplay ?? [for (final o in options) CsColumnDisplay(id: o.id)];
    final known = {for (final d in current) d.id};
    return [
      ...current,
      for (final o in options)
        if (!known.contains(o.id)) CsColumnDisplay(id: o.id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final left = <Widget>[];
    final page = _c.pageSizePreference;
    if (page != null) {
      left.add(
        CsFormField(
          label: page.title ?? _s.pageSizeTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.xxs,
            children: [
              for (final o in page.options)
                CsCollectionRadioRow(
                  label: o.label ?? '${o.value}',
                  checked: _value.pageSize == o.value,
                  onSelect: () => _set(_value.copyWith(pageSize: o.value)),
                ),
            ],
          ),
        ),
      );
    }
    Widget check(CsCheckboxPreference p, String label, String description, bool value, ValueChanged<bool> onChange) =>
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CsCheckbox(
            checked: value,
            label: p.label ?? label,
            description: p.description ?? description,
            onChange: onChange,
          ),
        );
    if (_c.wrapLinesPreference != null) {
      left.add(
        check(
          _c.wrapLinesPreference!,
          _s.wrapLinesLabel,
          _s.wrapLinesDescription,
          _value.wrapLines ?? false,
          (v) => _set(_value.copyWith(wrapLines: v)),
        ),
      );
    }
    if (_c.stripedRowsPreference != null) {
      left.add(
        check(
          _c.stripedRowsPreference!,
          _s.stripedRowsLabel,
          _s.stripedRowsDescription,
          _value.stripedRows ?? false,
          (v) => _set(_value.copyWith(stripedRows: v)),
        ),
      );
    }
    if (_c.contentDensityPreference != null) {
      left.add(
        check(
          _c.contentDensityPreference!,
          _s.contentDensityLabel,
          _s.contentDensityDescription,
          _value.contentDensity == CsDensity.compact,
          (v) => _set(_value.copyWith(contentDensity: v ? CsDensity.compact : CsDensity.comfortable)),
        ),
      );
    }
    final sticky = _c.stickyColumnsPreference;
    if (sticky != null) {
      final current = _value.stickyColumns ?? CsStickyColumns.none;
      Widget group(CsStickyColumnPreference p, int value, CsStickyColumns Function(int) apply) => CsFormField(
        label: p.title,
        description: p.description,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: CsSpace.xxs,
          children: [
            for (final o in p.options)
              CsCollectionRadioRow(
                label: o.label,
                checked: value == o.value,
                onSelect: () => _set(_value.copyWith(stickyColumns: apply(o.value))),
              ),
          ],
        ),
      );
      left.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: CsSpace.l,
          children: [
            if (sticky.firstColumns != null)
              group(sticky.firstColumns!, current.first, (v) => CsStickyColumns(first: v, last: current.last)),
            if (sticky.lastColumns != null)
              group(sticky.lastColumns!, current.last, (v) => CsStickyColumns(first: current.first, last: v)),
          ],
        ),
      );
    }
    final custom = _c.customPreference;
    if (custom != null) {
      left.add(Builder(builder: (context) => custom(context, _value.custom, (v) => _set(_value.copyWith(custom: v)))));
    }

    Widget? right;
    if (_c.contentDisplayPreference != null) {
      right = _ContentDisplay(
        preference: _c.contentDisplayPreference!,
        strings: _s,
        value: _contentDisplay(),
        onChange: (v) => _set(_value.copyWith(contentDisplay: v)),
      );
    } else if (_c.visibleContentPreference != null) {
      right = _VisibleContent(
        preference: _c.visibleContentPreference!,
        value: _value.visibleContent ?? const [],
        onChange: (v) => _set(_value.copyWith(visibleContent: v)),
      );
    }

    final leftColumn = left.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: CsSpace.l,
            children: left,
          );
    final both = leftColumn != null && right != null;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (!both) return leftColumn ?? right ?? const SizedBox.shrink();
        // Cloudscape's ModalContentLayout: two columns, stacked when narrow.
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              leftColumn,
              Padding(
                padding: EdgeInsets.only(top: 2 * cs.space.scaledL),
                child: right,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: cs.space.gridGutter,
          children: [
            Expanded(child: leftColumn),
            Expanded(child: right!),
          ],
        );
      },
    );

    return CsCollectionDialogPanel(
      title: _c._title,
      closeLabel: _c.closeAriaLabel ?? _c.cancelLabel ?? _s.cancelLabel,
      size: both ? CsCollectionDialogSize.large : CsCollectionDialogSize.medium,
      onDismiss: () => Navigator.of(context).maybePop(),
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: CsSpace.xs,
        runSpacing: CsSpace.xs,
        children: [
          CsButton(
            text: _c.cancelLabel ?? _s.cancelLabel,
            variant: CsButtonVariant.link,
            onPress: () => Navigator.of(context).maybePop(),
          ),
          CsButton(text: _c.confirmLabel ?? _s.confirmLabel, variant: CsButtonVariant.primary, onPress: _confirm),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_c.contentBefore != null)
            Padding(
              padding: const EdgeInsets.only(bottom: CsSpace.l),
              child: _c.contentBefore,
            ),
          content,
        ],
      ),
    );
  }
}

class _ContentDisplay extends StatefulWidget {
  const _ContentDisplay({required this.preference, required this.strings, required this.value, required this.onChange});

  final CsContentDisplayPreference preference;
  final CsCollectionPreferencesI18nStrings strings;
  final List<CsColumnDisplay> value;
  final ValueChanged<List<CsColumnDisplay>> onChange;

  @override
  State<_ContentDisplay> createState() => _ContentDisplayState();
}

class _ContentDisplayState extends State<_ContentDisplay> {
  String _filter = '';

  /// Keyboard reordering: the picked item's starting index and the order
  /// before the move, restored by Escape.
  int? _pickedFrom;
  String? _pickedId;
  List<CsColumnDisplay>? _before;

  CsCollectionPreferencesI18nStrings get _s => widget.strings;

  CsContentDisplayOption? _option(String id) {
    for (final o in widget.preference.options) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _toggle(String id, bool visible) {
    widget.onChange([for (final d in widget.value) d.id == id ? d.copyWith(visible: visible) : d]);
  }

  void _move(int from, int to) {
    final list = [...widget.value];
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    widget.onChange(list);
  }

  KeyEventResult _onHandleKey(String id, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final total = widget.value.length;
    final index = widget.value.indexWhere((d) => d.id == id);
    final picked = _pickedId == id;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (!picked) {
        setState(() {
          _pickedId = id;
          _pickedFrom = index;
          _before = widget.value;
        });
        csCollectionAnnounce(context, _s.liveAnnouncementDndStarted(index + 1, total));
      } else {
        csCollectionAnnounce(context, _s.liveAnnouncementDndItemCommitted(_pickedFrom! + 1, index + 1, total));
        setState(() {
          _pickedId = null;
          _pickedFrom = null;
          _before = null;
        });
      }
      return KeyEventResult.handled;
    }
    if (!picked) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape) {
      widget.onChange(_before!);
      csCollectionAnnounce(context, _s.liveAnnouncementDndDiscarded);
      setState(() {
        _pickedId = null;
        _pickedFrom = null;
        _before = null;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      final to = key == LogicalKeyboardKey.arrowUp ? index - 1 : index + 1;
      if (to < 0 || to >= total) return KeyEventResult.handled;
      _move(index, to);
      csCollectionAnnounce(context, _s.liveAnnouncementDndItemReordered(_pickedFrom! + 1, to + 1, total));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final p = widget.preference;
    final filtering = _filter.trim().toLowerCase();
    final shown = [
      for (final d in widget.value)
        if (_option(d.id) != null && (filtering.isEmpty || _option(d.id)!.label.toLowerCase().contains(filtering))) d,
    ];
    final canReorder = filtering.isEmpty;

    Widget row(CsColumnDisplay d, int index) {
      final option = _option(d.id)!;
      final picked = _pickedId == d.id;
      Widget handle = Focus(
        onKeyEvent: (node, event) => canReorder ? _onHandleKey(d.id, event) : KeyEventResult.ignored,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return CsFocusRing(
              visible: focused,
              borderRadius: BorderRadius.circular(CsBorderRadius.controlDefaultFocusRing),
              child: Semantics(
                container: true,
                label: _s.dragHandleAriaLabel,
                hint: _s.dragHandleAriaDescription,
                button: true,
                child: MouseRegion(
                  cursor: canReorder ? SystemMouseCursors.grab : SystemMouseCursors.basic,
                  child: Padding(
                    padding: EdgeInsets.all(cs.space.scaledXxxs + CsSpace.xxxs),
                    child: CsIcon(
                      CsIcons.dragIndicator,
                      variant: canReorder ? CsIconVariant.normal : CsIconVariant.disabled,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      if (canReorder) handle = ReorderableDragStartListener(index: index, child: handle);
      return Container(
        key: ValueKey(d.id),
        decoration: BoxDecoration(
          color: picked ? cs.colors.backgroundContainerContent : null,
          borderRadius: BorderRadius.circular(CsBorderRadius.item),
          boxShadow: picked ? cs.shadows.dropdown : null,
        ),
        // A padded 44px toggle already gives the row its height on touch.
        padding: EdgeInsetsDirectional.only(
          top: cs.minTapTarget > 0 ? 0 : cs.space.scaledXs,
          bottom: cs.minTapTarget > 0 ? 0 : cs.space.scaledXs,
          end: CsSpace.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            handle,
            const SizedBox(width: CsSpace.xxs),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: CsSpace.l),
                child: Text(option.label, style: cs.body),
              ),
            ),
            CsCollectionToggle(
              checked: option.alwaysVisible || d.visible,
              disabled: option.alwaysVisible,
              semanticLabel: option.label,
              onChange: (v) => _toggle(d.id, v),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            p.title ?? _s.contentDisplayTitle,
            style: cs.text(CsTypeScale.bodyM, weight: CsFontTokens.fontWeightFormLabel, color: CsColor.textFormLabel),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: cs.space.scaledXxxs),
          child: Text(
            p.description ?? _s.contentDisplayDescription,
            style: cs.text(CsTypeScale.bodyS, color: CsColor.textFormSecondary),
          ),
        ),
        if (p.enableColumnFiltering)
          Padding(
            padding: EdgeInsets.only(top: cs.space.scaledL),
            child: Row(
              spacing: CsSpace.s,
              children: [
                Expanded(
                  child: CsInput(
                    value: _filter,
                    type: CsInputType.search,
                    placeholder: _s.columnFilteringPlaceholder,
                    ariaLabel: _s.columnFilteringPlaceholder,
                    onChange: (v) => setState(() => _filter = v),
                  ),
                ),
                if (filtering.isNotEmpty)
                  Text(
                    _s.columnFilteringCountText(shown.length),
                    style: cs.text(CsTypeScale.bodyM, color: CsColor.textBodySecondary),
                  ),
              ],
            ),
          ),
        SizedBox(height: cs.space.scaledM),
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: cs.space.scaledL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CsSpace.xs,
              children: [
                Text(_s.columnFilteringNoMatchText, style: cs.text(CsTypeScale.bodyM, color: CsColor.textEmpty)),
                CsButton(text: _s.columnFilteringClearFilterText, onPress: () => setState(() => _filter = '')),
              ],
            ),
          )
        else
          ReorderableList(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shown.length,
            // `onReorderItem` replaces `onReorder` from Flutter 3.41, but this package
            // still supports 3.38, which only has `onReorder`. Move to
            // `onReorderItem` (it already adjusts the index) when the minimum is 3.41.
            // ignore: deprecated_member_use
            onReorder: (from, to) {
              if (!canReorder) return;
              _move(from, to > from ? to - 1 : to);
            },
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, child) => DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.colors.backgroundContainerContent,
                  borderRadius: BorderRadius.circular(CsBorderRadius.item),
                  boxShadow: cs.shadows.dropdown,
                ),
                child: child,
              ),
              child: child,
            ),
            itemBuilder: (context, index) => row(shown[index], index),
          ),
      ],
    );
  }
}

class _VisibleContent extends StatelessWidget {
  const _VisibleContent({required this.preference, required this.value, required this.onChange});

  final CsVisibleContentPreference preference;
  final List<String> value;
  final ValueChanged<List<String>> onChange;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final c = cs.colors;
    final border = BorderSide(color: c.borderDividerSecondary, width: CsBorderLine.dividerListWidth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: cs.space.scaledL),
          child: Semantics(
            header: true,
            child: Text(
              preference.title,
              style: cs.text(CsTypeScale.bodyM, weight: CsFontTokens.fontWeightFormLabel, color: CsColor.textFormLabel),
            ),
          ),
        ),
        for (final group in preference.options) ...[
          Container(
            padding: const EdgeInsets.only(bottom: CsSpace.xs),
            decoration: BoxDecoration(border: Border(bottom: border)),
            child: Text(group.label, style: cs.text(CsTypeScale.bodyM, color: CsColor.textGroupLabel)),
          ),
          for (var i = 0; i < group.options.length; i++)
            Container(
              padding: EdgeInsetsDirectional.only(top: CsSpace.xs, bottom: CsSpace.xs, start: cs.space.scaledL),
              decoration: BoxDecoration(border: i == group.options.length - 1 ? null : Border(bottom: border)),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: CsSpace.l),
                      child: Text(group.options[i].label, overflow: TextOverflow.ellipsis, style: cs.body),
                    ),
                  ),
                  CsCollectionToggle(
                    checked: value.contains(group.options[i].id),
                    disabled: !group.options[i].editable,
                    semanticLabel: group.options[i].label,
                    onChange: (v) {
                      final id = group.options[i].id;
                      onChange(
                        v
                            ? [...value, id]
                            : [
                                for (final x in value)
                                  if (x != id) x,
                              ],
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: CsSpace.m),
        ],
      ],
    );
  }
}
