import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/log_system/log_system.dart';
import '../../../domain/entities/reader_search_result_data.dart';
import '../../../domain/entities/reader_set_state_data.dart';
import '../../data_transfer_objects/reader_web_message_dto.dart';
import '../reader_webview_data_source.dart';

class ReaderWebViewDataSourceImpl implements ReaderWebViewDataSource {
  factory ReaderWebViewDataSourceImpl(WebViewController controller) {
    final ReaderWebViewDataSourceImpl instance =
        ReaderWebViewDataSourceImpl._(controller);

    controller.enableZoom(false);
    controller.setBackgroundColor(Colors.transparent);
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.addJavaScriptChannel(
      _channelName,
      onMessageReceived: instance._receive,
    );

    return instance;
  }

  ReaderWebViewDataSourceImpl._(this._controller);

  static const String _channelName = 'appApi';

  final WebViewController _controller;

  /// ========== Messages Stream Controllers ==========
  final StreamController<void> _loadDoneStreamController =
      StreamController<void>.broadcast();
  final StreamController<String> _saveLocationStreamController =
      StreamController<String>.broadcast();
  final StreamController<ReaderSetStateData> _setStateStreamController =
      StreamController<ReaderSetStateData>.broadcast();
  final StreamController<String> _ttsPlayStreamController =
      StreamController<String>.broadcast();
  final StreamController<void> _ttsStopStreamController =
      StreamController<void>.broadcast();
  final StreamController<void> _ttsEndStreamController =
      StreamController<void>.broadcast();
  final StreamController<List<ReaderSearchResultData>>
      _searchResultStreamController =
      StreamController<List<ReaderSearchResultData>>.broadcast();

  void _receive(JavaScriptMessage message) {
    final Map<String, dynamic> data = jsonDecode(message.message);

    if (data['route'] is String) {
      LogSystem.info("Reader: Receive - ${data['route']} ${data['data']}");

      final ReaderWebMessageDto message = ReaderWebMessageDto(
        route: data['route'],
        data: data['data'],
      );

      // Dispatch messages
      switch (message.route) {
        case 'loadDone':
          _loadDoneStreamController.add(null);
          break;

        case 'saveLocation':
          if (message.data is String) {
            _saveLocationStreamController.add(message.data);
          }
          break;

        case 'setState':
          if (message.data is Map<String, dynamic>) {
            _setStateStreamController.add(ReaderSetStateData(
              breadcrumb: message.data['breadcrumb'],
              chapterIdentifier: message.data['chapterIdentifier'],
              startCfi: message.data['startCfi'],
              chapterCurrentPage: message.data['chapterCurrentPage'],
              chapterTotalPage: message.data['chapterTotalPage'],
              htmlContent: null,
            ));
          }
          break;

        case 'ttsPlay':
          if (message.data is String) {
            _ttsPlayStreamController.add(message.data);
          }
          break;

        case 'ttsStop':
          _ttsStopStreamController.add(null);
          break;

        case 'ttsEnd':
          _ttsEndStreamController.add(null);
          break;

        case 'setSearchResultList':
          if (message.data is Map<String, dynamic>) {
            _searchResultStreamController.add(
              (message.data['searchResultList'] as List<dynamic>)
                  .map<ReaderSearchResultData>(
                      (dynamic e) => ReaderSearchResultData(
                            cfi: e['cfi'],
                            excerpt: e['excerpt'],
                          ))
                  .toList(),
            );
          }
          break;
      }
    }
  }

  @override
  void send(ReaderWebMessageDto message) {
    _controller.runJavaScript(
        'window.communicationService.receive("${message.route}", '
        '${message.data != null ? jsonEncode(message.data) : 'undefined'})');
  }

  @override
  void setChannel() {
    _controller.runJavaScript(
        'window.communicationService.setChannel(window.$_channelName)');
  }

  @override
  Stream<void> get onLoadDone => _loadDoneStreamController.stream;

  @override
  Stream<String> get onSaveLocation => _saveLocationStreamController.stream;

  @override
  Stream<ReaderSetStateData> get onSetState => _setStateStreamController.stream;

  @override
  Stream<String> get onPlayTts => _ttsPlayStreamController.stream;

  @override
  Stream<void> get onStopTts => _ttsStopStreamController.stream;

  @override
  Stream<void> get onEndTts => _ttsEndStreamController.stream;

  @override
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList =>
      _searchResultStreamController.stream;

  @override
  Future<void> dispose() async {
    await _loadDoneStreamController.close();
    await _saveLocationStreamController.close();
    await _setStateStreamController.close();
    await _ttsPlayStreamController.close();
    await _ttsStopStreamController.close();
    await _ttsEndStreamController.close();
    await _searchResultStreamController.close();
  }
}
