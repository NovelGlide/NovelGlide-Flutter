import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/preference_service/preference_service.dart';
import '../../features/shared_components/common_delete_dialog.dart';
import '../../features/shared_components/common_loading.dart';
import '../../features/shared_components/common_success_dialog.dart';
import '../../generated/i18n/app_localizations.dart';
import '../../main.dart';
import '../bookmark/domain/use_cases/bookmark_reset_use_case.dart';
import '../books/domain/use_cases/book_reset_use_case.dart';
import '../collection/domain/use_cases/collection_reset_use_case.dart';
import '../collection/presentation/collection_list/cubit/collection_list_cubit.dart';
import '../reader/domain/use_cases/reader_clear_location_cache_use_case.dart';
import '../settings_page/settings_service.dart';

part 'presentation/reset_page.dart';
part 'presentation/reset_service_settings_list_tile.dart';
part 'presentation/widgets/settings_page_cache_card.dart';
part 'presentation/widgets/settings_page_data_card.dart';
part 'presentation/widgets/settings_page_list_tile.dart';
part 'presentation/widgets/settings_page_preference_card.dart';

class ResetService {
  const ResetService();
}
