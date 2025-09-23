import 'dart:async';

import 'package:flutter/material.dart';
import 'package:novel_glide/features/reader/domain/entities/reader_set_state_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/color_extension.dart';
import '../../domain/entities/reader_search_result_data.dart';
import '../../domain/repositories/reader_location_cache_repository.dart';
import '../../domain/repositories/reader_server_repository.dart';
import '../../domain/repositories/reader_webview_repository.dart';
import '../data_sources/reader_webview_data_source.dart';
import '../data_transfer_objects/reader_web_message_dto.dart';

class ReaderWebViewRepositoryImpl implements ReaderWebViewRepository {
  ReaderWebViewRepositoryImpl(
    this._dataSource,
    this._serverRepository,
    this._cacheRepository,
  );

  final ReaderWebViewDataSource _dataSource;
  final ReaderServerRepository _serverRepository;
  final ReaderLocationCacheRepository _cacheRepository;

  late final String _bookIdentifier;

  /// Message Subscriptions
  late final Set<StreamSubscription<dynamic>> _subscriptionSet =
      <StreamSubscription<dynamic>>{
    // Load done.
    _dataSource.onLoadDone.listen((void _) async {
      // Stop the local web server.
      await _serverRepository.stop();
    }),

    // Save location.
    _dataSource.onSaveLocation.listen((String location) async {
      await _cacheRepository.store(_bookIdentifier, location);
    }),
  };

  @override
  WebViewController get webViewController => _dataSource.webViewController;

  @override
  Future<void> startLoading({
    required String bookIdentifier,
    String? destination,
  }) async {
    _bookIdentifier = bookIdentifier;

    // Start up the local server
    final Uri serverUri = await _serverRepository.start(bookIdentifier);

    // Setup the navigation delegate.
    webViewController.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (String url) async {
        _dataSource.setChannel();
        _dataSource.send(ReaderWebMessageDto(
          route: 'main',
          data: <String, String?>{
            'destination': destination,
            'savedLocation': await _cacheRepository.get(bookIdentifier),
          },
        ));
      },
      onNavigationRequest: (NavigationRequest request) {
        final bool isUrlAllowed = <String>[
          serverUri.toString(),
          'about:srcdoc',
        ].any((String url) => request.url.startsWith(url));
        return isUrlAllowed
            ? NavigationDecision.navigate
            : NavigationDecision.prevent;
      },
    ));

    // Load the page.
    webViewController.loadRequest(serverUri);
  }

  @override
  void goto(String destination) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'goto',
      data: destination,
    ));
  }

  @override
  void nextPage() {
    _dataSource.send(const ReaderWebMessageDto(route: 'nextPage'));
  }

  @override
  void previousPage() {
    _dataSource.send(const ReaderWebMessageDto(route: 'prevPage'));
  }

  @override
  void ttsPlay() {
    _dataSource.send(const ReaderWebMessageDto(route: 'ttsPlay'));
  }

  @override
  void ttsNext() {
    _dataSource.send(const ReaderWebMessageDto(route: 'ttsNext'));
  }

  @override
  void ttsStop() {
    _dataSource.send(const ReaderWebMessageDto(route: 'ttsStop'));
  }

  @override
  void searchInCurrentChapter(String query) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'searchInCurrentChapter',
      data: query,
    ));
  }

  @override
  void searchInWholeBook(String query) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'searchInWholeBook',
      data: query,
    ));
  }

  @override
  set fontColor(Color color) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'setFontColor',
      data: color.toCssRgba(),
    ));
  }

  @override
  set fontSize(double fontSize) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'setFontSize',
      data: fontSize,
    ));
  }

  @override
  set lineHeight(double lineHeight) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'setLineHeight',
      data: lineHeight,
    ));
  }

  @override
  set smoothScroll(bool smoothScroll) {
    _dataSource.send(ReaderWebMessageDto(
      route: 'setSmoothScroll',
      data: smoothScroll,
    ));
  }

  @override
  Stream<void> get onLoadDone => _dataSource.onLoadDone;

  @override
  Stream<ReaderSetStateData> get onSetState => _dataSource.onSetState;

  @override
  Stream<void> get onEndTts => _dataSource.onEndTts;

  @override
  Stream<String> get onPlayTts => _dataSource.onPlayTts;

  @override
  Stream<void> get onStopTts => _dataSource.onStopTts;

  @override
  Stream<List<ReaderSearchResultData>> get onSetSearchResultList =>
      _dataSource.onSetSearchResultList;

  @override
  Future<void> dispose() async {
    // Subscriptions
    for (StreamSubscription<dynamic> subscription in _subscriptionSet) {
      await subscription.cancel();
    }

    // Data sources
    await _dataSource.dispose();

    // Repositories
    await _serverRepository.stop();
  }
}
