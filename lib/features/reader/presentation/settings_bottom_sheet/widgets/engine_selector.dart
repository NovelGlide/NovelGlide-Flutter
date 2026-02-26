part of '../reader_bottom_sheet.dart';

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

  void _onEngineChanged(ReaderCoreType? value) {
    if (value == null) return;
    if (value ==
        context.read<ReaderCubit>().state.readerPreference.coreType) {
      return; // Same value, do nothing
    }

    setState(() => _selected = value);
    _showConfirmationDialog(value);
  }

  void _showConfirmationDialog(ReaderCoreType newEngine) {
    final l10n = AppLocalizations.of(context)!;
    final engineName = newEngine == ReaderCoreType.webView
        ? l10n.readerEngineWebView
        : l10n.readerEngineHtmlWidget;

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.readerEngineSwitchTitle),
        content: Text(
          l10n.readerEngineSwitchContent(engine: engineName),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selected =
                  context.read<ReaderCubit>().state.readerPreference.coreType);
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
    ).then((confirmed) {
      if (confirmed != true) {
        setState(() => _selected =
            context.read<ReaderCubit>().state.readerPreference.coreType);
      }
    });
  }

  void _saveEnginePreference(ReaderCoreType newEngine) {
    final cubit = context.read<ReaderCubit>();

    // Update the preference
    cubit.emit(cubit.state.copyWith(
      readerPreference:
          cubit.state.readerPreference.copyWith(coreType: newEngine),
    ));

    // Save to storage
    cubit.savePreference();

    // Close bottom sheet
    Navigator.pop(context);

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.readerEngineChangedSnackbar),
        ),
      );
    }
  }

  void _showInfoDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.readerEngineInfoTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _EngineInfoSection(
                title: l10n.readerEngineHtmlWidget,
                pros: [
                  l10n.readerEngineHtmlWidgetPro1,
                  l10n.readerEngineHtmlWidgetPro2,
                  l10n.readerEngineHtmlWidgetPro3,
                ],
                cons: [
                  l10n.readerEngineHtmlWidgetCon1,
                  l10n.readerEngineHtmlWidgetCon2,
                ],
              ),
              const SizedBox(height: 16),
              _EngineInfoSection(
                title: l10n.readerEngineWebView,
                pros: [
                  l10n.readerEngineWebViewPro1,
                  l10n.readerEngineWebViewPro2,
                  l10n.readerEngineWebViewPro3,
                ],
                cons: [
                  l10n.readerEngineWebViewCon1,
                  l10n.readerEngineWebViewCon2,
                ],
              ),
            ],
          ),
        ),
        actions: [
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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
          dropdownMenuEntries: [
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

class _EngineInfoSection extends StatelessWidget {
  final String title;
  final List<String> pros;
  final List<String> cons;

  const _EngineInfoSection({
    required this.title,
    required this.pros,
    required this.cons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...pros.map((pro) => _buildItem(context, pro, true)),
        ...cons.map((con) => _buildItem(context, con, false)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, String text, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPro ? '✓' : '✗'),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
