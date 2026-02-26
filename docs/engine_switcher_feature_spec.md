# Feature Spec: Reader Engine Switcher UI

## Overview

Allow users to switch between the two reader engines (Flutter Native / Web View)
from within the reader settings bottom sheet. The change is persisted and takes
effect the next time the user opens a book.

---

## User Stories

**As a user**, I want to know what each engine offers before choosing one, so
that I can make an informed decision.

**As a user**, I want to switch the reader engine from within the reader
settings, so that I don't have to leave the reading experience to change it.

**As a user**, I want to be told that the change takes effect on next open, so
that I'm not confused when nothing changes immediately.

---

## Engines

| Engine         | Enum value                  | Display name   |
|----------------|-----------------------------|----------------|
| Flutter Native | `ReaderCoreType.htmlWidget` | Flutter Native |
| Web View       | `ReaderCoreType.webView`    | Web View       |

---

## UI Entry Point

The engine selector is placed in `ReaderBottomSheet` as a new `SettingsCard`,
positioned **between the page number card and the reset button card**.

```
┌─────────────────────────────┐
│  Font Size / Line Height    │  ← existing card
├─────────────────────────────┤
│  Auto Save / Smooth Scroll  │  ← existing card
├─────────────────────────────┤
│  Page Number                │  ← existing card
├─────────────────────────────┤
│  Reader Engine          (i) │  ← NEW card
│  [ Flutter Native       ▾ ] │
├─────────────────────────────┤
│                      Reset  │  ← existing card
└─────────────────────────────┘
```

---

## Components

### 1. Engine Selector Card (`_EngineSelector`)

- A `SettingsCard` containing:
    - A header `Row` with the label "Reader Engine" on the left and an `(i)`
      `IconButton` on the right.
    - A `DropdownMenu<ReaderCoreType>` spanning full width, showing the currently
      saved engine.
- The widget must be `StatefulWidget` to hold a local `_selected` value
  separately from the saved preference. This allows reverting the dropdown
  visually if the user cancels the confirmation dialog.

**State management:**
- On build, initialise `_selected` from `state.readerPreference.coreType`.
- On dropdown selection of a *different* value:
    1. Update `_selected` locally to reflect the new choice immediately in the UI.
    2. Show the **Confirmation Dialog**.
    3. If confirmed → call cubit setter + `savePreference()` + dismiss bottom
       sheet + show snackbar.
    4. If cancelled → revert `_selected` back to the saved value.
- If the user selects the *same* value that is already saved, do nothing.

---

### 2. Info Dialog

**Trigger:** Tapping the `(i)` icon button.

**Type:** `AlertDialog`

**Title:** "Reader Engines"

**Content layout:**

```
Flutter Native
  ✓ Fast startup
  ✓ Lower memory usage
  ✓ Scroll-based navigation
  ✗ No page-based pagination
  ✗ Limited publisher CSS support

Web View
  ✓ Full publisher CSS support
  ✓ Page-based navigation
  ✓ Smooth scroll & RTL support
  ✗ Slower startup
  ✗ Higher memory usage
```

**Actions:** Single "OK" button — dismiss only, no side effects.

---

### 3. Confirmation Dialog

**Trigger:** User selects a *different* engine from the dropdown.

**Type:** `AlertDialog`

**Title:** "Restart Required"

**Content:** "Switch to {engine}? The change will take effect the next time you
open this book."

`{engine}` is substituted with the display name of the newly selected engine
(e.g. "Flutter Native" or "Web View").

**Actions:**

| Button | Style | Behaviour |
|---|---|---|
| Cancel | text | Revert `_selected` to saved value, dismiss dialog |
| Switch | filled / primary | Save preference, dismiss bottom sheet, show snackbar |

**Snackbar:** "Changes will apply on next open" — shown on the reader page
after the bottom sheet is dismissed.

---

## Conditional Behaviour

The `_SmoothScrollSwitch` is already conditionally shown only for `webView`.
No change needed there — it continues to work as-is.

After a switch is saved but before the book is reopened, `state.coreType`
still reflects the *active* engine, while `state.readerPreference.coreType`
reflects the *saved* engine. The UI should use `state.readerPreference.coreType`
to drive the dropdown display, not `state.coreType`.

---

## i18n Strings (`app_en.arb`)

```
readerEngineTitle             → "Reader Engine"
readerEngineInfoTitle         → "Reader Engines"
readerEngineInfoOk            → "OK"
readerEngineWebView           → "Web View"
readerEngineHtmlWidget        → "Flutter Native"

readerEngineSwitchTitle       → "Restart Required"
readerEngineSwitchContent     → "Switch to {engine}? The change will take effect the next time you open this book."
readerEngineSwitchCancel      → "Cancel"
readerEngineSwitchConfirm     → "Switch"
readerEngineChangedSnackbar   → "Changes will apply on next open"

readerEngineHtmlWidgetPro1    → "Fast startup"
readerEngineHtmlWidgetPro2    → "Lower memory usage"
readerEngineHtmlWidgetPro3    → "Scroll-based navigation"
readerEngineHtmlWidgetCon1    → "No page-based pagination"
readerEngineHtmlWidgetCon2    → "Limited publisher CSS support"

readerEngineWebViewPro1       → "Full publisher CSS support"
readerEngineWebViewPro2       → "Page-based navigation"
readerEngineWebViewPro3       → "Smooth scroll & RTL support"
readerEngineWebViewCon1       → "Slower startup"
readerEngineWebViewCon2       → "Higher memory usage"
```

All strings must be mirrored in every other `.arb` locale file.

---

## Out of Scope

- Immediate engine hot-swap without reopening the book.
- Per-book engine preference (global only).
- Engine auto-selection based on EPUB complexity.