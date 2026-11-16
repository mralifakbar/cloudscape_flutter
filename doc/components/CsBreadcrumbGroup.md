# CsBreadcrumbGroup

Shows the path from the top of a service's hierarchy to the current page, so people can see where they are and move up.

Cloudscape reference: https://cloudscape.design/components/breadcrumb-group/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsBreadcrumbGroup(
  items: const [
    CsBreadcrumbGroupItem(text: 'Service', href: '/'),
    CsBreadcrumbGroupItem(text: 'Buckets', href: '/buckets'),
    CsBreadcrumbGroupItem(text: 'example-bucket', href: '/buckets/example-bucket'),
  ],
  onFollow: (item) => Navigator.of(context).pushNamed(item.href),
)
```

## When to use / when not to

- Use at the top of every page below the service root, inside the app layout's breadcrumbs slot.
- Do not use for a flat app with one level, or as a step indicator (use `CsWizard` or `CsSteps`).
- The last item is always the current page and is not a link.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsBreadcrumbGroupItem>` | required | The path, root first. The last item is the current page. |
| `onFollow` | `ValueChanged<CsBreadcrumbGroupItem>?` | `null` | Called when an item other than the current page is followed. Navigate here. |
| `onClick` | `ValueChanged<CsBreadcrumbGroupItem>?` | `null` | Called on every item activation before `onFollow`, for side effects. |
| `ariaLabel` | `String?` | `CsStrings.breadcrumbs` | Accessible name of the group. |
| `expandAriaLabel` | `String?` | `'Show path'` | Accessible name of the ellipsis button. Overrides `i18nStrings`. |
| `i18nStrings` | `CsBreadcrumbGroupI18nStrings` | English | `expandAriaLabel`, `ariaLabel`. |
| `presentation` | `CsPresentation` | `auto` | How the collapsed items open: a dropdown on wide screens, a bottom sheet on phones. |

`CsBreadcrumbGroupItem(text:, href:, data:)`: `href` is a path or route name that identifies the item; the widget never opens it. `data` carries any value of yours.

## Examples

### Collapsing on narrow widths

When the items do not fit, the ones after the first collapse into an ellipsis button that lists them. When only the first item would remain, the whole path becomes one button with the current page title.

```dart
SizedBox(
  width: 280,
  child: CsBreadcrumbGroup(
    items: const [
      CsBreadcrumbGroupItem(text: 'Service', href: '/'),
      CsBreadcrumbGroupItem(text: 'Distributions', href: '/distributions'),
      CsBreadcrumbGroupItem(text: 'd111111abcdef8', href: '/distributions/d111111abcdef8'),
      CsBreadcrumbGroupItem(text: 'Behaviors', href: '/distributions/d111111abcdef8/behaviors'),
    ],
    onFollow: (item) {},
  ),
)
```

### Carrying route data

```dart
CsBreadcrumbGroup(
  items: const [
    CsBreadcrumbGroupItem(text: 'Instances', href: 'instances'),
    CsBreadcrumbGroupItem(text: 'i-0abc123', href: 'instance', data: 'i-0abc123'),
  ],
  onFollow: (item) => Navigator.of(context).pushNamed(item.href, arguments: item.data),
)
```

## Accessibility

- The group is a labeled container ("Breadcrumbs" by default).
- Items are links; the current page is announced as a disabled, selected link (Cloudscape's `aria-current="page"`).
- The ellipsis button announces `expandAriaLabel` and its expanded state. Its menu takes focus; arrow keys move between items and Escape closes it.
- A truncated current page title shows the full text in a tooltip on hover, focus and long press.

## Motion

The caret of the collapsed path button turns 180 degrees when the list opens (`CsDurations.responsive`). The dropdown scales from its trigger; reduced motion makes both instant.

## Mobile

At or below 688px the list of collapsed items opens as a bottom sheet. Widths are measured with the current text scale, so 2x text collapses earlier instead of overflowing.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` (`text`, `href`) | `items` (`CsBreadcrumbGroupItem.text`, `.href`) |
| `onFollow` | `onFollow` (receives the item) |
| `onClick` | `onClick` (receives the item) |
| `ariaLabel` | `ariaLabel` |
| `expandAriaLabel` | `expandAriaLabel` or `i18nStrings.expandAriaLabel` |
| one-theme `slash-divider` separators | not applicable (visual refresh only) |
