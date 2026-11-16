# CsPieChart

A pie or donut chart that shows how parts make up a single whole, with segment labels, a legend, a segment filter and a detail popover.

Cloudscape reference: https://cloudscape.design/components/pie-chart/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPieChart<CsPieChartDatum>(
  data: const [
    CsPieChartDatum(title: 'Running', value: 60),
    CsPieChartDatum(title: 'Stopped', value: 25),
    CsPieChartDatum(title: 'Terminated', value: 15),
  ],
  variant: CsPieChartVariant.donut,
  innerMetricValue: '100',
  innerMetricDescription: 'instances',
  segmentDescription: (segment, sum) => '${(segment.value * 100 / sum).round()}%',
  ariaLabel: 'Instance states',
)
```

## When to use / when not to

- Use it for parts of one whole with few segments (up to about 6). Order segments by size.
- Use the donut variant to show the total (or a key figure) in the middle.
- Use `CsBarChart` to compare values that are not parts of one total, or when segments are close in size.

## Parameters

`T` is your segment type: `CsPieChartDatum` or a subclass that carries more fields; callbacks receive your type.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `data` | `List<T>` | required | Segments, clockwise from 12 o'clock. Values of zero or less get no segment; each segment is drawn at least 1% of the pie. |
| `size` | `CsPieChartSize` | `medium` | Outer radius `small` 50, `medium` 100, `large` 140. With `fitHeight`, the minimum. On screens too narrow for the pie and its labels, the pie shrinks. |
| `variant` | `CsPieChartVariant` | `pie` | `pie` or `donut`. |
| `innerMetricValue` | `String?` | `null` | Large text in the middle of a donut. |
| `innerMetricDescription` | `String?` | `null` | Text under it, usually the unit. Not shown for `small`. |
| `segmentDescription` | `CsPieChartSegmentDescription<T>?` | `null` | `(segment, visibleSum) => String` shown under each label. |
| `hideTitles` / `hideDescriptions` | `bool` | `false` | Hide segment titles / descriptions next to the pie. With both, there are no labels. |
| `detailPopoverContent` | `CsPieChartDetailPopoverContent<T>?` | `null` | `(segment, visibleSum) => List<CsChartDetailPair>`. Defaults to "Value" and "Percentage". |
| `detailPopoverFooter` | `Widget Function(T segment)?` | `null` | Content under a divider in the popover. |
| `detailPopoverSize` | `CsChartPopoverSize` | `medium` | Popover max width (210, 310, 482). |
| `hideLegend` / `hideFilter` | `bool` | `false` | Hide the legend / the built-in filter. |
| `legendTitle` | `String?` | `null` | Bold title above the legend. |
| `additionalFilters` | `Widget?` | `null` | Extra filters next to the built-in one. |
| `highlightedSegment` | `T?` | `null` | Segment to highlight; a new value replaces the current highlight. |
| `onHighlightChange` | `ValueChanged<T?>?` | `null` | The user highlighted a segment or cleared it. |
| `visibleSegments` | `List<T>?` | `null` | Segments shown. Null lets the filter manage it. |
| `onFilterChange` | `ValueChanged<List<T>>?` | `null` | The built-in filter changed the visible segments. |
| `statusType` | `CsChartStatusType` | `finished` | `loading`, `finished` or `error`. |
| `empty` / `noMatch` | `Widget?` | `null` | No data (or all zero) / everything filtered out. |
| `loadingText` / `errorText` / `recoveryText` | `String?` | `null` | Defaults: "Loading chart", "The data couldn't be fetched. Try again later.", "Retry". |
| `onRecoveryClick` | `VoidCallback?` | `null` | Recovery link action. Without it there is no link. |
| `ariaLabel` / `ariaDescription` | `String?` | `null` | Accessible name and summary. |
| `i18nStrings` | `CsPieChartI18nStrings` | `const CsPieChartI18nStrings()` | `detailsValue`, `detailsPercentage`, `filterLabel`, `filterPlaceholder`, `filterSelectedAriaLabel`, `legendAriaLabel`, `detailPopoverDismissAriaLabel`, `chartAriaRoleDescription` ("Pie chart"), `segmentAriaRoleDescription` ("Segment"). |
| `fitHeight` | `bool` | `false` | Fill a parent with bounded height. |

`CsPieChartDatum(title:, value:, color:, colorToken:)`: `color` (a `Color`) or `colorToken` (a `CsColor`, follows light and dark) override the palette.

## Examples

### Custom segment type and popover

```dart
class BucketUsage extends CsPieChartDatum {
  const BucketUsage(String title, num value, this.region) : super(title: title, value: value);
  final String region;
}

