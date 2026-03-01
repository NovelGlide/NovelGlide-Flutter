/// Enum representing the migration scenario based on what exists
/// locally and in the cloud.
///
/// The scenario determines which migration steps are executed
/// and how books are handled during the process.
enum MigrationScenario {
  /// Both local Library/ and Library.zip on Drive exist.
  /// Books from both sources will be merged (local preferred if
  /// duplicate).
  localAndCloud,

  /// Only local Library/ folder exists.
  /// No cloud backup to process, only local migration.
  localOnly,

  /// Only Library.zip exists on Drive (clean install).
  /// Cloud backup will be downloaded and processed.
  cloudOnly,

  /// Neither local Library/ nor Library.zip exists.
  /// No migration needed.
  none,
}
