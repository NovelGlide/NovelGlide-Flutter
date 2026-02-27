part of '../reader_bottom_sheet.dart';

/// Widget that allows users to switch between Flutter Native and Web View
/// reader engines from the reader settings bottom sheet.
///
/// Displays engine options in a dropdown with an info button that shows
/// pros/cons for each engine. Changes require confirmation and take effect
/// on next book open.
class _EngineSelector extends StatefulWidget {
  const _EngineSelector({Key? key}) : super(key: key);

  @override
  State<_EngineSelector> createState() => _EngineSelectorState();
}

class _EngineSelectorState extends State<_EngineSelector> {
  late ReaderCoreType _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<ReaderCubit>().state.readerPreference.coreType;
  }

  @override
  void didUpdateWidget(covariant _EngineSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = context.read<ReaderCubit>().state.readerPreference.coreType;
  }

  /// Handles engine selection from the dropdown menu.
  ///
  /// If the selected engine is different from the saved one, shows a
  /// confirmation dialog. Updates the local [_selected] state and calls
  /// [_showConfirmationDialog] if needed.
  void _onEngineChanged(ReaderCoreType? value) {
    if (value == null) {
      return;
    }

    final ReaderCoreType savedEngine =
        context.read<ReaderCubit>().state.readerPreference.coreType;
    if (value == savedEngine) {
      return; // Same value, do nothing
    }

    setState(() => _selected = value);
    _showConfirmationDialog(value);
  }

  /// Shows a confirmation dialog before switching engines.
  ///
  /// Displays the engine name and prompts the user to confirm the switch.
  /// On confirmation, saves the preference and closes the bottom sheet.
  /// On cancellation, reverts the [_selected] state visually.
  void _showConfirmationDialog(ReaderCoreType newEngine) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String engineName = newEngine == ReaderCoreType.webView
        ? l10n.readerEngineWebView
        : l10n.readerEngineHtmlWidget;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.readerEngineSwitchTitle),
        content: Text(
          l10n.readerEngineSwitchContent(engineName),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final ReaderCoreType savedEngine =
                  context.read<ReaderCubit>().state.readerPreference.coreType;
              setState(() => _selected = savedEngine);
              Navigator.pop(context, false);
            },
            child: Text(l10n.readerEngineSwitchCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
              _saveEnginePreference(newEngine);
            },
            child: Text(l10n.readerEngineSwitchConfirm),
          ),
        ],
      ),
    ).then((bool? confirmed) {
      if (confirmed != true) {
        final ReaderCoreType savedEngine =
            context.read<ReaderCubit>().state.readerPreference.coreType;
        setState(() => _selected = savedEngine);
      }
    });
  }

  /// Saves the new engine preference and shows a snackbar notification.
  ///
  /// Updates the cubit state with the new engine, persists to storage,
  /// closes the bottom sheet, and displays a confirmation snackbar.
  void _saveEnginePreference(ReaderCoreType newEngine) {
    final ReaderCubit cubit = context.read<ReaderCubit>();

    // Update the preference using the cubit setter
    cubit.coreType = newEngine;

    // Save to storage
    cubit.savePreference();

    // Close bottom sheet
    Navigator.pop(context);

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.readerEngineChangedSnackbar),
        ),
      );
    }
  }

  /// Shows an info dialog with pros and cons for both reader engines.
  ///
  /// Displays detailed information about Flutter Native and Web View engines
  /// to help users make an informed decision about which engine to use.
  void _showInfoDialog() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.readerEngineInfoTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _EngineInfoSection(
                title: l10n.readerEngineHtmlWidget,
                pros: <String>[
                  l10n.readerEngineHtmlWidgetPro1,
                  l10n.readerEngineHtmlWidgetPro2,
                  l10n.readerEngineHtmlWidgetPro3,
                ],
                cons: <String>[
                  l10n.readerEngineHtmlWidgetCon1,
                  l10n.readerEngineHtmlWidgetCon2,
                ],
              ),
              const SizedBox(height: 16),
              _EngineInfoSection(
                title: l10n.readerEngineWebView,
                pros: <String>[
                  l10n.readerEngineWebViewPro1,
                  l10n.readerEngineWebViewPro2,
                  l10n.readerEngineWebViewPro3,
                ],
                cons: <String>[
                  l10n.readerEngineWebViewCon1,
                  l10n.readerEngineWebViewCon2,
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.readerEngineInfoOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(l10n.readerEngineTitle),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: l10n.readerEngineInfoTitle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownMenu<ReaderCoreType>(
          initialSelection: _selected,
          onSelected: _onEngineChanged,
          dropdownMenuEntries: <DropdownMenuEntry<ReaderCoreType>>[
            DropdownMenuEntry(
              value: ReaderCoreType.htmlWidget,
              label: l10n.readerEngineHtmlWidget,
            ),
            DropdownMenuEntry(
              value: ReaderCoreType.webView,
              label: l10n.readerEngineWebView,
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget that displays the pros and cons of a single reader engine.
///
/// Used in the info dialog to show comparisons between Flutter Native
/// and Web View engines.
class _EngineInfoSection extends StatelessWidget {
  /// Creates a new engine info section.
  const _EngineInfoSection({
    required this.title,
    required this.pros,
    required this.cons,
  });

  /// The name of the engine (e.g. "Flutter Native" or "Web View").
  final String title;

  /// List of advantages for this engine.
  final List<String> pros;

  /// List of disadvantages for this engine.
  final List<String> cons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...pros.map((String pro) => _buildItem(context, pro, true)),
        ...cons.map((String con) => _buildItem(context, con, false)),
      ],
    );
  }

  /// Builds a single pro/con item with a checkmark or X icon.
  ///
  /// Displays [text] with a leading checkmark (✓) if [isPro] is true,
  /// or an X mark (✗) if [isPro] is false.
  Widget _buildItem(
    BuildContext context,
    String text,
    bool isPro,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(isPro ? '✓' : '✗'),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
