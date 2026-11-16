# CsKeyValuePairs

Labeled values of a resource in up to four responsive columns, such as the details section of an instance or a distribution.

Cloudscape reference: https://cloudscape.design/components/key-value-pairs/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const details = CsKeyValuePairs(
  columns: 3,
  items: [
    CsKeyValuePair(label: 'Distribution ID', value: 'd111111abcdef8'),
    CsKeyValuePair(label: 'Price class', value: 'Use all edge locations'),
    CsKeyValuePair(label: 'Domain name', value: 'd111111abcdef8.cloudfront.example'),
  ],
);
```

## When to use / when not to

- Use it for read-only properties of one resource, usually inside a `CsContainer` on a details page.
- Group related pairs with `CsKeyValueGroup` and a title when there are many.
- Do not use it for editable values (use a form) or for many resources (use a table).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsKeyValueItem>` | required | `CsKeyValuePair`s and `CsKeyValueGroup`s, mixed freely, laid out row by row. |
| `columns` | `int` | `1` | Maximum columns, 1 to 4 (values above 4 use 4). |
| `minColumnWidth` | `double` | `150` | Minimum width of a column. Fewer columns are used when they do not fit. |
| `ariaLabel` | `String?` | `null` | Accessible name of the whole list. |

`CsKeyValuePair`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | The key. |
| `labelWidget` | `Widget?` | `null` | Custom label content. |
| `value` | `String?` | `null` | The value as text. One of `value` and `valueWidget` is required. |
| `valueWidget` | `Widget?` | `null` | The value as a widget (status indicator, link, copy control). Wins over `value`. |
| `info` | `Widget?` | `null` | Area after the label, usually an "Info" link. |
| `id` | `String?` | `null` | Stable identifier, used as the pair's key. |

`CsKeyValueGroup`: `items` (`List<CsKeyValuePair>`, required) and `title` (`String?`, an h3 heading).

`CsKeyValuePairs.columnCountFor(columns, minColumnWidth, width)` returns the columns used at a width.

## Examples

### Values with status and an info link

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
import 'package:flutter/widgets.dart';

Widget details(VoidCallback openHelp) => CsKeyValuePairs(
  columns: 2,
  items: [
    const CsKeyValuePair(label: 'Instance ID', value: 'i-0abc123'),
    CsKeyValuePair(
      label: 'State',
      info: CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: openHelp),
      valueWidget: const CsStatusIndicator(type: CsStatusType.success, text: 'Running'),
    ),
  ],
);
```

### Groups

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';

const groups = CsKeyValuePairs(
  columns: 2,
  items: [
    CsKeyValueGroup(
      title: 'Origin',
      items: [
        CsKeyValuePair(label: 'Bucket', value: 'example-bucket'),
        CsKeyValuePair(label: 'Origin path', value: '/static'),
      ],
    ),
    CsKeyValueGroup(
      title: 'Behavior',
      items: [CsKeyValuePair(label: 'Viewer protocol', value: 'Redirect HTTP to HTTPS')],
    ),
  ],
);
```

## Accessibility

Each pair is its own semantics node, so a screen reader reads the label and then its value. Links inside values default to the underlined primary variant (`CsLinkDefaults`), as in Cloudscape. Pass `ariaLabel` when the list has no visible heading.

## Motion

None.

## Mobile

Columns follow the width, not the device: at most `columns`, each at least `minColumnWidth` wide, and an even count when wrapping (four columns become two, never three). At 390px with the default 150px minimum, four columns become two, and inside a padded container usually one. Labels and values wrap; nothing overflows at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` (`type: 'pair'`) | `CsKeyValuePair` |
| `items` (`type: 'group'`) | `CsKeyValueGroup` |
| `columns` | `columns` |
| `minColumnWidth` | `minColumnWidth` |
| `ariaLabel` | `ariaLabel` |
| `ariaLabelledby` | not applicable (use `ariaLabel`) |
| pair `label`, `value`, `info`, `id` | `label`/`labelWidget`, `value`/`valueWidget`, `info`, `id` |
