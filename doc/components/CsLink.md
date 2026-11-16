# CsLink

A text link that navigates somewhere or opens related content, such as the help panel.

Cloudscape reference: https://cloudscape.design/components/link/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsLink(
  text: 'View bucket policy',
  onFollow: () => Navigator.of(context).pushNamed('/buckets/example-bucket/policy'),
)
```

## When to use / when not to

- Use a link to move to another page or to open related content (an "Info" link opening the help panel).
- Use a button (`CsButton`) for actions that change something, such as "Delete" or "Launch instance".
- Use `CsLinkVariant.primary` next to other text (inside a paragraph, a table cell, a key-value pair, an alert) so the underline separates it from the surrounding words.
- Use `CsLinkVariant.secondary` (the default) where the context already says the text is interactive, such as a list of links.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required | The link text. |
| `onFollow` | `VoidCallback?` | `null` | Called when the link is followed. Navigate here. Without `onFollow` and `onClick` the link is inert text. |
| `onClick` | `VoidCallback?` | `null` | Called on every activation before `onFollow`, for side effects such as metrics. |
| `href` | `String?` | `null` | Where the link points. Only used for semantics (announced as a link instead of a button). Never opened by the widget. |
| `variant` | `CsLinkVariant?` | `null` | `primary`, `secondary`, `info` or `awsuiValueLarge`. Null takes the nearest `CsLinkDefaults`, else `secondary`. |
| `color` | `CsLinkColor` | `normal` | `inverted` for links on colored backgrounds (flash messages). Ignored for `info`. |
| `fontSize` | `CsLinkFontSize?` | `null` | `bodyS` to `headingXl`, `displayL` or `inherit`. Null inherits the surrounding text size (display-l for `awsuiValueLarge`). Ignored for `info`. |
| `external` | `bool` | `false` | Adds the external icon and announces that the link opens in a new window. |
| `externalIconAriaLabel` | `String?` | `CsStrings.opensInNewWindow` | Accessible text for the external icon. |
| `ariaLabel` | `String?` | `null` | Accessible name that replaces `text`. |
| `focusNode` | `FocusNode?` | `null` | Move focus to the link (`ref.focus()` in Cloudscape). |
| `autofocus` | `bool` | `false` | Focus the link when it first builds. |
| `maxLines` | `int?` | `null` | Clamp the text with an ellipsis. |

`CsLinkDefaults(variant:, child:)` sets the default variant for the links below it. Tables, cards, alerts and popovers set it to `primary`, as Cloudscape does.

## Examples

### Variants

```dart
Wrap(
  spacing: 16,
  children: [
    CsLink(text: 'Secondary', onFollow: () {}),
    CsLink(text: 'Primary', variant: CsLinkVariant.primary, onFollow: () {}),
    CsLink(text: 'Info', variant: CsLinkVariant.info, onFollow: () {}),
    CsLink(text: '128', variant: CsLinkVariant.awsuiValueLarge, onFollow: () {}),
  ],
)
```

### External link

```dart
CsLink(
  text: 'Pricing details',
  external: true,
  externalIconAriaLabel: 'Opens in a new tab',
  onFollow: () {},
)
```

### Inside running text

```dart
Text.rich(
  TextSpan(
    children: [
      const TextSpan(text: 'Objects in '),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: CsLink(text: 'example-bucket', variant: CsLinkVariant.primary, onFollow: () {}),
      ),
      const TextSpan(text: ' are encrypted at rest.'),
    ],
  ),
)
```

### Inverted, on a colored background

```dart
CsLink(text: 'View instance', color: CsLinkColor.inverted, onFollow: () {})
```

## Accessibility

- Without `href` (and not `external`) the link is announced as a button, as Cloudscape does for a link without `href`; with `href` or `external` it is announced as a link.
- `external` adds the hint "Opens in a new window" (or `externalIconAriaLabel`).
- Keyboard: Tab focuses the link and shows the 2px focus ring; Enter activates it.
- `ariaLabel` replaces the text for screen readers, for example to add context to "Info".

## Motion

Hover and pressed colors switch instantly. There is no press scale on links.

## Mobile

Links wrap with the surrounding text and keep their text box as the hit area so lines are not pushed apart. Give standalone links on touch screens room around them (a list row) when they are the only target.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `text` |
| `variant` | `variant` (`'awsui-value-large'` is `CsLinkVariant.awsuiValueLarge`) |
| `fontSize` | `fontSize` (`CsLinkFontSize`) |
| `color` | `color` |
| `external` | `external` |
| `externalIconAriaLabel` | `externalIconAriaLabel` |
| `ariaLabel` | `ariaLabel` |
| `onFollow` | `onFollow` |
| `onClick` | `onClick` |
| `href` | `href` (semantics only) |
| `target`, `rel`, `nativeAttributes` | not applicable (web only) |
| `style` | not supported; theme with color overrides |
| `ref.focus()` | `focusNode.requestFocus()` |
