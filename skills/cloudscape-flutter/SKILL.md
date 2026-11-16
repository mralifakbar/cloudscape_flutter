---
name: cloudscape-flutter
description: |
  Build and review Flutter UI with cloudscape_flutter, the unofficial Flutter port of AWS Cloudscape Design System.
  Use when creating screens, components or visual changes in a Flutter app that depends on cloudscape_flutter, when
  choosing Cloudscape components, tokens, icons or motion, or when auditing Flutter code for Cloudscape adherence.
  Not for non-visual logic (state management, networking, persistence) or for apps that do not use cloudscape_flutter.
license: Apache-2.0
---

# cloudscape_flutter

## Companion skill

Load `cloudscape-flutter-craft` together with this one for every UI task. It holds the design, accessibility, motion and copy standard and the delivery checklist that closes each task.

## Before writing code

1. Confirm the app depends on `cloudscape_flutter` (check `pubspec.yaml`). If not, ask before adding it.
2. Read `references/guides/for-ai-agents.md` and `references/guides/tokens.md` once per session.
3. For every component you plan to use, read its page in `references/components/<Name>.md`. Parameters, defaults and examples there are exact; do not guess names from Cloudscape React or Material.
4. Tell the user which Cloudscape components you will use before building.

## Rules

- `import 'package:cloudscape_flutter/cloudscape_flutter.dart';` and `CsThemeProvider` at the root (with `csMaterialTheme(context.cs)` for MaterialApp). Read the theme with `context.cs`.
- Colors: `CsColor` tokens (`context.cs.colors.textBodySecondary`) only; never hex values. Spacing: `CsSpace` for fixed gaps, `context.cs.space` for density-aware spacing, `CsSpaceBetween` between blocks. Radii and borders from `CsBorderRadius` / `CsBorderWidth`. Shadows only on floating surfaces (`context.cs.shadows.dropdown`).
- Text through `CsBox` (variants h1-h5, p, small, code, key label, large value) and `CsHeader` for titles with actions. Content is body-m 14/20; headings, labels and buttons bold.
- Icons: `CsIcon(CsIcons.<name>)` or the `icon:` parameter of components. Pick by meaning; `genAi` only for generative AI features.
- One `primary` `CsButton` per view; `normal` by default; `link` for Cancel; `icon` in toolbars. Icon-only buttons need `semanticLabel`.
- Controlled inputs: hold `value`/`checked`/`selectedOption`/`visible` in your state and update it in `onChange`/`onDismiss`.
- Custom tappable surfaces use `CsPressable`, never raw `GestureDetector`/`InkWell`. Custom floating panels use `CsAnchoredOverlay` + `CsPopupSurface` or `CsDropdown`; custom phone panels use `showCsSheet`.
- Every collection ships loading (`loading` + `loadingText`), empty (`empty`) and error states.
- Copy: specific labels ("Launch instance"), no em dash, no buzzwords, no invented numbers presented as real.

## Component picker

| Need | Use |
| --- | --- |
| Page frame with navigation, tools, split panel | `CsAppLayout` (or `CsAppLayoutToolbar`) + `CsSideNavigation` + `CsHelpPanel`; `CsTopNavigation` above |
| Page header, breadcrumbs, notifications | `CsContentLayout` + `CsHeader(variant: h1)`, `CsBreadcrumbGroup`, `CsFlashbar` |
| Block of content | `CsContainer` with a `CsHeader(variant: h2)`; `CsColumnLayout`, `CsGrid`, `CsSpaceBetween` inside |
| Details | `CsKeyValuePairs`, `CsStatusIndicator`, `CsBadge`, `CsCopyToClipboard` |
| Collections | `CsTable` / `CsCards` with `CsTextFilter` or `CsPropertyFilter`, `CsPagination`, `CsCollectionPreferences`, driven by `CsCollection` |
| Actions | `CsButton`, `CsButtonDropdown`, `CsButtonGroup`, `CsToggleButton`, `CsLink` |
| Forms | `CsForm` + `CsFormField` around `CsInput`, `CsTextarea`, `CsSelect`, `CsMultiselect`, `CsAutosuggest`, `CsCheckbox`, `CsRadioGroup`, `CsToggle`, `CsTiles`, `CsSegmentedControl`, `CsSlider`, `CsAttributeEditor`, `CsTagEditor`, `CsFileUpload` |
| Dates and time | `CsDatePicker`, `CsDateRangePicker`, `CsCalendar`, `CsDateInput`, `CsTimeInput` |
| Multi-step flow | `CsWizard`; `CsSteps` for progress of a process |
| Disclosure and sections | `CsExpandableSection`, `CsTabs`, `CsSplitPanel`, `CsDrawer`, `CsTreeView`, `CsAnchorNavigation` |
| Overlays | `CsModal`, `CsPopover`, `CsTooltip` |
| Feedback | `CsFlashbar`, `CsAlert`, `CsProgressBar`, `CsSpinner`, `CsSkeleton`, `CsLiveRegion` |
| Charts | `CsLineChart`, `CsAreaChart`, `CsBarChart`, `CsMixedLineBarChart`, `CsPieChart` |
| Generative AI | `CsChatBubble`, `CsAvatar`, `CsPromptInput`, `CsSupportPromptGroup`, `CsLoadingBar`, `CsCodeView` |
| Dashboards | `CsBoard` + `CsBoardItem`, `CsItemsPalette` |
| Onboarding | `CsAnnotationContext`, `CsHotspot`, `CsTutorialPanel` |
| Code | `CsCodeEditor` (editable), `CsCodeView` (read-only) |

## If no component fits

1. Compose primitives (`CsPressable`, `CsBox`, `CsIcon`, `CsContainer`, `CsFieldBox` + `CsEditable`, `CsMenuPanel` + `CsMenuRow`) with tokens.
2. Only then fall back to plain Flutter widgets, styled from `context.cs`.

## Review mode

When asked to audit code for Cloudscape adherence, check in this order and report findings with file:line:
hardcoded colors, sizes or spacing; Material widgets where a Cloudscape component exists; density-dependent spacing read
as constants; missing semantics or tap targets; missing loading/empty/error states; motion that ignores disabled motion
or loops forever; more than one primary button; nested containers.
