# Implementation Reference: Reader Engine Switcher UI

## Files to Modify

| File                                     | Change type           |
|------------------------------------------|-----------------------|
| `reader_preference_repository_impl.dart` | Uncomment 1 line      |
| `reader_preference_data.dart`            | Remove TODO comment   |
| `reader_cubit.dart`                      | Add `coreType` setter |
| `reader_bottom_sheet.dart`               | Add part + card       |
| `app_en.arb` (+ all locale files)        | Add i18n strings      |

## Files to Create

| File                                                 | Purpose       |
|------------------------------------------------------|---------------|
| `settings_bottom_sheet/widgets/engine_selector.dart` | New part file |

---

## 1. `reader_preference_repository_impl.dart`

Uncomment the `coreType` restore in `getPreference()`:

```dart
// BEFORE
// TODO(kai): Uncomment in future.
// coreType:
//     coreTypeIndex == null ? null : ReaderCoreType.values[coreTypeIndex],

// AFTER
coreType:
    coreTypeIndex == null ? null : ReaderCoreType.values[coreTypeIndex],
```

Also remove the TODO comment from `reader_preference_data.dart`:

```dart
// BEFORE
// TODO(kai): Change core type manually.
this.coreType = ReaderCoreType.htmlWidget,

// AFTER
this.coreType = ReaderCoreType.htmlWidget,
```

---

## 2. `reader_cubit.dart` — Add `coreType` setter

Add alongside the existing `fontSize`, `lineHeight`, `isSmoothScroll` setters
in the Settings section:

```dart
set coreType(ReaderCoreType value) {
  emit(state.copyWith(
    readerPreference: state.readerPreference.copyWith(
      coreType: value,
    ),
  ));
  savePreference();
}
```

Note: `savePreference()` is called immediately here — unlike `fontSize` which
defers to `onChangeEnd`, the engine choice should always be persisted at the
moment of confirmation.

---

## 3. `reader_bottom_sheet.dart` — Register part file and add card

Add the part declaration at the top with the other parts:

```dart
part 'widgets/engine_selector.dart';
```

Add the new card in the `Column` children, between `_PageNumSelector` card and
the reset card:

```dart
const SettingsCard(
  margin: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
  child: Column(
    children: <Widget>[
      _EngineSelector(),
    ],
  ),
),
```

---

## 4. `engine_selector.dart` — New part file

This is a `StatefulWidget` because it needs a local `_selected` state to
handle dialog cancellation without touching the cubit.

### Widget skeleton

```dart
part of '../reader_bottom_sheet.dart';

class _EngineSelector extends StatefulWidget {
  const _EngineSelector();

  @override
  State<_EngineSelector> createState() => _EngineSelectorState();
}

class _EngineSelectorState extends State<_EngineSelector> {
  // Mirrors the saved preference — used to revert on cancel.
  late ReaderCoreType _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<ReaderCubit>().state.readerPreference.coreType;
  }

  @override
  Widget build(BuildContext context) { ... }

  void _onChanged(ReaderCoreType? value) { ... }
  void _showInfoDialog(BuildContext context) { ... }
  void _showConfirmationDialog(BuildContext context, ReaderCoreType next) { ... }
  String _engineName(AppLocalizations l, ReaderCoreType type) { ... }
}
```

### `build()` method

```dart
Widget build(BuildContext context) {
  final AppLocalizations l = AppLocalizations.of(context)!;
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.readerEngineTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: l.readerEngineInfoTitle,
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          DropdownMenu<ReaderCoreType>(
            width: constraints.maxWidth,
            initialSelection: _selected,
            onSelected: _onChanged,
            dropdownMenuEntries: ReaderCoreType.values
                .map((ReaderCoreType type) => DropdownMenuEntry<ReaderCoreType>(
                      value: type,
                      label: _engineName(l, type),
                    ))
                .toList(),
          ),
        ],
      );
    },
  );
}
```

### `_onChanged()` method

```dart
void _onChanged(ReaderCoreType? value) {
  if (value == null) return;
  final ReaderCoreType saved =
      context.read<ReaderCubit>().state.readerPreference.coreType;
  // If the user picked the same engine that is already saved, do nothing.
  if (value == saved) return;

  // Reflect the selection immediately in the dropdown.
  setState(() => _selected = value);
  // Then ask for confirmation.
  _showConfirmationDialog(context, value);
}
```

### `_showInfoDialog()` method

```dart
void _showInfoDialog(BuildContext context) {
  final AppLocalizations l = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l.readerEngineInfoTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _EngineInfoSection(
              name: l.readerEngineHtmlWidget,
              pros: <String>[
                l.readerEngineHtmlWidgetPro1,
                l.readerEngineHtmlWidgetPro2,
                l.readerEngineHtmlWidgetPro3,
              ],
              cons: <String>[
                l.readerEngineHtmlWidgetCon1,
                l.readerEngineHtmlWidgetCon2,
              ],
            ),
            const SizedBox(height: 16.0),
            _EngineInfoSection(
              name: l.readerEngineWebView,
              pros: <String>[
                l.readerEngineWebViewPro1,
                l.readerEngineWebViewPro2,
                l.readerEngineWebViewPro3,
              ],
              cons: <String>[
                l.readerEngineWebViewCon1,
                l.readerEngineWebViewCon2,
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.readerEngineInfoOk),
        ),
      ],
    ),
  );
}
```

