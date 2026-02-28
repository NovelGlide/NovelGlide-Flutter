import 'package:equatable/equatable.dart';

/// Metadata for files and folders on Google Drive.
///
/// This entity encapsulates file/folder information returned from Google Drive API,
/// including identification, content type, and modification timestamps.
class DriveFileMetadata extends Equatable {
  /// Creates a new instance of [DriveFileMetadata].
  const DriveFileMetadata({
    required this.fileId,
    required this.name,
    required this.mimeType,
    required this.modifiedTime,
  });

  /// The unique identifier of the file/folder on Google Drive.
  final String fileId;

  /// The name of the file/folder.
  final String name;

  /// The MIME type of the file/folder.
  /// For folders: 'application/vnd.google-apps.folder'
  /// For other files: standard MIME types (e.g., 'application/pdf', 'text/plain')
  final String mimeType;

  /// The timestamp when the file/folder was last modified.
  final DateTime modifiedTime;

  /// Checks if this metadata represents a folder.
  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';

  /// Checks if this metadata represents a file.
  bool get isFile => !isFolder;

  @override
  List<Object?> get props => <Object?>[
        fileId,
        name,
        mimeType,
        modifiedTime,
      ];
}
