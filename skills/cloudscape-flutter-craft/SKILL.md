---
name: cloudscape-flutter-craft
description: |
  Craft standard for Flutter apps built with cloudscape_flutter: honest content, screens that reflow from phone to desktop,
  accessibility for every kind of user, fluid touch-driven motion, Cloudscape typography and spacing, clear copy and clean
  code comments. Use whenever you build, change or review a screen, flow or custom widget in a cloudscape_flutter app,
  alongside the cloudscape-flutter skill (which covers which component to use). Ends every UI task with the delivery checklist.
license: Apache-2.0
---

# cloudscape_flutter craft

The cloudscape-flutter skill tells you *which* component to use. This skill tells you how to make the result feel designed rather than generated: purposeful, honest, usable by everyone, and alive under the finger.

## Two modes

- **Build** (default): apply every section while you write, then run the delivery checklist before you hand anything over.
- **Review** (only when asked to audit or review): produce a numbered list of findings, each with severity (blocker, should fix, polish), the rule it breaks, `file:line` and a one-line reason. Change nothing until the user picks numbers. Fix exactly those, then re-run the checklist.

## 1. Direction before pixels

Cloudscape is the visual language: palette, type scale, spacing, density, radii and borders are decided. What the app brings is its content, its voice, and where the single accent moment lands.

Before building a screen, write one line:

> Building `<screen>` for `<who>`, so they can `<one decision or task>`. Energy `<calm|balanced|bold>`, rhythm `<uniform|mostly consistent|varied>`, motion `<feedback only|transitions|choreographed>`.

- **Energy**: how loudly the screen greets you. Cloud consoles are mostly calm: a list of resources, a details page, a create flow. Reserve bold for a first-run moment.
- **Rhythm**: how much consecutive sections differ in composition.
- **Motion**: how much moves, and the reason for each movement (feedback, state change, spatial orientation). "It looks nice" is not a reason.

Hold those choices to the end of the screen. If you cannot name the user's one decision, the screen is not ready to build. If the owner has given no direction for voice or brand moments, ask one short question; if you cannot ask, build calm, uniform, feedback-only and say it is a draft.

## 2. Honesty (blocking)

- Never show numbers, statistics, uptime, prices, testimonials, names, avatars or logos that are not real data or explicitly labeled sample data. Empty is better than invented. Fake precision (`99.98%`, `4.1x faster`) is invention too.
- Placeholders say what they are: `example-bucket`, `i-0abc123`, "Sample data", "Coming soon". Never `John Doe`, never `Acme`.
- No security, compliance or performance claims without evidence the user gave you.
- Do not create logos, app icons or photos of people on assumption. Use the product name in text, initials avatars, or ask.
- Never use AWS logos, AWS service icons or the Amazon Ember font, and never imply AWS made or endorsed the app.

## 3. Function and states (blocking)

- Every control does something real: navigates to a route that exists, opens and closes an overlay, toggles state, submits with feedback. Otherwise remove it, or ship it disabled with a visible "Coming soon" and a `TODO:` naming the task.
- Navigation items (sidebar, tabs, bottom navigation, menus) only point at destinations that exist.
- Every data view has three states, each saying why and what next:
  - **Loading**: `CsSkeleton` shapes that match the real layout, or the component's own `loading` + `loadingText` (tables, cards, selects, charts).
  - **Empty**: the component's `empty` slot with the reason and the one action that fills it ("No instances. Launch an instance to get started with compute." with a "Launch instance" button).
  - **Error**: what failed in plain words and how to recover (retry, check the token).
  - First run, filtered-to-nothing, offline and permission-denied are different states with different copy.
- Search never opens blank: show recent items, common destinations or a hint of what can be searched.
- Forms: label above the field (`CsFormField`), helper text below, error below and announced, never a placeholder used as the label. Validate when the user leaves a field, keep the entered value on error, disable submit only while submitting (`loading: true`).
- Prefer selection over typing when the options are known (select, radio group, segmented toggle), with "Other" plus a field as the fallback.
- Status flows (deployments, jobs, orders) open with a clear status line and show progress as a timeline, not a list of dates.

## 4. Accessibility (blocking)