final chart = CsPieChart<BucketUsage>(
  data: const [BucketUsage('example-bucket', 420, 'us-east-1'), BucketUsage('logs-bucket', 180, 'eu-west-1')],
  detailPopoverContent: (b, sum) => [
    CsChartDetailPair(key: 'Region', value: b.region),
    CsChartDetailPair(key: 'Size', value: '${b.value} GB'),
  ],
  detailPopoverFooter: (b) => CsLink(text: 'Open ${b.title}', onFollow: () {}),
  ariaLabel: 'Storage by bucket',
);
```

### Small donut without labels

```dart
const CsPieChart<CsPieChartDatum>(
  data: [CsPieChartDatum(title: 'Used', value: 72), CsPieChartDatum(title: 'Free', value: 28)],
  variant: CsPieChartVariant.donut,
  size: CsPieChartSize.small,
  innerMetricValue: '72%',
  hideTitles: true,
  hideDescriptions: true,
  hideFilter: true,
  ariaLabel: 'Quota used',
)
```

## Accessibility

- One focusable element announced as `ariaLabel` plus "Pie chart"; its hint reads `ariaDescription`, the inner metric and every segment with its value.
- Keyboard, as in Cloudscape: Tab focuses the chart and highlights a segment, Left and Right cycle segments, Enter or Space pins the popover, Escape clears. The semantics value reads "Segment 2 of 3, Stopped (25), 25%".
- A 2px focus outline wraps the highlighted segment; a 2px ring 4px outside the segment marks the highlight.
- The legend and filter follow the cartesian charts (one tab stop, Left and Right; checkable filter rows). Colors are always paired with titles.

## Motion

- Segments sweep in clockwise once (250ms, `showPaced`); labels appear after. Highlight dimming fades over 90ms. Reduced motion shows everything at once.

## Mobile

- Tap a segment to highlight it and pin its popover; tap it again or outside to dismiss. At or below 688px the popover opens above the segment.
- The pie shrinks when labels and pie do not fit side by side; label text truncates at the chart edge. The filter opens as a bottom sheet.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `data` (`title`, `value`, `color`) | `data` of `CsPieChartDatum` (`color` or `colorToken`) |
| `size`, `variant` | `size` (`CsPieChartSize`), `variant` (`CsPieChartVariant`) |
| `innerMetricValue`, `innerMetricDescription` | same names |
| `segmentDescription`, `detailPopoverContent`, `detailPopoverFooter`, `detailPopoverSize` | same names (Dart functions, `CsChartPopoverSize`) |
| `hideLegend`, `hideTitles`, `hideDescriptions`, `hideFilter`, `legendTitle`, `additionalFilters` | same names |
| `highlightedSegment` + `onHighlightChange` | same names, callback receives the segment |
| `visibleSegments` + `onFilterChange` | same names, callback receives the list |
| `statusType`, `empty`, `noMatch`, `loadingText`, `errorText`, `recoveryText`, `onRecoveryClick` | same names |
| `ariaLabel`, `ariaDescription`, `i18nStrings`, `fitHeight` | same names (`CsPieChartI18nStrings`) |
| `ariaLabelledby` | not supported (web only); use `ariaLabel` |
