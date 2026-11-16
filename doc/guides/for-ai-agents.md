# For AI agents

This page is for coding agents that build Flutter apps with cloudscape_flutter.

## Install the skills

```sh
dart run cloudscape_flutter:install_skill            # into .claude/skills
dart run cloudscape_flutter:install_skill --agents   # also add a pointer to AGENTS.md
```

This installs two skills: `cloudscape-flutter` (components, tokens, recipes) and `cloudscape-flutter-craft` (the design, accessibility, motion and copy standard, with a delivery checklist). Read both before UI work.

## Where to look

- `llms.txt`: an index of every guide and component page. `llms-full.txt`: all of them in one file.
- `doc/components/<Name>.md`: one page per component with parameters, defaults, examples and the Cloudscape React mapping.
- The Cloudscape docs at https://cloudscape.design describe the same components for React; prop names carry over (`variant`, `value`/`onChange`, `visible`/`onDismiss`, `items`, `selectedItems`).

## Rules that keep output on-brand

1. Wrap the app in `CsThemeProvider`; read colors from `context.cs`, never hardcode hex values.
2. Content text is body-m (14/20); headings use `CsHeader` (page `h1`, container `h2`); labels and buttons are bold.
3. One `primary` `CsButton` per view, `normal` by default, `link` for Cancel, `icon` in toolbars.
4. Controls are controlled: hold the value in your state and pass it back in `onChange`.
5. Pages are `CsAppLayout` + `CsContentLayout`; blocks of content are `CsContainer` with a `CsHeader`; collections are `CsTable` or `CsCards` with `CsCollection` for filtering, sorting and pagination.
6. Every collection has `loading` + `loadingText`, an `empty` state and an error state.
