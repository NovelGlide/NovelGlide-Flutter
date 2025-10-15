import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import '../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../enum/window_size.dart';
import '../../features/shared_components/common_delete_dialog.dart';
import '../../features/shared_components/common_success_dialog.dart';
import '../../main.dart';
import '../shared_components/animated_switchers/simple_fade_switcher.dart';
import '../shared_components/common_error_widgets/common_error_dialog.dart';
import '../shared_components/common_error_widgets/common_error_widget.dart';
import '../shared_components/common_loading_widgets/common_loading_dialog.dart';

part 'cards/card_template.dart';
part 'cards/device_info_card.dart';
part 'cards/dialog_card.dart';
part 'cards/file_path_card.dart';
part 'cards/firebase_card.dart';
part 'dialog/backup_progress_dialog.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Page'),
      ),
      body: SafeArea(
        child: ListView(
          children: const <Widget>[
            _DeviceInfoCard(),
            _FilePathCard(),
            _DialogCard(),
            _FirebaseCard(),
          ],
        ),
      ),
    );
  }
}
