import 'package:bloc/bloc.dart';

import '../../domain/use_cases/get_deferral_count_use_case.dart';
import '../../domain/use_cases/increment_deferral_count_use_case.dart';
import '../../domain/use_cases/run_migration_use_case.dart';
import '../../domain/use_cases/migration_progress.dart';

/// Represents states in the migration wizard flow.
sealed class WizardState {
  const WizardState();
}

/// Initial state before wizard starts.
class WizardInitial extends WizardState {
  const WizardInitial();
}

/// Showing introduction screen.
class Screen1Introduction extends WizardState {
  const Screen1Introduction({
    required this.canDefer,
  });

  final bool canDefer;
}

/// Showing cloud choice screen (conditional, only if cloud backup found).
class Screen2CloudChoice extends WizardState {
  const Screen2CloudChoice();
}

/// Showing progress screen with real-time updates.
class Screen3Progress extends WizardState {
  const Screen3Progress({
    required this.progress,
  });

  final MigrationProgress progress;
}

/// Showing completion screen.
class Screen4Complete extends WizardState {
  const Screen4Complete({
    required this.skippedBooksCount,
  });

  final int skippedBooksCount;
}

/// Error state during migration with retry option.
class Screen3Error extends WizardState {
  const Screen3Error({
    required this.error,
    required this.progress,
  });

  final Exception error;
  final MigrationProgress progress;
}

/// Cubit for managing migration wizard flow and state.
///
/// Handles screen navigation, deferral logic, user choices, and
/// migration progress streaming. Controls the full blocking wizard
/// flow from introduction to completion.
///
/// State transitions:
/// - Initial → Screen1 (introduction)
/// - Screen1 → Screen2 (if cloud backup) or Screen3 (if no cloud)
/// - Screen2 → Screen3 (cloud choice made)
/// - Screen3 → Screen4 (migration complete)
/// - Screen3 → Screen3Error (on error)
/// - Screen3Error → Screen3 (on retry)
/// - Screen1 → Exit (on defer)
class MigrationWizardCubit extends Cubit<WizardState> {
  /// Creates a MigrationWizardCubit.
  ///
  /// [getDeferralCountUseCase] - reads deferral count
  /// [incrementDeferralCountUseCase] - increments deferral count
  /// [runMigrationUseCase] - executes the migration
  MigrationWizardCubit({
    required GetDeferralCountUseCase getDeferralCountUseCase,
    required IncrementDeferralCountUseCase incrementDeferralCountUseCase,
    required RunMigrationUseCase runMigrationUseCase,
  })  : _getDeferralCountUseCase = getDeferralCountUseCase,
        _incrementDeferralCountUseCase = incrementDeferralCountUseCase,
        _runMigrationUseCase = runMigrationUseCase,
        super(const WizardInitial());

  final GetDeferralCountUseCase _getDeferralCountUseCase;
  final IncrementDeferralCountUseCase _incrementDeferralCountUseCase;
  final RunMigrationUseCase _runMigrationUseCase;

  /// Goes to introduction screen (screen 1).
  Future<void> goToScreen1() async {
    final deferralCount = await _getDeferralCountUseCase();
    final canDefer = deferralCount < 3;
    emit(Screen1Introduction(canDefer: canDefer));
  }

  /// Defers migration (user clicks "Remind me later").
  ///
  /// Increments deferral count and closes wizard.
  /// On next app launch, wizard may appear again if deferrals < 3.
  /// If deferrals >= 3, wizard is forced (no deferral button shown).
  Future<void> deferMigration() async {
    await _incrementDeferralCountUseCase();
    // Return to main app (emit special state or close)
    // In actual implementation, would navigate back via context
  }

  /// Goes to cloud choice screen (screen 2).
  ///
  /// Only shown if:
  /// - User is signed into Google Drive
  /// - Library.zip backup exists on Drive
  void goToScreen2() {
    emit(const Screen2CloudChoice());
  }

  /// User chose to include cloud backup in merge.
  void chooseIncludeCloud() {
    // Save choice to context
    // Proceed to screen 3
    goToScreen3();
  }

  /// User chose device-only migration (skip cloud backup).
  void chooseDeviceOnly() {
    // Save choice to context
    // Proceed to screen 3
    goToScreen3();
  }

  /// Goes to progress screen (screen 3) and starts migration.
  void goToScreen3() {
    _startMigration();
  }

  /// Starts the migration process.
  ///
  /// Subscribes to RunMigrationUseCase stream and emits progress states.
  Future<void> _startMigration() async {
    try {
      // TODO: Emit initial progress state
      emit(Screen3Progress(
        progress: MigrationProgress(
          step: /* current step */ null,
          progressPercent: 0,
          currentLabel: 'Starting migration…',
          processedBooks: 0,
          totalBooks: 0,
        ),
      ));

      // Subscribe to migration stream
      await _runMigrationUseCase().forEach((progress) {
        if (progress.hasError) {
          emit(Screen3Error(
            error: progress.error!,
            progress: progress,
          ));
        } else if (progress.step.toString() == 'MigrationStep.markComplete'
            && progress.progressPercent == 100) {
          // Migration complete
          emit(Screen4Complete(
            skippedBooksCount: 0, // TODO: Get from progress
          ));
        } else {
          // Regular progress update
          emit(Screen3Progress(progress: progress));
        }
      });
    } catch (e) {
      emit(Screen3Error(
        error: e is Exception ? e : Exception('Migration failed: $e'),
        progress: state is Screen3Progress
            ? (state as Screen3Progress).progress
            : MigrationProgress(
                step: null,
                progressPercent: 0,
                currentLabel: 'Error',
                processedBooks: 0,
                totalBooks: 0,
              ),
      ));
    }
  }

  /// Retries migration after error.
  void retryMigration() {
    _startMigration();
  }
}
