# CsActionCard

Cloudscape's `ActionCard`: a card that is one button or link, for choosing between a few actions or destinations.

Cloudscape reference: https://cloudscape.design/components/action-card/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsActionCard(
  header: const Text('Launch instance'),
  description: const Text('Start a virtual server from an image.'),
  icon: const CsIcon(CsIcons.angleRight),
  onPress: () {},
)
```

## When to use / when not to

Use action cards for a small set of starting points ("Create bucket", "Import a template"). Do not put buttons or links inside an action card; use `CsItemCard` for cards that hold their own actions.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `Widget?` |  | Title, heading-s |
| `description` | `Widget?` |  | Body-s under the title |
| `child` | `Widget?` |  | More content |
| `onPress` | `VoidCallback?` |  | Cloudscape `onClick` |
| `isLink` / `onFollow` | `bool` / `VoidCallback?` | `false` | Announce as a link and follow it (Cloudscape `href`) |
| `ariaLabel` | `String?` |  | Accessible name; replaces the content in the name |
| `disabled` | `bool` | `false` | Disabled colors, no presses |
| `icon` | `Widget?` |  | At the end of the card |
| `iconVerticalAlignment` | `CsActionCardIconVerticalAlignment` | `top` | `top` or `center` |
| `variant` | `CsActionCardVariant` | `defaultVariant` | `defaultVariant` or `embedded` |
| `disableHeaderPaddings`, `disableContentPaddings`, `fitHeight` | `bool` | `false` |  |
| `focusNode`, `autofocus` |  |  | Focus control (Cloudscape `ref.focus()`) |

## Examples

### Embedded, centered icon

```dart
CsActionCard(
  variant: CsActionCardVariant.embedded,
  iconVerticalAlignment: CsActionCardIconVerticalAlignment.center,
  header: const Text('Import a template'),
  icon: const CsIcon(CsIcons.upload),
  onPress: () {},
)
```

### Disabled

```dart
const CsActionCard(header: Text('Create stack'), description: Text('Unavailable while a stack updates.'), disabled: true)
```

## Accessibility

A button (or link with `isLink`) named by `ariaLabel` or its content; disabled cards report disabled. Tab focuses with a 2px ring outside the card; Enter and Space activate.

## Motion

Pressing scales the card to 0.98 with a spring from pointer-down. Hover and active colors switch at once (Cloudscape animates them; this package never animates hover colors). Reduced motion turns the scale off.

## Mobile

Touch targets are the whole card. Text wraps at 2x without overflow.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `onClick` | `onPress` |
| `href`, `target`, `rel`, `download` | `isLink` + `onFollow` (navigation is the app's) |
| `variant: 'default'` | `CsActionCardVariant.defaultVariant` |
| `ref.focus()` | `focusNode.requestFocus()` |
| `nativeButtonAttributes`, `nativeAnchorAttributes`, `ariaDescribedby` | web only, not ported |
