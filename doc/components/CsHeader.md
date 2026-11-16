# CsHeader

Cloudscape's `Header`: the title of a page, container or section, with a counter, info link, description, secondary content and actions.

Cloudscape reference: https://cloudscape.design/components/header/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsHeader(
  variant: CsHeaderVariant.h1,
  title: 'Distributions',
  counter: '(24)',
  description: 'Sample distributions in this account.',
  actions: CsButton(text: 'Create distribution', variant: CsButtonVariant.primary, onPress: () {}),
)
```

## When to use / when not to

Use `h1` once per page for the page title, `h2` for container titles and `h3` for sections inside a container. Use `awsuiH1Sticky` for full-page tables and cards whose header sticks. For plain headings in text use `CsBox` variants.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String?` |  | Heading text (Cloudscape `children`); pass this or `titleWidget` |
| `titleWidget` | `Widget?` |  | Custom heading content |
| `variant` | `CsHeaderVariant` | `h2` | `h1` (heading-xl), `h2` (heading-l), `h3` (heading-m), `awsuiH1Sticky` |
| `counter` | `String?` |  | "(12)" in `color-text-counter`, normal weight |
| `info` | `Widget?` |  | Info link after the title |
| `description` | `String?` |  | Text under the title in `color-text-heading-secondary` |
| `descriptionWidget` | `Widget?` |  | Custom description |
| `actions` | `Widget?` |  | Buttons at the end of the title row |
| `secondaryContent` | `Widget?` |  | Content between the title and the actions |
| `headingTagOverride` | `int?` |  | Heading level announced, 1 to 6 |

## Examples

### Sticky page header while stuck

```dart
const CsHeaderStickyScope(
  stuck: true,
  child: CsHeader(variant: CsHeaderVariant.awsuiH1Sticky, title: 'Instances', description: 'Hidden while stuck'),
)
```

### Secondary content

```dart
CsHeader(
  title: 'Origins',
  secondaryContent: const CsStatusIndicator(text: 'Healthy'),
  actions: CsButton(text: 'Add origin', onPress: () {}),
)
```

## Accessibility

The title is a heading (`Semantics.header`) with `headingLevel` from the variant (1, 2, 3) or `headingTagOverride`. The counter is part of the heading text.

## Motion

None. `awsuiH1Sticky` switches size instantly when `CsHeaderStickyScope.stuck` changes.

## Mobile

The title and actions share a row when both fit at their natural widths (CSS flex-wrap) and the actions move under the title otherwise. The title is centered on the 32px button row. Everything wraps at 2x text.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `title` / `titleWidget` |
| `variant` | `variant` (`CsHeaderVariant`, `awsui-h1-sticky` is `awsuiH1Sticky`) |
| `counter` | `counter` |
| `info` | `info` |
| `description` | `description` / `descriptionWidget` |
| `actions` | `actions` |
| `secondaryContent` | `secondaryContent` |
| `headingTagOverride` | `headingTagOverride` (int) |
| `(sticky state)` | `CsHeaderStickyScope` |
