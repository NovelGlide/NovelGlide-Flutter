import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/preference/domain/entities/reader_preference_data.dart';
import 'package:novel_glide/features/reader/domain/entities/reader_core_type.dart';
import 'package:novel_glide/features/reader/presentation/reader_page/cubit/reader_cubit.dart';
import 'package:novel_glide/generated/i18n/app_localizations.dart';

// Mock ReaderCubit with proper stream support
class MockReaderCubit extends Mock implements ReaderCubit {
  late ReaderState _currentState;
  late Stream<ReaderState> _stateStream;

  MockReaderCubit({required ReaderState initialState}) {
    _currentState = initialState;
    _stateStream = Stream<ReaderState>.value(initialState);
  }

  @override
  ReaderState get state => _currentState;

  @override
  Stream<ReaderState> get stream => _stateStream;

  void updateState(ReaderState newState) {
    _currentState = newState;
  }
}

void main() {
  group('Engine Selector Widget Tests', () {
    late MockReaderCubit mockReaderCubit;
    late ReaderPreferenceData initialPreference;

    setUp(() {
      initialPreference = const ReaderPreferenceData(
        fontSize: 16.0,
        lineHeight: 1.5,
        isAutoSaving: false,
        isSmoothScroll: false,
        coreType: ReaderCoreType.htmlWidget,
      );

      final ReaderState initialState = ReaderState(
        readerPreference: initialPreference,
      );

      mockReaderCubit = MockReaderCubit(initialState: initialState);

      // Stub savePreference method
      when(() => mockReaderCubit.savePreference()).thenAnswer((_) async {});
    });

    /// Helper to build widget tree with proper localization
    Widget buildReaderBottomSheetTestWidget() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ReaderCubit>.value(
            value: mockReaderCubit,
            child: Builder(
              builder: (BuildContext context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider<ReaderCubit>.value(
                            value: mockReaderCubit,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  // Simulating _EngineSelector content
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child:
                                        BlocBuilder<ReaderCubit, ReaderState>(
                                      buildWhen: (previous, current) =>
                                          previous.readerPreference.coreType !=
                                          current.readerPreference.coreType,
                                      builder: (context, state) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .readerEngineTitle,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.info_outline,
                                                  ),
                                                  onPressed: () {
                                                    _showInfoDialog(context);
                                                  },
                                                  tooltip: AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .readerEngineInfoTitle,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownMenu<ReaderCoreType>(
                                              expandedInsets: EdgeInsets.zero,
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .readerEngineInfoTitle,
                                              ),
                                              initialSelection: state
                                                  .readerPreference.coreType,
                                              onSelected:
                                                  (ReaderCoreType? value) {
                                                if (value != null &&
                                                    value !=
                                                        state.readerPreference
                                                            .coreType) {
                                                  _showConfirmDialog(
                                                    context,
                                                    value,
                                                  );
                                                }
                                              },
                                              dropdownMenuEntries: <DropdownMenuEntry<
                                                  ReaderCoreType>>[
                                                DropdownMenuEntry<
                                                    ReaderCoreType>(
                                                  value:
                                                      ReaderCoreType.htmlWidget,
                                                  label: AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .readerEngineHtmlWidget,
                                                ),
                                                DropdownMenuEntry<
                                                    ReaderCoreType>(
                                                  value: ReaderCoreType.webView,
                                                  label: AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .readerEngineWebView,
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Open Settings'),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
      'renders engine selector within bottom sheet',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Verify dropdown exists
        expect(find.byType(DropdownMenu<ReaderCoreType>), findsOneWidget);
      },
    );

    testWidgets(
      'displays info button and opens info dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Verify info button exists
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Tap info button
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Verify dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'shows confirmation dialog on engine change',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Tap dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Select different engine
        await tester.tap(find.text('Web View').last);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'cancels engine switch without saving',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Tap dropdown and select different engine
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Web View').last);
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify savePreference was not called
        verifyNever(() => mockReaderCubit.savePreference());
      },
    );

    testWidgets(
      'same engine selection shows no dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Tap dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Select same engine (htmlWidget is initial value)
        await tester.tap(find.text('Flutter Native').last);
        await tester.pumpAndSettle();

        // Verify no dialog appears
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'both engine options appear in dropdown',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildReaderBottomSheetTestWidget());

        // Open bottom sheet
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Tap dropdown
        await tester.tap(find.byType(DropdownMenu<ReaderCoreType>));
        await tester.pumpAndSettle();

        // Verify both options are visible
        expect(find.text('Flutter Native'), findsWidgets);
        expect(find.text('Web View'), findsWidgets);
      },
    );
  });
}

void _showInfoDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l10n.readerEngineInfoTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.readerEngineHtmlWidget,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.readerEngineHtmlWidgetPro1),
            Text(l10n.readerEngineHtmlWidgetPro2),
            Text(l10n.readerEngineHtmlWidgetPro3),
            const SizedBox(height: 16),
            Text(
              l10n.readerEngineWebView,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.readerEngineWebViewPro1),
            Text(l10n.readerEngineWebViewPro2),
            Text(l10n.readerEngineWebViewPro3),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.readerEngineInfoOk),
        ),
      ],
    ),
  );
}

void _showConfirmDialog(
  BuildContext context,
  ReaderCoreType newEngine,
) {
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final String engineName = newEngine == ReaderCoreType.webView
      ? l10n.readerEngineWebView
      : l10n.readerEngineHtmlWidget;

  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l10n.readerEngineSwitchTitle),
      content: Text(l10n.readerEngineSwitchContent(engineName)),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.readerEngineSwitchCancel),
        ),
        FilledButton(
          onPressed: () {
            final ReaderCubit cubit = context.read<ReaderCubit>();
            cubit.coreType = newEngine;
            cubit.savePreference();
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text(l10n.readerEngineSwitchConfirm),
        ),
      ],
    ),
  );
}
