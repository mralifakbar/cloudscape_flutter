# CsPagination

Moves through pages of a table, cards or list, with page numbers, arrows and an optional jump-to-page field.

Cloudscape reference: https://cloudscape.design/components/pagination/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPagination(
  currentPageIndex: 3,
  pagesCount: 12,
  onChange: (page) => setState(() {}),
)
```

## When to use / when not to

- Use in a table or cards header (`CsHeader` actions or the collection's `pagination` slot) when the items do not fit one page.
- Use `openEnd` when the total is unknown and pages load on demand.
- Do not use for a short list that fits one screen, or for step-by-step flows (use `CsWizard`).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `currentPageIndex` | `int` | required | The current page, starting at 1. |
| `pagesCount` | `int` | required | Total pages (pages known so far when `openEnd`). |
| `onChange` | `ValueChanged<int>?` | `null` | Called with the page picked from a page button, an arrow or the jump field. |
| `onNextPageClick` | `ValueChanged<CsPaginationPageClickDetail>?` | `null` | Next arrow. `requestedPageAvailable` is false on the last loaded page of an open-ended pagination. |
| `onPreviousPageClick` | `ValueChanged<CsPaginationPageClickDetail>?` | `null` | Previous arrow. |
| `openEnd` | `bool` | `false` | The total is unknown: dots always follow the pages and the next arrow never disables. |
| `disabled` | `bool` | `false` | Disables every control, for example while items load. |
| `pagesVariant` | `CsPaginationPagesVariant?` | `null` | `normal` (page buttons) or `compact` ("3 of 12"). Null uses normal while it fits and compact when it does not. |
| `ariaLabels` | `CsPaginationAriaLabels` | English | `nextPageLabel`, `previousPageLabel`, `paginationLabel`, `pageLabel(int)`, `jumpToPageButton`. |
| `i18nStrings` | `CsPaginationI18nStrings` | English | `jumpToPageInputLabel`, `jumpToPageError`, `jumpToPageLoadingText`, `pagesCompactText(current, count, openEnd)`. |
| `jumpToPage` | `CsPaginationJumpToPage?` | `null` | Adds a page field and a jump button. `loading` shows a spinner on the button. |

`CsPaginationState.setError(bool)` shows the jump-to-page error popover (Cloudscape `ref.setError`). Reach it with a `GlobalKey<CsPaginationState>`.

`CsPaginationWindow.of(current, count, openEnd:)` exposes the page window logic (up to 7 controls between the first and last page, with dots for the gaps).

## Examples

### Open ended, loading more on demand

```dart
CsPagination(
  currentPageIndex: 4,
  pagesCount: 4,
  openEnd: true,
  onChange: (page) {},
  onNextPageClick: (detail) {
    if (!detail.requestedPageAvailable) {
      // Fetch the next page of items, then raise pagesCount.
    }
  },
)
```

### Compact

```dart
CsPagination(
  currentPageIndex: 3,
  pagesCount: 12,
  pagesVariant: CsPaginationPagesVariant.compact,
  onChange: (page) {},
)
```

### Jump to page with an error

```dart
final key = GlobalKey<CsPaginationState>();

Widget build(BuildContext context) => CsPagination(
  key: key,
  currentPageIndex: 1,
  pagesCount: 40,
  jumpToPage: const CsPaginationJumpToPage(loading: false),
  onChange: (page) {
    // If the server reports the page does not exist:
    key.currentState?.setError(true);
  },
);
```

## Accessibility

- The group is a labeled container (`paginationLabel`, "Pagination" by default).
- Each page button is announced with `pageLabel` ("Page 3 of all pages"); the current page is marked selected.
- Disabled arrows leave the Tab order. Tab moves through the controls; Enter and Space activate.
- The compact text and the jump error are live regions, so page changes and errors are announced.

## Motion

None: colors switch instantly on hover. The error popover scales from the jump button and is instant under reduced motion.

## Mobile

With `pagesVariant` left null, the page buttons are measured against the available width with 44px touch targets; when they do not fit (a phone in portrait) the compact "3 of 12" form is used. Pass a variant to fix the layout. The jump field wraps onto its own line if needed.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `currentPageIndex` | `currentPageIndex` |
| `pagesCount` | `pagesCount` |
| `openEnd` | `openEnd` |
| `pagesVariant` | `pagesVariant` (null adds automatic switching) |
| `disabled` | `disabled` |
| `ariaLabels` | `ariaLabels` |
| `i18nStrings` | `i18nStrings` |
| `jumpToPage` | `jumpToPage` |
| `onChange` (`detail.currentPageIndex`) | `onChange` (the page) |
| `onNextPageClick`, `onPreviousPageClick` | same names (`CsPaginationPageClickDetail`) |
| `ref.setError` | `CsPaginationState.setError` |
