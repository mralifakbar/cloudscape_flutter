# CsSideNavigation

The list of pages of a service, with sections and groups, shown in the navigation drawer of the app layout.

Cloudscape reference: https://cloudscape.design/components/side-navigation/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsSideNavigation(
  header: const CsSideNavigationHeader(text: 'Service', href: '/'),
  activeHref: '/buckets',
  onFollow: (detail) {
    if (!detail.external) Navigator.of(context).pushNamed(detail.href);
  },
  items: const [
    CsSideNavigationLink(text: 'Dashboard', href: '/dashboard'),
    CsSideNavigationSection(
      text: 'Storage',
      items: [
        CsSideNavigationLink(text: 'Buckets', href: '/buckets'),
        CsSideNavigationLink(text: 'Access points', href: '/access-points'),
      ],
    ),
    CsSideNavigationDivider(),
    CsSideNavigationLink(text: 'Documentation', href: 'https://example.com/docs', external: true),
  ],
)
```

## When to use / when not to

- Use as the primary navigation of a service with several pages, inside the app layout's navigation slot.
- Do not use for a table of contents within one page (use `CsAnchorNavigation`) or for global links across services (use `CsTopNavigation`).
- Keep one level of nesting.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<CsSideNavigationItem>` | `[]` | The items. See the item types below. |
| `header` | `CsSideNavigationHeader?` | `null` | `text`, `href` and an optional `logo` widget. |
| `activeHref` | `String?` | `null` | Every link with this href is highlighted. Groups holding it expand. |
| `itemsControl` | `Widget?` | `null` | A slot between the header and the items. |
| `onFollow` | `ValueChanged<CsSideNavigationFollowDetail>?` | `null` | A link, group link or the header was followed: `href`, `text`, `type`, `external`, `item`. |
| `onChange` | `ValueChanged<CsSideNavigationChangeDetail>?` | `null` | A section or expandable link group was toggled: `item`, `expanded`, `expandableParents`. |
| `collapsed` | `bool` | `false` | Icon-only rail: only items with an icon remain, as round buttons with tooltips. |
| `ariaLabel` | `String?` | `CsStrings.navigation` | Accessible name. |

Item types (`sealed class CsSideNavigationItem`):

| Class | Cloudscape type | Fields |
| --- | --- | --- |
| `CsSideNavigationLink` | `link` | `text`, `href`, `external`, `externalIconAriaLabel`, `info`, `icon`, `iconWidget` |
| `CsSideNavigationDivider` | `divider` | none |
| `CsSideNavigationSection` | `section` | `text`, `items`, `defaultExpanded` (true), `info` |
| `CsSideNavigationSectionGroup` | `section-group` | `title`, `items`, `info` |
| `CsSideNavigationLinkGroup` | `link-group` | `text`, `href`, `items`, `info`, `icon`, `iconWidget` |
| `CsSideNavigationExpandableLinkGroup` | `expandable-link-group` | `text`, `href`, `items`, `defaultExpanded`, `info`, `icon`, `iconWidget` |

## Examples

### Groups and info

```dart
CsSideNavigation(
  activeHref: '/instances/templates',
  onFollow: (detail) {},
  onChange: (detail) {},
  items: const [
    CsSideNavigationExpandableLinkGroup(
      text: 'Instances',
      href: '/instances',
      items: [
        CsSideNavigationLink(text: 'Launch templates', href: '/instances/templates'),
        CsSideNavigationLink(text: 'Spot requests', href: '/instances/spot'),
      ],
    ),
    CsSideNavigationLinkGroup(
      text: 'Distributions',
      href: '/distributions',
      items: [CsSideNavigationLink(text: 'Origins', href: '/distributions/origins')],
    ),
    CsSideNavigationSectionGroup(
      title: 'Settings',
      items: [CsSideNavigationLink(text: 'Preferences', href: '/preferences', info: Text('New'))],
    ),
  ],
)
```

### Icon-only rail

```dart
CsSideNavigation(
  collapsed: true,
  activeHref: '/buckets',
  onFollow: (detail) {},
  items: const [
    CsSideNavigationLink(text: 'Dashboard', href: '/dashboard', icon: CsIcons.gridView),
    CsSideNavigationLink(text: 'Buckets', href: '/buckets', icon: CsIcons.folder),
  ],
)
```

## Accessibility

- The navigation is a labeled container. Links announce as links; the active one is marked selected (Cloudscape's `aria-current="page"`).
- Section headers and expandable carets are buttons with an expanded state. Tab reaches every link and caret; Enter and Space activate them.
- External links add "Opens in a new window" (or `externalIconAriaLabel`).
- In the collapsed rail each icon button is named by its text, which also shows in a tooltip.
- Collapsed content is removed from the tree, so it leaves the Tab order.

## Motion

Sections and groups expand and collapse from the top with a fade (`CsDurations.expandableContentEnter`, 180ms in, 135ms out). The caret turns 90 degrees (`CsDurations.rotate90`). Reduced motion makes both instant. Hover colors switch instantly.

## Mobile

The app layout shows the navigation in a drawer on phones. The list wraps long titles; on touch screens hit areas grow to 44px. Use `collapsed` for a narrow rail on tablets.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `items` (`type` unions) | `items` (sealed `CsSideNavigationItem` classes) |
| `header` (`text`, `href`, `logo`) | `header` (`logo` is a widget) |
| `activeHref` | `activeHref` |
| `itemsControl` | `itemsControl` |
| `onFollow` | `onFollow` (`CsSideNavigationFollowDetail`) |
| `onChange` | `onChange` (`CsSideNavigationChangeDetail`) |
| `collapsed` | `collapsed` |
| `info`, `icon` (ReactNode) | `info` (`Widget`), `icon` (`CsIconData`) or `iconWidget` |
