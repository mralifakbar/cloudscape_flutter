import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

import '../demo.dart';

/// Board and board items for configurable dashboards, with the items palette. Every name and figure here is sample data.
final CsDemoCategory boardCategory = CsDemoCategory(
  title: 'Dashboard board',
  description: 'Board and board items for configurable dashboards, with the items palette.',
  icon: CsIcons.gridView,
  demos: [
    CsDemo(
      title: 'CsBoard',
      description: 'Drag to reorder, resize from the corner, use the keyboard, remove items, add from a palette.',
      docPath: 'doc/components/CsBoard.md',
      builder: (_) => const _BoardDemo(),
    ),
    CsDemo(
      title: 'CsBoardItem',
      description: 'Header, settings, content, footer and full-bleed content.',
      docPath: 'doc/components/CsBoardItem.md',
      builder: (_) => const _BoardItemDemo(),
    ),
    CsDemo(
      title: 'CsItemsPalette',
      description: 'Widgets to drag onto a board, or add with the button or the keyboard.',
      docPath: 'doc/components/CsItemsPalette.md',
      builder: (_) => const _PaletteDemo(),
    ),
  ],
);

/// Sample widget data: a title and two lines of sample metrics.
class _Widget {
  const _Widget(this.title, this.summary, this.detail);
  final String title;
  final String summary;
  final String detail;
}

const _health = _Widget(
  'Instance health',
  '12 of 12 instances healthy',
  'i-0abc123, i-0def456 and 10 more in us-east-1',
);
const _cost = _Widget('Monthly cost', '1,284.50 USD so far', '8% more than last month at this point');
const _alarms = _Widget('Alarms', '2 in alarm, 14 OK', 'HighCPU on i-0abc123, 5xxErrors on d111111abcdef8');
const _storage = _Widget('Storage', '1.2 TB in example-bucket', '48,210 objects, versioning enabled');
const _traffic = _Widget('Network traffic', '3.4 GB in, 1.1 GB out', 'Last hour, all instances');
const _errors = _Widget('Error rate', '0.4% of requests', 'Distribution d111111abcdef8, last 24 hours');
const _latency = _Widget('Latency', 'p95 182 ms', 'API stage prod, last hour');

List<CsBoardEntry<_Widget>> _initialBoard() => const [
  CsBoardEntry(id: 'health', data: _health, columnSpan: 2),
  CsBoardEntry(id: 'cost', data: _cost, columnSpan: 2),
  CsBoardEntry(id: 'alarms', data: _alarms, columnSpan: 1, rowSpan: 3),
  CsBoardEntry(id: 'storage', data: _storage, columnSpan: 3, definition: CsBoardItemDefinition(minColumnSpan: 2)),
];

List<CsItemsPaletteItem<_Widget>> _initialPalette() => const [
  CsItemsPaletteItem(
    id: 'traffic',
    data: _traffic,
    definition: CsBoardItemDefinition(defaultColumnSpan: 2, defaultRowSpan: 2),
  ),
  CsItemsPaletteItem(id: 'errors', data: _errors, definition: CsBoardItemDefinition(defaultColumnSpan: 1)),
  CsItemsPaletteItem(
    id: 'latency',
    data: _latency,
    definition: CsBoardItemDefinition(defaultColumnSpan: 2, defaultRowSpan: 3),
  ),
];

CsBoardItemI18nStrings _handles(String title) => CsBoardItemI18nStrings(
  dragHandleAriaLabel: 'Drag $title',
  resizeHandleAriaLabel: 'Resize $title',
  dragHandleTooltipText: 'Drag to move',
  resizeHandleTooltipText: 'Drag to resize',
  addButtonAriaLabel: 'Add $title to the board',
);

