import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/preference/domain/entities/reader_preference_data.dart';
import 'package:novel_glide/features/preference/domain/use_cases/preference_get_use_cases.dart';
import 'package:novel_glide/features/preference/domain/use_cases/preference_save_use_case.dart';
import 'package:novel_glide/features/reader/domain/entities/reader_core_type.dart';
import 'package:novel_glide/features/reader/domain/repositories/reader_core_repository.dart';
import 'package:novel_glide/features/reader/presentation/reader_page/cubit/reader_cubit.dart';

// Mock classes
class MockReaderCoreRepository extends Mock implements ReaderCoreRepository {}

class MockReaderSavePreferenceUseCase extends Mock
    implements ReaderSavePreferenceUseCase {}

class MockReaderGetPreferenceUseCase extends Mock
    implements ReaderGetPreferenceUseCase {}

class MockReaderObservePreferenceChangeUseCase extends Mock
    implements ReaderObservePreferenceChangeUseCase {}

void main() {
  group('ReaderCubit - Engine Selector (coreType setter)', () {
    late MockReaderGetPreferenceUseCase mockGetPreferenceUseCase;
    late MockReaderSavePreferenceUseCase mockSavePreferenceUseCase;

    setUp(() {
      mockGetPreferenceUseCase = MockReaderGetPreferenceUseCase();
      mockSavePreferenceUseCase = MockReaderSavePreferenceUseCase();

      // Set up default return value for get preference use case
      when(() => mockGetPreferenceUseCase.call())
          .thenAnswer((_) async => const ReaderPreferenceData(
                coreType: ReaderCoreType.htmlWidget,
              ));
    });

    /// Tests for the coreType setter
    group('coreType setter', () {
      test(
        'should emit new state with updated coreType when set to webView',
        () async {
          final ReaderCubit cubit = ReaderCubit(
            mockGetPreferenceUseCase,
            (_) => ReaderCubitDependencies(
              // Dependencies would be properly mocked in full integration
              null,
              null,
              MockReaderCoreRepository(),
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              mockSavePreferenceUseCase,
              MockReaderObservePreferenceChangeUseCase(),
              null,
              null,
            ),
            null,
          );

          // Initialize the cubit
          await cubit.init(bookIdentifier: 'test-book');

          expect(
            cubit.stream,
            emits(
              predicate<ReaderState>(
                (ReaderState state) =>
                    state.readerPreference.coreType ==
                    ReaderCoreType.webView,
              ),
            ),
          );

          cubit.coreType = ReaderCoreType.webView;

          await cubit.close();
        },
      );

      test(
        'should emit new state with updated coreType when set to htmlWidget',
        () async {
          final ReaderCubit cubit = ReaderCubit(
            mockGetPreferenceUseCase,
            (_) => ReaderCubitDependencies(
              null,
              null,
              MockReaderCoreRepository(),
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              mockSavePreferenceUseCase,
              MockReaderObservePreferenceChangeUseCase(),
              null,
              null,
            ),
            null,
          );

          // Initialize with webView
          when(() => mockGetPreferenceUseCase.call())
              .thenAnswer((_) async => const ReaderPreferenceData(
                    coreType: ReaderCoreType.webView,
                  ));

          await cubit.init(bookIdentifier: 'test-book');

          expect(
            cubit.stream,
            emits(
              predicate<ReaderState>(
                (ReaderState state) =>
                    state.readerPreference.coreType ==
                    ReaderCoreType.htmlWidget,
              ),
            ),
          );

          cubit.coreType = ReaderCoreType.htmlWidget;

          await cubit.close();
        },
      );

      test(
        'should preserve other preference values when changing coreType',
        () async {
          final ReaderCubit cubit = ReaderCubit(
            mockGetPreferenceUseCase,
            (_) => ReaderCubitDependencies(
              null,
              null,
              MockReaderCoreRepository(),
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              mockSavePreferenceUseCase,
              MockReaderObservePreferenceChangeUseCase(),
              null,
              null,
            ),
            null,
          );

          // Initialize with custom preferences
          final ReaderPreferenceData initialPreference =
              const ReaderPreferenceData(
                fontSize: 18.0,
                lineHeight: 1.8,
                isAutoSaving: true,
                isSmoothScroll: true,
                coreType: ReaderCoreType.htmlWidget,
              );

          when(() => mockGetPreferenceUseCase.call())
              .thenAnswer((_) async => initialPreference);

          await cubit.init(bookIdentifier: 'test-book');

          expect(
            cubit.stream,
            emits(
              predicate<ReaderState>(
                (ReaderState state) =>
                    state.readerPreference.fontSize == 18.0 &&
                    state.readerPreference.lineHeight == 1.8 &&
                    state.readerPreference.isAutoSaving == true &&
                    state.readerPreference.isSmoothScroll == true &&
                    state.readerPreference.coreType ==
                        ReaderCoreType.webView,
              ),
            ),
          );

          cubit.coreType = ReaderCoreType.webView;

          await cubit.close();
        },
      );
    });

    group('savePreference', () {
      test('should call save preference use case with current state', () async {
        final ReaderCubit cubit = ReaderCubit(
          mockGetPreferenceUseCase,
          (_) => ReaderCubitDependencies(
            null,
            null,
            MockReaderCoreRepository(),
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            mockSavePreferenceUseCase,
            MockReaderObservePreferenceChangeUseCase(),
            null,
            null,
          ),
          null,
        );

        await cubit.init(bookIdentifier: 'test-book');

        cubit.coreType = ReaderCoreType.webView;
        cubit.savePreference();

        verify(() => mockSavePreferenceUseCase(any)).called(1);

        await cubit.close();
      });

      test('should persist coreType change to storage', () async {
        final ReaderCubit cubit = ReaderCubit(
          mockGetPreferenceUseCase,
          (_) => ReaderCubitDependencies(
            null,
            null,
            MockReaderCoreRepository(),
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            mockSavePreferenceUseCase,
            MockReaderObservePreferenceChangeUseCase(),
            null,
            null,
          ),
          null,
        );

        await cubit.init(bookIdentifier: 'test-book');

        cubit.coreType = ReaderCoreType.webView;
        cubit.savePreference();

        // Verify that savePreferenceUseCase was called with a preference
        // that has coreType set to webView
        final dynamic capturedArg = verify(
          () => mockSavePreferenceUseCase(
            captureAny(),
          ),
        ).captured.single;

        expect(
          capturedArg.coreType,
          equals(ReaderCoreType.webView),
        );

        await cubit.close();
      });
    });
  });
}
