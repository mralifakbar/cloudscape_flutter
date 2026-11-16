import 'dart:async';

import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Tables, cards, item cards, action cards, collection preferences, the S3
/// resource selector and the collection controller. Every name and figure
/// here is sample data.
final CsDemoCategory collectionsCategory = CsDemoCategory(
  title: 'Collections',
  description: 'Tables, cards, item cards, action cards, collection preferences and the S3 resource selector.',
  icon: CsIcons.listView,
  demos: [
    CsDemo(
      title: 'CsTable',
      description:
          'Sorting, selection, inline editing, expandable rows, resizable and sticky columns, and phone layouts.',
      docPath: 'doc/components/CsTable.md',
      builder: (_) => const _TableDemo(),
    ),
    CsDemo(
      title: 'CsCards',
      description: 'A responsive grid of cards with sections, selection and visible content.',
      docPath: 'doc/components/CsCards.md',
      builder: (_) => const _CardsDemo(),
    ),
    CsDemo(
      title: 'CsItemCard',
      description: 'One resource with an icon, title, description, actions, content and footer.',
      docPath: 'doc/components/CsItemCard.md',
      builder: (_) => const _ItemCardDemo(),
    ),
    CsDemo(
      title: 'CsActionCard',
      description: 'A whole card that is one action, in default, embedded and disabled states.',
      docPath: 'doc/components/CsActionCard.md',
      builder: (_) => const _ActionCardDemo(),
    ),
    CsDemo(
      title: 'CsCollectionPreferences',
      description: 'Page size, wrap lines, striped rows, density, sticky columns and column order.',
      docPath: 'doc/components/CsCollectionPreferences.md',
      builder: (_) => const _PreferencesDemo(),
    ),
    CsDemo(
      title: 'CsS3ResourceSelector',
      description: 'An S3 URI input with validation, a version picker and a browse modal.',
      docPath: 'doc/components/CsS3ResourceSelector.md',
      builder: (_) => const _S3Demo(),
    ),
    CsDemo(
      title: 'CsCollection',
      description: 'Filtering, sorting, pagination and selection in memory, driving a table.',
      docPath: 'doc/components/CsCollection.md',
      builder: (_) => const _CollectionDemo(),
    ),
    CsDemo(
      title: 'CsTableRoot',
      description:
          'A composed table with grid columns, sorting, selection, striped rows, compact density and a sticky first column.',
      docPath: 'doc/components/CsTableRoot.md',
      builder: (_) => const _TableRootDemo(),
    ),
    CsDemo(
      title: 'CsTableHead',
      description: 'A header section that stays pinned while the body scrolls.',
      docPath: 'doc/components/CsTableHead.md',
      builder: (_) => const _TableHeadDemo(),
    ),
    CsDemo(
      title: 'CsTableBody',
      description: 'Body rows with striping, dividers and a spanning empty-state row.',
      docPath: 'doc/components/CsTableBody.md',
      builder: (_) => const _TableBodyDemo(),
    ),
    CsDemo(
      title: 'CsTableRow',
      description: 'Selected rows that join, a tappable row and a shaded summary row.',
      docPath: 'doc/components/CsTableRow.md',
      builder: (_) => const _TableRowDemo(),
    ),
    CsDemo(
      title: 'CsTableHeaderCell',
      description: 'Sortable headers with the sorting caret, a resizable column and a disabled sort.',
      docPath: 'doc/components/CsTableHeaderCell.md',
      builder: (_) => const _TableHeaderCellDemo(),
    ),
    CsDemo(
      title: 'CsTableBodyCell',
      description: 'Row headers, wrapped text, top alignment, spanning cells and inline edit.',
      docPath: 'doc/components/CsTableBodyCell.md',
      builder: (_) => const _TableBodyCellDemo(),
    ),
  ],
);

class _Instance {
  const _Instance(this.id, this.name, this.state, this.type, this.zone, this.cpu);

  final String id;
  final String name;
  final String state;
  final String type;
  final String zone;
  final int cpu;

  _Instance copyWith({String? name}) => _Instance(id, name ?? this.name, state, type, zone, cpu);

  Object? field(String key) => switch (key) {
    'id' => id,
    'name' => name,
    'state' => state,
    'type' => type,
    'zone' => zone,
    'cpu' => cpu,
    _ => null,
  };
}

const _states = ['Running', 'Stopped', 'Pending', 'Running', 'Running'];
const _types = ['t3.micro', 't3.large', 'c5.xlarge', 'm5.large', 'r5.2xlarge'];
const _zones = ['us-east-1a', 'us-east-1b', 'eu-west-1a'];

final List<_Instance> _sampleInstances = [
  for (var i = 0; i < 48; i++)
    _Instance(
      'i-0abc${(123 + i).toString().padLeft(3, '0')}',
      i.isEven ? 'web-server-${i + 1}' : 'batch-worker-${i + 1}',
      _states[i % _states.length],
      _types[i % _types.length],
      _zones[i % _zones.length],
      [2, 4, 8, 16][i % 4],
    ),
];

Widget _status(String state) => CsStatusIndicator(
  type: switch (state) {
    'Running' => CsStatusType.success,
    'Pending' => CsStatusType.pending,
    _ => CsStatusType.stopped,
  },
  text: state,
);

