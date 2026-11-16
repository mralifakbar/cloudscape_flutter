# CsAnchorNavigation

A table of contents for a long page that jumps to sections and highlights the one in view.

Cloudscape reference: https://cloudscape.design/components/anchor-navigation/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsAnchorNavigation(
  anchors: const [
    CsAnchorNavigationAnchor(text: 'Overview', href: '#overview'),
    CsAnchorNavigationAnchor(text: 'Pricing', href: '#pricing'),
    CsAnchorNavigationAnchor(text: 'On-demand', href: '#on-demand', level: 2),
  ],
  activeHref: '#pricing',
  onFollow: (anchor) {},
)
```

## When to use / when not to

- Use on long documentation or detail pages with several sections, usually in the tools panel or beside the content.
- Do not use for moving between pages (use `CsSideNavigation`) or for a few short sections that fit one screen.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `anchors` | `List<CsAnchorNavigationAnchor>` | required | Anchors in page order. |
| `activeHref` | `String?` | `null` | The active anchor. When set, the highlight is controlled and the scroll spy is ignored. |
| `scrollSpy` | `CsAnchorScrollSpy?` | `null` | Follows the scroll position when `activeHref` is null and scrolls to sections on follow. |
| `scrollOnFollow` | `bool` | `true` | Scroll to the section through `scrollSpy` when an anchor is followed. |
| `onFollow` | `ValueChanged<CsAnchorNavigationAnchor>?` | `null` | Called when an anchor is followed. |
| `onActiveHrefChange` | `ValueChanged<CsAnchorNavigationAnchor>?` | `null` | Called when the active anchor changes, from scrolling or from `activeHref`. |
| `ariaLabel` | `String?` | `CsStrings.tableOfContents` | Accessible name of the list. |

`CsAnchorNavigationAnchor(text:, href:, level: 1, info:)`: `level` starts at 1 and indents 16px per level; `info` adds a short bold tag such as "New".

### CsAnchorScrollSpy

`CsAnchorScrollSpy(controller:, sections:, offset: 0)` is a `ChangeNotifier` that tracks which section of a scroll view is in view. `sections` maps each anchor href to the `GlobalKey` of its section, in page order. `offset` is the height covering the top of the viewport (a sticky header). Read `activeHref`, call `scrollTo(href)`, and dispose it with the scroll controller.

## Examples

### Following the scroll position

```dart
class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  final controller = ScrollController();
  final overview = GlobalKey();
  final pricing = GlobalKey();
  late final spy = CsAnchorScrollSpy(
    controller: controller,
    sections: {'#overview': overview, '#pricing': pricing},
  );

  @override
  void dispose() {
    spy.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                CsContainer(key: overview, child: const Text('Overview')),
                CsContainer(key: pricing, child: const Text('Pricing')),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 240,
          child: CsAnchorNavigation(
            scrollSpy: spy,
            anchors: const [
              CsAnchorNavigationAnchor(text: 'Overview', href: '#overview'),
              CsAnchorNavigationAnchor(text: 'Pricing', href: '#pricing', info: 'Updated'),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Accessibility

- The list is a labeled container ("Table of contents" by default).
- Anchors are links; the active one is marked selected (Cloudscape's `aria-current`). The info tag is read after the text.
- Tab moves through anchors; Enter and Space follow them.

## Motion

The accent bar fades between anchors over `CsDurations.slow`. Scrolling to a section animates over `CsDurations.complex`; both are instant under reduced motion. Hover colors switch instantly.

## Mobile

The list wraps long titles. On touch screens each anchor row is at least 36px tall. On phones, place it above the content or in a sheet rather than beside it.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `anchors` (`text`, `href`, `level`, `info`) | `anchors` (`CsAnchorNavigationAnchor`) |
| `activeHref` | `activeHref` |
| `scrollSpyOffset` | `CsAnchorScrollSpy.offset` |
| internal scroll spy (window scroll) | `scrollSpy` (`CsAnchorScrollSpy` on a `ScrollController`) |
| `onFollow` | `onFollow` |
| `onActiveHrefChange` | `onActiveHrefChange` |
| `ariaLabelledby` | `ariaLabel` |
