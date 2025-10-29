import 'package:flutter/material.dart';

import '../../../animated_placeholders/ease_flash_placeholder.dart';
import '../../shared_list.dart';

class SharedListItemPlaceholder extends StatelessWidget {
  const SharedListItemPlaceholder({
    super.key,
    required this.listType,
  });

  final SharedListType listType;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: switch (listType) {
        SharedListType.grid => const EdgeInsets.all(16.0),
        SharedListType.list => const EdgeInsets.all(4.0),
      },
      width: double.infinity,
      height: switch (listType) {
        SharedListType.grid => double.infinity,
        SharedListType.list => 48.0,
      },
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
      ),
      clipBehavior: Clip.hardEdge,
      child: const EaseFlashPlaceholder(),
    );
  }
}