CsBoardI18nStrings<_Widget> _announcements() => CsBoardI18nStrings<_Widget>(
  liveAnnouncementDndItemReordered: (s) =>
      '${s.item.data.title} moved to column ${s.placement.x + 1}, row ${s.placement.y + 1}.',
  liveAnnouncementDndItemResized: (s) =>
      '${s.item.data.title} resized to ${s.placement.width} columns and ${s.placement.height} rows.',
  liveAnnouncementDndItemInserted: (s) =>
      '${s.item.data.title} inserted at column ${s.placement.x + 1}, row ${s.placement.y + 1}.',
  liveAnnouncementItemRemoved: (s) => '${s.item.data.title} removed.',
);

Widget _boardItem(_Widget w, {VoidCallback? onRemove, bool preview = false}) => CsBoardItem(
  header: CsHeader(title: w.title),
  i18nStrings: _handles(w.title),
  settings: onRemove == null
      ? null
      : CsButton(
          variant: CsButtonVariant.icon,
          icon: CsIcons.close,
          semanticLabel: 'Remove ${w.title}',
          onPress: onRemove,
        ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CsSpace.xxs,
    children: [
      CsBox(variant: CsBoxVariant.awsuiValueLarge, text: w.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
      CsBox(color: CsBoxColor.textBodySecondary, variant: CsBoxVariant.small, text: preview ? 'Preview' : w.detail),
    ],
  ),
);

class _BoardDemo extends StatefulWidget {
  const _BoardDemo();

  @override
  State<_BoardDemo> createState() => _BoardDemoState();
}

class _BoardDemoState extends State<_BoardDemo> {
  List<CsBoardEntry<_Widget>> _items = _initialBoard();
  List<CsItemsPaletteItem<_Widget>> _palette = _initialPalette();
  String _last = 'No changes yet.';

  void _onChange(CsBoardItemsChange<_Widget> change) {
    setState(() {
      _items = change.items;
      final added = change.addedItem;
      if (added != null) _palette = _palette.where((p) => p.id != added.id).toList();
      final removed = change.removedItem;
      if (removed != null && _initialPalette().any((p) => p.id == removed.id)) {
        _palette = [..._palette, _initialPalette().firstWhere((p) => p.id == removed.id)];
      }
      _last = switch (change) {
        CsBoardItemsChange(movedItem: final m?) => 'Moved ${m.data.title}.',
        CsBoardItemsChange(resizedItem: final r?) => 'Resized ${r.data.title} to ${r.columnSpan} x ${r.rowSpan}.',
        CsBoardItemsChange(addedItem: final a?) => 'Added ${a.data.title}.',
        CsBoardItemsChange(removedItem: final r?) => 'Removed ${r.data.title}.',
        _ => 'Changed.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Dashboard',
          caption:
              'Drag a handle to move, the corner to resize. With the keyboard: focus a handle, Enter, arrow keys, Enter. '
              'Columns follow the width: 1, 2, 4 or 6.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CsSpace.s,
            children: [
              CsBoard<_Widget>(
                items: _items,
                i18nStrings: _announcements(),
                onItemsChange: _onChange,
                renderItem: (context, item, actions) => _boardItem(item.data, onRemove: actions.removeItem),
                empty: Column(
                  spacing: CsSpace.s,
                  children: [
                    const CsBox(variant: CsBoxVariant.strong, text: 'No widgets'),
                    const CsBox(text: 'Add widgets from the palette below.'),
                    CsButton(
                      text: 'Reset to default layout',
                      onPress: () => setState(() {
                        _items = _initialBoard();
                        _palette = _initialPalette();
                      }),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: CsSpace.m,
                runSpacing: CsSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CsBox(color: CsBoxColor.textBodySecondary, text: _last),
                  CsButton(
                    text: 'Reset layout',
                    variant: CsButtonVariant.link,
                    onPress: () => setState(() {
                      _items = _initialBoard();
                      _palette = _initialPalette();
                    }),
                  ),
                  CsButton(
                    text: 'Remove all',
                    variant: CsButtonVariant.link,
                    onPress: () => setState(() => _items = const []),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Add widgets',
          caption: 'Drag by the handle, press and hold on touch, or use the add button.',
          child: _palette.isEmpty
              ? const CsBox(color: CsBoxColor.textBodySecondary, text: 'Every widget is on the board.')
              : CsItemsPalette<_Widget>(
                  items: _palette,
                  renderItem: (context, item, ctx) => _boardItem(item.data, preview: ctx.showPreview),
                  onItemAdd: (item) => _onChange(
                    CsBoardItemsChange(items: [..._items, item.toBoardEntry()], addedItem: item.toBoardEntry()),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BoardItemDemo extends StatelessWidget {
  const _BoardItemDemo();

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Header, settings and footer',
          caption: 'Outside a board the handles are inert and the item takes its natural height.',
          child: CsBoardItem(
            header: const CsHeader(title: 'Instance health', description: 'us-east-1'),
            settings: CsButton(
              variant: CsButtonVariant.icon,
              icon: CsIcons.ellipsis,
              semanticLabel: 'Instance health settings',
              onPress: () {},
            ),
            footer: const CsBox(color: CsBoxColor.textBodySecondary, text: 'Updated 2 minutes ago'),
            child: const CsBox(text: '12 of 12 instances healthy'),
          ),
        ),
        DemoSection(
          title: 'Full-bleed content',
          caption: 'disableContentPaddings removes the content padding.',
          child: CsBoardItem(
            header: const CsHeader(title: 'Requests per minute'),
            disableContentPaddings: true,
            child: Builder(
              builder: (context) => Container(
                height: 96,
                color: context.cs.colors.backgroundContainerHeader,
                alignment: Alignment.center,
                child: const CsBox(color: CsBoxColor.textBodySecondary, text: 'Chart area'),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'On a board',
          caption: 'Inside a board the item fills its cells and shows the resize handle.',
          child: CsBoard<_Widget>(
            columns: 1,
            items: const [CsBoardEntry(id: 'single', data: _alarms)],
            onItemsChange: (_) {},
            renderItem: (context, item, actions) => _boardItem(item.data),
          ),
        ),
      ],
    );
  }
}

class _PaletteDemo extends StatefulWidget {
  const _PaletteDemo();

  @override
  State<_PaletteDemo> createState() => _PaletteDemoState();
}

class _PaletteDemoState extends State<_PaletteDemo> {
  List<CsBoardEntry<_Widget>> _board = const [];
  List<CsItemsPaletteItem<_Widget>> _palette = _initialPalette();

  @override
  Widget build(BuildContext context) {
    return DemoColumn(
      children: [
        DemoSection(
          title: 'Board',
          caption: 'Drop palette items here. Remove one to return it to the palette.',
          child: CsBoard<_Widget>(
            items: _board,
            onItemsChange: (c) => setState(() {
              _board = c.items;
              final added = c.addedItem;
              if (added != null) _palette = _palette.where((p) => p.id != added.id).toList();
              final removed = c.removedItem;
              if (removed != null) _palette = [..._palette, _initialPalette().firstWhere((p) => p.id == removed.id)];
            }),
            renderItem: (context, item, actions) => _boardItem(item.data, onRemove: actions.removeItem),
            empty: const CsBox(text: 'Drag a widget here, or use its add button.'),
          ),
        ),
        DemoSection(
          title: 'Palette',
          child: _palette.isEmpty
              ? const CsBox(color: CsBoxColor.textBodySecondary, text: 'Every widget is on the board.')
              : CsItemsPalette<_Widget>(
                  items: _palette,
                  renderItem: (context, item, ctx) => _boardItem(item.data, preview: ctx.showPreview),
                  onItemAdd: (item) => setState(() {
                    _board = [..._board, item.toBoardEntry()];
                    _palette = _palette.where((p) => p.id != item.id).toList();
                  }),
                ),
        ),
      ],
    );
  }
}
