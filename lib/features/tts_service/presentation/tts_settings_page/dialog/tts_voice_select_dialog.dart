import 'package:flutter/material.dart';

import '../../../../../enum/window_size.dart';
import '../../../../../generated/i18n/app_localizations.dart';
import '../../../domain/entities/tts_voice_data.dart';

class TtsVoiceSelectDialog extends StatelessWidget {
  const TtsVoiceSelectDialog({super.key, required this.voiceList});

  final List<TtsVoiceData> voiceList;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Dialog(
      constraints: BoxConstraints(maxWidth: WindowSize.compact.maxWidth),
      clipBehavior: Clip.hardEdge,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.ttsSettingsSelectVoice),
        ),
        body: Scrollbar(
          child: ListView.builder(
            itemCount: voiceList.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(voiceList[index].name),
                subtitle: Text(voiceList[index].getLocaleName(context)),
                onTap: () {
                  Navigator.of(context).pop(voiceList[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
