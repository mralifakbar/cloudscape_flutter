import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../status/cs_status_indicator.dart';
import '../system/cs_strings.dart';
import '../theme/theme.dart';
import 'cs_collection_internal.dart';
import 'cs_collection_types.dart';
import 'cs_item_card.dart';
import 'cs_table_layout.dart';

/// Cards styles (Cloudscape cards `variant`).
enum CsCardsVariant {
  /// The header and tools sit in their own container above the cards.
  container,

  /// The cards are the whole page: the header sits on the page background.
  fullPage,
}

/// One section of a card (Cloudscape `SectionDefinition`).
@immutable
class CsCardSection<T> {
  const CsCardSection({this.id, this.header, this.headerWidget, this.content, this.width = 100})
    : assert(width > 0 && width <= 100);

  /// Matches [CsCards.visibleSections] entries.
  final String? id;

  /// Section label, in bold `color-text-label`.
  final String? header;

  /// Custom section label in place of [header].
  final Widget? headerWidget;

  /// Builds the section content for an item.
  final Widget Function(BuildContext context, T item)? content;

  /// Width in percent of the card. Sections that add up to 100 or less share
  /// a line.
  final double width;
}

/// What each card shows (Cloudscape `CardDefinition`).
@immutable
class CsCardDefinition<T> {
  const CsCardDefinition({this.header, this.sections = const []});

  /// Builds the card title, in heading-m.
  final Widget Function(BuildContext context, T item)? header;
  final List<CsCardSection<T>> sections;
}

/// Cards per row from a minimum container width (Cloudscape `CardsLayout`).
@immutable
class CsCardsLayout {
  const CsCardsLayout({required this.cards, this.minWidth = 0}) : assert(cards >= 1 && cards <= 20);

  final int cards;
  final double minWidth;

  /// Cloudscape's default: 1 card, then 2 from 768px, 3 from 992px, 4 from
  /// 1200px, 5 from 1400px and 6 from 1920px.
  static const List<CsCardsLayout> defaults = [
    CsCardsLayout(cards: 1),
    CsCardsLayout(cards: 2, minWidth: 768),
    CsCardsLayout(cards: 3, minWidth: 992),
    CsCardsLayout(cards: 4, minWidth: 1200),
    CsCardsLayout(cards: 5, minWidth: 1400),
    CsCardsLayout(cards: 6, minWidth: 1920),
  ];

  /// The number of cards per row at [width] (Cloudscape `getCardsPerRow`).
  static int cardsPerRow(double width, List<CsCardsLayout> config) {
    final sorted = [...(config.isEmpty ? defaults : config)]..sort((a, b) => b.minWidth.compareTo(a.minWidth));
    for (final layout in sorted) {
      if (width >= layout.minWidth) return layout.cards;
    }
    return 1;
  }
}

/// Accessible labels for [CsCards] (Cloudscape cards `ariaLabels`).
@immutable
class CsCardsAriaLabels<T> {
  const CsCardsAriaLabels({this.itemSelectionLabel, this.selectionGroupLabel, this.cardsLabel});

  final String Function(List<T> selectedItems, T item)? itemSelectionLabel;
  final String? selectionGroupLabel;

  /// Names the list of cards.
  final String? cardsLabel;
}

