import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';

/// Repository interface for managing the cloud index registry.
///
/// The cloud index is the source of truth for all synced books across devices.
/// It maps bookIds to their cloud locations and synchronization metadata.
/// This repository handles reading and writing the index with graceful
/// fallback and merge semantics.
abstract class CloudIndexRepository {
  /// Retrieves the latest cloud index.
  ///
  /// Attempts to fetch the latest version from cloud storage with a timeout.
  /// If offline or timeout occurs, falls back to the local cached copy.
  /// On app launch, automatically compares local vs cloud and updates
  /// local if cloud version is newer.
  ///
  /// Always returns a valid CloudIndex (never null). Graceful degradation
  /// ensures the app continues working even if cloud is unavailable.
  ///
  /// Returns:
  ///   The latest CloudIndex. If cloud is unreachable, returns the local
  ///   cached version. If both are unavailable, returns an empty index.
  Future<CloudIndex> getIndex();

  /// Updates the cloud index.
  ///
  /// Writes the index locally immediately (optimistic update) and queues
  /// the upload to cloud asynchronously. If the cloud upload fails, the
  /// error is logged but does not crash the app. The local version remains
  /// valid and will be retried on next sync opportunity.
  ///
  /// This ensures the app remains responsive and functional even if cloud
  /// is temporarily unavailable.
  ///
  /// Parameters:
  ///   index: The new CloudIndex to persist.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> updateIndex(CloudIndex index);

  /// Retrieves a specific book entry from the index by bookId.
  ///
  /// Convenience method that calls [getIndex] and extracts the entry.
  /// Returns null if the bookId is not found or has been deleted.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to retrieve.
  ///
  /// Returns:
  ///   The IndexEntry if found and active, null otherwise.
  Future<IndexEntry?> getEntry(String bookId);

  /// Updates a single entry in the index.
  ///
  /// Convenience method that fetches the current index, updates the entry,
  /// and persists the updated index. Maintains consistency with [updateIndex].
  ///
  /// Parameters:
  ///   entry: The IndexEntry to add or update.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> updateEntry(IndexEntry entry);
}
