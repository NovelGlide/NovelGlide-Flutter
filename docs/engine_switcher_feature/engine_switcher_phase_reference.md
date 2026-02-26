# Phases Plan: Reader Engine Switcher UI

## Overview

3 phases. Each phase is independently shippable and testable.
Total estimated scope: small — no new architecture, no new dependencies.

---

## Phase 1 — Unlock the Preference

**Goal:** Make the engine preference actually persist and restore between
sessions. No UI change yet. After this phase, the engine can be switched
by changing the default value in `reader_preference_data.dart` and verifying
it survives app restarts.

### Tasks

- [ ] In `reader_preference_repository_impl.dart`, uncomment the `coreType`
restore line in `getPreference()`
- [ ] Remove the `TODO(kai): Change core type manually.` comment from
`reader_preference_data.dart` (the default value stays as `htmlWidget`)
- [ ] Manually test: change the default to `webView`, hot restart, confirm
the WebView engine loads; change back, confirm Native loads

### Acceptance criteria

- Engine preference survives app restart
- No regression in existing preference restore (font size, line height, etc.)

### Risk

Low. This is a single uncommented line. `readerCoreType` is already being
written to storage in `savePreference()` — only the read side was disabled.

---

## Phase 2 — Cubit Setter + i18n Strings

**Goal:** Wire up the cubit so it can accept an engine change, and add all
the i18n strings so the UI work in Phase 3 has no string dependencies to
resolve mid-implementation.

### Tasks

- [ ] Add `set coreType(ReaderCoreType value)` setter to `ReaderCubit`
(see Implementation Reference §2)
- [ ] Add all 21 new strings to `app_en.arb`
(see Implementation Reference §5)
- [ ] Add translated equivalents to all other `.arb` locale files
(`app_ja.arb`, `app_zh.arb`, `app_zh_Hant_TW.arb`, etc.)
- [ ] Run `flutter gen-l10n` and confirm `AppLocalizations` generates cleanly
with the new `{engine}` placeholder

### Acceptance criteria

- `cubit.coreType = ReaderCoreType.webView` saves the preference and emits
a new state
- All locale files compile without missing-key warnings
- `l.readerEngineSwitchContent('Web View')` returns the expected string

### Risk

Low. The setter pattern is identical to `isSmoothScroll`. The only new
complexity is the ARB placeholder syntax for `{engine}` — verify it generates
correctly before proceeding to Phase 3.

---

## Phase 3 — UI Widgets

**Goal:** Build and integrate the full engine selector card with both dialogs.

### Tasks

#### 3a — Engine Selector Card (no dialogs yet)

- [ ] Create `engine_selector.dart` as a part file
- [ ] Implement `_EngineSelector` as a `StatefulWidget` with local `_selected`
- [ ] Implement `build()` with the header row (label + info icon button stub)
and the `DropdownMenu`
- [ ] Register the part in `reader_bottom_sheet.dart`
- [ ] Add the `SettingsCard` wrapping `_EngineSelector` between the page
number card and the reset card
- [ ] Verify: dropdown shows current engine, selecting a value updates `_selected`
locally (no save yet)

#### 3b — Info Dialog

- [ ] Implement `_EngineInfoSection` and `_ProConRow` private widgets
- [ ] Implement `_showInfoDialog()` using `AlertDialog`
- [ ] Wire the `(i)` icon button to `_showInfoDialog()`
- [ ] Verify: info dialog opens, shows correct pros/cons for both engines,
OK dismisses it with no side effects

#### 3c — Confirmation Dialog + Save Flow

- [ ] Implement `_showConfirmationDialog()` with Cancel / Switch actions
- [ ] Wire `_onChanged()` to call `_showConfirmationDialog()` only when a
*different* engine is selected
- [ ] On confirm: call `cubit.coreType = next`, pop bottom sheet, show snackbar
- [ ] On cancel: revert `_selected` to the saved value
- [ ] Verify the full flow end-to-end (see test scenarios below)

### Acceptance criteria

All test scenarios below pass.

---

## Test Scenarios

### Info dialog

| # | Action             | Expected                                                      |
|---|--------------------|---------------------------------------------------------------|
| 1 | Tap `(i)`          | Info dialog appears with Flutter Native and Web View sections |
| 2 | Tap OK             | Dialog dismisses, no preference change                        |
| 3 | Tap outside dialog | Dialog dismisses (barrier dismissible), no preference change  |

### Confirmation dialog — confirm path

| # | Action                    | Expected                                                                 |
|---|---------------------------|--------------------------------------------------------------------------|
| 4 | Select a different engine | `_selected` updates immediately in dropdown, confirmation dialog appears |
| 5 | Tap Switch                | Dialog dismisses, bottom sheet dismisses, snackbar appears               |
| 6 | Reopen bottom sheet       | Dropdown shows the newly selected engine                                 |
| 7 | Close and reopen book     | New engine is active                                                     |

### Confirmation dialog — cancel path

| #  | Action                                | Expected                                 |
|----|---------------------------------------|------------------------------------------|
| 8  | Select a different engine, tap Cancel | Dropdown reverts to previous engine      |
| 9  | Reopen bottom sheet after cancel      | Dropdown still shows the original engine |
| 10 | Close and reopen book after cancel    | Original engine is still active          |

### No-op path

| #  | Action                                  | Expected                           |
|----|-----------------------------------------|------------------------------------|
| 11 | Select the engine that is already saved | No dialog appears, no state change |

### Preference reset

| #  | Action                                    | Expected                                                      |
|----|-------------------------------------------|---------------------------------------------------------------|
| 12 | Switch engine, then reset reader settings | Engine preference is NOT reset (existing behaviour preserved) |

---

## Definition of Done

- [ ] All 3 phases complete
- [ ] All 12 test scenarios pass manually on Android and iOS
- [ ] No `use_build_context_synchronously` lint warnings
- [ ] All locale files updated
- [ ] `flutter gen-l10n` produces no errors or warnings
- [ ] Both TODO comments removed from the codebase