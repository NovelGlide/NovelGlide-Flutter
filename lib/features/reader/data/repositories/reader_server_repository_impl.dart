import 'dart:io';

import 'package:flutter/services.dart';

import '../../../../core/web_server/domain/entities/app_local_web_server.dart';
import '../../../../core/web_server/domain/entities/web_server_request.dart';
import '../../../../core/web_server/domain/entities/web_server_response.dart';
import '../../../../core/web_server/domain/use_cases/web_server_start_use_case.dart';
import '../../../../core/web_server/domain/use_cases/web_server_stop_use_case.dart';
import '../../../books/domain/use_cases/book_read_bytes_use_case.dart';
import '../../domain/repositories/reader_server_repository.dart';

class ReaderServerRepositoryImpl implements ReaderServerRepository {
  ReaderServerRepositoryImpl(
    this._bookReadBytesUseCase,
    this._startUseCase,
    this._stopUseCase,
  );

  late String _bookIdentifier;

  final BookReadBytesUseCase _bookReadBytesUseCase;
  final WebServerStartUseCase _startUseCase;
  final WebServerStopUseCase _stopUseCase;

  @override
  Future<Uri> start(String bookIdentifier) async {
    _bookIdentifier = bookIdentifier;
    _startUseCase(WebServerStartUseCaseParam(
      server: AppLocalWebServer.reader,
      routes: <String, Future<WebServerResponse> Function(WebServerRequest)>{
        '': _sendIndexHtml,
        'index.html': _sendIndexHtml,
        'index.js': _sendIndexJs,
        'main.css': _sendMainCss,
        'book.epub': _sendBookEpub,
      },
    ));

    return AppLocalWebServer.reader.uri;
  }

  /// Send the content of the index.html file.
  Future<WebServerResponse> _sendIndexHtml(WebServerRequest request) async {
    return WebServerResponse(
      body: await rootBundle.loadString('assets/renderer/index.html'),
      headers: const <String, Object>{
        HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8'
      },
    );
  }

  /// Send the content of the index.js file.
  Future<WebServerResponse> _sendIndexJs(WebServerRequest request) async {
    return WebServerResponse(
      body: await rootBundle.loadString('assets/renderer/index.js'),
      headers: const <String, Object>{
        HttpHeaders.contentTypeHeader: 'text/javascript; charset=utf-8'
      },
    );
  }

  /// Send the content of the main.css file.
  Future<WebServerResponse> _sendMainCss(WebServerRequest request) async {
    return WebServerResponse(
      body: await rootBundle.loadString('assets/renderer/main.css'),
      headers: const <String, Object>{
        HttpHeaders.contentTypeHeader: 'text/css; charset=utf-8'
      },
    );
  }

  /// Send the content of the book.epub file.
  Future<WebServerResponse> _sendBookEpub(WebServerRequest request) async {
    return WebServerResponse(
      body: await _bookReadBytesUseCase(_bookIdentifier),
      headers: const <String, Object>{
        HttpHeaders.contentTypeHeader: 'application/epub+zip'
      },
    );
  }

  @override
  Future<void> stop() async {
    _stopUseCase(AppLocalWebServer.reader);
  }
}
