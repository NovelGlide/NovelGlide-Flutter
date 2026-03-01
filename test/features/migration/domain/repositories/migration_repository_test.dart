import 'package:flutter_test/flutter_test.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_context.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_scenario.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_state.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_step.dart';
import 'package:migration_implementation/features/migration/domain/repositories/migration_repository.dart';

/// Mock implementation of MigrationRepository for testing interface
/// contract and ensuring all methods exist with correct signatures.
class MockMigrationRepository implements MigrationRepository {
  @override
  Future<bool> isMigrationNeeded() async => false;

  @override
  Future<void> markMigrationComplete() async {}

  @override
  Future<MigrationScenario> detectScenario() async =>
      MigrationScenario.none;

  @override
  Future<int> getDeferralCount() async => 0;

  @override
  Future<int> incrementDeferralCount() async => 1;

  @override
  Future<void> resetDeferralCount() async {}

  @override
  Future<MigrationState?> getLastMigrationState() async => null;

  @override
  Future<void> saveMigrationState(MigrationState state) async {}

  @override
  Future<void> deleteMigrationState() async {}

  @override
  Future<void> downloadCloudBackup(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> enumerateBooks(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> buildNewFolderStructure(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> migrateCollections(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> clearSupersededData(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> rebuildBookmarkCache(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> renameCloudBackup(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}

  @override
  Future<void> enableCloudSync(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {}
}

void main() {
  group('MigrationRepository', () {
    group('Interface Contract', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('isMigrationNeeded() method exists', () async {
        expect(repository.isMigrationNeeded, isNotNull);
        final result = await repository.isMigrationNeeded();
        expect(result, isA<bool>());
      });

      test('markMigrationComplete() method exists', () async {
        expect(repository.markMigrationComplete, isNotNull);
        await repository.markMigrationComplete();
      });

      test('detectScenario() method exists', () async {
        expect(repository.detectScenario, isNotNull);
        final result = await repository.detectScenario();
        expect(result, isA<MigrationScenario>());
      });

      test('getDeferralCount() method exists', () async {
        expect(repository.getDeferralCount, isNotNull);
        final result = await repository.getDeferralCount();
        expect(result, isA<int>());
      });

      test('incrementDeferralCount() method exists', () async {
        expect(repository.incrementDeferralCount, isNotNull);
        final result = await repository.incrementDeferralCount();
        expect(result, isA<int>());
      });

      test('resetDeferralCount() method exists', () async {
        expect(repository.resetDeferralCount, isNotNull);
        await repository.resetDeferralCount();
      });

      test('getLastMigrationState() method exists', () async {
        expect(repository.getLastMigrationState, isNotNull);
        final result = await repository.getLastMigrationState();
        expect(result, isNull); // Mock returns null
      });

      test('saveMigrationState() method exists', () async {
        expect(repository.saveMigrationState, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );
        await repository.saveMigrationState(state);
      });

      test('deleteMigrationState() method exists', () async {
        expect(repository.deleteMigrationState, isNotNull);
        await repository.deleteMigrationState();
      });

      test('downloadCloudBackup() method exists with correct signature', () async {
        expect(repository.downloadCloudBackup, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.downloadCloudBackup(state, context, (_) async {});
      });

      test('enumerateBooks() method exists with correct signature', () async {
        expect(repository.enumerateBooks, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.enumerateBooks,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.enumerateBooks(state, context, (_) async {});
      });

      test(
        'buildNewFolderStructure() method exists with correct signature',
        () async {
          expect(repository.buildNewFolderStructure, isNotNull);
          final state = MigrationState.initial(
            MigrationStep.buildNewFolderStructure,
          );
          final context = MigrationContext(
            scenario: MigrationScenario.none,
            tempExtractionPath: '/tmp',
            userChosenIncludeCloud: false,
            totalBooksToMigrate: 0,
          );
          await repository.buildNewFolderStructure(state, context, (_) async {});
        },
      );

      test('migrateCollections() method exists with correct signature', () async {
        expect(repository.migrateCollections, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.migrateCollections,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.migrateCollections(state, context, (_) async {});
      });

      test('clearSupersededData() method exists with correct signature', () async {
        expect(repository.clearSupersededData, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.clearSupersededData,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.clearSupersededData(state, context, (_) async {});
      });

      test('rebuildBookmarkCache() method exists with correct signature', () async {
        expect(repository.rebuildBookmarkCache, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.rebuildBookmarkCache,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.rebuildBookmarkCache(state, context, (_) async {});
      });

      test('renameCloudBackup() method exists with correct signature', () async {
        expect(repository.renameCloudBackup, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.renameCloudBackup,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.renameCloudBackup(state, context, (_) async {});
      });

      test('enableCloudSync() method exists with correct signature', () async {
        expect(repository.enableCloudSync, isNotNull);
        final state = MigrationState.initial(
          MigrationStep.enableCloudSync,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );
        await repository.enableCloudSync(state, context, (_) async {});
      });
    });

    group('Step Method Signatures', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('all step methods are async and return Future<void>', () async {
        final state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.none,
          tempExtractionPath: '/tmp',
          userChosenIncludeCloud: false,
          totalBooksToMigrate: 0,
        );

        // All these should be Future<void>
        expect(
          repository.downloadCloudBackup(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.enumerateBooks(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.buildNewFolderStructure(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.migrateCollections(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.clearSupersededData(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.rebuildBookmarkCache(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.renameCloudBackup(state, context, (_) async {}),
          isA<Future<void>>(),
        );
        expect(
          repository.enableCloudSync(state, context, (_) async {}),
          isA<Future<void>>(),
        );
      });

      test('all step methods accept correct parameters', () async {
        final state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );
        final context = MigrationContext(
          scenario: MigrationScenario.localAndCloud,
          tempExtractionPath: '/tmp/extract',
          userChosenIncludeCloud: true,
          totalBooksToMigrate: 5,
        );

        bool saveStateCalled = false;
        Future<void> mockSaveState(MigrationState updatedState) async {
          saveStateCalled = true;
        }

        // Should not throw
        await repository.downloadCloudBackup(state, context, mockSaveState);
        await repository.enumerateBooks(state, context, mockSaveState);
        await repository.buildNewFolderStructure(state, context, mockSaveState);
        await repository.migrateCollections(state, context, mockSaveState);
        await repository.clearSupersededData(state, context, mockSaveState);
        await repository.rebuildBookmarkCache(state, context, mockSaveState);
        await repository.renameCloudBackup(state, context, mockSaveState);
        await repository.enableCloudSync(state, context, mockSaveState);
      });
    });

    group('State Persistence Methods', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('saveMigrationState accepts MigrationState', () async {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {'step': true},
          downloadedBooks: ['book.epub'],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 1,
          processedBooks: 1,
        );

        // Should not throw
        await repository.saveMigrationState(state);
      });

      test('getLastMigrationState returns nullable MigrationState', () async {
        final result = await repository.getLastMigrationState();
        expect(result, isNull); // Mock returns null
      });

      test('deleteMigrationState is idempotent', () async {
        // Should not throw
        await repository.deleteMigrationState();
        await repository.deleteMigrationState();
      });
    });

    group('Deferral System', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('deferral count starts at 0', () async {
        final count = await repository.getDeferralCount();
        expect(count, 0);
      });

      test('incrementDeferralCount returns updated count', () async {
        final count = await repository.incrementDeferralCount();
        expect(count, 1);
      });

      test('resetDeferralCount resets to 0', () async {
        await repository.incrementDeferralCount();
        await repository.resetDeferralCount();
        final count = await repository.getDeferralCount();
        expect(count, 0);
      });
    });

    group('Migration Needed Check', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('isMigrationNeeded returns boolean', () async {
        final needed = await repository.isMigrationNeeded();
        expect(needed, isA<bool>());
      });

      test('markMigrationComplete completes without error', () async {
        // Should not throw
        await repository.markMigrationComplete();
      });
    });

    group('Scenario Detection', () {
      late MigrationRepository repository;

      setUp(() {
        repository = MockMigrationRepository();
      });

      test('detectScenario returns valid MigrationScenario', () async {
        final scenario = await repository.detectScenario();
        expect(scenario, isA<MigrationScenario>());
        expect(
          MigrationScenario.values,
          contains(scenario),
        );
      });

      test('detectScenario can be called multiple times', () async {
        final scenario1 = await repository.detectScenario();
        final scenario2 = await repository.detectScenario();
        expect(scenario1, isA<MigrationScenario>());
        expect(scenario2, isA<MigrationScenario>());
      });
    });
  });
}
