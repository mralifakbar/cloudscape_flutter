# CsErrorBoundary

Cloudscape's `ErrorBoundary` (`src/error-boundary`): shows an error fallback in place of content that failed to build, so one broken section does not take down the screen.

Cloudscape reference: https://cloudscape.design/components/error-boundary/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsErrorBoundary(
  errorBoundaryId: 'instance-details',
  onError: (detail) => debugPrint('${detail.errorBoundaryId}: ${detail.error}'),
  child: const Text('Instance i-0abc123'),
)
```

## When to use / when not to

Wrap independent sections (a dashboard item, a details panel, a split panel's content) so a build error in one of them shows a contained fallback with a way to retry. Do not use it for expected failures such as a failed request; show those with `CsAlert`, a status indicator or a collection's error state.

## How it works

Flutter cannot catch a descendant's build error the way React does. While at least one boundary is mounted it installs, chained to the previous one, an `ErrorWidget.builder` that builds a small probe in place of the failed widget. The probe finds the nearest boundary above it and switches it to the fallback after the frame; with no boundary above, the previous builder runs (the usual error box). When the last boundary unmounts, the previous builder is restored. Errors thrown by `builder` are caught directly. Flutter still reports every error to `FlutterError.onError`, so logging keeps working.

Only build errors reach a boundary. Errors in layout, paint, gesture callbacks or async code do not, as in React.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` |  | The guarded content (pass this or `builder`) |
| `builder` | `WidgetBuilder?` |  | Builds the content; errors it throws are caught too. Wins over `child` |
| `onError` | `ValueChanged<CsErrorBoundaryErrorDetail>` | required | Called once per caught error, to log or report it |
| `errorBoundaryId` | `String?` |  | Passed to `onError` and set as the semantics identifier |
| `renderFallback` | `Widget? Function(BuildContext, CsErrorBoundaryFallbackSlots)?` |  | Custom fallback from the default slots; return null for the default alert |
| `i18nStrings` | `CsErrorBoundaryI18nStrings` | English | Header, description, refresh text and an optional inline feedback action |
| `suppressNested` | `bool` | `false` | Disables nested `suppressible` boundaries so their errors reach this one |
| `suppressible` | `bool` | `false` | Lets an outer `suppressNested` boundary disable this one |
| `onRefresh` | `VoidCallback?` |  | Called when "Refresh" is pressed, after the error is cleared (refetch data here) |
| `showRefreshAction` | `bool` | `true` | Shows the "Refresh" button |

`CsErrorBoundaryErrorDetail`: `error` (`Object`), `stackTrace` (`StackTrace?`), `details` (`FlutterErrorDetails?`, null for errors thrown by `builder`), `errorBoundaryId` (`String?`).

`CsErrorBoundaryFallbackSlots`: `header`, `description`, `action` (`Widget?`), `reset` (`VoidCallback`).

`CsErrorBoundaryI18nStrings`: `headerText` ("Unexpected error, content failed to show"), `descriptionText` ("Refresh to try again."), `refreshActionText` ("Refresh"), `feedbackText` and `feedbackBuilder` for an inline feedback action.

`CsErrorBoundaryState` (through a `GlobalKey`): `hasError`, `reset()`, `forceError([error])`.

## Examples

### Custom fallback

```dart
CsErrorBoundary(
  onError: (detail) {},
  renderFallback: (context, slots) => CsBox(
    padding: const CsBoxSpacing.all(CsSpacingSize.m),
    child: Column(children: [slots.header, slots.description, if (slots.action != null) slots.action!]),
  ),
  child: const Text('Distribution d111111abcdef8'),
)
```

### Feedback action in the description

```dart
CsErrorBoundary(
  onError: (detail) {},
  i18nStrings: CsErrorBoundaryI18nStrings(
    feedbackText: 'Report a problem',
    feedbackBuilder: (context, text) => CsLink(text: text, onFollow: () {}),
  ),
  builder: (context) => const Text('Bucket example-bucket'),
)
```

### Retry with fresh data

```dart
CsErrorBoundary(
  onError: (detail) {},
  onRefresh: () => setState(() => reloadKey++),
  child: const Text('Metrics'),
)
```

## Accessibility

The default fallback is an error `CsAlert`: an error icon with its label, the bold header, the description and a "Refresh" button. Focus is not moved; the content that failed is replaced in place.

## Motion

The fallback alert fades in with Cloudscape's `motion-duration-show-paced`.

## Mobile

The fallback takes the width of the failed section; the alert's action moves below the message at phone widths.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `children` | `child` / `builder` |
| `onError` (`error`, `errorInfo`, `errorBoundaryId`) | `onError` (`error`, `stackTrace`, `details`, `errorBoundaryId`) |
| `errorBoundaryId` | `errorBoundaryId` |
| `renderFallback` (`header`, `description`, `action`) | `renderFallback` (`CsErrorBoundaryFallbackSlots`, plus `reset`) |
| `i18nStrings.headerText / descriptionText / refreshActionText` | `i18nStrings` fields of the same names |
| `i18nStrings.components.Feedback` | `i18nStrings.feedbackBuilder` + `feedbackText` |
| `suppressNested` / `suppressible` | `suppressNested` / `suppressible` |
| page reload on "Refresh" | clears the error and rebuilds; `onRefresh` for more |
| `__awsui__.forceError` / `clearForcedError` | `CsErrorBoundaryState.forceError` / `reset` |
