/// Enumeration of events that trigger automatic synchronization.
///
/// These events represent user actions or system states that should
/// automatically initiate cloud sync to keep local and cloud in sync.
enum SyncTriggerEvent {
  /// App was backgrounded by user (app lifecycle event).
  /// Triggers pending sync queue to process.
  appBackgrounded,

  /// User created a new bookmark.
  /// Triggers metadata sync for the affected book.
  bookmarkCreated,

  /// Reading session ended (user closed the book/app).
  /// Triggers metadata sync for reading position update.
  sessionEnded,

  /// Periodic heartbeat timer fired during active reading.
  /// Triggers incremental metadata sync to capture progress.
  heartbeat,

  /// App launched (app lifecycle event).
  /// Triggers comparison of local vs cloud and merge if needed.
  appLaunched,

  /// New book was added to library.
  /// Triggers full book sync (EPUB + metadata).
  bookAdded,
}
