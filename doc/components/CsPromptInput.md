# CsPromptInput

Cloudscape's `PromptInput`: the multi-line field of a chat or generative AI experience, with a send button, actions under the text and content above it.

Cloudscape reference: https://cloudscape.design/components/prompt-input/

## Import

```dart
import 'package:cloudscape_flutter/cloudscape_flutter.dart';
```

## Usage

```dart
CsPromptInput(
  value: prompt,
  placeholder: 'Ask a question about your instances',
  actionButtonIcon: CsIcons.send,
  disableActionButton: prompt.trim().isEmpty,
  onChange: (v) => setState(() => prompt = v),
  onAction: (v) => setState(() {
    send(v);
    prompt = '';
  }),
)
```

## When to use / when not to

Use it for conversational input that is sent as a whole (chat, assistants, prompts). For single-line form values use `CsInput`; for long-form text in a form use a textarea.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | |
| `onChange` | `ValueChanged<String>?` | | |
| `onAction` | `ValueChanged<String>?` | | Enter or the action button; clear `value` here |
| `actionButtonIcon` | `CsIconData?` | | Usually `CsIcons.send`; no icon means no button |
| `actionButtonIconWidget` | `Widget?` | | Custom icon (Cloudscape `actionButtonIconSvg`) |
| `actionButtonAriaLabel` | `String?` | `i18nStrings.actionButtonAriaLabel` ("Submit prompt") | |
| `disableActionButton` | `bool` | `false` | |
| `customPrimaryAction` | `Widget?` | | Replaces the action button (a stop button while streaming) |
| `minRows` | `int` | `1` | |
| `maxRows` | `int` | `3` | `-1` grows without limit |
| `secondaryActions` | `Widget?` | | Actions under the text; the action button moves to this row |
| `secondaryContent` | `Widget?` | | Content above the text (attached files) |
| `disableSecondaryActionsPaddings`, `disableSecondaryContentPaddings` | `bool` | `false` | |
| `placeholder` | `String?` | | |
| `disabled`, `readOnly` | `bool` | `false` | |
| `invalid`, `warning` | `bool` | `false` | Status border with a thick start edge |
| `ariaLabel` | `String?` | | |
| `autoFocus` | `bool` | `false` | |
| `spellcheck`, `autoComplete` | `bool` | `true` | |
| `onFocus`, `onBlur` | `VoidCallback?` | | |
| `focusNode` | `FocusNode?` | | |
| `i18nStrings` | `CsPromptInputI18nStrings` | English | `actionButtonAriaLabel` |

## Examples

### Attachments and actions

```dart
CsPromptInput(
  value: prompt,
  actionButtonIcon: CsIcons.send,
  minRows: 2,
  maxRows: 6,
  onChange: (v) {},
  onAction: (v) {},
  secondaryContent: CsFileTokenGroup(
    alignment: CsFileTokenGroupAlignment.horizontal,
    items: [for (final f in attached) CsFileTokenGroupItem(file: f)],
    onDismiss: (i) {},
  ),
  secondaryActions: CsFileInput(
    value: attached,
    variant: CsFileInputVariant.icon,
    ariaLabel: 'Attach file',
    onPick: (request) async => null,
    onChange: (files) {},
  ),
)
```

### Stop while streaming

```dart
CsPromptInput(
  value: '',
  customPrimaryAction: CsButton(icon: CsIcons.stopCircle, variant: CsButtonVariant.icon, semanticLabel: 'Stop generating', onPress: () {}),
)
```

## Accessibility

A labelled container around a multi-line text field. Enter sends, Shift+Enter inserts a new line (IME composition is never interrupted). The action button is named "Submit prompt" by default and disabled while `disabled`, `readOnly` or `disableActionButton`. Focus anywhere inside draws the field's focus ring.

## Motion

The field grows line by line as text wraps, without animation, like Cloudscape.

## Mobile

The soft keyboard shows a send key, which calls `onAction`. Secondary actions and the send button sit in one row under the text; the field never scrolls horizontally.

## Cloudscape React mapping

| Cloudscape prop | Flutter parameter |
| --- | --- |
| `value`, `placeholder`, `disabled`, `readOnly`, `invalid`, `warning`, `minRows`, `maxRows`, `disableActionButton`, `customPrimaryAction`, `secondaryActions`, `secondaryContent`, `disableSecondaryActionsPaddings`, `disableSecondaryContentPaddings`, `ariaLabel`, `autoFocus`, `spellcheck`, `i18nStrings` | same names |
| `onChange`, `onAction` (`detail.value`) | `ValueChanged<String>` |
| `actionButtonIconName` | `actionButtonIcon` |
| `actionButtonIconSvg`, `actionButtonIconUrl` | `actionButtonIconWidget` |
| `actionButtonAriaLabel` | `actionButtonAriaLabel` |
| `autoComplete` (string) | `autoComplete` (`bool`) |
| `tokens`, `tokensToText`, `menus`, `onMenuItemSelect`, `onMenuLoadItems`, `onMenuFilter`, `onTriggerDetected`, `maxMenuHeight` | not supported (token mode) |
| `name`, `nativeTextareaAttributes`, `style`, `onKeyDown`, `onKeyUp` | not applicable |
