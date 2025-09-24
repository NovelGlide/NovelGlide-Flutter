import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../generated/i18n/app_localizations.dart';
import '../../../../enum/window_size.dart';
import '../../../../main.dart';
import '../../../advertisement/domain/entities/ad_unit_id.dart';
import '../../../advertisement/presentation/advertisement.dart';
import '../../../books/domain/entities/book.dart';
import '../../../shared_components/common_loading_widgets/common_loading_widget.dart';
import '../../domain/entities/reader_destination_type.dart';
import '../../domain/entities/reader_navigation_state_code.dart';
import '../../domain/entities/reader_page_num_type.dart';
import '../search_page/widgets/reader_search_button.dart';
import 'core_webview/reader_core_webview.dart';
import 'cubit/reader_cubit.dart';
import 'cubit/reader_tts_cubit.dart';
import 'cubit/reader_tts_state.dart';
import 'widgets/nav/default/reader_nav_bookmark_button.dart';
import 'widgets/nav/default/reader_nav_next_button.dart';
import 'widgets/nav/default/reader_nav_previous_button.dart';
import 'widgets/nav/default/reader_nav_settings_button.dart';
import 'widgets/nav/tts/reader_tts_close_button.dart';
import 'widgets/nav/tts/reader_tts_play_pause_button.dart';
import 'widgets/nav/tts/reader_tts_settings_button.dart';
import 'widgets/nav/tts/reader_tts_stop_button.dart';

part 'widgets/nav/default/reader_nav_tts_button.dart';
part 'widgets/nav/navigation_bar.dart';
part 'widgets/nav/navigation_rail.dart';
part 'widgets/reader_app_bar.dart';
part 'widgets/reader_breadcrumb.dart';
part 'widgets/reader_loading_widget.dart';
part 'widgets/reader_overlap_widget.dart';
part 'widgets/reader_pagination.dart';
part 'widgets/reader_scaffold.dart';
part 'widgets/reader_scaffold_body.dart';

class ReaderWidget extends StatelessWidget {
  const ReaderWidget({
    super.key,
    required this.bookIdentifier,
    this.bookData,
    this.destinationType = ReaderDestinationType.none,
    this.destination,
  });

  final String bookIdentifier;
  final Book? bookData;
  final ReaderDestinationType destinationType;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = sl<ReaderCubit>();
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ReaderCubit>(
          create: (_) => cubit
            ..initAsync(
              bookData: bookData,
              bookIdentifier: bookIdentifier,
              currentTheme: Theme.of(context),
              destinationType: destinationType,
              destination: destination,
            ),
        ),
        BlocProvider<ReaderTtsCubit>(
          create: (_) => cubit.ttsCubit..startLoading(),
        )
      ],
      child: const ReaderScaffold(),
    );
  }
}
