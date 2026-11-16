# CsIconProvider

Cloudscape's `IconProvider` (`src/icon-provider`): replaces built-in icons by name for everything below it, including the icons inside components.

Cloudscape reference: https://cloudscape.design/components/icon-provider/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsIconProvider(
  icons: {'close': CsIcons.arrowLeft, 'status-positive': CsIcons.check},
  child: Text('Content'),
)
```

## When to use / when not to

Use it to adapt the icon set to a brand or a platform convention (a back arrow in place of a close icon in a full-screen flow) without changing each component. Do not use it to change one icon in one place; pass a different `icon` there.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `icons` | `Map<String, CsIconData?>?` |  | Overrides by Cloudscape icon name (`'close'`, `'caret-down-filled'`); a `null` value resets that name |
| `iconWidgets` | `Map<String, Widget?>?` |  | Widget overrides (an image, an SVG widget), sized like the icon they replace; wins over `icons` for the same name |
| `child` | `Widget` | required | The subtree |

`CsIconProvider.reset(child:)` resets every override from outer providers (Cloudscape `icons={null}`).

Names are the `name` of `CsIconData` (the Cloudscape icon name). `CsIcons.byName('settings')` looks a built-in icon up by name.

## Examples

### Nested providers

```dart
const CsIconProvider(
  icons: {'close': CsIcons.arrowLeft},
  child: Column(
    children: [
      CsIcon(CsIcons.close),
      CsIconProvider(icons: {'close': null}, child: CsIcon(CsIcons.close)),
    ],
  ),
)
```

### Custom drawing

```dart
CsIconProvider(
  icons: const {
    'notification': CsIconData('notification', [CsIconPart('M3 12h10M5 12V7a3 3 0 0 1 6 0v5M7 14h2', roundJoin: true)]),
  },
  child: CsButton(icon: CsIcons.notification, variant: CsButtonVariant.icon, semanticLabel: 'Notifications', onPress: () {}),
)
```

### Image in place of an icon

```dart
const CsIconProvider(
  iconWidgets: {'user-profile': ColoredBox(color: Color(0xFF0972D3))},
  child: CsIcon(CsIcons.userProfile, size: CsIconSize.medium),
)
```

## Accessibility

An override keeps the icon's `semanticLabel`. Decorative icons stay hidden from screen readers.

## Motion

None. Changing the overrides rebuilds the icons below.

## Mobile

No layout change: an override is drawn in the size of the icon it replaces.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `icons` (`ReactNode` values) | `icons` (`CsIconData`) or `iconWidgets` (`Widget`) |
| `icons={null}` | `CsIconProvider.reset` |
| `{name: null}` | `null` map value |
| `componentIcons` (table, tree view, expandable section stateful icons) | not supported yet |
| infinite loop when an override uses its own name | never loops: an override is drawn with its own name reset |
