# CsPropertyFilter

Cloudscape's `PropertyFilter`: builds a query of `property operator value` tokens and free-text tokens for filtering a collection.

Cloudscape reference: https://cloudscape.design/components/property-filter/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPropertyFilter(
  query: const CsPropertyFilterQuery(),
  onChange: (query) {},
  countText: '5 matches',
  filteringProperties: const [
    CsPropertyFilterProperty(key: 'type', propertyLabel: 'Instance type', groupValuesLabel: 'Instance type values'),
    CsPropertyFilterProperty(key: 'state', propertyLabel: 'State', groupValuesLabel: 'State values'),
  ],
  filteringOptions: const [
    CsPropertyFilterOption(propertyKey: 'type', value: 't3.micro'),
    CsPropertyFilterOption(propertyKey: 'state', value: 'Running'),
  ],
)
```

## When to use / when not to

Use it above large collections where users filter by several properties. For plain text search use `CsTextFilter`.

## How it works

1. With an empty input the suggestions list properties and values.
2. Picking a property fills "Instance type " and suggests its operators.
3. Picking an operator fills "Instance type = " and suggests that property's values.
4. Picking a value adds the token. Typing a whole query ("State = Running") and pressing Enter works too; other text becomes a free-text token (operator `contains`) unless `disableFreeTextFiltering`.
5. Tokens show under the input, joined by the and/or operation (tap it to switch). Tapping a token opens the editor (property, operator, value, Cancel and Apply). "Clear filters" removes every token.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `query` | `CsPropertyFilterQuery` | required | `tokens` and `operation` (`and`, `or`) |
| `onChange` | `ValueChanged<CsPropertyFilterQuery>` | required | Next query |
| `filteringProperties` | `List<CsPropertyFilterProperty>` | required | `key`, `propertyLabel`, `groupValuesLabel`, `operators`, `defaultOperator`, `group` |
| `filteringOptions` | `List<CsPropertyFilterOption>` | `[]` | `propertyKey`, `value`, `label` |
| `countText` | `String?` | | Next to the input while there are tokens |
| `disabled` | `bool` | `false` | |
| `hideOperations` | `bool` | `false` | Hide and/or |
| `readOnlyOperations` | `bool` | `false` | And/or as text |
| `disableFreeTextFiltering` | `bool` | `false` | |
| `freeTextOperators` | `List<CsPropertyFilterOperator>` | `contains`, `notContains` | Offered in the editor for free text |
| `customGroupsText` | `List<CsPropertyFilterGroupText>` | `[]` | Headings of custom property groups |
| `tokenLimit` | `int?` | | Tokens before "Show more" |
| `i18nStrings` | `CsPropertyFilterI18nStrings` | English | Every label, operator name and `formatToken`, `removeTokenButtonAriaLabel`, `enteredTextLabel` |
| `onLoadItems` | `ValueChanged<CsPropertyFilterLoadItemsDetail>?` | | As the user types: property, operator and value text |
| `filteringEmpty`, `filteringLoadingText`, `filteringFinishedText`, `filteringErrorText`, `filteringRecoveryText`, `filteringStatusType` | | | Suggestion status |
| `filteringConstraintText` | `String?` | | Help under the input |
| `customControl` | `Widget?` | | Before the input |
| `customFilterActions` | `Widget?` | | Replaces "Clear filters" |
| `loading` | `bool` | `false` | Hides the count |
| `tokenLimitShowMoreAriaLabel`, `tokenLimitShowFewerAriaLabel` | `String?` | | |

Operators (`CsPropertyFilterOperator`): `lessThan` `<`, `lessThanOrEqual` `<=`, `greaterThan` `>`, `greaterThanOrEqual` `>=`, `contains` `:`, `notContains` `!:`, `equals` `=`, `notEquals` `!=`, `startsWith` `^`, `notStartsWith` `!^`.

## Examples

### Numeric operators and custom groups

```dart
CsPropertyFilter(
  query: const CsPropertyFilterQuery(tokens: [
    CsPropertyFilterToken(propertyKey: 'cpu', operator: CsPropertyFilterOperator.greaterThan, value: '80'),
  ], operation: CsPropertyFilterOperation.or),
  onChange: (query) {},
  filteringProperties: const [
    CsPropertyFilterProperty(
      key: 'cpu',
      propertyLabel: 'CPU utilization',
      groupValuesLabel: 'CPU values',
      operators: [CsPropertyFilterOperator.greaterThan, CsPropertyFilterOperator.lessThan],
      group: 'metrics',
    ),
  ],
  customGroupsText: const [CsPropertyFilterGroupText(group: 'metrics', properties: 'Metrics', values: 'Metric values')],
)
```

## Accessibility

The input is a text field with suggestions driven by Up, Down and Enter (see `CsAutosuggest`). Each token is a button announcing "<property> <operator name> <value>" (override with `formatToken`) that opens the editor, plus a remove button. The and/or control announces "Boolean operator" with its value. The editor traps focus, Escape closes it and focus returns to the token.

## Motion

Suggestions, the and/or menu and the editor scale and fade from their anchors; reduced motion keeps only the fade.

## Mobile

Tokens wrap. The token editor opens as a bottom sheet at or below 688px.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `query`, `onChange` (`detail`) | `query`, `onChange` (the query) |
| `filteringProperties`, `filteringOptions`, `countText`, `disabled`, `hideOperations`, `readOnlyOperations`, `disableFreeTextFiltering`, `customGroupsText`, `tokenLimit`, `i18nStrings`, `onLoadItems` | same names |
| `freeTextFiltering.operators` | `freeTextOperators` |
| `filteringEmpty`, `filteringLoadingText`, `filteringFinishedText`, `filteringErrorText`, `filteringRecoveryText`, `filteringStatusType`, `filteringConstraintText`, `customControl`, `customFilterActions` | same names |
| `filteringAriaLabel`, `filteringPlaceholder` | `i18nStrings.filteringAriaLabel`, `.filteringPlaceholder` |
| `enableTokenGroups`, extended operators with custom forms, `asyncProperties` | not implemented (tokens are flat; values are strings) |
| `expandToViewport`, `virtualScroll` | not applicable |
