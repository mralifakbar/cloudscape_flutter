# CsThemeProvider

The root of a Cloudscape app: resolves light or dark mode and density, applies color overrides and typography, provides `context.cs`, and cross-fades mode changes. `CsTheme` forces a theme for a subtree, `CsDensityScope` switches density for a subtree.

Cloudscape reference: https://cloudscape.design/foundation/visual-foundation/visual-modes/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsThemeProvider(
  child: Builder(
    builder: (context) => MaterialApp(theme: csMaterialTheme(context.cs), home: const SizedBox()),
  ),
)
```

## When to use / when not to

Once, above `MaterialApp`. Use `CsTheme` or `CsDensityScope` for parts of the screen that need another mode or density, and `CsVisualContext` for Cloudscape's visual contexts.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `mode` | `CsThemeMode` | `system` | `system`, `light`, `dark` |
| `density` | `CsDensity` | `comfortable` | `comfortable` or `compact` |
| `typography` | `CsTypography` | Open Sans | Font families |
| `tapTargetSize` | `CsTapTargetSize?` | platform default | `padded` (44px hit areas) on touch, `shrinkWrap` with a mouse |
| `disableMotion` | `bool` | `false` | Cloudscape's `disableMotion` |
| `lightColorOverrides`, `darkColorOverrides` | `Map<CsColor, Color>` | `{}` | Token overrides per mode (`applyTheme`) |
| `light`, `dark` | `CsThemeData?` | | Replace the generated themes |
| `animationDuration` | `Duration` | 250ms | Mode cross-fade |
| `child` | `Widget` | | |

## Examples

### Compact density for a table

```dart
CsDensityScope(density: CsDensity.compact, child: const CsBox(text: 'Compact content'))
```

### Force dark for one panel

```dart
CsTheme(data: CsThemeData.dark(), child: const CsBox(text: 'Always dark'))
```

## Accessibility

Follows the platform's light/dark setting by default; the platform reduce-motion setting turns motion off like `disableMotion`.

## Motion

Mode changes cross-fade every token over 250ms; instant when motion is off.

## Mobile

Touch platforms default to 44px hit areas.

## Cloudscape React mapping

| Cloudscape API | Flutter |
| --- | --- |
| `applyMode(Mode.Dark)` | `mode: CsThemeMode.dark` |
| `applyDensity(Density.Compact)` | `density: CsDensity.compact` |
| `disableMotion(true)` | `disableMotion: true` |
| `applyTheme({ theme: { tokens } })` | `lightColorOverrides` / `darkColorOverrides` |