/// Cloudscape's `Cards`: a collection of items as a grid of cards, with the
/// header, filter, pagination and preferences slots of a collection and
/// optional selection.
///
/// ```dart
/// CsCards<Distribution>(
///   header: const CsHeader(title: 'Distributions', counter: '(2)'),
///   items: distributions,
///   cardDefinition: CsCardDefinition(
///     header: (context, d) => Text(d.id),
///     sections: [
///       CsCardSection(id: 'domain', header: 'Domain name', content: (context, d) => Text(d.domain)),
///       CsCardSection(id: 'status', header: 'Status', content: (context, d) => Text(d.status), width: 50),
///     ],
///   ),
/// )
/// ```
///
/// Cards in a row share the tallest card's height. The number of cards per
/// row follows [cardsPerRow] against the available width, so phones show
/// one column.
class CsCards<T> extends StatefulWidget {
  const CsCards({
    super.key,
    required this.items,
    required this.cardDefinition,
    this.empty,
    this.header,
    this.filter,
    this.pagination,
    this.preferences,
    this.loading = false,
    this.loadingText,
    this.cardsPerRow = CsCardsLayout.defaults,
    this.trackBy,
    this.selectionType,
    this.selectedItems = const [],
    this.isItemDisabled,
    this.ariaLabels,
    this.visibleSections,
    this.onSelectionChange,
    this.stickyHeader = false,
    this.stickyHeaderVerticalOffset = 0,
    this.totalItemsCount,
    this.firstIndex,
    this.renderAriaLive,
    this.variant = CsCardsVariant.container,
    this.entireCardClickable = false,
  });

  final List<T> items;
  final CsCardDefinition<T> cardDefinition;

  /// Shown when [items] is empty and not [loading].
  final Widget? empty;
  final Widget? header;
  final Widget? filter;
  final Widget? pagination;
  final Widget? preferences;
  final bool loading;
  final String? loadingText;
  final List<CsCardsLayout> cardsPerRow;
  final CsTrackBy<T>? trackBy;
  final CsSelectionType? selectionType;
  final List<T> selectedItems;
  final bool Function(T item)? isItemDisabled;
  final CsCardsAriaLabels<T>? ariaLabels;

  /// Ids of visible sections. Order is set by [CsCardDefinition.sections].
  final List<String>? visibleSections;
  final ValueChanged<List<T>>? onSelectionChange;

  /// Keeps the header in place while the cards scroll. Needs a bounded
  /// height; off on phones, as in Cloudscape.
  final bool stickyHeader;
  final double stickyHeaderVerticalOffset;
  final int? totalItemsCount;
  final int? firstIndex;
  final String Function(CsLiveAnnouncement data)? renderAriaLive;
  final CsCardsVariant variant;

  /// Pressing anywhere on a card selects it. Do not use it when cards hold
  /// other interactive content.
  final bool entireCardClickable;

  @override
  State<CsCards<T>> createState() => _CsCardsState<T>();
}

class _CsCardsState<T> extends State<CsCards<T>> {
  T? _anchor;

