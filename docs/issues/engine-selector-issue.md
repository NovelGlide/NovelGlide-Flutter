# Test File Analysis: `engine_selector_test.dart`

## Overview

The test structure and intent are correct, but the file **will not compile or run as-is** due to several blocking issues. Below is a categorized breakdown.

---

## Critical Issues (Will Cause Test Failures or Compilation Errors)

### 1. `_EngineSelector` is private and inaccessible

`_EngineSelector` is prefixed with `_`, making it library-private. Since it is declared as `part of '../reader_bottom_sheet.dart'`, it cannot be imported directly into a test file.

**Fix options:**
- Extract `_EngineSelector` into its own public widget file and import it normally.
- Test it indirectly through the parent `ReaderBottomSheet` widget.

---

### 2. Missing `stream` stub on `MockReaderCubit`

`BlocBuilder` subscribes to the cubit's stream. Without stubbing it, the widget will throw a null/missing stub error during `pumpWidget`.

**Add to `setUp`:**
```dart
when(() => mockReaderCubit.stream).thenReturn(const Stream.empty());
```

---

### 3. Localization delegates are empty

```dart
localizationsDelegates: const [],
```

With no delegates, `AppLocalizations.of(context)!` will throw a null assertion error on every widget build.

**Fix:**
```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
```

Note: Text-based assertions like `find.text('Reader Engines')` are then coupled to the English locale, which is acceptable but worth being aware of.

---

### 4. Cubit methods are not stubbed for the confirm path

The confirmation flow calls `cubit.coreType = newEngine` and `cubit.savePreference()`. Without stubs, these will throw when the Confirm button is tapped.

**Add to `setUp`:**
```dart
when(() => mockReaderCubit.savePreference()).thenAnswer((_) async {});
```

Register a fallback value for the `coreType` setter if Mocktail requires it.

---

## Minor Issues

### 5. Confirm path is not tested

There is no test that taps the **Confirm** button and verifies the outcome. This is a meaningful gap since it's the primary user action.

**Missing test should verify:**
```dart
verify(() => mockReaderCubit.savePreference()).called(1);
```

And optionally that the bottom sheet is dismissed and the snackbar appears.

---

### 6. Text assertions are coupled to localization strings

Tests like:
```dart
expect(find.text('Switch to Web View?'), findsWidgets);
expect(find.text('Fast startup'), findsOneWidget);
```

These will silently break if localization strings change. Consider using widget keys or `Finder` by type for more resilient assertions where appropriate.

---

### 7. Unnecessary double mock layer for `ReaderState`

`MockReaderState` is used to stub `readerPreference`, but if `ReaderState` is a concrete class with a constructor, it can be instantiated directly — removing one layer of indirection and making the setup easier to read.

---

## What a Complete Test Suite Should Cover

| Scenario | Currently Covered |
|---|---|
| Dropdown renders | ✅ |
| Info button renders | ✅ |
| Info dialog opens | ✅ |
| Info dialog content | ✅ |
| Info dialog closes | ✅ |
| Confirmation dialog appears on engine change | ✅ |
| Cancel reverts dropdown | ✅ |
| Same engine selected — no dialog | ✅ |
| Both dropdown options visible | ✅ |
| **Confirm saves preference** | ❌ Missing |
| **Confirm closes bottom sheet** | ❌ Missing |
| **Snackbar appears after confirm** | ❌ Missing |

---

## Summary

The file has good coverage intent and a clean structure. Resolve the four critical issues first (accessibility, stream stub, localization delegates, method stubs), then add the confirm-path test to achieve meaningful end-to-end coverage of the widget's primary interaction.
```