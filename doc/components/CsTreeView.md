# CsTreeView

Shows hierarchical items, such as folders and objects in a bucket or nested resources, that people can expand and collapse.

Cloudscape reference: https://cloudscape.design/components/tree-view/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
class Node {
  const Node(this.id, this.name, [this.children]);
  final String id;
  final String name;
  final List<Node>? children;
}

class BucketTree extends StatefulWidget {
  const BucketTree({super.key});

  @override
  State<BucketTree> createState() => _BucketTreeState();
}

class _BucketTreeState extends State<BucketTree> {
  final expanded = <String>{'logs'};

  @override
  Widget build(BuildContext context) {
    return CsTreeView<Node>(
      ariaLabel: 'example-bucket',
      items: const [
        Node('logs', 'logs', [Node('jan', 'january.log'), Node('feb', 'february.log')]),
        Node('index', 'index.html'),
      ],
      expandedItems: expanded,
      getItemId: (node, index) => node.id,
      getItemChildren: (node, index) => node.children,
      onItemToggle: (detail) => setState(() {
        detail.expanded ? expanded.add(detail.id) : expanded.remove(detail.id);
      }),
      renderItem: (node, index) => CsTreeViewItem(
        icon: CsIcon(node.children == null ? CsIcons.file : CsIcons.folder),
        content: Text(node.name),
      ),
    );
  }
}
```

## When to use / when not to

- Use for content with a real hierarchy that people browse: object prefixes, organizational units, nested stacks.
- Do not use for page navigation (use `CsSideNavigation`) or for tabular data with columns (use a table with expandable rows).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<T>` | required | The top-level items. |
| `renderItem` | `CsTreeViewItem Function(T, int)` | required | Maps an item to `content`, `icon`, `secondaryContent`, `actions` and `announcementLabel`. |
| `getItemId` | `String Function(T, int)` | required | A unique id per item. |
| `getItemChildren` | `List<T>? Function(T, int)` | required | The item's children; null or empty for a leaf. |
| `expandedItems` | `Set<String>` | `{}` | Ids of the expanded items. |
| `onItemToggle` | `ValueChanged<CsTreeViewItemToggleDetail<T>>?` | `null` | `id`, `item` and the requested `expanded` state. |
| `connectorLines` | `CsTreeViewConnectorLines` | `none` | `vertical` draws a line beside the children of each expanded item. |
| `i18nStrings` | `CsTreeViewI18nStrings<T>` | English | `expandButtonLabel(item)`, `collapseButtonLabel(item)`; default "Expand" and "Collapse". |
| `renderItemToggleIcon` | `Widget Function(bool expanded)?` | `null` | Replaces the caret. |
| `ariaLabel` | `String?` | `null` | Accessible name of the tree. |

## Examples

### Connector lines, secondary content and actions

```dart
CsTreeView<String>(
  items: const ['logs/', 'index.html'],
  expandedItems: const {'logs/'},
  connectorLines: CsTreeViewConnectorLines.vertical,
  getItemId: (path, index) => path,
  getItemChildren: (path, index) => path == 'logs/' ? const ['logs/january.log'] : null,
  renderItem: (path, index) => CsTreeViewItem(
    icon: CsIcon(path.endsWith('/') ? CsIcons.folder : CsIcons.file),
    content: Text(path),
    secondaryContent: const Text('Last modified 2 hours ago'),
    actions: CsButton(
      variant: CsButtonVariant.inlineIcon,
      icon: CsIcons.download,
      semanticLabel: 'Download $path',
      onPress: () {},
    ),
  ),
)
```

## Accessibility

- The tree is a labeled container. Each row announces its `announcementLabel` (or content), its expanded state, and its level and position ("level 2, 1 of 3").
- One row is in the Tab order (roving focus). Up and Down move between visible rows, Home and End jump to the first and last, Right expands or moves to the first child, Left collapses or moves to the parent, Enter and Space toggle. Arrow directions flip in right-to-left layouts.
- Toggles are named by `expandButtonLabel` and `collapseButtonLabel`. Collapsing a branch that holds focus moves focus to its item.

## Motion

Children expand and collapse with Cloudscape's expandable motion and the caret turns 90 degrees (`CsDurations.rotate90`). Reduced motion makes both instant.

## Mobile

Rows wrap long content. On touch screens the toggle's hit area grows to 32px without changing the layout. Each level indents 24px (`CsSpace.treeViewIndentation`); keep trees shallow on phones.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` | `items` |
| `renderItem` (`content`, `icon`, `secondaryContent`, `actions`, `announcementLabel`) | `renderItem` (`CsTreeViewItem`) |
| `getItemId`, `getItemChildren` | same names |
| `expandedItems` | `expandedItems` (a `Set<String>`) |
| `onItemToggle` | `onItemToggle` (`CsTreeViewItemToggleDetail`) |
| `connectorLines` | `connectorLines` |
| `i18nStrings` | `i18nStrings` |
| `renderItemToggleIcon` | `renderItemToggleIcon` |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby`, `ariaDescribedby` | not applicable; use `ariaLabel` |
