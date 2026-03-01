import 'package:novel_glide/features/cloud/domain/entities/book_cloud_metadata.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';

/// Resolver for cloud sync conflicts.
///
/// Handles deterministic and user-prompted resolution of conflicts
/// between local and cloud versions across three layers:
/// - Index conflicts: union with newer timestamp wins
/// - Metadata conflicts: smart merge with user prompt for major differences
/// - Book file conflicts: user choice between versions
abstract class ConflictResolver {
  /// Resolves conflicts between two index versions.
  ///
  /// Strategy: Union of entries, newer lastSyncedAt wins
  /// Always deterministic, never requires user input.
  CloudIndex resolveIndexConflict(CloudIndex local, CloudIndex cloud);

  /// Resolves metadata conflicts.
  ///
  /// Auto bookmarks: last-write-wins (silent)
  /// Manual bookmarks: union (merge)
  /// Reading position: prompts if > 5 pages different
  Future<BookCloudMetadata?> resolveMetadataConflict(
    BookCloudMetadata local,
    BookCloudMetadata cloud, {
    int pageThreshold = 5,
  });

  /// Resolves book file conflicts.
  ///
  /// Prompts user to choose between local and cloud versions.
  Future<ConflictDecision> resolveBookConflict(
    String localHash,
    String cloudHash,
  );
}

/// Decision for conflict resolution.
enum ConflictDecision {
  keepLocal,
  keepCloud,
  archive,
}

/// Prompt for user to resolve conflict.
class ConflictPrompt {
  ConflictPrompt({
    required this.bookId,
    required this.type,
    required this.localValue,
    required this.cloudValue,
    required this.message,
  });

  final String bookId;
  final String type; // 'position', 'bookmark', 'file'
  final String localValue;
  final String cloudValue;
  final String message;
}
