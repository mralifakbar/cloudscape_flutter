# CsChartSeries

The data types shared by `CsLineChart`, `CsBarChart`, `CsMixedLineBarChart` and `CsAreaChart`: series, data points, popover details, palette and copy.

Cloudscape reference: https://cloudscape.design/components/mixed-line-bar-chart/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
final latency = CsChartSeries<int>.line(
  title: 'p99 latency',
  data: const [CsChartDatum(0, 120), CsChartDatum(1, 135), CsChartDatum(2, 98)],
  valueFormatter: (y, x) => '${y}ms',
);
const sla = CsChartSeries<int>.threshold(title: 'SLA', y: 150, colorToken: CsColor.chartsThresholdNegative);
```

## When to use / when not to

- Build series once (fields, `const`) and pass the same instances on every build: charts track filtering and highlight by series identity.
- Use `colorToken` for color overrides so they follow light and dark mode; leave colors out to get Cloudscape's categorical palette in order.

## Parameters

### CsChartSeries<T>

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `CsChartSeries.line/.bar/.area(title:, data:)` | constructors | | A data series of that `type`. |
| `CsChartSeries.threshold(title:, y: or x:)` | constructor | | Dashed reference line at a value (`y`) or position (`x`, not in area charts). |
| `type` | `CsChartSeriesType` | | `line`, `bar`, `area`, `threshold`. |
| `title` | `String` | required | Shown in legend, filter and popover. |
| `data` | `List<CsChartDatum<T>>` | `[]` | `CsChartDatum(x, y)`; `y` is a `num`. |
| `color` | `Color?` | `null` | Raw color override (Cloudscape `color`). |
| `colorToken` | `CsColor?` | `null` | Token color override. |
| `valueFormatter` | `CsChartValueFormatter<T>?` | `null` | `(y, x) => String` for popover values. |
| `valueFormatter` (threshold) | `CsChartTickFormatter<num>?` | `null` | `(y) => String` for the threshold value, stored as `thresholdValueFormatter`. |

### Other types

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `CsChartScaleType` | enum | | `linear`, `log`, `time`, `categorical`. |
| `CsChartYScaleType` | enum | | `linear`, `log`. |
| `CsChartStatusType` | enum | | `loading`, `finished`, `error`. |
| `CsChartPopoverSize` | enum | | `small` (210), `medium` (310), `large` (482); `maxWidth`. |
| `CsChartSeriesDetail` | class | | Returned by `detailPopoverSeriesContent`: `key`/`keyWidget`, `value`/`valueWidget`, `subItems`, `expandable`. |
| `CsChartDetailPair` | class | | `key`/`keyWidget`, `value`/`valueWidget`; popover rows and sub-items. |
| `CsChartColors` | class | | `categorical` (the 50 palette tokens in Cloudscape order), `threshold`, `at(theme, i)`, `resolve(...)`. |
| `CsChartI18nStrings` | class | all `null` | `filterLabel` ("Filter displayed data"), `filterPlaceholder` ("Filter data"), `filterSelectedAriaLabel`, `legendAriaLabel` ("Legend"), `detailPopoverDismissAriaLabel` ("Dismiss"), `chartAriaRoleDescription`, `xAxisAriaRoleDescription` ("x-axis"), `yAxisAriaRoleDescription` ("y-axis"), `detailTotalLabel` ("Total"), `expandAriaLabel`, `collapseAriaLabel`. |

## Examples

### Palette colors outside a chart

```dart
Widget swatch(BuildContext context, int i) => Container(
  width: 14,
  height: 14,
  color: CsChartColors.at(context.cs, i),
);
```

### Popover breakdown

```dart
CsChartSeriesDetail detail(CsChartSeries<String> s, String x, num y) => CsChartSeriesDetail(
  value: '$y requests',
  expandable: true,
  subItems: const [CsChartDetailPair(key: 'GET', value: '640'), CsChartDetailPair(key: 'PUT', value: '120')],
);
```

## Accessibility

Series titles name everything a color shows: legend entries, filter rows, popover rows and the chart's screen reader summary.

## Motion

Not animated on their own; see the chart pages.

## Mobile

No layout of their own; see the chart pages.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `MixedLineBarChartProps.ChartSeries`, `AreaChartProps.Series` | `CsChartSeries<T>` |
| `Datum` | `CsChartDatum<T>` |
| `DetailPopoverSeriesKeyValuePair` | `CsChartSeriesDetail` |
| `ChartDetailPair` | `CsChartDetailPair` |
| `CartesianChartProps.I18nStrings` | `CsChartI18nStrings` |
| `color-charts-palette-categorical-*` | `CsChartColors.categorical` |
