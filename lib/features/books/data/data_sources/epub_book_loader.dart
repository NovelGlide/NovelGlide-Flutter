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

  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamController<EpubBookLoaderResult> _streamController =
      StreamController<EpubBookLoaderResult>.broadcast();

  final LinkedHashSet<String> _waitingQueue = LinkedHashSet<String>();

  bool _isLock = false;
  bool _isBooting = false;
  bool _isRunning = false;

  Stream<EpubBookLoaderResult> get stream => _streamController.stream;

  Future<void> _bootup() async {
    if (_isBooting || _isRunning) {
      // It's booting or already running.
      return;
    }

    LogSystem.info('Boot up the EPUB loader...');
    _reset();

    // Start boot up.
    _isBooting = true;
    final Completer<void> completer = Completer<void>();

    _receivePort = ReceivePort();
    await Isolate.spawn<SendPort>(
      _isolatedRunner,
      _receivePort!.sendPort,
    );

    _receivePort!.listen((dynamic message) {
      if (message is SendPort) {
        // Save the send port.
        _sendPort = message;

        // Complete the initialization.
        completer.complete(null);

        _isRunning = true;
        _isBooting = false;

        LogSystem.info('The EPUB loader was boot up successfully.');

        // Start processing tasks.
        _startNextTask();
      } else if (message is EpubBookLoaderResult) {
        // Send with stream.
        _streamController.add(message);

        LogSystem.info('Loading ${message.absolutePath} completed.');

        // Task Completed.
        _isLock = false;
        _startNextTask();
      }
    });
  }

  Stream<EpubBookLoaderResult> loadByPathSet(Set<String> pathSet) async* {
    await _bootup();

    LogSystem.info('Add these path to waiting queue: $pathSet');

    // Start loading the file.
    _waitingQueue.addAll(pathSet);

    LogSystem.info('Waiting queue: $_waitingQueue');

    // Try to start the task.
    _startNextTask();

    yield* stream;
  }

  void _startNextTask() {
    LogSystem.info('Try to start the next task.');

    if (_isRunning && !_isLock) {
      // No task is running.
      LogSystem.info('No task is running.');
      if (_waitingQueue.isEmpty) {
        // No pending task.
        LogSystem.info('No pending task.');
        _shutdown();
      } else {
        // Start the next task.
        _isLock = true;
        final String path = _waitingQueue.first;
        _waitingQueue.remove(path);

        LogSystem.info('Start the next task. $path');
        _sendPort?.send(path);
      }
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

  void _shutdown() {
    if (!_isRunning) {
      // Already shutdown.
      return;
    }

    _waitingQueue.clear();

    _sendPort?.send(_closeText);
    _receivePort?.close();
    _streamController.close();

    _streamController = StreamController<EpubBookLoaderResult>.broadcast();

    _reset();
    LogSystem.info('The EPUB loader was shutdown.');
  }

  void _reset() {
    _sendPort = null;
    _receivePort = null;

    _isLock = false;
    _isRunning = false;
    _isBooting = false;
  }
}
