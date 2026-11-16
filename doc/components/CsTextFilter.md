# CsTextFilter

Cloudscape's `TextFilter`: a search input that filters a collection by text, with the match count next to it.

Cloudscape reference: https://cloudscape.design/components/text-filter/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTextFilter(
  filteringText: 'web',
  filteringPlaceholder: 'Find instances',
  countText: '3 matches',
  onChange: (text) {},
)
```

## When to use / when not to

Use it above a table or card list when free-text search is enough. For structured filters by property use `CsPropertyFilter`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `filteringText` | `String` | required | The text |
| `onChange` | `ValueChanged<String>?` | | Every edit |
| `onDelayedChange` | `ValueChanged<String>?` | | 400ms after the last edit (server filtering) |
| `filteringPlaceholder` | `String?` | | |
| `filteringAriaLabel` | `String?` | placeholder | |
| `filteringClearAriaLabel` | `String?` | "Clear" | |
| `countText` | `String?` | | Shown while there is text |
| `loading` | `bool` | `false` | Pauses count announcements |
| `disabled` | `bool` | `false` | |
| `focusNode`, `autoFocus` | | | |

## Examples

### Server filtering

```dart
CsTextFilter(
  filteringText: '',
  filteringPlaceholder: 'Find distributions',
  onChange: (text) {},
  onDelayedChange: (text) {},
)
```

## Accessibility

A search text field with a clear button. Changes to `countText` are announced (not while `loading`).

## Motion

None.

## Mobile

The filter fills the width (at most 648px) and the count stays on one line beside it.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `filteringText`, `filteringPlaceholder`, `filteringAriaLabel`, `filteringClearAriaLabel`, `countText`, `loading`, `disabled` | same names |
| `onChange`, `onDelayedChange` (`detail.filteringText`) | `onChange`, `onDelayedChange` (the text) |
| `controlId`, `ariaLabelledby`, `style` | not applicable |
