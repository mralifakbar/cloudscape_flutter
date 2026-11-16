# CsTopNavigation

The global bar above the app layout with the product identity, a search field and utilities such as notifications, settings and the user menu.

Cloudscape reference: https://cloudscape.design/components/top-navigation/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsTopNavigation(
  identity: CsTopNavigationIdentity(href: '/', title: 'Cloud console', onFollow: () {}),
  utilities: [
    CsTopNavigationButton(
      icon: CsIcons.notification,
      ariaLabel: 'Notifications (2 unread)',
      badge: true,
      disableUtilityCollapse: true,
      onClick: () {},
    ),
    CsTopNavigationMenuDropdown(
      text: 'Account',
      description: 'user@example.com',
      icon: CsIcons.userProfile,
      items: const [
        CsTopNavigationMenuItem(id: 'profile', text: 'Profile'),
        CsTopNavigationMenuItem(id: 'signout', text: 'Sign out'),
      ],
      onItemClick: (item) {},
    ),
  ],
)
```

## When to use / when not to

- Use once, at the very top of a console, above `CsAppLayout`.
- Do not put page actions here; they belong in the page header.
- Keep utilities to a few: notifications, settings, help and the user menu.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `identity` | `CsTopNavigationIdentity?` | `null` | `href`, `title`, `logo` (a widget, at most 32px tall), `logoWidth` (32), `onFollow`. |
| `search` | `Widget?` | `null` | A search field, such as `CsInput(type: CsInputType.search)`. At most 340px wide. |
| `utilities` | `List<CsTopNavigationUtility>` | `[]` | `CsTopNavigationButton` and `CsTopNavigationMenuDropdown` items. |
| `i18nStrings` | `CsTopNavigationI18nStrings` | English | `searchIconAriaLabel`, `searchDismissIconAriaLabel`, `overflowMenuTriggerText` ("More"), `overflowMenuTitleText` ("All"), `overflowMenuBackIconAriaLabel`, `overflowMenuDismissIconAriaLabel`. |
| `visualContext` | `CsTopNavigationVisualContext` | `topNavigation` | `topNavigation` keeps the bar dark in both modes; `none` uses the page colors. |
| `safeAreaTop` | `bool` | `true` | Pads the content below the status bar and notch while the dark bar extends under them. Turn off when the bar is not at the top of the screen. |
| `child` | `Widget?` | `null` | Custom content. When set, `identity`, `search` and `utilities` are ignored. |

Shared utility fields: `text`, `title`, `icon`, `iconWidget`, `ariaLabel`, `badge`, `disableTextCollapse`, `disableUtilityCollapse`.

`CsTopNavigationButton`: `variant` (`link` or `primaryButton`), `href`, `external`, `externalIconAriaLabel`, `onClick`, `onFollow` (called when `href` is set).

`CsTopNavigationMenuDropdown`: `items` (`CsTopNavigationMenuItem`), `description`, `expandableGroups`, `onItemClick`, `onItemFollow` (items with `href`).

`CsTopNavigationMenuItem`: `id`, `text`, `href`, `external`, `externalIconAriaLabel`, `disabled`, `description`, `icon`, `items` (makes it a group).

## Examples

### With search and a primary button

```dart
CsTopNavigation(
  identity: const CsTopNavigationIdentity(
    href: '/',
    title: 'Cloud console',
    logo: SizedBox(width: 32, height: 32, child: Placeholder()),
  ),
  search: CsInput(value: '', type: CsInputType.search, placeholder: 'Search', onChange: (value) {}),
  utilities: [
    CsTopNavigationButton(
      text: 'Create resource',
      variant: CsTopNavigationButtonVariant.primaryButton,
      onClick: () {},
    ),
    CsTopNavigationButton(text: 'Docs', href: '/docs', external: true, onFollow: () {}),
  ],
)
```

### Responsive collapse

The bar measures its content and, as the width shrinks, steps through Cloudscape's states in order: utility texts hide (icons stay, unless `disableTextCollapse`), the search field becomes a search button that expands the field across the bar, utilities move one by one into a "More" menu (unless `disableUtilityCollapse`), and finally the title hides next to a logo. `CsTopNavigationResponsiveState.statesFor` exposes the state list.

## Accessibility

- The identity is a link named by the title. Icon-only utilities need `ariaLabel`; when text is hidden on narrow screens, `ariaLabel` or `text` names the control.
- Menu triggers announce their expanded state. Menus take focus; arrow keys move between items; Escape closes them and focus returns to the trigger.
- The overflow menu is a full-screen view with a focus trap. Escape goes back from a submenu, then closes; focus returns to "More".
- `badge` adds a dot to the icon; describe it in `ariaLabel` ("Notifications (2 unread)").

## Motion

Menu carets turn 180 degrees when open (`CsDurations.rotate180`). Menus scale from their trigger; the overflow menu fades in over `CsDurations.showPaced`. Reduced motion makes all of them instant.

## Mobile

The bar is 56px tall on wide screens, 48px from 465px and 40px below (plus a 1px bottom border). On phones menus open as bottom sheets and the overflow menu covers the screen. At extreme text sizes the utilities scale down rather than overflow.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `identity` (`title`, `logo`, `href`, `onFollow`) | `identity` (`logo` is a widget) |
| `search` | `search` |
| `utilities` (`type: 'button'`) | `CsTopNavigationButton` (`variant: 'primary-button'` is `primaryButton`) |
| `utilities` (`type: 'menu-dropdown'`) | `CsTopNavigationMenuDropdown` |
| `iconName`, `iconUrl` / `iconSvg` | `icon`, `iconWidget` |
| `badge`, `disableTextCollapse`, `disableUtilityCollapse` | same names |
| `i18nStrings` | `i18nStrings` |
| `visualContext` | `visualContext` |
| `children` | `child` |
| `target`, `rel`, `iconAlt` | not applicable (web only) |
