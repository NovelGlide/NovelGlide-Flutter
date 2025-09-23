import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../data_transfer_objects/reader_web_message_dto.dart';

abstract class ReaderWebViewDataSource {
  WebViewController get webViewController;

  void send(ReaderWebMessageDto message);

  void setChannel();

  Stream<void> get onLoadDone;

  Stream<String> get onSaveLocation;

  Stream<ReaderSetStateData> get onSetState;

  Stream<String> get onPlayTts;

  Stream<void> get onStopTts;

  Stream<void> get onEndTts;

  Stream<List<ReaderSearchResultData>> get onSetSearchResultList;

  Future<void> dispose();
}
