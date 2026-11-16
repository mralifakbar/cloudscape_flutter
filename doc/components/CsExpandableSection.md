# CsExpandableSection

Cloudscape's `ExpandableSection`: a header that shows and hides its content, in six variants.

Cloudscape reference: https://cloudscape.design/components/expandable-section/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
const CsExpandableSection(
  headerText: 'Additional settings',
  child: Text('Detailed monitoring: off'),
)
```

## When to use / when not to

Use it to hide secondary or advanced content. Use the `container` variant for an optional container, `footer` at the end of a form or container, `navigation` for groups of links, `inline` inside text. Do not hide content people need to finish their task.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` |  | The content (Cloudscape `children`) |
| `headerText` | `String?` |  | Title |
| `header` | `Widget?` |  | Custom title content |
| `variant` | `CsExpandableSectionVariant` | `defaultVariant` | `defaultVariant`, `footer`, `container`, `stacked`, `navigation`, `inline` |
| `expanded` | `bool?` |  | Controlled state; null lets the section manage it |
| `defaultExpanded` | `bool` | `false` | Starting state when uncontrolled |
| `onChange` | `ValueChanged<bool>?` |  | Next expanded state |
| `headerCounter` | `String?` |  | "(2)" after the title (container variants) |
| `headerDescription` | `String?` |  | Text under the title |
| `headerInfo` | `Widget?` |  | Info link (container variants) |
| `headerActions` | `Widget?` |  | Buttons in the header (container variants); they do not toggle |
| `headerSecondaryContent` | `Widget?` |  |  |
| `headingTagOverride` | `int?` |  | Heading level announced |
| `headerAriaLabel` | `String?` |  | Accessible name of the toggle |
| `hideHeaderText` | `bool` | `false` |  |
| `disableContentPaddings` | `bool` | `false` |  |
| `stackPosition` | `CsStackPosition` | `only` | For the `stacked` variant |

## Examples

### Controlled container

```dart
CsExpandableSection(
  variant: CsExpandableSectionVariant.container,
  headerText: 'Tags',
  headerCounter: '(2)',
  headerActions: CsButton(text: 'Manage tags', onPress: () {}),
  expanded: true,
  onChange: (v) {},
  child: const Text('environment: test'),
)
```

### Navigation group

```dart
const CsExpandableSection(
  variant: CsExpandableSectionVariant.navigation,
  headerText: 'Images',
  defaultExpanded: true,
  child: Text('AMIs'),
)
```

## Accessibility

The toggle is a button with `expanded` state and Enter/Space activation; the title is a heading. In the navigation variant only the caret is the button.

## Motion

Content reveals over `motion-duration-expandable-content-enter` (180ms) with the expandable easing; the fade and 4px slide start a third of the way in. Collapse runs over `motion-duration-show-quick` (135ms). The caret turns 90 degrees over 135ms. Reduced motion snaps.

## Mobile

Header text and actions wrap; the 44px touch target comes from `CsPressable`.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `headerText / header` | `headerText` / `header` |
| `variant` | `variant` |
| `expanded / onChange` | `expanded` / `onChange` (bool) |
| `defaultExpanded` | `defaultExpanded` |
| `headerCounter / headerDescription / headerInfo / headerActions` | same names |
| `headerSecondaryContent` | `headerSecondaryContent` |
| `headingTagOverride` | `headingTagOverride` (int) |
| `headerAriaLabel` | `headerAriaLabel` |
| `disableContentPaddings` | `disableContentPaddings` |
| `analyticsMetadata` | not supported (web only) |
