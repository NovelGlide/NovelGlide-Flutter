import '../../core/file_system/domain/repositories/json_repository.dart';
import '../../core/path_provider/domain/repositories/json_path_provider.dart';
import '../../main.dart';
import '../book_storage/data/repositories/local_book_storage.dart';
import '../preference/domain/repositories/preference_repository.dart';
import '../preference/domain/use_cases/preference_get_use_cases.dart';
import '../preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../preference/domain/use_cases/preference_reset_use_case.dart';
import '../preference/domain/use_cases/preference_save_use_case.dart';
import 'data/data_sources/collection_local_json_data_source.dart';
import 'data/data_sources/collection_local_json_data_source_impl.dart';
import 'data/repositories/collection_repository_impl.dart';
import 'domain/repositories/collection_repository.dart';
import 'domain/use_cases/collection_create_data_use_case.dart';
import 'domain/use_cases/collection_delete_all_books_use_case.dart';
import 'domain/use_cases/collection_delete_data_use_case.dart';
import 'domain/use_cases/collection_get_data_use_case.dart';
import 'domain/use_cases/collection_get_list_use_case.dart';
import 'domain/use_cases/collection_observe_change_use_case.dart';
import 'domain/use_cases/collection_reset_use_case.dart';
import 'domain/use_cases/collection_update_data_use_case.dart';
import 'presentation/add_book_page/cubit/collection_add_book_cubit.dart';
import 'presentation/add_dialog/cubit/collection_add_cubit.dart';
import 'presentation/collection_list/cubit/collection_list_cubit.dart';
import 'presentation/collection_viewer/cubit/collection_viewer_cubit.dart';

void setupCollectionDependencies() {
  // Register data sources
  sl.registerLazySingleton<CollectionLocalJsonDataSource>(
      () => CollectionLocalJsonDataSourceImpl(
            sl<JsonPathProvider>(),
            sl<JsonRepository>(),
          ));

  // Register repository
  sl.registerLazySingleton<CollectionRepository>(
      () => CollectionRepositoryImpl(sl<CollectionLocalJsonDataSource>()));

  // Register use cases
  sl.registerFactory<CollectionCreateDataUseCase>(
      () => CollectionCreateDataUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionDeleteAllBooksUseCase>(
      () => CollectionDeleteAllBooksUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionDeleteDataUseCase>(
      () => CollectionDeleteDataUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionGetDataUseCase>(
      () => CollectionGetDataUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionGetListUseCase>(
      () => CollectionGetListUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionObserveChangeUseCase>(
      () => CollectionObserveChangeUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionResetUseCase>(
      () => CollectionResetUseCase(sl<CollectionRepository>()));
  sl.registerFactory<CollectionUpdateDataUseCase>(
      () => CollectionUpdateDataUseCase(sl<CollectionRepository>()));

  // Register preference use cases
  sl.registerFactory<CollectionListGetPreferenceUseCase>(() =>
      CollectionListGetPreferenceUseCase(
          sl<CollectionListPreferenceRepository>()));
  sl.registerFactory<CollectionListSavePreferenceUseCase>(() =>
      CollectionListSavePreferenceUseCase(
          sl<CollectionListPreferenceRepository>()));
  sl.registerFactory<CollectionListObserveChangeUseCase>(() =>
      CollectionListObserveChangeUseCase(
          sl<CollectionListPreferenceRepository>()));
  sl.registerFactory<CollectionListResetPreferenceUseCase>(() =>
      CollectionListResetPreferenceUseCase(
          sl<CollectionListPreferenceRepository>()));

  // Cubit factories
  /// CollectionViewerCubit now uses LocalBookStorage to load books by BookId
  /// instead of BookGetListByIdentifiersUseCase (which expected filenames).
  sl.registerFactory<CollectionViewerCubit>(() => CollectionViewerCubit(
        sl<LocalBookStorage>(),
        sl<CollectionGetDataUseCase>(),
        sl<CollectionUpdateDataUseCase>(),
      ));
  sl.registerFactory<CollectionListCubit>(() => CollectionListCubit(
        sl<CollectionDeleteDataUseCase>(),
        sl<CollectionGetListUseCase>(),
        sl<CollectionObserveChangeUseCase>(),
        sl<CollectionListGetPreferenceUseCase>(),
        sl<CollectionListSavePreferenceUseCase>(),
        sl<CollectionListObserveChangeUseCase>(),
      ));
  sl.registerFactory<CollectionAddBookCubit>(() => CollectionAddBookCubit(
        sl<CollectionGetListUseCase>(),
        sl<CollectionObserveChangeUseCase>(),
        sl<CollectionUpdateDataUseCase>(),
      ));
  sl.registerFactory<CollectionAddCubit>(() => CollectionAddCubit(
        sl<CollectionCreateDataUseCase>(),
      ));
}
