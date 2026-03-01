import 'package:flutter_test/flutter_test.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_state.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_step.dart';
import 'package:migration_implementation/features/migration/domain/entities/skipped_book.dart';

void main() {
  group('MigrationState', () {
    group('JSON Serialization', () {
      test('serializes to JSON correctly', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {
            'MigrationStep.downloadCloudBackup': true,
            'MigrationStep.enumerateBooks': false,
          },
          downloadedBooks: ['book1.epub', 'book2.epub'],
          localBooks: ['book1.epub', 'book3.epub'],
          fileNameToBookId: {
            'book1.epub': 'uuid-1',
            'book2.epub': 'uuid-2',
            'book3.epub': 'uuid-3',
          },
          skippedBooks: [],
          totalBooks: 3,
          processedBooks: 1,
        );

        final json = state.toJson();
        expect(json['version'], 1);
        expect(json['currentStep'], 'MigrationStep.enumerateBooks');
        expect(json['totalBooks'], 3);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'version': 1,
          'currentStep': 'MigrationStep.buildNewFolderStructure',
          'stepStatus': {
            'MigrationStep.downloadCloudBackup': true,
            'MigrationStep.enumerateBooks': true,
          },
          'downloadedBooks': ['book1.epub'],
          'localBooks': ['book2.epub'],
          'fileNameToBookId': {'book1.epub': 'uuid-1'},
          'skippedBooks': [],
          'totalBooks': 2,
          'processedBooks': 2,
        };

        final state = MigrationState.fromJson(json);
        expect(state.version, 1);
        expect(state.currentStep, MigrationStep.buildNewFolderStructure);
        expect(state.totalBooks, 2);
      });

      test('round-trip serialization preserves all data', () {
        final original = MigrationState(
          version: 1,
          currentStep: MigrationStep.migrateCollections,
          stepStatus: {
            'MigrationStep.downloadCloudBackup': true,
            'MigrationStep.enumerateBooks': true,
            'MigrationStep.buildNewFolderStructure': true,
          },
          downloadedBooks: ['a.epub', 'b.epub'],
          localBooks: ['b.epub', 'c.epub'],
          fileNameToBookId: {
            'a.epub': 'id-a',
            'b.epub': 'id-b',
            'c.epub': 'id-c',
          },
          skippedBooks: [
            SkippedBook(
              originalFileName: 'corrupt.epub',
              reason: 'Corrupt EPUB',
              attemptedAt: DateTime(2026, 3, 1, 10, 30),
            ),
          ],
          totalBooks: 4,
          processedBooks: 3,
        );

        final json = original.toJson();
        final restored = MigrationState.fromJson(json);

        expect(restored.version, original.version);
        expect(restored.currentStep, original.currentStep);
        expect(restored.downloadedBooks, original.downloadedBooks);
        expect(restored.localBooks, original.localBooks);
        expect(restored.fileNameToBookId, original.fileNameToBookId);
        expect(restored.totalBooks, original.totalBooks);
        expect(restored.processedBooks, original.processedBooks);
        expect(restored.skippedBooks.length, 1);
      });
    });

    group('Immutability', () {
      test('is immutable (cannot modify properties)', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.downloadCloudBackup,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        expect(() => state.downloadedBooks.add('book.epub'), throwsException);
      });

      test('copyWith creates new instance', () {
        final state1 = MigrationState(
          version: 1,
          currentStep: MigrationStep.downloadCloudBackup,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 5,
          processedBooks: 0,
        );

        final state2 = state1.copyWith(processedBooks: 3);

        expect(state1.processedBooks, 0);
        expect(state2.processedBooks, 3);
        expect(identical(state1, state2), false);
      });
    });

    group('Equality', () {
      test('two states with same data are equal', () {
        final state1 = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {'step1': true},
          downloadedBooks: ['book.epub'],
          localBooks: ['book.epub'],
          fileNameToBookId: {'book.epub': 'id-1'},
          skippedBooks: [],
          totalBooks: 1,
          processedBooks: 1,
        );

        final state2 = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {'step1': true},
          downloadedBooks: ['book.epub'],
          localBooks: ['book.epub'],
          fileNameToBookId: {'book.epub': 'id-1'},
          skippedBooks: [],
          totalBooks: 1,
          processedBooks: 1,
        );

        expect(state1, equals(state2));
      });

      test('two states with different data are not equal', () {
        final state1 = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        final state2 = MigrationState(
          version: 1,
          currentStep: MigrationStep.buildNewFolderStructure,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        expect(state1, isNot(equals(state2)));
      });
    });

    group('Factory and Extensions', () {
      test('initial() creates fresh state', () {
        final state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );

        expect(state.version, 1);
        expect(state.currentStep, MigrationStep.downloadCloudBackup);
        expect(state.stepStatus, isEmpty);
        expect(state.downloadedBooks, isEmpty);
        expect(state.totalBooks, 0);
        expect(state.processedBooks, 0);
      });

      test('markCurrentStepComplete() marks step as done', () {
        final state = MigrationState.initial(
          MigrationStep.enumerateBooks,
        );

        final updated = state.markCurrentStepComplete();

        expect(updated.isStepComplete(MigrationStep.enumerateBooks), true);
        expect(state.isStepComplete(MigrationStep.enumerateBooks), false);
      });

      test('isStepComplete() checks step status', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {
            'MigrationStep.downloadCloudBackup': true,
            'MigrationStep.enumerateBooks': false,
          },
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        expect(state.isStepComplete(MigrationStep.downloadCloudBackup), true);
        expect(state.isStepComplete(MigrationStep.enumerateBooks), false);
      });

      test('progressPercent calculates percentage correctly', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.buildNewFolderStructure,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 10,
          processedBooks: 7,
        );

        expect(state.progressPercent, 70);
      });

      test('progressPercent returns 0 when totalBooks is 0', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.downloadCloudBackup,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        expect(state.progressPercent, 0);
      });

      test('isComplete() returns true when all steps done', () {
        var state = MigrationState.initial(
          MigrationStep.downloadCloudBackup,
        );

        for (final step in MigrationStep.values) {
          state = state
              .copyWith(currentStep: step)
              .markCurrentStepComplete();
        }

        expect(state.isComplete, true);
      });
    });

    group('Edge Cases', () {
      test('handles empty books list', () {
        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.enumerateBooks,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: [],
          totalBooks: 0,
          processedBooks: 0,
        );

        expect(state.downloadedBooks, isEmpty);
        expect(state.localBooks, isEmpty);
        expect(state.totalBooks, 0);
      });

      test('handles multiple skipped books', () {
        final skipped = [
          SkippedBook(
            originalFileName: 'corrupt1.epub',
            reason: 'Corrupt EPUB',
            attemptedAt: DateTime(2026, 3, 1, 10, 0),
          ),
          SkippedBook(
            originalFileName: 'corrupt2.epub',
            reason: 'Unreadable metadata',
            attemptedAt: DateTime(2026, 3, 1, 10, 5),
          ),
        ];

        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.buildNewFolderStructure,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: {},
          skippedBooks: skipped,
          totalBooks: 5,
          processedBooks: 3,
        );

        expect(state.skippedBooks.length, 2);
        expect(state.skippedBooks[0].reason, 'Corrupt EPUB');
      });

      test('handles large file name to BookId mapping', () {
        final mapping = <String, String>{};
        for (int i = 0; i < 1000; i++) {
          mapping['book$i.epub'] = 'uuid-$i';
        }

        final state = MigrationState(
          version: 1,
          currentStep: MigrationStep.buildNewFolderStructure,
          stepStatus: {},
          downloadedBooks: [],
          localBooks: [],
          fileNameToBookId: mapping,
          skippedBooks: [],
          totalBooks: 1000,
          processedBooks: 500,
        );

        expect(state.fileNameToBookId.length, 1000);
      });
    });

    group('All Enum Values', () {
      test('all MigrationStep values serialize/deserialize', () {
        for (final step in MigrationStep.values) {
          final state = MigrationState.initial(step);
          final json = state.toJson();
          final restored = MigrationState.fromJson(json);

          expect(restored.currentStep, step);
        }
      });
    });
  });
}
