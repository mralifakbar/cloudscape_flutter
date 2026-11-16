# Theming

## Modes

`CsThemeProvider(mode: ...)` takes `CsThemeMode.system` (default, follows the platform), `.light` or `.dark`. Mode changes cross-fade every token over 250ms (`CsDurations.complex`), instantly when motion is off.

Force a mode for one subtree:

```dart
CsTheme(
  data: CsThemeData.dark(),
  child: const CsBox(text: 'Always dark'),
)
```

## Density

Cloudscape has two content densities. Comfortable is the default; compact tightens vertical spacing and makes controls 28px instead of 32px, for data-heavy pages.

```dart
CsThemeProvider(density: CsDensity.compact, child: const SizedBox())
```

Switch density for a subtree with `CsDensityScope`. Components read density-dependent spacing from `context.cs.space`, so they adapt on their own.

## Visual contexts

Cloudscape recolors parts of the page with `awsui-context-*` classes: the top navigation and the high-contrast page header are always dark, and flash messages and alerts recolor the controls inside them. `CsVisualContext` does the same for a subtree:

```dart
const CsVisualContext(
  context: CsVisualContextName.header,
  child: CsHeader(variant: CsHeaderVariant.h1, title: 'Amazon S3'),
)
```

Components that need a context (top navigation, flash messages, alerts, content layout's high-contrast header) apply it themselves.

## Brand overrides

Every color is a `CsColor` token, Cloudscape's `applyTheme` equivalent is a map of overrides per mode:

```dart
CsThemeProvider(
  lightColorOverrides: const {
    CsColor.backgroundButtonPrimaryDefault: Color(0xFF7B2FBE),
    CsColor.borderButtonPrimaryDefault: Color(0xFF7B2FBE),
  },
  darkColorOverrides: const {
    CsColor.backgroundButtonPrimaryDefault: Color(0xFFC08BF0),
    CsColor.borderButtonPrimaryDefault: Color(0xFFC08BF0),
  },
  child: const SizedBox(),
)
```

Check new pairings with `CsColorUtils.contrastRatio`: 4.5 for text, 3 for control boundaries. For full control, pass complete themes with `light:` and `dark:` (`CsThemeData.light().copyWith(...)`).

## Fonts

Open Sans (300, 400, 700) is bundled under the SIL OFL; it is the first family in Cloudscape's font stack. Monospace text uses Cloudscape's system stack (Monaco, Menlo, Consolas). To use your own faces, declare them in your app's pubspec and pass their family names with `package: null`:

```dart
CsThemeProvider(
  typography: const CsTypography(sans: 'BrandSans', package: null, mono: 'BrandMono'),
  child: const SizedBox(),
)
```

The OFL and Apache license texts are registered with Flutter's license page by the provider (`registerCsLicenses`).

## Motion

`CsThemeProvider(disableMotion: true)` is Cloudscape's `disableMotion`: transitions become instant everywhere. The platform's reduce-motion setting has the same effect.

## Tap targets

Cloudscape's controls are 32px tall. On touch platforms the provider pads hit areas to 44x44 without changing the visuals (`CsTapTargetSize.padded`); with a mouse they match the visual (`shrinkWrap`). Override with `tapTargetSize:`.

## Material bridge

`csMaterialTheme(context.cs)` builds a `ThemeData` from the Cloudscape theme (colors, text theme, no ink splashes). `CsMaterialTheme` does the same as a widget for a subtree.

## Copy and locale

Shared strings ("Close", "Loading", month names) come from `CsStrings`; provide your own with `CsLocale`. Component-specific copy is passed per component as `i18nStrings`, the way Cloudscape does.

```dart
CsLocale(
  strings: const CsStrings(close: 'Tutup', cancel: 'Batal', loading: 'Memuat'),
  child: const SizedBox(),
)
```
