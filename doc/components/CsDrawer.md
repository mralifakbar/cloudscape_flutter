# CsDrawer

Cloudscape's `Drawer`: a panel with a header, scrolling content and a sticky footer, used in the app layout or over the screen.

Cloudscape reference: https://cloudscape.design/components/drawer/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsDrawer(
  header: const Text('Instance details'),
  footer: CsButton(text: 'Stop instance', onPress: () {}),
  child: const Text('i-0abc123'),
)
```

## When to use / when not to

Use a drawer for supplementary content and tools beside the main content, such as details or filters. For a blocking decision use `CsModal`; for help text use `CsHelpPanel`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `header` | `Widget?` |  | Title in the panel header font |
| `headerActions` | `Widget?` |  |  |
| `child` | `Widget?` |  | Content |
| `footer` | `Widget?` |  |  |
| `stickyFooter` | `bool` | `true` | Footer stays visible while content scrolls |
| `loading` | `bool` | `false` |  |
| `disableContentPaddings` | `bool` | `false` |  |
| `i18nStrings` | `CsDrawerI18nStrings` |  | `loadingText` |
| `position` | `CsDrawerPosition` | `static` | `static`, `sticky`, `absolute`, `fixed` |
| `placement` | `CsDrawerPlacement` | `end` | `start`, `end`, `top`, `bottom` (overlay positions) |
| `size` | `double` | `320` | Width (or height) of an overlay drawer |
| `open` | `bool` | `true` | Shows an overlay drawer |
| `onClose` | `ValueChanged<CsDrawerCloseMethod>?` |  | `closeAction`, `backdropClick`, `escape`; shows the close button |
| `closeAction` | `CsDrawerCloseAction?` |  | Label, disabled state and icon of the close button |
| `hideCloseAction` | `bool` | `false` |  |
| `backdrop` | `bool` | `false` | Dims the content behind an overlay drawer |
| `autoFocus` | `bool` | `true` |  |
| `trapFocus` | `bool` | `true` |  |
| `semanticLabel` | `String?` |  |  |

## Examples

### Over the screen

```dart
CsDrawer(
  position: CsDrawerPosition.fixed,
  open: true,
  backdrop: true,
  header: const Text('Filters'),
  onClose: (method) {},
  child: const Text('State: running'),
)
```

## Accessibility

The header is a level-2 heading; the close button has a label. Overlay drawers trap focus, move focus in on open and close with Escape.

## Motion

Overlay drawers slide in from their edge over `motion-duration-complex` (250ms) with the expressive easing; the backdrop fades. Reduced motion shows them instantly. Keep the drawer mounted and drive `open` so it animates out.

## Mobile

Fixed start and end drawers take the full width at or below 688px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `header / headerActions` | same names |
| `children` | `child` |
| `footer` | `footer` (`stickyFooter`) |
| `loading / i18nStrings.loadingText` | `loading` / `i18nStrings` |
| `position / placement` | `position` / `placement` |
| `open / onClose` | `open` / `onClose` (`CsDrawerCloseMethod`) |
| `closeAction / hideCloseAction` | `closeAction` / `hideCloseAction` |
| `backdrop` | `backdrop` |
| `focusBehavior` | `autoFocus` / `trapFocus` |
| `offset / stickyOffset / zIndex / role` | not supported (Flutter layout) |
