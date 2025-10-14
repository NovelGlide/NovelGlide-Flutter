import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:epubx/epubx.dart' as epub;

class EpubBookLoader {
  static const String _closeText = '=== CLOSE ===';

  late final Isolate _loaderIsolate;
  final ReceivePort _receivePort = ReceivePort();
  late final SendPort _sendPort;
  final StreamController<epub.EpubBook> _streamController =
      StreamController<epub.EpubBook>.broadcast();

  final Queue<String> _waitingQueue = Queue<String>();
  bool _isLock = false;

  Stream<epub.EpubBook> get stream => _streamController.stream;

  Future<void> initLoader() async {
    _loaderIsolate = await Isolate.spawn<SendPort>(
      _isolatedRunner,
      _receivePort.sendPort,
    );
    _receivePort.listen((dynamic message) {
      if (message is SendPort) {
        // Save the send port.
        _sendPort = message;
      } else if (message is epub.EpubBook) {
        // Send with stream.
        _streamController.add(message);

        // Task Completed.
        _isLock = false;
        _startNextTask();
      }
    });
  }

  void loadByPath(String path) {
    _waitingQueue.add(path);

    // Try to start the task.
    _startNextTask();
  }

  void _startNextTask() {
    if (!_isLock && _waitingQueue.isNotEmpty) {
      _isLock = true;
      final String path = _waitingQueue.first;
      _waitingQueue.removeFirst();
      _sendPort.send(path);
    }
  }

  void _isolatedRunner(SendPort sendPort) {
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
          sendPort
              .send(await epub.EpubReader.readBook(File(path).readAsBytes()));
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
  }
}
