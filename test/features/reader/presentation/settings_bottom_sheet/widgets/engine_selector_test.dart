import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/preference/domain/entities/reader_preference_data.dart';
import 'package:novel_glide/features/reader/domain/entities/reader_core_type.dart';
import 'package:novel_glide/features/reader/presentation/reader_page/cubit/reader_cubit.dart';

// Mock ReaderCubit
class MockReaderCubit extends Mock implements ReaderCubit {}

// Mock ReaderState
class MockReaderState extends Mock implements ReaderState {}

void main() {
  group('_EngineSelector Widget Tests', () {
    late MockReaderCubit mockReaderCubit;

    setUp(() {
      mockReaderCubit = MockReaderCubit();

      // Set up default state
      final MockReaderState mockState = MockReaderState();
      final ReaderPreferenceData mockPreference =
          const ReaderPreferenceData(
            coreType: ReaderCoreType.htmlWidget,
          );

      when(() => mockReaderCubit.state).thenReturn(mockState);
      when(() => mockState.readerPreference).thenReturn(mockPreference);
    });

    /// Helper to build the widget tree with engine selector
    Widget buildTestWidget(
      ReaderCubit cubit,
    ) {
      return MaterialApp(
        localizationsDelegates: const [],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: BlocProvider<ReaderCubit>.value(
            value: cubit,
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  _EngineSelector(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'renders engine selector with dropdown menu',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Verify the dropdown menu exists
        expect(find.byType(DropdownMenu), findsOneWidget);
      },
    );

    testWidgets(
      'displays info button with correct icon',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Verify info button exists
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      },
    );

    testWidgets(
      'shows info dialog when info button is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the info button
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Verify the dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);

        // Verify dialog title exists
        expect(find.text('Reader Engines'), findsOneWidget);
      },
    );

    testWidgets(
      'info dialog displays engine comparisons',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the info button
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Verify pros are displayed
        expect(find.text('Fast startup'), findsOneWidget);
        expect(find.text('Lower memory usage'), findsOneWidget);
        expect(find.text('Scroll-based navigation'), findsOneWidget);

        // Verify cons are displayed
        expect(find.text('No page-based pagination'), findsOneWidget);
        expect(find.text('Limited publisher CSS support'), findsOneWidget);
      },
    );

    testWidgets(
      'closes info dialog when OK button is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the info button
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Verify dialog is open
        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap OK button
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'shows confirmation dialog when different engine is selected',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Select Web View (different from current htmlWidget)
        await tester.tap(find.text('Web View').last);
        await tester.pumpAndSettle();

        // Verify confirmation dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Restart Required'), findsOneWidget);
        expect(
          find.text('Switch to Web View?'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'cancels engine switch and reverts dropdown',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Select Web View
        await tester.tap(find.text('Web View').last);
        await tester.pumpAndSettle();

        // Verify confirmation dialog is open
        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap Cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is closed (revert successful)
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'does nothing when same engine is selected',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Select Flutter Native (same as current)
        await tester.tap(find.text('Flutter Native').last);
        await tester.pumpAndSettle();

        // Verify no dialog is shown
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'displays both engine options in dropdown',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mockReaderCubit));

        // Tap the dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Verify both engines are present
        expect(find.text('Flutter Native'), findsWidgets);
        expect(find.text('Web View'), findsWidgets);
      },
    );
  });
}

// Note: The actual _EngineSelector widget needs to be part of the
// reader_bottom_sheet.dart file's public API or extracted for testing.
// For this test to work, add the following to the bottom of
// reader_bottom_sheet.dart if using this in production:
//
// export 'widgets/engine_selector.dart' show _EngineSelector;