List<CsTableColumn<_Instance>> _instanceColumns({bool editable = false}) => [
  CsTableColumn<_Instance>(
    id: 'id',
    header: 'Instance ID',
    isRowHeader: true,
    sortingField: 'id',
    cell: (context, i) => CsLink(text: i.id, onFollow: () {}),
  ),
  CsTableColumn<_Instance>(
    id: 'name',
    header: 'Name',
    sortingField: 'name',
    minWidth: 176,
    cell: (context, i) => Text(i.name),
    editConfig: editable
        ? CsTableEditConfig<_Instance>(
            ariaLabel: 'Name',
            constraintText: 'Up to 32 characters.',
            validation: (item, value) {
              final v = value as String?;
              if (v == null) return null;
              if (v.trim().isEmpty) return 'Enter a name.';
              if (v.length > 32) return 'Use 32 characters or fewer.';
              return null;
            },
            disabledReason: (item) => item.state == 'Pending' ? 'Wait until the instance is running.' : null,
            editingCell: (context, item, ctx) => CsInput(
              value: ctx.currentValue as String? ?? item.name,
              autoFocus: true,
              ariaLabel: 'Name',
              onChange: ctx.setValue,
              onSubmit: (_) => ctx.submitValue(),
            ),
          )
        : null,
  ),
  CsTableColumn<_Instance>(id: 'state', header: 'State', sortingField: 'state', cell: (context, i) => _status(i.state)),
  CsTableColumn<_Instance>(id: 'type', header: 'Type', sortingField: 'type', cell: (context, i) => Text(i.type)),
  CsTableColumn<_Instance>(id: 'zone', header: 'Availability zone', cell: (context, i) => Text(i.zone)),
  CsTableColumn<_Instance>(
    id: 'cpu',
    header: 'vCPU',
    sortingComparator: (a, b) => a.cpu.compareTo(b.cpu),
    width: 96,
    cell: (context, i) => Text('${i.cpu}'),
  ),
];

class _TableDemo extends StatefulWidget {
  const _TableDemo();

