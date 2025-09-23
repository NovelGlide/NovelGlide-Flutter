import 'package:flutter/material.dart';

import '../../../shared_components/common_delete_dialog.dart';
import '../../../shared_components/common_loading_widgets/common_loading_dialog.dart';
import '../../../shared_components/common_success_dialog.dart';

class SettingsPageListTile extends StatelessWidget {
  const SettingsPageListTile({
    super.key,
    required this.title,
    required this.iconData,
    this.deleteLabel,
    this.isDangerous = true,
    this.onAccept,
    this.onComplete,
  });

  final String title;
  final IconData iconData;
  final String? deleteLabel;
  final bool isDangerous;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onComplete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () {
        if (isDangerous) {
          showDialog(
            context: context,
            builder: (_) => CommonDeleteDialog(
              title: title,
              deleteIcon: iconData,
              deleteLabel: deleteLabel,
              onAccept: () => _performDeletion(context),
            ),
          );
        } else {
          _performDeletion(context);
        }
      },
      leading: Icon(iconData),
      title: Text(title),
    );
  }

  Future<void> _performDeletion(BuildContext context) async {
    // Show loading dialog.
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Notify the user accept the process.
        onAccept?.call().then((_) {
          // Process end. Close the loading dialog.
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return const CommonLoadingDialog();
      },
    );

    // Process completed.
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => const CommonSuccessDialog(),
      );
    }

    // Notify the process is completed.
    onComplete?.call();
  }
}
