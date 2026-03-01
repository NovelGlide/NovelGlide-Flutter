import 'dart:async';

import '../entities/migration_context.dart';
import '../entities/migration_scenario.dart';
import '../entities/migration_state.dart';
import '../entities/migration_step.dart';
import '../repositories/migration_repository.dart';
import 'migration_progress.dart';

/// Main migration orchestrator use case.
///
/// Orchestrates the complete 9-step migration process, including:
/// - Scenario detection
/// - Resume from last checkpoint if interrupted
/// - Running each step in sequence
/// - Emitting progress updates for UI
/// - Error handling with retry capability
/// - Completion and cleanup
///
/// Emits [MigrationProgress] updates through a Stream for real-time UI
/// updates. Supports resume logic so interrupted migrations can
/// continue from the last successful step.
class RunMigrationUseCase {
  /// Creates a RunMigrationUseCase.
  ///
  /// [repository] is the migration repository for all operations.
  RunMigrationUseCase({
    required MigrationRepository repository,
  }) : _repository = repository;

  final MigrationRepository _repository;

  /// Executes the migration process.
  ///
  /// Returns a Stream of [MigrationProgress] updates. The stream emits:
  /// - Progress updates after each step (step name, %)
  /// - Error states with exception details
  /// - Final completion event
  ///
  /// The stream completes when migration finishes (success or final error).
  ///
  /// On error:
  /// - Emits error state (allows UI to show retry button)
  /// - Saves state for resumption
  /// - Does NOT complete stream (wait for user retry or quit)
  ///
  /// On success:
  /// - Emits completion with 100%
  /// - Marks migration complete
  /// - Deletes state file
  /// - Completes stream
  ///
  /// Example usage:
  /// ```dart
  /// final useCase = RunMigrationUseCase(repository: myRepo);
  /// runMigration()
  ///   .listen(
  ///     (progress) {
  ///       print('${progress.currentLabel} ${progress.progressPercent}%');
  ///       if (progress.hasError) {
  ///         showRetryDialog(progress.error);
  ///       }
  ///     },
  ///     onDone: () => Navigator.pop(context),
  ///   );
  /// ```
  Stream<MigrationProgress> call() async* {
    try {
      // 1. Detect scenario
      final scenario = await _repository.detectScenario();

      // 2. Load prior state if exists (resume case)
      var state = await _repository.getLastMigrationState();

      final isResume = state != null;

      // If fresh start, create initial state
      state ??= MigrationState.initial(MigrationStep.downloadCloudBackup);

      // 3. Create shared context
      final context = MigrationContext(
        scenario: scenario,
        tempExtractionPath: '/tmp/migration_extract',
        userChosenIncludeCloud: scenario == MigrationScenario.localAndCloud,
        totalBooksToMigrate: state.totalBooks,
      );

      // Helper function to save state
      Future<void> saveState(MigrationState updated) async {
        state = updated;
        await _repository.saveMigrationState(updated);
      }

      // 4. Execute steps in order
      for (final step in MigrationStep.values) {
        // Skip if already completed (resume logic)
        if (state.isStepComplete(step)) {
          continue;
        }

        // Update current step
        state = state.copyWithStep(step);

        try {
          // Emit progress before step
          yield MigrationProgress(
            step: step,
            progressPercent: state.progressPercent,
            currentLabel: _getStepLabel(step),
            processedBooks: state.processedBooks,
            totalBooks: state.totalBooks,
          );

          // Execute step
          await _executeStep(step, state, context, saveState);

          // Mark step complete
          state = state.markCurrentStepComplete();
          await saveState(state);

          // Emit progress after step
          yield MigrationProgress(
            step: step,
            progressPercent: state.progressPercent,
            currentLabel: _getStepLabel(step),
            processedBooks: state.processedBooks,
            totalBooks: state.totalBooks,
          );
        } catch (e) {
          // Emit error state (allows retry)
          yield MigrationProgress(
            step: step,
            progressPercent: state.progressPercent,
            currentLabel: _getStepLabel(step),
            processedBooks: state.processedBooks,
            totalBooks: state.totalBooks,
            error: e is Exception
                ? e
                : Exception('Migration failed: $e'),
          );

          // Save state for resumption
          await saveState(state);

          // Rethrow to signal migration failure
          rethrow;
        }
      }

      // 5. Mark complete
      await _repository.markMigrationComplete();
      await _repository.resetDeferralCount();
      await _repository.deleteMigrationState();

      // 6. Final success emission
      yield MigrationProgress(
        step: MigrationStep.markComplete,
        progressPercent: 100,
        currentLabel: 'Migration complete!',
        processedBooks: state.totalBooks,
        totalBooks: state.totalBooks,
      );
    } catch (e) {
      // Unexpected error (not from a step)
      yield MigrationProgress(
        step: MigrationStep.downloadCloudBackup,
        progressPercent: 0,
        currentLabel: 'Error',
        processedBooks: 0,
        totalBooks: 0,
        error: e is Exception
            ? e
            : Exception('Unexpected error: $e'),
      );
      rethrow;
    }
  }

  /// Executes a single migration step.
  Future<void> _executeStep(
    MigrationStep step,
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  ) async {
    switch (step) {
      case MigrationStep.downloadCloudBackup:
        await _repository.downloadCloudBackup(state, context, saveState);
      case MigrationStep.enumerateBooks:
        await _repository.enumerateBooks(state, context, saveState);
      case MigrationStep.buildNewFolderStructure:
        await _repository.buildNewFolderStructure(state, context, saveState);
      case MigrationStep.migrateCollections:
        await _repository.migrateCollections(state, context, saveState);
      case MigrationStep.clearSupersededData:
        await _repository.clearSupersededData(state, context, saveState);
      case MigrationStep.rebuildBookmarkCache:
        await _repository.rebuildBookmarkCache(state, context, saveState);
      case MigrationStep.renameCloudBackup:
        await _repository.renameCloudBackup(state, context, saveState);
      case MigrationStep.enableCloudSync:
        await _repository.enableCloudSync(state, context, saveState);
      case MigrationStep.markComplete:
        // No-op (handled after loop)
        break;
    }
  }

  /// Gets human-readable label for a step.
  String _getStepLabel(MigrationStep step) {
    switch (step) {
      case MigrationStep.downloadCloudBackup:
        return 'Downloading backup…';
      case MigrationStep.enumerateBooks:
        return 'Enumerating books…';
      case MigrationStep.buildNewFolderStructure:
        return 'Building folder structure…';
      case MigrationStep.migrateCollections:
        return 'Updating collections…';
      case MigrationStep.clearSupersededData:
        return 'Clearing old files…';
      case MigrationStep.rebuildBookmarkCache:
        return 'Rebuilding bookmark cache…';
      case MigrationStep.renameCloudBackup:
        return 'Archiving cloud backup…';
      case MigrationStep.enableCloudSync:
        return 'Enabling cloud sync…';
      case MigrationStep.markComplete:
        return 'Finalizing…';
    }
  }
}