### `_showConfirmationDialog()` method

```dart
void _showConfirmationDialog(BuildContext context, ReaderCoreType next) {
  final AppLocalizations l = AppLocalizations.of(context)!;
  // Capture references before async gaps.
  final ReaderCubit cubit = context.read<ReaderCubit>();
  final NavigatorState navigator = Navigator.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final ReaderCoreType saved = cubit.state.readerPreference.coreType;

  showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l.readerEngineSwitchTitle),
      content: Text(
        l.readerEngineSwitchContent(_engineName(l, next)),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.readerEngineSwitchCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.readerEngineSwitchConfirm),
        ),
      ],
    ),
  ).then((bool? confirmed) {
    if (confirmed == true) {
      cubit.coreType = next;
      // Dismiss the bottom sheet.
      navigator.pop();
      // Show snackbar on the reader page.
      messenger.showSnackBar(
        SnackBar(content: Text(l.readerEngineChangedSnackbar)),
      );
    } else {
      // Revert the dropdown to the previously saved engine.
      setState(() => _selected = saved);
    }
  });
}
```

### `_engineName()` helper

```dart
String _engineName(AppLocalizations l, ReaderCoreType type) {
  return switch (type) {
    ReaderCoreType.htmlWidget => l.readerEngineHtmlWidget,
    ReaderCoreType.webView    => l.readerEngineWebView,
  };
}
```

### `_EngineInfoSection` private widget

A small private widget used inside the info dialog to render one engine's
pros and cons. Keep it in the same part file.

```dart
class _EngineInfoSection extends StatelessWidget {
  const _EngineInfoSection({
    required this.name,
    required this.pros,
    required this.cons,
  });

  final String name;
  final List<String> pros;
  final List<String> cons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(name,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4.0),
        ...pros.map((String p) => _ProConRow(text: p, isPro: true)),
        ...cons.map((String c) => _ProConRow(text: c, isPro: false)),
      ],
    );
  }
}

class _ProConRow extends StatelessWidget {
  const _ProConRow({required this.text, required this.isPro});

  final String text;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          isPro ? Icons.check_rounded : Icons.close_rounded,
          size: 16.0,
          color: isPro
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 6.0),
        Expanded(child: Text(text)),
      ],
    );
  }
}
```

---

## 5. i18n — `app_en.arb`

Add the following entries. The `{engine}` placeholder in
`readerEngineSwitchContent` uses ARB's named placeholder syntax:

```json
"readerEngineTitle": "Reader Engine",
"readerEngineInfoTitle": "Reader Engines",
"readerEngineInfoOk": "OK",
"readerEngineWebView": "Web View",
"readerEngineHtmlWidget": "Flutter Native",
"readerEngineSwitchTitle": "Restart Required",
"readerEngineSwitchContent": "Switch to {engine}? The change will take effect the next time you open this book.",
"@readerEngineSwitchContent": {
  "placeholders": {
    "engine": { "type": "String" }
  }
},
"readerEngineSwitchCancel": "Cancel",
"readerEngineSwitchConfirm": "Switch",
"readerEngineChangedSnackbar": "Changes will apply on next open",
"readerEngineHtmlWidgetPro1": "Fast startup",
"readerEngineHtmlWidgetPro2": "Lower memory usage",
"readerEngineHtmlWidgetPro3": "Scroll-based navigation",
"readerEngineHtmlWidgetCon1": "No page-based pagination",
"readerEngineHtmlWidgetCon2": "Limited publisher CSS support",
"readerEngineWebViewPro1": "Full publisher CSS support",
"readerEngineWebViewPro2": "Page-based navigation",
"readerEngineWebViewPro3": "Smooth scroll & RTL support",
"readerEngineWebViewCon1": "Slower startup",
"readerEngineWebViewCon2": "Higher memory usage"
```

Mirror all keys into every other `.arb` locale file
(`app_ja.arb`, `app_zh.arb`, etc.) with translated values.

---

## Key Decisions & Rationale

**Why `StatefulWidget` for `_EngineSelector`?**
The dropdown must be able to visually revert if the user cancels the
confirmation dialog. Storing `_selected` locally in widget state — separate
from the cubit's saved preference — is the cleanest way to achieve this
without adding temporary state to the cubit.

**Why capture `navigator`, `messenger`, and `cubit` before the async gap?**
After `await showDialog(...)`, the widget may have been disposed. Capturing
these references before the `then()` callback avoids `use_build_context_synchronously`
lint warnings and potential null-context crashes.

**Why dismiss the bottom sheet after confirming?**
The `_SmoothScrollSwitch` visibility depends on the active engine
(`state.coreType`), not the saved preference. Since the active engine won't
change until the book is reopened, the bottom sheet could show stale/misleading
conditional settings if left open. Closing it is the safest UX.

**Why not reset `coreType` during preference reset?**
The existing `resetPreference()` already deliberately skips resetting
`coreType` (see the commented-out line in `reader_preference_repository_impl.dart`).
This is intentional — engine choice is a device capability preference, not a
reading style preference, and should survive a settings reset.