import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/entities/reader_set_state_data.dart';
import '../data_transfer_objects/reader_web_message_dto.dart';

abstract class ReaderWebViewDataSource {
  Future<void> loadPage(Uri uri);

  void send(ReaderWebMessageDto message);

  void setChannel();

  Stream<String> get onSaveLocation;

  Stream<ReaderSetStateData> get onSetState;

  Stream<String> get onPlayTts;

  Stream<void> get onStopTts;

  Stream<void> get onEndTts;

  Stream<List<ReaderSearchResultData>> get onSetSearchResultList;

  Future<void> dispose();
}
