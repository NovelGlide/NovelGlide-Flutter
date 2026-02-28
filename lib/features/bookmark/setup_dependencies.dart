import 'package:get_it/get_it.dart';

import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/bookmark/data/repositories/bookmark_cache_repository_impl.dart';
import 'package:novel_glide/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_cache_repository.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_add_use_case.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_delete_use_case.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_get_by_id_use_case.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_get_list_use_case.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_observe_change_use_case.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_rebuild_cache_use_case.dart';

/// Sets up dependency injection for the bookmark feature.
///
/// **Important:** Must be called after
/// [setupBookStorageDependencies], as the bookmark system depends
/// on [LocalBookStorage] being registered.
void setupBookmarkDependencies() {
  final GetIt getIt = GetIt.instance;

  // Register BookmarkCacheRepository as lazy singleton
  getIt.registerLazySingleton<
      BookmarkCacheRepository>(
    () => BookmarkCacheRepositoryImpl(
      localBookStorage: getIt<LocalBookStorage>(),
      jsonRepository: getIt.get(),
      appPathProvider: getIt.get(),
    ),
  );

  // Register BookmarkRepository as lazy singleton
  getIt.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(
      bookmarkCacheRepository:
          getIt<BookmarkCacheRepository>(),
      localBookStorage: getIt<LocalBookStorage>(),
    ),
  );

  // Register use cases as factories (new instance each time)
  getIt.registerFactory<
      BookmarkGetListUseCase>(
    () => BookmarkGetListUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );

  getIt.registerFactory<
      BookmarkGetByIdUseCase>(
    () => BookmarkGetByIdUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );

  getIt.registerFactory<
      BookmarkAddUseCase>(
    () => BookmarkAddUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );

  getIt.registerFactory<
      BookmarkDeleteUseCase>(
    () => BookmarkDeleteUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );

  getIt.registerFactory<
      BookmarkObserveChangeUseCase>(
    () => BookmarkObserveChangeUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );

  getIt.registerFactory<
      BookmarkRebuildCacheUseCase>(
    () => BookmarkRebuildCacheUseCase(
      bookmarkRepository:
          getIt<BookmarkRepository>(),
    ),
  );
}
