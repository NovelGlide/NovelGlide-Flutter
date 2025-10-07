import '../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../core/mime_resolver/domain/repositories/mime_repository.dart';
import '../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../main.dart';
import '../bookmark/domain/use_cases/bookmark_get_data_use_case.dart';
import '../bookmark/domain/use_cases/bookmark_observe_change_use_case.dart';
import '../bookmark/domain/use_cases/bookmark_reset_use_case.dart';
import '../collection/domain/use_cases/collection_delete_all_books_use_case.dart';
import '../download_manager/domain/use_cases/downloader_download_file_use_case.dart';
import '../pick_file/domain/repositories/pick_file_repository.dart';
import '../pick_file/domain/use_cases/pick_file_clear_temp_use_case.dart';
import '../preference/domain/repositories/preference_repository.dart';
import '../preference/domain/use_cases/preference_get_use_cases.dart';
import '../preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../preference/domain/use_cases/preference_reset_use_case.dart';
import '../preference/domain/use_cases/preference_save_use_case.dart';
import '../reader/domain/use_cases/location_cache_use_cases/reader_clear_location_cache_use_case.dart';
import '../reader/domain/use_cases/location_cache_use_cases/reader_delete_location_cache_use_case.dart';
import 'data/data_sources/epub_data_source.dart';
import 'data/repositories/book_repository_impl.dart';
import 'domain/repositories/book_repository.dart';
import 'domain/use_cases/book_add_use_case.dart';
import 'domain/use_cases/book_delete_use_case.dart';
import 'domain/use_cases/book_download_and_add_use_case.dart';
import 'domain/use_cases/book_exists_use_case.dart';
import 'domain/use_cases/book_get_allowed_extensions_use_case.dart';
import 'domain/use_cases/book_get_chapter_list_use_case.dart';
import 'domain/use_cases/book_get_cover_use_case.dart';
import 'domain/use_cases/book_get_list_by_identifiers_use_case.dart';
import 'domain/use_cases/book_get_list_use_case.dart';
import 'domain/use_cases/book_get_use_case.dart';
import 'domain/use_cases/book_observe_change_use_case.dart';
import 'domain/use_cases/book_pick_use_case.dart';
import 'domain/use_cases/book_reset_use_case.dart';
import 'presentation/add_page/cubit/book_add_cubit.dart';
import 'presentation/book_list/cubit/book_list_cubit.dart';
import 'presentation/table_of_contents_page/cubit/toc_cubit.dart';

void setupBookDependencies() {
  /// Register repositories
  sl.registerLazySingleton<BookRepository>(
    () => BookRepositoryImpl(
      EpubDataSource(),
      sl<AppPathProvider>(),
      sl<FileSystemRepository>(),
      sl<PickFileRepository>(),
      sl<MimeRepository>(),
    ),
  );

  /// Register book management use cases
  sl.registerFactory<BookAddUseCase>(
    () => BookAddUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookExistsUseCase>(
    () => BookExistsUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookDeleteUseCase>(
    () => BookDeleteUseCase(
      sl<BookRepository>(),
      sl<ReaderDeleteLocationCacheUseCase>(),
    ),
  );
  sl.registerFactory<BookGetAllowedExtensionsUseCase>(
    () => BookGetAllowedExtensionsUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookGetListByIdentifiersUseCase>(
    () => BookGetListByIdentifiersUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookGetListUseCase>(
    () => BookGetListUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookGetUseCase>(
    () => BookGetUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookObserveChangeUseCase>(
    () => BookObserveChangeUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookPickUseCase>(
    () => BookPickUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookGetCoverUseCase>(
    () => BookGetCoverUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookGetChapterListUseCase>(
    () => BookGetChapterListUseCase(
      sl<BookRepository>(),
    ),
  );
  sl.registerFactory<BookResetUseCase>(
    () => BookResetUseCase(
      sl<BookRepository>(),
      sl<BookmarkResetUseCase>(),
      sl<CollectionDeleteAllBooksUseCase>(),
      sl<ReaderClearLocationCacheUseCase>(),
    ),
  );
  sl.registerFactory<BookDownloadAndAddUseCase>(
    () => BookDownloadAndAddUseCase(
      sl<DownloaderDownloadFileUseCase>(),
      sl<BookAddUseCase>(),
    ),
  );

  /// Register bookshelf preference use cases
  sl.registerFactory<BookshelfGetPreferenceUseCase>(
    () => BookshelfGetPreferenceUseCase(
      sl<BookshelfPreferenceRepository>(),
    ),
  );
  sl.registerFactory<BookshelfSavePreferenceUseCase>(
    () => BookshelfSavePreferenceUseCase(
      sl<BookshelfPreferenceRepository>(),
    ),
  );
  sl.registerFactory<BookshelfResetPreferenceUseCase>(
    () => BookshelfResetPreferenceUseCase(
      sl<BookshelfPreferenceRepository>(),
    ),
  );
  sl.registerFactory<BookshelfObserveChangeUseCase>(
    () => BookshelfObserveChangeUseCase(
      sl<BookshelfPreferenceRepository>(),
    ),
  );

  /// Cubit factories
  sl.registerFactory<BookListCubit>(
    () => BookListCubit(
      // Book managements use cases
      sl<BookGetListUseCase>(),
      sl<BookDeleteUseCase>(),
      sl<BookObserveChangeUseCase>(),
      sl<BookExistsUseCase>(),
      sl<BookGetCoverUseCase>(),
      // Bookshelf preferences use cases
      sl<BookshelfGetPreferenceUseCase>(),
      sl<BookshelfSavePreferenceUseCase>(),
      sl<BookshelfObserveChangeUseCase>(),
    ),
  );
  sl.registerFactory<BookAddCubit>(
    () => BookAddCubit(
      sl<BookAddUseCase>(),
      sl<BookGetAllowedExtensionsUseCase>(),
      sl<BookPickUseCase>(),
      sl<PickFileClearTempUseCase>(),
    ),
  );
  sl.registerFactory<TocCubit>(
    () => TocCubit(
      sl<BookGetChapterListUseCase>(),
      sl<BookmarkGetDataUseCase>(),
      sl<BookmarkObserveChangeUseCase>(),
    ),
  );
}
