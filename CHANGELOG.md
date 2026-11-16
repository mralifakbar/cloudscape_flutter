## 0.1.1

- Static analysis on the latest Flutter: `CsList` and `CsCollectionPreferences` no longer report the `ReorderableList.onReorder` deprecation from Flutter 3.41. Behavior is unchanged, and Flutter 3.38 is still supported.

## 0.1.0

First release.

- Theme: all 1,173 tokens of Cloudscape's visual refresh theme, generated from the Cloudscape theme preset: 807 color tokens in light and dark, the eight visual contexts (top navigation, high-contrast header, flash messages, alerts), comfortable and compact density, borders, radii, type scale, shadows and motion. `CsThemeProvider`, `context.cs`, `CsVisualContext`, `CsDensityScope`, Material bridge, mode cross-fade.
- Icons: the 148 Cloudscape icons as vector outlines with Cloudscape's per-size stroke widths and right-to-left mirroring (`CsIcons`, `CsIcon`).
- Type: Open Sans on the Cloudscape type scale (`CsTypeScale`, `CsBox`).
- Motion: springs from the current value, press feedback on every pressable, sheets that follow the finger, popups that scale from their trigger, disabled and reduced motion everywhere.
- Components: forms and controls, selection and filtering, editors and uploads, dates, layout (app layout, content layout, containers, tabs, split panel), navigation, feedback and overlays, display and onboarding, collections (table, cards, collection preferences), charts, generative AI components, code view and the dashboard board.
- Localizable copy through `CsStrings` and per-component `i18nStrings`.
- Agent skills (`dart run cloudscape_flutter:install_skill`), `llms.txt`, and a reference page for every component.