- **Contrast**: text at least 4.5:1, large text and UI boundaries at least 3:1. Cloudscape text tokens on Cloudscape surfaces pass; for anything custom compute it with `CsColorUtils.contrastRatio`, never eyeball grey on grey. Text over images needs a scrim and is checked at its lightest spot.
- **Touch**: every target at least 44x44 with space between neighbours. `CsPressable` pads Cloudscape's 32px controls on touch platforms; keep `CsTapTargetSize.padded` there.
- **Screen readers**: every control has a role, label and state. Icon-only buttons get `semanticLabel`. Decorative icons stay excluded. Page and section titles are `CsHeader` (marked as headings). Announce async results (live regions).
- **Keyboard**: Tab follows visual order, Enter/Space activate, Escape closes overlays, arrows move inside groups, focus is trapped in modals and restored to the trigger. Never hide the focus ring.
- **Text size**: verify at 2x. No fixed heights around text; use min heights, wrapping, and ellipsis only where the full value is reachable elsewhere.
- **Never color alone**: status pairs color with an icon or a word ("Failed", "Healthy").
- **Platform settings**: reduced motion (`CsMotion.reduceMotion`, which also covers the theme's `disableMotion`), bold text, RTL (start/end, `EdgeInsetsDirectional`).

## 5. Layout that reflows (blocking on phones)

Cloudscape is designed for wide consoles. A phone layout is its own layout, not the desktop one squeezed.

- Width classes are a starting point; place breakpoints where the content breaks. cloudscape_flutter switches at Cloudscape's mobile breakpoint, 688px (`context.csIsNarrow`), and uses `CsBreakpoint` (465, 688, 912, 1120, 1320, 1840) for grids.
  - **Compact** (phones): one column, 20px gutters, `CsAppLayout` navigation and tools as overlays opened from its toolbar, primary action in the thumb zone (bottom third), dropdowns as bottom sheets.
  - **Medium**: two columns where content has two natural groups, or a list/detail split; side navigation still an overlay, split panel at the bottom.
  - **Expanded**: persistent side navigation, tools panel and split panel on the side; `contentType` caps content width (form, wizard) or lets tables use it all.
- No horizontal page scroll at 320px or any width between. Tables and code scroll inside their own container with a visible edge, or reflow to cards.
- Respect safe areas, the home indicator and the keyboard: a focused field is never hidden; a fixed bar never covers the last row (reserve its height).
- Fixed chrome stays compact so content dominates. Sticky headers get a bottom border.
- Size with tokens and relative constraints; let flex children shrink.

## 6. Composition and hierarchy

- **One focal point per screen**: the resource name, the failing check, the primary action. Everything else defers in size, weight and color.
- **Cloudscape type rules**: content text body-m 14/20; descriptions body-s 12/16 secondary; page title `CsHeader(variant: h1)` 24px, containers `h2` 20px, sub-sections `h3` 18px; headings, labels and buttons bold. Monospace (`CsBox(variant: code)`) for IDs and ARNs. Headings in sentence case. At most four sizes on a screen.
- **Key-value pairs**: labels bold (`awsuiKeyLabel`), values body text; large numbers in dashboards use `awsuiValueLarge`. Use `CsKeyValuePairs`.
- **Spacing as structure**: related text closer together than the content around it (use `CsSpaceBetween` with `xxs`/`xs` inside a group, `l` between containers). Read density-dependent spacing from `context.cs.space` so compact mode works. One gap everywhere flattens the screen.
- **One accent**: Cloudscape blue belongs to the primary action, links and the current selection. Zero accent is sterile; accent on everything means nothing stands out.
- **One primary button per view**; `normal` by default, `link` for Cancel next to the primary, `icon` in toolbars. One label per intent across the screen ("Launch instance" everywhere, not "Launch", "Create" and "Start").
- **Shapes from Cloudscape**: buttons are pills (20px), inputs and dropdowns 8px, containers 16px, badges 4px. Do not invent radii.
- **Build from the user's decision, not a template.** Avoid the default dashboard (side navigation, four stat cards, a chart, a table) when the job is "find the unhealthy instance and reboot it"; build around that job. If a section exists only because "apps usually have one", cut it.
- **Vary composition by weight**: the item that needs attention can be a full-width card, the rest a list. Identical cards for unequal content hide the hierarchy. Do not nest containers; use `CsContainer(variant: stacked)` or headers inside one container.

## 7. Techniques that need a reason

Each is allowed when you can state its purpose in one line; otherwise leave it out.

- **Shadows** only on surfaces that float (menus, popovers, toasts, dialogs). Resting surfaces get Cloudscape's 1px divider border and no shadow.
- **Translucency or blur** on at most one piece of chrome that content scrolls under, with a solid fallback.
- **Gradients** to encode data (chart areas) or Cloudscape's generative AI avatar and loading bar. Not as backgrounds.
- **Badges and dots** only for real state (failed, paused, new since last visit). A dot that marks nothing goes.
- **Icons** chosen for meaning from `CsIcons`. The `gen-ai` sparkle is only for generative AI features; no emoji in UI text. Use the `-filled` icons for active states where they exist.
- **Arrows and carets** where they signal navigation or disclosure, not on every button.
- **Illustrations** only when they explain something about this product.

## 8. Motion that answers touch

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

- **Respond instantly.** Feedback on pointer-down (`CsPressable` does this). Hover colors change instantly, never animated. No artificial delays on the input path.
- **Direct manipulation.** Dragged things move 1:1 with the finger and keep the grab offset. Track velocity during the drag.
- **Interruptible always.** `AnimationController.unbounded` + `CsMotion.springTo`, which starts from the current value and velocity. A closing sheet can be caught and pulled back without a jump. Never lock input during a transition.
- **Springs for touch.** `CsSprings.standard` (no overshoot) by default; `CsSprings.momentum` only when the gesture carried momentum; `CsSprings.sheet` for sheets and drawers; `CsSprings.popup` for things scaling from a trigger. Move X and Y with separate springs.
- **Velocity handoff and projection.** On release, pass the finger's velocity into the spring; choose the snap target from `position + CsMotion.project(velocity)`; decide dismiss vs. return from velocity direction. Past a boundary, `CsMotion.rubberband`.
- **Spatial consistency.** Things leave the way they came; popups grow from their trigger (`CsAnchoredOverlay`, `CsDropdown`); page transitions follow navigation direction.
- **Fixed durations** for fades and expand/collapse from Cloudscape's motion tokens (`CsDurations.responsive` 115ms, `expressive` 165ms, `complex` 250ms, `showPaced` 180ms for expanding content) with `CsCurves`. Collapsing content keeps its size while it animates.
- **Nothing loops forever.** Repetition only while a real process runs (loading), paused off screen, static under reduced motion. No idle pulses, floating elements or decorative shimmer.
- **Haptics on the causal moment** (toggle flips, a sheet snaps, a selection changes) through `csHaptic`, on the same frame as the visual. Not on scroll ticks, not on every button.
- **Peak and end.** Find the moment that matters (an instance launching, a bucket created) and give it clear, brief feedback: a success `CsFlashbar` with the result and the next action. End flows with a summary, not a blank screen.
- **Reduced motion** swaps slides, scales and springs for an instant change or a short cross-fade, keeps color and opacity changes that aid understanding.
- Animate transform and opacity; do not animate layout every frame.

## 9. Typography details

- Counters, durations and byte sizes that change use tabular figures (`FontFeature.tabularFigures()`); IDs, ARNs and paths use monospace (`CsBox(variant: CsBoxVariant.code)`).
- Do not invent sizes or letter spacing outside the scale.
- Format numbers and dates with the user's locale, including separators.
- Truncate only where the full value is reachable (a detail page, a tooltip, a copy button).

## 10. Copy

- Labels name the action and the object: "Launch instance", "Create bucket", "Add rule", "Delete distribution". Not "Submit", "Get started", "Learn more". Primary labels fit on one line.
- Sentence case for titles, buttons and menu items. Product names keep their capitals.
- Errors: what happened, then what to do ("The bucket name is already taken. Choose a different name."). Never blame the user; never show raw exception text.
- Empty states: why it is empty, then the action.
- Confirmation only for destructive or irreversible actions; the confirm button repeats the verb ("Delete bucket"). For high-stakes deletes, ask the user to type the resource name.
- No em dash character. Use a period, comma, colon or parentheses.
- No hype words: seamless, effortless, powerful, revolutionary, next-generation, cutting-edge, unlock, elevate, supercharge. Say the concrete effect.
- No announcements of what you are about to say, no chatty sign-offs, no "Honestly?" openers, no lists forced into threes, no all-caps emphasis.
- Name the actor: "We sent a verification email", not "A verification email has been sent".
- Re-read every visible string before delivery; replace anything clever that is unclear with a plain sentence.
- Keep the product's own voice when the user provides one.

## 11. Code and comments

- Public widgets get dartdoc: one sentence on purpose plus a short example. Parameters get docs only when the name does not say everything.
- Comments explain why (a platform quirk, a Cloudscape rule, a non-obvious constraint) in one or two lines. Never restate the code, narrate steps, add banner separators, emoji, end-of-block markers or vague TODOs.
- Build features in source. Never patch generated files or other code with scripts.
- Small composable widgets, `const` constructors, controlled inputs (`value` + `onChange`), tokens from `context.cs` over literals. Create animation controllers in `initState`.

## 12. Delivery checklist

Run before handing over any UI. Report each line as PASS or FAIL with concrete evidence. Any FAIL means fix and re-run; never deliver with a FAIL.

**Blocking**
1. No invented data, people, logos or claims; sample data labeled.
2. Every control and navigation item works or is visibly marked "Coming soon".
3. Loading, empty and error states exist for every data view, each with cause and next action.
4. Contrast checked (4.5:1 text, 3:1 large text and UI); no color-only status.
5. Targets at least 44px on touch; semantics labels, roles and states present; keyboard path works; focus ring visible.
6. No overflow or clipping at 320px wide and at 2x text; safe areas and keyboard respected; medium and expanded widths have their own layout.
7. Light and dark both render correctly.
8. Ran the app (simulator, device or web) and used every control. Evidence recorded per control, for example: "Launch instance -> success flash", "empty name -> inline error", "region select on phone -> sheet, drags, flings closed".

**Purpose**
9. Shadows, blur, gradients, badges, dots, icons and arrows each have a stated reason.
10. Motion follows section 8: press feedback, instant hover, interruptible springs, velocity handoff, no endless loops, reduced motion handled.

**Craft**
11. The direction line from section 1 was written and the screen matches it.
12. One focal point, one primary action, one accent per screen; one label per intent.
13. Cloudscape type and spacing rules held: body-m content, bold headings and labels, sentence case, related text closer, density read from the theme, no nested containers.
14. Copy passes section 10.
15. Comments pass section 11.
16. Swap the product name: the screen still feels like this product because of its content and decisions, not because of decoration.