  @override
  State<_TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<_TableDemo> {
  late List<_Instance> _items = _sampleInstances.take(8).toList();
  List<_Instance> _selected = [];
  CsSortingColumn<_Instance>? _sort;
  bool _descending = false;
  CsTableVariant _variant = CsTableVariant.container;
  bool _striped = false;
  bool _compact = false;
  bool _wrap = false;
  bool _resizable = true;
  bool _cardsOnPhone = false;
  bool _loading = false;
  CsSelectionType? _selectionType = CsSelectionType.multi;
  List<_Instance> _expanded = [];
  List<double>? _widths;

  List<_Instance> get _sorted {
    final s = _sort;
    if (s == null) return _items;
    final list = [..._items];
    list.sort((a, b) {
      final r = s.sortingComparator != null
          ? s.sortingComparator!(a, b)
          : '${a.field(s.sortingField!)}'.compareTo('${b.field(s.sortingField!)}');
      return _descending ? -r : r;
    });
    return list;
  }

  Future<void> _save(_Instance item, CsTableColumn<_Instance> column, Object? value) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _items = [for (final i in _items) i.id == item.id ? i.copyWith(name: value as String) : i]);
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChange) =>
      CsCheckbox(checked: value, label: label, onChange: onChange);

  @override
  Widget build(BuildContext context) {
    final columns = _instanceColumns(editable: true);
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Options',
          caption: 'Change the table live. Sample data.',
          child: Wrap(
            spacing: CsSpace.l,
            runSpacing: CsSpace.xs,
            children: [
              _toggle('Striped rows', _striped, (v) => setState(() => _striped = v)),
              _toggle('Compact', _compact, (v) => setState(() => _compact = v)),
              _toggle('Wrap lines', _wrap, (v) => setState(() => _wrap = v)),
              _toggle('Resizable columns', _resizable, (v) => setState(() => _resizable = v)),
              _toggle('Cards on phones', _cardsOnPhone, (v) => setState(() => _cardsOnPhone = v)),
              _toggle('Loading', _loading, (v) => setState(() => _loading = v)),
              _toggle(
                'Single selection',
                _selectionType == CsSelectionType.single,
                (v) => setState(() {
                  _selectionType = v ? CsSelectionType.single : CsSelectionType.multi;
                  _selected = [];
                }),
              ),
              for (final v in CsTableVariant.values)
                CsButton(
                  text: v.name,
                  variant: v == _variant ? CsButtonVariant.primary : CsButtonVariant.normal,
                  onPress: () => setState(() => _variant = v),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Instances',
          caption: 'Sort by a header, select rows (Shift extends), press a name to edit it, drag the header dividers.',
          child: CsTable<_Instance>(
            header: CsHeader(
              title: 'Instances',
              counter: _selected.isEmpty ? '(${_items.length})' : '(${_selected.length}/${_items.length})',
              actions: CsButton(text: 'Launch instance', variant: CsButtonVariant.primary, onPress: () {}),
            ),
            footer: _widths == null ? null : Text('Column widths: ${_widths!.map((w) => w.round()).join(', ')}'),
            items: _sorted,
            trackBy: (i) => i.id,
            columnDefinitions: columns,
            variant: _variant,
            stripedRows: _striped,
            contentDensity: _compact ? CsDensity.compact : CsDensity.comfortable,
            wrapLines: _wrap,
            resizableColumns: _resizable,
            onColumnWidthsChange: (w) => setState(() => _widths = w),
            loading: _loading,
            loadingText: 'Loading instances',
            selectionType: _selectionType,
            selectedItems: _selected,
            onSelectionChange: (next) => setState(() => _selected = next),
            isItemDisabled: (i) => i.state == 'Pending',
            sortingColumn: _sort,
            sortingDescending: _descending,
            onSortingChange: (s) => setState(() {
              _sort = s.sortingColumn;
              _descending = s.isDescending;
            }),
            submitEdit: _save,
            mobileLayout: _cardsOnPhone ? CsTableMobileLayout.cards : CsTableMobileLayout.scroll,
            ariaLabels: CsTableAriaLabels<_Instance>(
              tableLabel: 'Instances',
              itemSelectionLabel: (state, item) => 'Select ${item.id}',
              allItemsSelectionLabel: (state) => 'Select all instances',
            ),
          ),
        ),
        DemoSection(
          title: 'Sticky columns and header',
          caption: 'A bounded height builds rows lazily; the first and last columns stay while scrolling sideways.',
          child: SizedBox(
            height: 360,
            child: CsTable<_Instance>(
              header: const CsHeader(title: 'Fleet', counter: '(48)'),
              items: _sampleInstances,
              columnDefinitions: [
                for (final c in _instanceColumns())
                  CsTableColumn<_Instance>(id: c.columnId, header: c.header, cell: c.cell, minWidth: 180),
              ],
              stickyHeader: true,
              stickyColumns: const CsStickyColumns(first: 1, last: 1),
              variant: CsTableVariant.container,
            ),
          ),
        ),
        DemoSection(
          title: 'Expandable rows',
          caption: 'Groups of instances by availability zone.',
          child: CsTable<_Instance>(
            variant: CsTableVariant.borderless,
            items: [
              for (final z in _zones)
                _Instance(z, '${_sampleInstances.where((i) => i.zone == z).length} instances', '', '', z, 0),
            ],
            trackBy: (i) => i.id,
            columnDefinitions: [
              CsTableColumn<_Instance>(id: 'id', header: 'Resource', cell: (context, i) => Text(i.id)),
              CsTableColumn<_Instance>(id: 'name', header: 'Name', cell: (context, i) => Text(i.name)),
              CsTableColumn<_Instance>(
                id: 'state',
                header: 'State',
                cell: (context, i) => i.state.isEmpty ? const Text('-') : _status(i.state),
              ),
            ],
            expandableRows: CsTableExpandableRows<_Instance>(
              getItemChildren: (g) =>
                  _zones.contains(g.id) ? _sampleInstances.where((i) => i.zone == g.id).take(4).toList() : const [],
              isItemExpandable: (i) => _zones.contains(i.id),
              expandedItems: _expanded,
              onExpandableItemToggle: (item, open) => setState(
                () => _expanded = open
                    ? [..._expanded, item]
                    : [
                        for (final e in _expanded)
                          if (e.id != item.id) e,
                      ],
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Empty state',
          child: CsTable<_Instance>(
            header: const CsHeader(title: 'Instances', counter: '(0)'),
            items: const [],
            columnDefinitions: _instanceColumns(),
            empty: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CsSpace.xs,
              children: [
                const CsBox(text: 'No instances', fontWeight: CsBoxFontWeight.bold, color: CsBoxColor.inherit),
                CsButton(text: 'Launch instance', onPress: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Distribution {
  const _Distribution(this.id, this.domain, this.status, this.origin, this.priceClass);

  final String id;
  final String domain;
  final String status;
  final String origin;
  final String priceClass;
}

const _distributions = [
  _Distribution('d111111abcdef8', 'd111111abcdef8.example.net', 'Deployed', 'example-bucket', 'All edge locations'),
  _Distribution('d222222abcdef8', 'd222222abcdef8.example.net', 'In progress', 'example-assets', 'North America'),
  _Distribution('d333333abcdef8', 'd333333abcdef8.example.net', 'Deployed', 'example-media', 'All edge locations'),
  _Distribution('d444444abcdef8', 'd444444abcdef8.example.net', 'Disabled', 'example-logs', 'Europe'),
  _Distribution('d555555abcdef8', 'd555555abcdef8.example.net', 'Deployed', 'example-site', 'All edge locations'),
];

class _CardsDemo extends StatefulWidget {
  const _CardsDemo();

  @override
  State<_CardsDemo> createState() => _CardsDemoState();
}

class _CardsDemoState extends State<_CardsDemo> {
  List<_Distribution> _selected = [];
  CsCollectionPreferencesValue<void> _prefs = const CsCollectionPreferencesValue(
    visibleContent: ['domain', 'status', 'origin'],
  );
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Distributions',
          caption: 'Press a card to select it; the gear chooses visible sections. Sample data.',
          child: CsCards<_Distribution>(
            header: CsHeader(
              title: 'Distributions',
              counter: '(${_distributions.length})',
              actions: CsButton(
                text: _loading ? 'Show cards' : 'Show loading',
                onPress: () => setState(() => _loading = !_loading),
              ),
            ),
            preferences: CsCollectionPreferences<void>(
              preferences: _prefs,
              onConfirm: (p) => setState(() => _prefs = p),
              visibleContentPreference: const CsVisibleContentPreference(
                title: 'Select visible content',
                options: [
                  CsVisibleContentOptionsGroup(
                    label: 'Distribution properties',
                    options: [
                      CsVisibleContentOption(id: 'domain', label: 'Domain name'),
                      CsVisibleContentOption(id: 'status', label: 'Status'),
                      CsVisibleContentOption(id: 'origin', label: 'Origin'),
                      CsVisibleContentOption(id: 'price', label: 'Price class'),
                    ],
                  ),
                ],
              ),
            ),
            items: _distributions,
            loading: _loading,
            loadingText: 'Loading distributions',
            trackBy: (d) => d.id,
            selectionType: CsSelectionType.multi,
            selectedItems: _selected,
            onSelectionChange: (next) => setState(() => _selected = next),
            isItemDisabled: (d) => d.status == 'Disabled',
            entireCardClickable: true,
            visibleSections: _prefs.visibleContent,
            ariaLabels: CsCardsAriaLabels<_Distribution>(
              itemSelectionLabel: (selected, d) => 'Select ${d.id}',
              selectionGroupLabel: 'Distribution selection',
              cardsLabel: 'Distributions',
            ),
            cardDefinition: CsCardDefinition<_Distribution>(
              header: (context, d) => Text(d.id),
              sections: [
                CsCardSection(id: 'domain', header: 'Domain name', content: (context, d) => Text(d.domain)),
                CsCardSection(
                  id: 'status',
                  header: 'Status',
                  width: 50,
                  content: (context, d) => CsStatusIndicator(
                    type: switch (d.status) {
                      'Deployed' => CsStatusType.success,
                      'In progress' => CsStatusType.inProgress,
                      _ => CsStatusType.stopped,
                    },
                    text: d.status,
                  ),
                ),
                CsCardSection(id: 'origin', header: 'Origin', width: 50, content: (context, d) => Text(d.origin)),
                CsCardSection(id: 'price', header: 'Price class', content: (context, d) => Text(d.priceClass)),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Full page, single selection, two per row',
          child: CsCards<_Distribution>(
            variant: CsCardsVariant.fullPage,
            header: const CsHeader(variant: CsHeaderVariant.h1, title: 'Origins'),
            items: _distributions.take(4).toList(),
            cardsPerRow: const [CsCardsLayout(cards: 1), CsCardsLayout(cards: 2, minWidth: 500)],
            selectionType: CsSelectionType.single,
            selectedItems: _selected.take(1).toList(),
            onSelectionChange: (next) => setState(() => _selected = next),
            cardDefinition: CsCardDefinition<_Distribution>(
              header: (context, d) => Text(d.origin),
              sections: [CsCardSection(header: 'Distribution', content: (context, d) => Text(d.id))],
            ),
          ),
        ),
        const DemoSection(
          title: 'Empty',
          child: CsCards<_Distribution>(
            items: [],
            header: CsHeader(title: 'Distributions', counter: '(0)'),
            empty: CsBox(text: 'No distributions', color: CsBoxColor.inherit),
            cardDefinition: CsCardDefinition<_Distribution>(),
          ),
        ),
      ],
    );
  }
}

class _ItemCardDemo extends StatefulWidget {
  const _ItemCardDemo();

  @override
  State<_ItemCardDemo> createState() => _ItemCardDemoState();
}

class _ItemCardDemoState extends State<_ItemCardDemo> {
  bool _highlighted = false;
  int _actions = 0;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Default',
          caption: 'Press the card to toggle the highlighted (selected) look. Sample data.',
          child: CsItemCard(
            icon: const CsIcon(CsIcons.folder),
            header: const Text('example-bucket'),
            description: const Text('us-east-1'),
            highlighted: _highlighted,
            onPress: () => setState(() => _highlighted = !_highlighted),
            semanticLabel: 'example-bucket',
            actions: CsButton(
              icon: CsIcons.ellipsis,
              variant: CsButtonVariant.icon,
              semanticLabel: 'Bucket actions',
              onPress: () => setState(() => _actions++),
            ),
            footer: Text('Actions opened $_actions times'),
            child: const Text('Versioning enabled. 1,204 objects.'),
          ),
        ),
        const DemoSection(
          title: 'Embedded',
          child: CsItemCard(
            variant: CsItemCardVariant.embedded,
            header: Text('i-0abc123'),
            description: Text('t3.large'),
            child: CsStatusIndicator(text: 'Running'),
          ),
        ),
        const DemoSection(
          title: 'Style overrides and footer divider',
          child: CsItemCard(
            header: Text('example-logs'),
            style: CsItemCardStyle(borderRadius: 4, footerDividerColor: Color(0xFFB4BBC6)),
            footer: Text('Lifecycle: expire after 90 days'),
            child: Text('Standard-IA storage'),
          ),
        ),
        DemoSection(
          title: 'Equal heights with fitHeight',
          // A shared height for both cards, scaled with the text size so the
          // longer card never overflows at large text.
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(180),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CsSpace.m,
              children: [
                Expanded(
                  child: CsItemCard(
                    fitHeight: true,
                    header: Text('Requests'),
                    footer: Text('Last 24 hours'),
                    child: Text('1,024'),
                  ),
                ),
                Expanded(
                  child: CsItemCard(
                    fitHeight: true,
                    header: Text('Errors'),
                    footer: Text('Last 24 hours'),
                    child: Text('3 errors in the last hour, all from one origin.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCardDemo extends StatefulWidget {
  const _ActionCardDemo();

  @override
  State<_ActionCardDemo> createState() => _ActionCardDemoState();
}

class _ActionCardDemoState extends State<_ActionCardDemo> {
  String _last = 'Nothing yet';

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Choose a starting point',
          caption: 'Last pressed: $_last',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsActionCard(
                header: const Text('Launch instance'),
                description: const Text('Start a virtual server from an image.'),
                icon: const CsIcon(CsIcons.angleRight),
                onPress: () => setState(() => _last = 'Launch instance'),
              ),
              CsActionCard(
                header: const Text('Create bucket'),
                description: const Text('Store objects in a new bucket.'),
                icon: const CsIcon(CsIcons.angleRight),
                iconVerticalAlignment: CsActionCardIconVerticalAlignment.center,
                onPress: () => setState(() => _last = 'Create bucket'),
                child: const CsBox(variant: CsBoxVariant.small, text: 'Free tier eligible'),
              ),
              CsActionCard(
                variant: CsActionCardVariant.embedded,
                header: const Text('Open the documentation'),
                isLink: true,
                icon: const CsIcon(CsIcons.external),
                onFollow: () => setState(() => _last = 'Documentation link'),
              ),
              const CsActionCard(
                header: Text('Import a template'),
                description: Text('Unavailable while a stack updates.'),
                icon: CsIcon(CsIcons.upload),
                disabled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferencesDemo extends StatefulWidget {
  const _PreferencesDemo();

  @override
  State<_PreferencesDemo> createState() => _PreferencesDemoState();
}

class _PreferencesDemoState extends State<_PreferencesDemo> {
  CsCollectionPreferencesValue<bool> _prefs = const CsCollectionPreferencesValue(
    pageSize: 10,
    wrapLines: false,
    stripedRows: false,
    contentDensity: CsDensity.comfortable,
    stickyColumns: CsStickyColumns(first: 1),
    contentDisplay: [
      CsColumnDisplay(id: 'id'),
      CsColumnDisplay(id: 'name'),
      CsColumnDisplay(id: 'state'),
      CsColumnDisplay(id: 'type'),
      CsColumnDisplay(id: 'zone', visible: false),
      CsColumnDisplay(id: 'cpu'),
    ],
    custom: false,
  );

  @override
  Widget build(BuildContext context) {
    final p = _prefs;
    final columns = _instanceColumns();
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Preferences driving a table',
          caption: 'Open the gear, change preferences, then Confirm. Cancel keeps the table as it was.',
          child: CsTable<_Instance>(
            header: CsHeader(title: 'Instances', counter: '(${p.pageSize})'),
            preferences: CsCollectionPreferences<bool>(
              preferences: p,
              onConfirm: (next) => setState(() => _prefs = next),
              pageSizePreference: const CsPageSizePreference(
                options: [
                  CsPageSizeOption(value: 5, label: '5 instances'),
                  CsPageSizeOption(value: 10, label: '10 instances'),
                  CsPageSizeOption(value: 20, label: '20 instances'),
                ],
              ),
              wrapLinesPreference: const CsCheckboxPreference(),
              stripedRowsPreference: const CsCheckboxPreference(),
              contentDensityPreference: const CsCheckboxPreference(),
              stickyColumnsPreference: const CsStickyColumnsPreference(
                firstColumns: CsStickyColumnPreference(
                  title: 'Stick first column(s)',
                  description: 'Keep the first column(s) visible while horizontally scrolling the table content.',
                  options: [
                    (label: 'None', value: 0),
                    (label: 'First column', value: 1),
                    (label: 'First two columns', value: 2),
                  ],
                ),
                lastColumns: CsStickyColumnPreference(
                  title: 'Stick last column',
                  description: 'Keep the last column visible while horizontally scrolling the table content.',
                  options: [(label: 'None', value: 0), (label: 'Last column', value: 1)],
                ),
              ),
              contentDisplayPreference: const CsContentDisplayPreference(
                enableColumnFiltering: true,
                options: [
                  CsContentDisplayOption(id: 'id', label: 'Instance ID', alwaysVisible: true),
                  CsContentDisplayOption(id: 'name', label: 'Name'),
                  CsContentDisplayOption(id: 'state', label: 'State'),
                  CsContentDisplayOption(id: 'type', label: 'Type'),
                  CsContentDisplayOption(id: 'zone', label: 'Availability zone'),
                  CsContentDisplayOption(id: 'cpu', label: 'vCPU'),
                ],
              ),
              customPreference: (context, value, setValue) => CsCheckbox(
                checked: value ?? false,
                label: 'Show footer',
                description: 'A custom preference.',
                onChange: setValue,
              ),
            ),
            footer: (p.custom ?? false) ? const Text('Custom preference is on.') : null,
            items: _sampleInstances.take(p.pageSize ?? 10).toList(),
            columnDefinitions: [
              for (final c in columns)
                CsTableColumn<_Instance>(id: c.columnId, header: c.header, cell: c.cell, minWidth: 150),
            ],
            columnDisplay: p.contentDisplay,
            wrapLines: p.wrapLines ?? false,
            stripedRows: p.stripedRows ?? false,
            contentDensity: p.contentDensity ?? CsDensity.comfortable,
            stickyColumns: p.stickyColumns ?? CsStickyColumns.none,
          ),
        ),
        DemoSection(
          title: 'Disabled trigger',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: CsCollectionPreferences<void>(
              disabled: true,
              wrapLinesPreference: const CsCheckboxPreference(),
              onConfirm: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

Future<List<CsS3Bucket>> _fetchBuckets() async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return [
    for (var i = 1; i <= 14; i++)
      CsS3Bucket(
        name: 'example-bucket-$i',
        creationDate: '2024-${(i % 12 + 1).toString().padLeft(2, '0')}-0${i % 9 + 1}',
        region: _zones[i % 3].substring(0, _zones[i % 3].length - 1),
      ),
  ];
}

Future<List<CsS3Object>> _fetchObjects(String bucket, String path) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (path.isEmpty) {
    return const [
      CsS3Object(key: 'logs', isFolder: true),
      CsS3Object(key: 'reports', isFolder: true),
      CsS3Object(key: 'index.html', size: 4210, lastModified: '2024-05-01 10:12'),
      CsS3Object(key: 'app.js', size: 182934, lastModified: '2024-05-02 08:40'),
    ];
  }
  return [
    for (var i = 1; i <= 6; i++) CsS3Object(key: 'file-$i.csv', size: 1024 * i * i, lastModified: '2024-04-0$i 09:00'),
  ];
}

Future<List<CsS3Version>> _fetchVersions(String bucket, String path) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  return [
    for (var i = 1; i <= 3; i++)
      CsS3Version(versionId: 'v-00$i-example', size: 2048 * i, lastModified: '2024-0$i-15 12:00'),
  ];
}

class _S3Demo extends StatefulWidget {
  const _S3Demo();

  @override
  State<_S3Demo> createState() => _S3DemoState();
}

class _S3DemoState extends State<_S3Demo> {
  CsS3Resource _read = const CsS3Resource(uri: '');
  String? _readError;
  CsS3Resource _write = const CsS3Resource(uri: '');
  String? _writeError;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Read mode: objects and versions',
          caption: 'Type a URI or browse. Folders cannot be chosen. Sample data with simulated delays.',
          child: CsFormField(
            errorText: _readError,
            constraintText:
                'Selected: ${_read.uri.isEmpty ? '-' : _read.uri}${_read.versionId == null ? '' : ' (${_read.versionId})'}',
            child: CsS3ResourceSelector(
              resource: _read,
              invalid: _readError != null,
              inputPlaceholder: 's3://bucket/prefix/object',
              selectableItemsTypes: const {CsS3SelectableItems.objects, CsS3SelectableItems.versions},
              objectsIsItemDisabled: (o) => o.isFolder,
              fetchBuckets: _fetchBuckets,
              fetchObjects: _fetchObjects,
              fetchVersions: _fetchVersions,
              onView: _read.uri.isEmpty ? null : () {},
              onChange: (c) => setState(() {
                _read = c.resource;
                _readError = c.errorText;
              }),
            ),
          ),
        ),
        DemoSection(
          title: 'Write mode: buckets and folders',
          child: CsFormField(
            errorText: _writeError,
            child: CsS3ResourceSelector(
              resource: _write,
              invalid: _writeError != null,
              selectableItemsTypes: const {CsS3SelectableItems.buckets, CsS3SelectableItems.objects},
              objectsIsItemDisabled: (o) => !o.isFolder,
              alert: const CsBox(
                variant: CsBoxVariant.small,
                color: CsBoxColor.textBodySecondary,
                text: 'Choose a bucket or folder to write the export to.',
              ),
              fetchBuckets: _fetchBuckets,
              fetchObjects: _fetchObjects,
              fetchVersions: _fetchVersions,
              onChange: (c) => setState(() {
                _write = c.resource;
                _writeError = c.errorText;
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionDemo extends StatefulWidget {
  const _CollectionDemo();

  @override
  State<_CollectionDemo> createState() => _CollectionDemoState();
}

class _CollectionDemoState extends State<_CollectionDemo> {
  late final CsCollection<_Instance> _collection;
  String _stateFilter = '';

  @override
  void initState() {
    super.initState();
    _collection = CsCollection<_Instance>(
      _sampleInstances,
      getField: (item, field) => item.field(field),
      filtering: const CsCollectionFiltering(
        fields: ['id', 'name', 'type'],
        empty: CsBox(text: 'No instances', color: CsBoxColor.inherit),
        noMatch: CsBox(text: 'No matches. Clear the filter to see all instances.', color: CsBoxColor.inherit),
      ),
      propertyFiltering: const CsCollectionPropertyFiltering(
        filteringProperties: [CsCollectionFilterProperty(key: 'state', propertyLabel: 'State')],
        noMatch: CsBox(text: 'No instances in this state.', color: CsBoxColor.inherit),
      ),
      sorting: const CsCollectionSorting(),
      pagination: const CsCollectionPagination(pageSize: 8),
      selection: CsCollectionSelection(trackBy: (i) => i.id, keepSelection: true),
    );
  }

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  void _setState(String state) {
    setState(() => _stateFilter = state);
    _collection.setPropertyFiltering(
      state.isEmpty
          ? CsCollectionFilterQuery.empty
          : CsCollectionFilterQuery(
              tokens: [CsCollectionFilterToken(propertyKey: 'state', operator: '=', value: state)],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Filter, sort, page and select',
          caption: 'The text filter searches ID, name and type; the buttons add a property filter on state.',
          child: ListenableBuilder(
            listenable: _collection,
            builder: (context, _) {
              final c = _collection;
              return CsTable<_Instance>(
                header: CsHeader(
                  title: 'Instances',
                  counter: c.selectedItems.isEmpty
                      ? '(${c.filteredItemsCount})'
                      : '(${c.selectedItems.length}/${c.filteredItemsCount})',
                  actions: Wrap(
                    spacing: CsSpace.xs,
                    children: [
                      for (final s in const ['', 'Running', 'Stopped', 'Pending'])
                        CsButton(
                          text: s.isEmpty ? 'All' : s,
                          variant: _stateFilter == s ? CsButtonVariant.primary : CsButtonVariant.normal,
                          onPress: () => _setState(s),
                        ),
                    ],
                  ),
                ),
                filter: Row(
                  spacing: CsSpace.s,
                  children: [
                    Expanded(
                      child: CsInput(
                        value: c.filteringText,
                        type: CsInputType.search,
                        placeholder: 'Find instances',
                        ariaLabel: 'Find instances',
                        onChange: c.setFiltering,
                      ),
                    ),
                    if (c.filteringText.isNotEmpty)
                      Text(c.filteredItemsCount == 1 ? '1 match' : '${c.filteredItemsCount} matches'),
                  ],
                ),
                pagination: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CsButton(
                      icon: CsIcons.angleLeft,
                      variant: CsButtonVariant.icon,
                      semanticLabel: 'Previous page',
                      disabled: c.currentPageIndex <= 1,
                      onPress: () => c.setCurrentPage(c.currentPageIndex - 1),
                    ),
                    Text('${c.currentPageIndex} / ${c.pagesCount}'),
                    CsButton(
                      icon: CsIcons.angleRight,
                      variant: CsButtonVariant.icon,
                      semanticLabel: 'Next page',
                      disabled: c.currentPageIndex >= c.pagesCount,
                      onPress: () => c.setCurrentPage(c.currentPageIndex + 1),
                    ),
                  ],
                ),
                items: c.items,
                trackBy: (i) => i.id,
                columnDefinitions: _instanceColumns(),
                sortingColumn: c.sortingColumn,
                sortingDescending: c.sortingDescending,
                onSortingChange: c.setSorting,
                selectionType: CsSelectionType.multi,
                selectedItems: c.selectedItems,
                onSelectionChange: c.setSelectedItems,
                empty: c.emptyState,
                firstIndex: c.firstIndex,
                totalItemsCount: c.filteredItemsCount,
                renderAriaLive: (d) => 'Displaying items ${d.firstIndex} to ${d.lastIndex} of ${d.totalItemsCount}',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Sample instances for the composable table demos.
class _PartsInstance {
  const _PartsInstance(this.name, this.id, this.type, this.state, this.zone);

  final String name;
  final String id;
  final String type;
  final String state;
  final String zone;
}

const _partsInstances = [
  _PartsInstance('web-server-1', 'i-0abc123', 't3.micro', 'Running', 'us-east-1a'),
  _PartsInstance('web-server-2', 'i-0abc124', 't3.micro', 'Stopped', 'us-east-1b'),
  _PartsInstance('batch-worker', 'i-0abc125', 'c6i.large', 'Running', 'us-east-1a'),
  _PartsInstance('bastion', 'i-0abc126', 't3.nano', 'Pending', 'us-east-1c'),
  _PartsInstance('analytics-db', 'i-0abc127', 'r6i.xlarge', 'Running', 'us-east-1b'),
];

CsStatusType _partsStatus(String state) => switch (state) {
  'Running' => CsStatusType.success,
  'Stopped' => CsStatusType.stopped,
  _ => CsStatusType.pending,
};

class _TableRootDemo extends StatefulWidget {
  const _TableRootDemo();

  @override
  State<_TableRootDemo> createState() => _TableRootDemoState();
}

class _TableRootDemoState extends State<_TableRootDemo> {
  bool _striped = false;
  bool _compact = false;
  bool _descending = false;
  final Set<String> _selected = {'i-0abc125'};

  @override
  Widget build(BuildContext context) {
    final items = [..._partsInstances]
      ..sort((a, b) => _descending ? b.name.compareTo(a.name) : a.name.compareTo(b.name));
    final all = _selected.length == items.length;
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Composed instances table',
          caption:
              'Sample data. Grid columns with a selection column, the first data column sticky when the table '
              'scrolls sideways.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              Wrap(
                spacing: CsSpace.l,
                runSpacing: CsSpace.xs,
                children: [
                  CsToggle(checked: _striped, onChange: (v) => setState(() => _striped = v), label: 'Striped rows'),
                  CsToggle(checked: _compact, onChange: (v) => setState(() => _compact = v), label: 'Compact'),
                ],
              ),
              CsTableRoot(
                ariaLabel: 'Instances',
                variant: CsTableVariant.container,
                stripedRows: _striped,
                contentDensity: _compact ? CsDensity.compact : CsDensity.comfortable,
                stickyColumns: const CsStickyColumns(first: 2),
                columnLayout: const CsTableColumnLayout.grid([
                  CsTableGridColumn.fixed(CsSize.tableSelectionHorizontal),
                  CsTableGridColumn(minWidth: 150, flex: 2),
                  CsTableGridColumn(minWidth: 110),
                  CsTableGridColumn(minWidth: 110),
                  CsTableGridColumn(minWidth: 120),
                ]),
                children: [
                  CsTableHead(
                    child: CsTableRow(
                      children: [
                        CsTableHeaderCell(
                          disablePaddings: true,
                          child: Center(
                            child: CsCheckbox(
                              checked: all,
                              indeterminate: _selected.isNotEmpty && !all,
                              ariaLabel: 'Select all instances',
                              onChange: (v) => setState(() {
                                _selected.clear();
                                if (v) _selected.addAll(items.map((i) => i.id));
                              }),
                            ),
                          ),
                        ),
                        CsTableHeaderCell(
                          sortingState: _descending ? CsTableSortingState.descending : CsTableSortingState.ascending,
                          onSort: () => setState(() => _descending = !_descending),
                          child: const Text('Name'),
                        ),
                        const CsTableHeaderCell(child: Text('Instance ID')),
                        const CsTableHeaderCell(child: Text('Type')),
                        const CsTableHeaderCell(child: Text('State')),
                      ],
                    ),
                  ),
                  CsTableBody(
                    children: [
                      for (final i in items)
                        CsTableRow(
                          selected: _selected.contains(i.id),
                          children: [
                            CsTableBodyCell(
                              disablePaddings: true,
                              child: Center(
                                child: CsCheckbox(
                                  checked: _selected.contains(i.id),
                                  ariaLabel: 'Select ${i.name}',
                                  onChange: (v) => setState(() => v ? _selected.add(i.id) : _selected.remove(i.id)),
                                ),
                              ),
                            ),
                            CsTableBodyCell(isRowHeader: true, child: Text(i.name)),
                            CsTableBodyCell(child: Text(i.id)),
                            CsTableBodyCell(child: Text(i.type)),
                            CsTableBodyCell(
                              child: CsStatusIndicator(type: _partsStatus(i.state), text: i.state),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeadDemo extends StatelessWidget {
  const _TableHeadDemo();

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Sticky header',
          caption: 'Scroll the 30 sample events: the head stays at the top and gains the sticky shadow.',
          child: SizedBox(
            height: 300,
            child: CsTableRoot(
              ariaLabel: 'Events',
              variant: CsTableVariant.container,
              stickyHeader: const CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(child: Text('Event')),
                    CsTableHeaderCell(child: Text('Resource')),
                  ],
                ),
              ),
              children: [
                CsTableBody(
                  children: [
                    for (var i = 0; i < 30; i++)
                      CsTableRow(
                        children: [
                          CsTableBodyCell(child: Text(i.isEven ? 'StartInstances' : 'StopInstances')),
                          CsTableBodyCell(child: Text('i-0abc${100 + i}')),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const DemoSection(
          title: 'Borderless head',
          caption: 'In the borderless variant the head has no fill, only the divider below.',
          child: CsTableRoot(
            children: [
              CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(child: Text('Bucket')),
                    CsTableHeaderCell(child: Text('Region')),
                  ],
                ),
              ),
              CsTableBody(
                children: [
                  CsTableRow(
                    children: [
                      CsTableBodyCell(child: Text('example-bucket')),
                      CsTableBodyCell(child: Text('us-east-1')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableBodyDemo extends StatefulWidget {
  const _TableBodyDemo();

  @override
  State<_TableBodyDemo> createState() => _TableBodyDemoState();
}

class _TableBodyDemoState extends State<_TableBodyDemo> {
  bool _empty = false;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Striped body and empty state',
          caption: 'Sample data. The empty state is one cell spanning every column.',
          child: CsSpaceBetween(
            size: CsSpacingSize.s,
            children: [
              CsToggle(checked: _empty, onChange: (v) => setState(() => _empty = v), label: 'No matches'),
              CsTableRoot(
                variant: CsTableVariant.container,
                stripedRows: true,
                children: [
                  const CsTableHead(
                    child: CsTableRow(
                      children: [
                        CsTableHeaderCell(child: Text('Distribution')),
                        CsTableHeaderCell(child: Text('Domain')),
                        CsTableHeaderCell(child: Text('Status')),
                      ],
                    ),
                  ),
                  CsTableBody(
                    children: _empty
                        ? [
                            const CsTableRow(
                              children: [
                                CsTableBodyCell(
                                  colSpan: 3,
                                  child: Center(child: Text('No distributions match the filter.')),
                                ),
                              ],
                            ),
                          ]
                        : [
                            for (var i = 0; i < 4; i++)
                              CsTableRow(
                                children: [
                                  CsTableBodyCell(child: Text('d11111${i}abcdef8')),
                                  CsTableBodyCell(child: Text('d11111${i}abcdef8.example.net')),
                                  const CsTableBodyCell(
                                    child: CsStatusIndicator(type: CsStatusType.success, text: 'Deployed'),
                                  ),
                                ],
                              ),
                          ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableRowDemo extends StatefulWidget {
  const _TableRowDemo();

  @override
  State<_TableRowDemo> createState() => _TableRowDemoState();
}

class _TableRowDemoState extends State<_TableRowDemo> {
  final Set<int> _selected = {1, 2};

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Selected and tappable rows',
          caption: 'Tap a row to toggle its selection; adjacent selected rows join into one outline.',
          child: CsTableRoot(
            variant: CsTableVariant.container,
            children: [
              const CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(child: Text('Name')),
                    CsTableHeaderCell(child: Text('Zone')),
                  ],
                ),
              ),
              CsTableBody(
                children: [
                  for (var i = 0; i < _partsInstances.length; i++)
                    CsTableRow(
                      selected: _selected.contains(i),
                      ariaLabel: _partsInstances[i].name,
                      onPress: () => setState(() => _selected.contains(i) ? _selected.remove(i) : _selected.add(i)),
                      children: [
                        CsTableBodyCell(child: Text(_partsInstances[i].name)),
                        CsTableBodyCell(child: Text(_partsInstances[i].zone)),
                      ],
                    ),
                  const CsTableRow(
                    shaded: true,
                    children: [
                      CsTableBodyCell(child: Text('Total')),
                      CsTableBodyCell(child: Text('5 instances')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCellDemo extends StatefulWidget {
  const _TableHeaderCellDemo();

  @override
  State<_TableHeaderCellDemo> createState() => _TableHeaderCellDemoState();
}

class _TableHeaderCellDemoState extends State<_TableHeaderCellDemo> {
  String _column = 'name';
  bool _descending = false;
  double _nameWidth = 180;

  CsTableSortingState _state(String column) => _column != column
      ? CsTableSortingState.sortable
      : (_descending ? CsTableSortingState.descending : CsTableSortingState.ascending);

  void _sort(String column) => setState(() {
    _descending = _column == column && !_descending;
    _column = column;
  });

  @override
  Widget build(BuildContext context) {
    final items = [..._partsInstances]
      ..sort((a, b) {
        final r = _column == 'name' ? a.name.compareTo(b.name) : a.type.compareTo(b.type);
        return _descending ? -r : r;
      });
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Sorting and resizing',
          caption:
              'Name and Type sort; drag the handle after Name to resize it (${_nameWidth.round()}px). '
              'Zone shows a sorting state that cannot change.',
          child: CsTableRoot(
            variant: CsTableVariant.container,
            columnLayout: CsTableColumnLayout.grid([
              CsTableGridColumn.fixed(_nameWidth),
              const CsTableGridColumn(minWidth: 110),
              const CsTableGridColumn(minWidth: 110),
            ]),
            children: [
              CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(
                      sortingState: _state('name'),
                      onSort: () => _sort('name'),
                      resizable: true,
                      onResize: (w) => setState(() => _nameWidth = w),
                      child: const Text('Name'),
                    ),
                    CsTableHeaderCell(
                      sortingState: _state('type'),
                      onSort: () => _sort('type'),
                      editable: true,
                      child: const Text('Type'),
                    ),
                    const CsTableHeaderCell(
                      sortingState: CsTableSortingState.ascending,
                      sortingDisabled: true,
                      child: Text('Zone'),
                    ),
                  ],
                ),
              ),
              CsTableBody(
                children: [
                  for (final i in items)
                    CsTableRow(
                      children: [
                        CsTableBodyCell(child: Text(i.name)),
                        CsTableBodyCell(child: Text(i.type)),
                        CsTableBodyCell(child: Text(i.zone)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableBodyCellDemo extends StatefulWidget {
  const _TableBodyCellDemo();

  @override
  State<_TableBodyCellDemo> createState() => _TableBodyCellDemoState();
}

class _TableBodyCellDemoState extends State<_TableBodyCellDemo> {
  final Map<String, String> _names = {for (final i in _partsInstances) i.id: i.name};
  String? _editing;

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Inline edit',
          caption:
              'Hover or focus a name to see the edit affordance; tap to edit, Enter to save. '
              'Running instances cannot be renamed in this sample.',
          child: CsTableRoot(
            variant: CsTableVariant.container,
            children: [
              const CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(editable: true, child: Text('Name')),
                    CsTableHeaderCell(child: Text('State')),
                  ],
                ),
              ),
              CsTableBody(
                children: [
                  for (final i in _partsInstances.take(3))
                    CsTableRow(
                      children: [
                        _editing == i.id
                            ? CsTableBodyCell(
                                child: CsInput(
                                  value: _names[i.id]!,
                                  autoFocus: true,
                                  onChange: (v) => setState(() => _names[i.id] = v),
                                  onSubmit: (_) => setState(() => _editing = null),
                                ),
                              )
                            : CsTableBodyCell(
                                editable: true,
                                editAriaLabel: 'Edit name of ${i.id}',
                                editDisabledReason: i.state == 'Running' ? 'Stop the instance to rename it.' : null,
                                onEdit: () => setState(() => _editing = i.id),
                                child: Text(_names[i.id]!),
                              ),
                        CsTableBodyCell(
                          child: CsStatusIndicator(type: _partsStatus(i.state), text: i.state),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Wrapping, alignment and spans',
          child: CsTableRoot(
            variant: CsTableVariant.container,
            children: [
              CsTableHead(
                child: CsTableRow(
                  children: [
                    CsTableHeaderCell(child: Text('Rule')),
                    CsTableHeaderCell(child: Text('Description')),
                    CsTableHeaderCell(child: Text('Port')),
                  ],
                ),
              ),
              CsTableBody(
                children: [
                  CsTableRow(
                    children: [
                      CsTableBodyCell(
                        isRowHeader: true,
                        verticalAlign: CsTableVerticalAlign.top,
                        child: Text('allow-https'),
                      ),
                      CsTableBodyCell(
                        wrapLines: true,
                        child: Text(
                          'Allows inbound HTTPS from the load balancer security group to the web servers in every '
                          'Availability Zone.',
                        ),
                      ),
                      CsTableBodyCell(verticalAlign: CsTableVerticalAlign.top, child: Text('443')),
                    ],
                  ),
                  CsTableRow(
                    children: [
                      CsTableBodyCell(isRowHeader: true, child: Text('default')),
                      CsTableBodyCell(colSpan: 2, child: Text('Spans the description and port columns')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
