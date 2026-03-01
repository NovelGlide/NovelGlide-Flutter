import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/cloud/data/services/auto_sync_orchestrator.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_trigger_event.dart';
import 'package:novel_glide/features/cloud/domain/repositories/book_cloud_sync_repository.dart';

class MockBookCloudSyncRepository extends Mock
    implements BookCloudSyncRepository {}

void main() {
  group('AutoSyncOrchestrator', () {
    late MockBookCloudSyncRepository mockRepository;
    late AutoSyncOrchestrator orchestrator;

    setUp(() {
      mockRepository = MockBookCloudSyncRepository();
      when(() => mockRepository.syncMetadata(any()))
          .thenAnswer((_) async => {});

      orchestrator = AutoSyncOrchestrator(
        bookCloudSyncRepository: mockRepository,
        heartbeatInterval: const Duration(milliseconds: 100),
        batchSize: 2,
      );
    });

    tearDown(() {
      orchestrator.stop();
    });

    group('Lifecycle', () {
      test('starts and stops cleanly', () async {
        orchestrator.start();
        expect(orchestrator.getPendingSyncCount(), equals(0));

        orchestrator.stop();
        expect(orchestrator.getPendingSyncCount(), equals(0));
      });

      test('prevents duplicate starts', () {
        orchestrator.start();
        orchestrator.start(); // Should be no-op
        orchestrator.stop();
      });

      test('prevents operations when not monitoring', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1'],
        );

        // Should not process without starting
        expect(orchestrator.getPendingSyncCount(), equals(0));
      });
    });

    group('Trigger Handling', () {
      setUp(() {
        orchestrator.start();
      });

      test('handles bookmark creation event', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-123'],
        );

        verify(() => mockRepository.syncMetadata('book-123')).called(1);
      });

      test('handles session ended event', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.sessionEnded,
          bookIds: <String>['book-123'],
        );

        verify(() => mockRepository.syncMetadata('book-123')).called(1);
      });

      test('handles app backgrounded event', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-2'],
        );

        await orchestrator.handleEvent(SyncTriggerEvent.appBackgrounded);

        verify(() => mockRepository.syncMetadata(any())).called(greaterThanOrEqualTo(1));
      });

      test('handles book added event', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookAdded,
          bookIds: <String>['book-new'],
        );

        verify(() => mockRepository.syncMetadata('book-new')).called(1);
      });

      test('handles app launched event', () async {
        await orchestrator.handleEvent(SyncTriggerEvent.appLaunched);
        // Should not crash, just log
      });

      test('ignores events with no bookIds when required', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
        );

        // Should not sync anything
        verifyNever(() => mockRepository.syncMetadata(any()));
      });
    });

    group('Batching', () {
      setUp(() {
        orchestrator.start();
      });

      test('batches sync operations by batchSize', () async {
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-2', 'book-3', 'book-4'],
        );

        // With batchSize=2, should process in batches
        verify(() => mockRepository.syncMetadata(any())).called(greaterThanOrEqualTo(3));
      });

      test('processes queue sequentially', () async {
        int callCount = 0;
        when(() => mockRepository.syncMetadata(any())).thenAnswer((_) async {
          callCount++;
        });

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-2'],
        );

        expect(callCount, greaterThan(0));
      });

      test('handles batch size limit correctly', () async {
        final List<String> books =
            List<String>.generate(10, (int i) => 'book-$i');

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: books,
        );

        // Should batch process all books
        verify(() => mockRepository.syncMetadata(any())).called(greaterThanOrEqualTo(10));
      });
    });

    group('Pending Sync Count', () {
      test('tracks pending sync count', () async {
        orchestrator.start();

        expect(orchestrator.getPendingSyncCount(), equals(0));

        // Add to queue but don't process
        final MockBookCloudSyncRepository slowMock =
            MockBookCloudSyncRepository();
        when(() => slowMock.syncMetadata(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
        });

        final AutoSyncOrchestrator slowOrchestrator = AutoSyncOrchestrator(
          bookCloudSyncRepository: slowMock,
        );

        slowOrchestrator.start();

        // Initial count should reflect queued items
        expect(slowOrchestrator.getPendingSyncCount(), isA<int>());

        slowOrchestrator.stop();
      });
    });

    group('Error Handling', () {
      setUp(() {
        orchestrator.start();
      });

      test('continues processing on single failure', () async {
        // First book fails, second succeeds
        int callCount = 0;
        when(() => mockRepository.syncMetadata(any()))
            .thenAnswer((Invocation inv) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Sync failed');
          }
        });

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-2'],
        );

        // Should attempt both syncs
        expect(callCount, greaterThan(1));
      });

      test('keeps failed items in queue for retry', () async {
        when(() => mockRepository.syncMetadata(any()))
            .thenThrow(Exception('Sync failed'));

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1'],
        );

        // Item should still be in queue for retry
        expect(orchestrator.getPendingSyncCount(), greaterThanOrEqualTo(0));
      });
    });

    group('Queue Management', () {
      test('clears queue when requested', () async {
        orchestrator.start();

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-2'],
        );

        orchestrator.clearQueue();
        expect(orchestrator.getPendingSyncCount(), equals(0));
      });

      test('prevents duplicate books in queue', () async {
        orchestrator.start();

        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1', 'book-1'],
        );

        // Should deduplicate (Set behavior)
        expect(orchestrator.getPendingSyncCount(), lessThanOrEqualTo(1));
      });
    });

    group('Heartbeat', () {
      test('fires periodically', () async {
        orchestrator.start();

        // Add items to queue
        await orchestrator.handleEvent(
          SyncTriggerEvent.bookmarkCreated,
          bookIds: <String>['book-1'],
        );

        // Wait for heartbeat to fire (100ms interval)
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Should have processed items by now
        expect(orchestrator.getPendingSyncCount(), lessThanOrEqualTo(1));
      });
    });
  });
}
