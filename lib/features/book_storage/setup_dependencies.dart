import 'package:novel_glide/core/file_system/domain/repositories/file_system_repository.dart';
import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/book_storage/data/repositories/cloud_book_storage.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:novel_glide/main.dart';

/// Sets up dependency injection for the book_storage feature.
///
/// This function must be called during app initialization, after core
/// dependencies (AppPathProvider, FileSystemRepository, JsonRepository,
/// CloudRepository) are registered but before any feature that depends on
/// book_storage.
///
/// Registers both [LocalBookStorage] and [CloudBookStorage] as lazy
/// singletons so they can coexist in the DI container. Callers choose
/// which implementation to use based on their storage backend preference:
/// - Use [LocalBookStorage] for reading/writing to device filesystem
/// - Use [CloudBookStorage] for reading/writing to Google Drive
///
/// Both implementations share the same [BookStorage] abstract interface,
/// so switching between them is transparent to calling code.
///
/// Example integration in core/setup_dependencies.dart:
/// ```dart
/// void _setupSystemsDependencies() {
///   // ... other features ...
///   setupBookStorageDependencies();
///   // ... other features ...
/// }
/// ```
///
/// Dependencies required (must be registered first):
/// - [AppPathProvider] - for local storage path resolution
/// - [FileSystemRepository] - for local filesystem operations
/// - [JsonRepository] - for local metadata JSON serialization
/// - [CloudRepository] - for cloud storage operations
void setupBookStorageDependencies() {
  LogSystem.info('Setting up book_storage dependencies...');

  sl.registerLazySingleton<LocalBookStorage>(
    () => LocalBookStorage(
      appPathProvider: sl<AppPathProvider>(),
      fileSystemRepository: sl<FileSystemRepository>(),
      jsonRepository: sl<JsonRepository>(),
    ),
  );
  LogSystem.info('Registered LocalBookStorage');

  sl.registerLazySingleton<CloudBookStorage>(
    () => CloudBookStorage(
      cloudRepository: sl<CloudRepository>(),
    ),
  );
  LogSystem.info('Registered CloudBookStorage');

  LogSystem.info('book_storage dependencies setup complete');
}
