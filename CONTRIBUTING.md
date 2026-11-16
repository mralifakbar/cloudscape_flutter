# Contributing to cloudscape_flutter

This file is the contract every component follows. Read it fully before adding or changing a component. It applies to human contributors and to coding agents alike.

## What this package is

`cloudscape_flutter` is an unofficial Flutter port of the [Cloudscape Design System](https://cloudscape.design), the open-source design system AWS builds its consoles with. The reference implementation is the React library in [github.com/cloudscape-design/components](https://github.com/cloudscape-design/components) (`src/<component>`), Apache 2.0. When in doubt about a value, a prop or a behavior, read the React source and match it:

- `src/<component>/interfaces.ts`: props and their documentation (the API to mirror).
- `src/<component>/styles.scss` and `src/internal/styles/**`: dimensions, tokens per state.
- `src/<component>/internal.tsx`: behavior (keyboard, focus, announcements).
- The chat components live in `cloudscape-design/chat-components`, code view in `cloudscape-design/code-view`, the board in `cloudscape-design/board-components` (all Apache 2.0).

Licensing rules that are not negotiable:

- Never ship an AWS or Amazon logo, the "Amazon Ember" font or any AWS service icon. Text uses Open Sans (SIL OFL), which is the first family in Cloudscape's own font stack.
- Keep `NOTICE` and `assets/licenses/Cloudscape-Apache-2.0.txt`. Files derived from Cloudscape sources (tokens, icons) say so in their header.
- Never describe the package as official, or as made or endorsed by AWS.

## Layout

```
lib/
  cloudscape_flutter.dart       public barrel (maintainers edit this)
  src/
    theme/                      generated tokens, typography, motion, provider, visual contexts, Material bridge
    icons/                      CsIcon, CsIcons (generated), CsIconData
    system/ overlays/ feedback/ foundation primitives
    <category>/                 one folder per component category
      <category>.dart           category barrel: exports every public file in the folder
      cs_<component>.dart       one public component (plus its parts) per file
test/
  helpers/harness.dart          pumpCs(), csHarness(), goldenPair(), csPhoneSize, csDesktopSize
  <category>/cs_<component>_test.dart
doc/components/<ComponentName>.md   one reference page per component (template below)
example/lib/gallery/categories/<category>.dart   demos for the example app
tool/                           token and icon generators, doc snippet checker, llms.txt generator
```

## Foundation you build on

Read these files before writing a component; do not re-implement what they do.

| Need | Use |
| --- | --- |
| Theme | `context.cs` (`CsThemeData`): `.colors.<token>` (all 807 Cloudscape color tokens, `colorTextBodyDefault` is `colors.textBodyDefault`), `.color(CsColor.x)`, `.text(CsTypeScale.bodyM, weight:, color:)`, `.body`, `.code(scale:)`, `.space.<densityToken>`, `.shadows.<name>`, `.isDark`, `.minTapTarget` |
| Tokens | `CsSpace.xs` (fixed spacing: `xxxs` 2 to `xxxl` 40, plus named tokens like `CsSpace.fieldHorizontal`), `context.cs.space.scaledM` (density-dependent `space-scaled-*` and named tokens), `CsSize`, `CsBorderRadius`, `CsBorderWidth`, `CsBorderLine`, `CsFontTokens`, `CsDurations`, `CsCurves`, `CsRing.inside/outside` |
| Type | `CsTypeScale` (`bodyS`, `bodyM`, `headingXs` to `headingXl`, `displayL`, `displayXl`), `CsTypography.bold/normal`. Cloudscape headings and emphasis are bold (700). |
| Responsive | `context.csIsNarrow` (at or below 688px, Cloudscape's mobile breakpoint), `context.csBreakpoint`, `CsBreakpoint.match(mapping, actual)` |
| Visual contexts | `CsVisualContext(context: CsVisualContextName.header, child:)` for the dark header/top navigation and the inside of alerts and flash messages |
| Motion | `CsMotion.springTo/project/rubberband/duration/reduceMotion`, `CsSprings.standard/press/momentum/popup/sheet`, `CsDurations`, `CsCurves` |
| Tappable surface | `CsPressable(builder: (context, state) => ...)`: press scale spring, instant hover, focus ring, Enter/Space, 44px touch target, semantics |
| Focus | `CsFocusRing` (2px `color-border-item-focused`), `CsFocusTrap` |
| Text editing | `CsEditable` (bare TextField core), `CsFieldBox` (input chrome with focus, invalid, warning, disabled, read-only), `CsTextFieldState` mixin (controlled value sync) |
| Floating UI | `CsAnchoredOverlay` (placement, flip, follow, scale-from-anchor, outside tap, Escape), `CsPopupSurface` (popover container with arrow), `CsDropdown` (dropdown container that becomes a bottom sheet on phones, `CsPresentation`), `CsMenuPanel` + `CsMenuRow` + `CsMenuGroupLabel` + `CsMenuSeparator` + `CsMenuKeyboard` (option rows) |
| Sheets and modals | `showCsSheet`, `CsSheet`, `CsSheetScope.closeFrom`, `CsDialogRoute`, `CsScrim` |
| Content | `CsBox` (Cloudscape's text primitive), `CsSpaceBetween`, `CsIcon` + `CsIcons` (148 icons), `CsSpinner`, `CsButton`, `CsLink`, `CsTooltip`, `CsStatusIndicator`, `CsContainer`, `CsHeader`, `CsInput`, `CsFormField`, `CsCheckbox` + `CsCheckboxIcon` |
| Copy | `context.csStrings` (`CsStrings`): shared copy. Component-specific copy goes in a component `i18nStrings` class (see below). |
| Color math | `CsColorUtils.mix`, `.contrastRatio` |

## API conventions

1. **Prefix every public widget with `Cs`** (`CsButton`, `CsTable`). It avoids clashes with Material and Cupertino. Enums and data classes too (`CsButtonVariant`, `CsTableColumn`).
2. **Mirror Cloudscape prop names**, translated to Dart style: `variant`, `disabled`, `loading`, `label`, `description`, `placeholder`, `value`/`onChange`, `checked`/`onChange`, `selectedOption`/`onChange`, `visible`/`onDismiss`, `expanded`/`onChange`, `items`, `header`, `footer`, `empty`. Where Cloudscape takes `onClick`, Flutter takes `onPress`; `onFollow` stays `onFollow`. Event `detail` objects become plain values or small data classes.
3. **Enums for closed sets**, named like Cloudscape's string unions in camelCase (`'in-progress'` is `CsStatusType.inProgress`, `'awsui-h1-sticky'` is `CsHeaderVariant.awsuiH1Sticky`). A Dart keyword or clash gets a suffix (`defaultVariant`).
4. **Icons are `CsIconData`** from `CsIcons` (`iconName: 'settings'` is `icon: CsIcons.settings`). Custom icons go in a `Widget? iconWidget` slot (Cloudscape `iconSvg` / `iconUrl`).
5. **Colors are tokens.** Never hardcode a color. A raw `Color` escape hatch is named `dangerouslySet<Prop>`.
6. **Spacing, radius, borders and type come from tokens.** Never hardcode a pixel value that exists as a token. Density-dependent spacing (`space-scaled-*`, `size-vertical-input`, button and field paddings) is read from `context.cs.space` so compact mode applies. Values that only exist in one component's SCSS live in that component, with a comment naming the SCSS rule.
7. **Read the theme through `context.cs`.** Never use Material `Theme.of` inside a component.
8. **Controlled by default.** Stateful inputs take the value and a change callback and do not hold their own copy of the value. Internal state is only for transient UI (pressed, focused, open, highlighted option, drag offset).
9. **`const` constructors** wherever possible. Required params first.
10. **Slots are widgets.** Where Cloudscape takes `React.ReactNode` (a header, actions, a filter, an empty state), take a `Widget?`. Where it takes a string, take a `String?` and, if rich content is useful, a sibling `Widget?` slot.
11. **i18n.** Cloudscape passes component copy as `i18nStrings` / `ariaLabels` objects. Do the same with an immutable `Cs<Component>I18nStrings` class whose fields default to English, taken as `i18nStrings` (falling back to `context.csStrings` for shared words like "Close" and "Loading"). Do not edit `cs_strings.dart` for component-specific copy.
12. **No new dependencies.** The package depends only on Flutter and `clock` (use `clock.now()`, never `DateTime.now()`, in component logic). Charts use `CustomPainter`. Material widgets may be used internally only where Flutter has no widgets-layer equivalent (text editing, through `CsEditable`).

## Cloudscape's visual rules (visual refresh)

- Content text is body-m, 14px on a 20px line. Body-s (12/16) is for descriptions, constraint text and metadata.
- Headings, labels, buttons and emphasis are bold (700). Headings use the heading color and the `letter-spacing-heading-*` tokens.
- Controls are 32px tall in comfortable density and 28px in compact (`context.cs.space.sizeVerticalInput`).
- Buttons are fully rounded (20px radius) with a 2px border. Inputs and dropdowns have an 8px radius; containers 16px; badges 4px.
- Containers have a 1px `color-border-divider-default` border and no shadow. Shadows are for things that float (dropdowns, popovers, modals) and sticky headers.
- Inside borders are CSS borders: draw them inside the box (`CsRing.inside`, or `foregroundDecoration`) so states never shift layout. Focus rings are drawn outside (`CsFocusRing`, `CsPressable`).
- Hover colors change instantly. Never animate a hover color.
- Never put a shadow under a transparent or translucent fill (Flutter paints it under the whole box).
- Invalid and warning fields color their border and thicken its start edge to 8px.
- Status is never color alone: pair it with a status icon or text.
- Sticky elements are separated from content with a border or the sticky shadow.
- Never conditionally render a modal: keep it mounted and drive `visible`, so it can animate out.

## Interaction and motion

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

- **Build every tappable surface on `CsPressable`.** Do not use `GestureDetector`/`InkWell` directly for buttons, rows, chips, tabs or menu items.
- **Feedback starts on pointer-down**, never only on release.
- **Springs, not fixed curves, for anything a finger touches.** `AnimationController.unbounded` + `CsMotion.springTo(controller, target, spring: ..., velocity: ...)`.
- **Drag follows the finger 1:1.** On release, hand the velocity to the spring, use `CsMotion.project` for the snap target and `CsMotion.rubberband` past bounds.
- **Fixed-duration transitions** (fades, expand and collapse, indicator slides) use Cloudscape's motion tokens (`CsDurations.responsive` 115ms, `expressive` 165ms, `complex` 250ms, `showPaced` 180ms; `CsCurves.responsive`, `expressive`, `showPaced`) through `CsMotion.duration(context, d)` so disabled motion collapses them.
- **Enter and exit on the same path**, anchored to the trigger (`CsAnchoredOverlay` already does this).
- **Nothing loops forever.** A repeating animation exists only while a real state is true (loading) and stops when hidden. The skeleton shimmer and gen-AI gradients follow this.
- **Never give `AnimatedSize` a zero duration.** Under reduced motion, skip the `AnimatedSize` wrapper.
- **Create AnimationControllers in `initState`**, never as `late final` field initializers.
- **Reduced motion** (`CsMotion.reduceMotion(context)`, which also covers the theme's `disableMotion`): replace slides, scales and springs with an instant change.
- **Haptics** only on touch-first controls (toggle, slider, segmented control, sheets) through `csHaptic`, on the causal event.

## Mobile and desktop

Cloudscape is built for wide consoles. A Flutter port runs on phones too, so every component has to hold up at 390px wide and with 2x text.

- Keep Cloudscape's visuals; let `CsPressable` pad hit areas to 44x44 on touch platforms.
- At or below 688px (`context.csIsNarrow`) components switch to their mobile layouts the way Cloudscape does: the app layout's navigation and tools become overlays, split panels and drawers go full screen, tables can switch to a card list, and dropdowns open as bottom sheets (`CsDropdown` with `CsPresentation.auto`). Document the switch and allow overriding it.
- Never put text in a fixed-height box that clips at 2x text; use minimum heights.
- No horizontal overflow at 390px. Rows that cannot fit wrap or scroll with a visible affordance.

## Accessibility

- Every interactive element exposes `Semantics`: role (`button`, `link`, `checked`, `toggled`, `selected`, `expanded`, `textField`, `slider`, `header`), a label and state. Icon-only controls require a label (Cloudscape `ariaLabel`).
- Keyboard: Tab order follows visual order, Enter/Space activate, Escape closes overlays, arrow keys move within groups (radio group, tabs, segmented control, menus, listboxes, calendar grid, tree view), focus is trapped in modals and restored on close.
- Text scales with the platform setting. Contrast comes from tokens.
- Flash messages, form errors and live regions announce (`liveRegion: true` or `SemanticsService.sendAnnouncement`).
- RTL: use `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end. Directional icons mirror automatically.

## States

Any component that shows data supports empty, loading and error states the way its Cloudscape counterpart does (`loading` + `loadingText`, `empty`, `statusType: 'loading' | 'error' | 'finished'`), or documents how the caller provides them.

## Writing: docs, comments, demo copy

- Dartdoc on every public class and every constructor parameter that is not self-explanatory, with one short usage example. Comments explain why, never restate the code. No banner comments, no step narration, no emoji.
- No em dash character in any text. No buzzwords. Specific actions ("Launch instance", "Create bucket"), never "Get started" or "Learn more".
- Demo data is sample data, labeled as such in the example app. Use generic cloud-console resources (an instance `i-0abc123`, a bucket `example-bucket`, a distribution `d111111abcdef8`); never use real customer names or AWS service logos.

## Tests

Every component ships widget tests in `test/<category>/cs_<component>_test.dart` using `pumpCs` from `test/helpers/harness.dart`. Cover, as applicable:

1. Renders in light and dark, comfortable and compact, without exceptions.
2. Callbacks fire on tap, and do not fire when disabled or loading.
3. Controlled value: interaction calls the change callback with the next value; the widget reflects the value it is given.
4. Semantics: role, label and state flags.
5. Keyboard: Tab focus, Enter/Space activation, arrow keys in groups, Escape closes overlays.
6. Gestures: drags and flings where the component has them.
7. Reduced motion: `pumpCs(..., disableAnimations: true)`.
8. Text scale 2.0 and 390px width: no overflow exceptions.
9. Narrow vs. wide: components that switch layout are tested at `csPhoneSize` and `csDesktopSize`.

Run before finishing: `dart analyze lib/src/<category> test/<category>` (zero issues) and `flutter test test/<category>`.

## Component doc template (`doc/components/<ComponentName>.md`)

```markdown
# CsComponentName

One sentence: what it is and when to reach for it.

Cloudscape reference: https://cloudscape.design/components/<name>/

## Import

(fenced dart block) import 'package:cloudscape_flutter/cloudscape_flutter.dart';

## Usage

(fenced dart block) smallest useful example

## When to use / when not to

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |

## Examples
### <Variant or scenario>

## Accessibility
## Motion
## Mobile
## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
```

Code goes in fenced blocks tagged `dart`, compilable and minimal (`tool/check_doc_snippets.py` compiles them). Agents read these pages to build apps, so be exact about types and defaults.
