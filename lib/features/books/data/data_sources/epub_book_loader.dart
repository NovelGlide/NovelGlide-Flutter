import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:epubx/epubx.dart' as epub;

import '../../../../core/log_system/log_system.dart';

class EpubBookLoaderResult {
  EpubBookLoaderResult({required this.absolutePath, required this.epubBook});

  final String absolutePath;
  final epub.EpubBook epubBook;
}

class EpubBookLoader {
  static const String _closeText = '=== CLOSE ===';

  late final Isolate _loaderIsolate;
  final ReceivePort _receivePort = ReceivePort();
  late final SendPort _sendPort;
  final StreamController<EpubBookLoaderResult> _streamController =
      StreamController<EpubBookLoaderResult>.broadcast();

  final Queue<String> _waitingQueue = Queue<String>();
  bool _isLock = false;

  Stream<EpubBookLoaderResult> get stream => _streamController.stream;

  Future<void> initLoader() async {
    LogSystem.info('Initializing an EPUB loader...');
    final Completer<void> completer = Completer<void>();

    _loaderIsolate = await Isolate.spawn<SendPort>(
      _isolatedRunner,
      _receivePort.sendPort,
    );

    _receivePort.listen((dynamic message) {
      if (message is SendPort) {
        // Save the send port.
        _sendPort = message;

        // Complete the initialization.
        completer.complete(null);

        LogSystem.info('An EPUB loader was initialized successfully.');
      } else if (message is EpubBookLoaderResult) {
        // Send with stream.
        _streamController.add(message);

        // Task Completed.
        _isLock = false;
        _startNextTask();
      }
    });

    return completer.future;
  }

  void loadByPath(Set<String> pathSet) {
    _waitingQueue.addAll(pathSet);

    // Try to start the task.
    _startNextTask();
  }

  Future<EpubBookLoaderResult> loadSingleBookByPath(String path) async {
    await initLoader();

    // Start loading the file.
    loadByPath(<String>{path});
    final EpubBookLoaderResult result = await stream.firstWhere(
        (EpubBookLoaderResult result) => result.absolutePath == path);

    // Finally.
    dispose();
    return result;
  }

  void _startNextTask() {
    if (!_isLock && _waitingQueue.isNotEmpty) {
      _isLock = true;
      final String path = _waitingQueue.first;
      _waitingQueue.removeFirst();
      _sendPort.send(path);
    }
  }

  static void _isolatedRunner(SendPort sendPort) {
    // Create the receive port
    final ReceivePort receivePort = ReceivePort();

    // Send it to the main thread.
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic message) async {
      if (message is String) {
        if (message == _closeText) {
          // Close!
          receivePort.close();
          Isolate.exit();
        } else {
          // Load the book.
          final String path = message;
          sendPort.send(EpubBookLoaderResult(
            absolutePath: message,
            epubBook: await epub.EpubReader.readBook(File(path).readAsBytes()),
          ));
        }
      }
    });
  }

  void dispose() {
    _waitingQueue.clear();

    _sendPort.send(_closeText);
    _loaderIsolate.kill();

    _streamController.close();
    _receivePort.close();

    LogSystem.info('An EPUB loader was disposed.');
  }
}
