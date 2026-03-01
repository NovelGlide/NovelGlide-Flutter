import 'dart:async';

import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_trigger_event.dart';
import 'package:novel_glide/features/cloud/domain/repositories/book_cloud_sync_repository.dart';

/// Auto-sync orchestrator that manages event-driven synchronization.
///
/// Listens to app lifecycle, bookmark creation, and reading session events
/// to automatically trigger cloud synchronization. Implements batching,
/// prioritization, and periodic heartbeat syncing.
///
/// Sync priority (descending):
/// 1. Bookmark creation (immediate)
/// 2. Reading state (heartbeat)
/// 3. EPUB content (on demand)
class AutoSyncOrchestrator {
  AutoSyncOrchestrator({
    required BookCloudSyncRepository bookCloudSyncRepository,
    Duration heartbeatInterval = const Duration(minutes: 5),
    int batchSize = 5,
  })  : _bookCloudSyncRepository = bookCloudSyncRepository,
        _heartbeatInterval = heartbeatInterval,
        _batchSize = batchSize,
        _syncQueue = <String>{},
        _processingQueue = false;

  final BookCloudSyncRepository _bookCloudSyncRepository;
  final Duration _heartbeatInterval;
  final int _batchSize;

  /// Queue of book IDs pending synchronization.
  final Set<String> _syncQueue;

  /// Whether the sync queue is currently being processed.
  bool _processingQueue;

  /// Timer for periodic heartbeat syncing.
  Timer? _heartbeatTimer;

  /// Whether the orchestrator is actively monitoring.
  bool _isMonitoring = false;

  /// Starts the auto-sync orchestrator.
  ///
  /// Begins listening to events and starts the heartbeat timer.
  /// Safe to call multiple times.
  void start() {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;
    _startHeartbeat();

    LogSystem.info('AutoSyncOrchestrator started');
  }

  /// Stops the auto-sync orchestrator.
  ///
  /// Cancels timers and stops listening to events.
  /// Safe to call multiple times.
  void stop() {
    if (!_isMonitoring) {
      return;
    }

    _isMonitoring = false;
    _heartbeatTimer?.cancel();

    LogSystem.info('AutoSyncOrchestrator stopped');
  }

  /// Handles a sync trigger event.
  ///
  /// Queues the appropriate sync operations based on the event type.
  /// Batches are processed asynchronously.
  ///
  /// Parameters:
  ///   event: The trigger event
  ///   bookIds: The affected book IDs (if applicable)
  Future<void> handleEvent(
    SyncTriggerEvent event, {
    List<String>? bookIds,
  }) async {
    if (!_isMonitoring) {
      LogSystem.warn('AutoSyncOrchestrator not monitoring');
      return;
    }

    LogSystem.info('Handling sync trigger event: $event');

    switch (event) {
      case SyncTriggerEvent.bookmarkCreated:
        if (bookIds != null) {
          // Priority: immediate metadata sync for bookmarks
          _syncQueue.addAll(bookIds);
          await _processSyncQueue();
        }

      case SyncTriggerEvent.sessionEnded:
        if (bookIds != null) {
          // Priority: sync reading state
          _syncQueue.addAll(bookIds);
          await _processSyncQueue();
        }

      case SyncTriggerEvent.appBackgrounded:
        // Process entire queue on app backgrounding
        await _processSyncQueue();

      case SyncTriggerEvent.appLaunched:
        // Light sync - just compare indexes
        LogSystem.info('App launched - will compare local vs cloud');

      case SyncTriggerEvent.bookAdded:
        if (bookIds != null) {
          // Full sync for newly added books
          _syncQueue.addAll(bookIds);
          await _processSyncQueue();
        }

      case SyncTriggerEvent.heartbeat:
        // Batched metadata sync during reading
        await _processSyncQueue();
    }
  }

  /// Processes the sync queue in batches.
  ///
  /// Takes up to [_batchSize] books from the queue and syncs them.
  /// Processes sequentially to avoid overwhelming the network.
  Future<void> _processSyncQueue() async {
    if (_processingQueue) {
      LogSystem.info('Sync already in progress, deferring');
      return;
    }

    if (_syncQueue.isEmpty) {
      return;
    }

    _processingQueue = true;

    try {
      while (_syncQueue.isNotEmpty) {
        // Take up to batchSize books
        final List<String> batch = _syncQueue.take(_batchSize).toList();

        for (final String bookId in batch) {
          try {
            LogSystem.info('Syncing book: $bookId');
            await _bookCloudSyncRepository.syncMetadata(bookId);
            _syncQueue.remove(bookId);
          } catch (e) {
            LogSystem.error('Failed to sync book: $bookId', error: e);
            // Keep in queue for retry
          }
        }

        // Brief pause between batches
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      LogSystem.info('Sync queue processing complete');
    } finally {
      _processingQueue = false;
    }
  }

  /// Starts the periodic heartbeat timer.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      LogSystem.info('Heartbeat fired - processing sync queue');
      unawaited(_processSyncQueue());
    });
  }

  /// Gets the current number of books pending sync.
  int getPendingSyncCount() => _syncQueue.length;

  /// Clears the sync queue (for testing/reset).
  void clearQueue() {
    _syncQueue.clear();
    LogSystem.info('Sync queue cleared');
  }
}

/// Helper to allow unawaited futures without warnings
void unawaited(Future<void> future) {
  future.ignore();
}