  @override
  void didUpdateWidget(CsCards<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.firstIndex != widget.firstIndex ||
        oldWidget.items.length != widget.items.length ||
        oldWidget.totalItemsCount != widget.totalItemsCount;
    if (changed && widget.renderAriaLive != null && widget.firstIndex != null && !widget.loading) {
      final first = widget.firstIndex!;
      final message = widget.renderAriaLive!(
        CsLiveAnnouncement(
          firstIndex: first,
          lastIndex: first + widget.items.length - 1,
          visibleItemsCount: widget.items.length,
          totalItemsCount: widget.totalItemsCount,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) csCollectionAnnounce(context, message);
      });
    }
  }

  CsCollectionSelectionModel<T> get _model => CsCollectionSelectionModel<T>(
    items: widget.items,
    selectedItems: widget.selectedItems,
    trackBy: widget.trackBy,
    isItemDisabled: widget.isItemDisabled,
  );

  Object? _key(T item) => widget.trackBy == null ? item : widget.trackBy!(item);

  void _toggle(T item, bool shift) {
    final type = widget.selectionType;
    if (type == null || widget.onSelectionChange == null) return;
    final next = _model.toggle(item, type: type, shift: shift, anchor: _anchor);
    _anchor = item;
    widget.onSelectionChange!(next);
  }

  List<CsCardSection<T>> get _sections {
    final all = widget.cardDefinition.sections;
    final visible = widget.visibleSections;
    if (visible == null) return all;
    return [
      for (final s in all)
        if (s.id != null && visible.contains(s.id)) s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final narrow = context.csIsNarrow;
    final fullPage = widget.variant == CsCardsVariant.fullPage;
    final footerPagination = narrow && fullPage && widget.pagination != null;
    final header = _toolsHeader(context, includePagination: !footerPagination);

    Widget? status;
    if (widget.loading) {
      status = CsStatusIndicator(type: CsStatusType.loading, text: widget.loadingText ?? context.csStrings.loading);
    } else if (widget.items.isEmpty) {
      status = widget.empty;
    }
    if (status != null || widget.items.isEmpty) {
      status = Padding(
        padding: EdgeInsets.only(bottom: cs.space.scaledL),
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(color: cs.colors.textEmpty),
            textAlign: TextAlign.center,
            child: status ?? const SizedBox.shrink(),
          ),
        ),
      );
    }

    final gap = header == null ? 0.0 : (fullPage ? cs.space.scaledS : cs.space.gridGutter);
    Widget list = status ?? _grid(context);
    list = Padding(
      padding: EdgeInsets.only(top: gap),
      child: list,
    );

    final footer = footerPagination
        ? Padding(
            padding: EdgeInsets.only(top: cs.space.scaledS),
            child: Align(alignment: AlignmentDirectional.centerEnd, child: widget.pagination),
          )
        : null;

    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final sticky = widget.stickyHeader && !narrow && bounded;
        if (sticky) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: widget.stickyHeaderVerticalOffset),
              ?header,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [list, ?footer],
                  ),
                ),
              ),
            ],
          );
        }
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [?header, list, ?footer],
        );
        return bounded ? SingleChildScrollView(child: column) : column;
      },
    );

    if (widget.selectionType != null) {
      result = Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
          SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
        },
        child: result,
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.ariaLabels?.cardsLabel,
      child: FocusTraversalGroup(child: result),
    );
  }

  Widget? _toolsHeader(BuildContext context, {required bool includePagination}) {
    final cs = context.cs;
    final c = cs.colors;
    final pagination = includePagination ? widget.pagination : null;
    final hasTools = widget.filter != null || pagination != null || widget.preferences != null;
    if (widget.header == null && !hasTools) return null;
    final end = <Widget>[
      ?pagination,
      if (pagination != null && widget.preferences != null)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: CsSpace.xs),
          width: CsBorderLine.dividerSectionWidth,
          height: CsFontTokens.lineHeightBodyM,
          color: c.borderDividerDefault,
        ),
      ?widget.preferences,
    ];
    Widget? tools;
    if (hasTools) {
      tools = LayoutBuilder(
        builder: (context, constraints) {
          final endRow = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: end,
          );
          final filter = widget.filter;
          if (filter == null) return Align(alignment: AlignmentDirectional.centerEnd, child: endRow);
          if (end.isEmpty) return filter;
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: cs.space.scaledXs,
              children: [
                filter,
                Align(alignment: AlignmentDirectional.centerEnd, child: endRow),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: CsSpace.l,
            children: [
              Expanded(child: filter),
              endRow,
            ],
          );
        },
      );
      if (widget.header != null) {
        tools = Padding(
          padding: EdgeInsets.only(top: cs.space.scaledXs),
          child: tools,
        );
      }
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [?widget.header, ?tools],
    );
    if (widget.variant == CsCardsVariant.fullPage) {
      return Padding(
        padding: EdgeInsets.only(bottom: cs.space.containerHeaderBottom + CsSpace.tableHeaderToolsFullPageBottom),
        child: content,
      );
    }
    const radius = BorderRadius.all(Radius.circular(CsBorderRadius.container));
    return Container(
      decoration: BoxDecoration(color: c.backgroundContainerContent, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.borderDividerDefault, strokeAlign: BorderSide.strokeAlignInside),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: CsSpace.containerHeaderTop,
        horizontal: CsSpace.containerHorizontal,
      ),
      child: content,
    );
  }

  Widget _grid(BuildContext context) {
    final cs = context.cs;
    final gutter = cs.space.gridGutter;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final perRow = CsCardsLayout.cardsPerRow(width, widget.cardsPerRow);
        final cardWidth = (width - gutter * (perRow - 1)) / perRow;
        final rows = <Widget>[];
        for (var start = 0; start < widget.items.length; start += perRow) {
          final children = <Widget>[];
          final widths = <double>[];
          for (var j = 0; j < perRow; j++) {
            if (j > 0) {
              children.add(const SizedBox.shrink());
              widths.add(gutter);
            }
            final index = start + j;
            children.add(index < widget.items.length ? _card(context, widget.items[index]) : const SizedBox.shrink());
            widths.add(cardWidth);
          }
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: gutter),
              child: CsTableRowLayout(
                widths: widths,
                pins: List<CsTablePin?>.filled(widths.length, null),
                controller: null,
                background: const Color(0x00000000),
                textDirection: Directionality.of(context),
                padStart: 0,
                shadowFirst: const [],
                shadowLast: const [],
                children: children,
              ),
            ),
          );
        }
        return Semantics(
          explicitChildNodes: true,
          label: widget.selectionType != null ? widget.ariaLabels?.selectionGroupLabel : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows),
        );
      },
    );
  }

  Widget _card(BuildContext context, T item) {
    final cs = context.cs;
    final model = _model;
    final selectable = widget.selectionType != null;
    final selected = selectable && model.isSelected(item);
    final disabled = model.isDisabled(item);
    final canSelect = selectable && !disabled && widget.onSelectionChange != null;
    final sections = _sections;

    Widget? selection;
    if (selectable) {
      selection = Padding(
        padding: const EdgeInsets.all(CsSpace.xxs),
        child: CsCollectionSelectionControl(
          selectionType: widget.selectionType!,
          checked: selected,
          disabled: disabled,
          semanticLabel: widget.ariaLabels?.itemSelectionLabel?.call(widget.selectedItems, item),
          onChange: canSelect ? (shift) => _toggle(item, shift) : null,
        ),
      );
    }

    Widget? body;
    if (sections.isNotEmpty) {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Wrap(
            children: [
              for (var i = 0; i < sections.length; i++)
                SizedBox(
                  width: w * sections[i].width / 100,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i == 0 ? 0 : CsSpace.xs,
                      bottom: i == sections.length - 1 ? 0 : cs.space.scaledXs,
                      right: sections[i].width < 100 ? CsSpace.xs : 0,
                    ),
                    child: _section(context, sections[i], item),
                  ),
                ),
            ],
          );
        },
      );
    }

    final headerBuilder = widget.cardDefinition.header;
    return CsItemCard(
      key: ValueKey<Object?>(_key(item)),
      fitHeight: true,
      highlighted: selected,
      header: headerBuilder == null
          ? (selection == null ? null : const SizedBox.shrink())
          : DefaultTextStyle.merge(
              style: cs.text(CsTypeScale.headingM),
              child: Builder(builder: (context) => headerBuilder(context, item)),
            ),
      actions: selection,
      onPress: widget.entireCardClickable && canSelect ? () => _toggle(item, false) : null,
      semanticLabel: widget.ariaLabels?.itemSelectionLabel?.call(widget.selectedItems, item),
      child: body,
    );
  }

  Widget _section(BuildContext context, CsCardSection<T> section, T item) {
    final cs = context.cs;
    final label = section.headerWidget ?? (section.header == null ? null : Text(section.header!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          DefaultTextStyle.merge(
            style: cs.text(CsTypeScale.bodyM, weight: CsFontTokens.fontWeightFormLabel, color: CsColor.textLabel),
            child: label,
          ),
        if (section.content != null) Builder(builder: (context) => section.content!(context, item)),
      ],
    );
  }
}
