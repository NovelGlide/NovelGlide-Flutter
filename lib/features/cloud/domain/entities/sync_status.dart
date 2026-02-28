/// Enumeration of all possible synchronization states for a book.
///
/// Each status represents a distinct phase in the cloud sync lifecycle.
/// Values are used to determine UI display (icon, color, label) and
/// to guide sync orchestration logic.
enum SyncStatus {
  /// Book is in sync with cloud. No pending changes.
  synced,

  /// Changes pending upload to cloud.
  pending,

  /// Active upload/download to cloud in progress.
  syncing,

  /// Last sync operation failed. Manual retry may be needed.
  error,

  /// Local and cloud versions have diverged. User intervention
  /// required to resolve which version to keep.
  conflict,

  /// Book exists only on cloud, not downloaded locally yet.
  cloudOnly,

  /// Book exists only locally, not uploaded to cloud yet.
  /// User opted to keep this book local-only.
  localOnly,
}

/// Extension providing UI properties for sync statuses.
extension SyncStatusDisplay on SyncStatus {
  /// Returns an emoji icon representing this sync status.
  ///
  /// Used in UI components to visually indicate sync state at a glance.
  String get icon {
    return switch (this) {
      SyncStatus.synced => '✅',
      SyncStatus.pending => '⏳',
      SyncStatus.syncing => '🔄',
      SyncStatus.error => '❌',
      SyncStatus.conflict => '⚠️',
      SyncStatus.cloudOnly => '☁️',
      SyncStatus.localOnly => '🔒',
    };
  }

  /// Returns a hex color code for visual differentiation.
  ///
  /// Color scheme:
  /// - Green (#4CAF50): synced
  /// - Blue (#2196F3): pending, syncing, cloudOnly
  /// - Orange (#FF9800): pending (secondary)
  /// - Red (#F44336): error, conflict
  /// - Gray (#9E9E9E): localOnly
  String get colorHex {
    return switch (this) {
      SyncStatus.synced => '#4CAF50',
      SyncStatus.pending => '#FF9800',
      SyncStatus.syncing => '#2196F3',
      SyncStatus.error => '#F44336',
      SyncStatus.conflict => '#F44336',
      SyncStatus.cloudOnly => '#2196F3',
      SyncStatus.localOnly => '#9E9E9E',
    };
  }

  /// Returns a human-readable label for this sync status.
  ///
  /// Used in UI tooltips and status messages.
  String get label {
    return switch (this) {
      SyncStatus.synced => 'Synced',
      SyncStatus.pending => 'Pending',
      SyncStatus.syncing => 'Syncing',
      SyncStatus.error => 'Error',
      SyncStatus.conflict => 'Conflict',
      SyncStatus.cloudOnly => 'Cloud Only',
      SyncStatus.localOnly => 'Local Only',
    };
  }

  /// Returns a detailed status message for user-facing tooltips.
  String get statusMessage {
    return switch (this) {
      SyncStatus.synced =>
        'Your book is synced to the cloud. Changes will sync '
            'automatically.',
      SyncStatus.pending => 'Changes are queued for sync to the cloud.',
      SyncStatus.syncing => 'Syncing to the cloud...',
      SyncStatus.error =>
        'Sync failed. Tap to retry, or check your connection.',
      SyncStatus.conflict => 'Local and cloud versions differ. Tap to resolve.',
      SyncStatus.cloudOnly => 'Book is on the cloud. Tap to download locally.',
      SyncStatus.localOnly =>
        'This book is local-only and won\'t sync to the cloud.',
    };
  }
}
