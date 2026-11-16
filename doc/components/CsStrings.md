# CsStrings

Shared built-in copy (Close, Cancel, Loading, status names, month and weekday names, pagination text) in one place, provided by `CsLocale` and read with `context.csStrings`. Component-specific copy is passed per component as `i18nStrings`, as in Cloudscape.

Cloudscape reference: https://cloudscape.design/get-started/dev-guides/internationalization/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsLocale(
  strings: const CsStrings(close: 'Tutup', cancel: 'Batal', loading: 'Memuat'),
  child: const SizedBox(),
)
```

## Parameters

`CsStrings` has one `String` field per piece of copy, each defaulting to English, plus formatting helpers (`pageOf`, `monthYear`, `shortDate`, `fullDate`, `stepOf`). `firstDayOfWeek` sets where calendars start.

## Accessibility

Accessible names of icon-only controls come from these strings unless a component's `i18nStrings` or `ariaLabel` overrides them.

## Cloudscape React mapping

| Cloudscape | Flutter |
| --- | --- |
| `I18nProvider` with messages | `CsLocale` for shared copy, `i18nStrings` per component |
