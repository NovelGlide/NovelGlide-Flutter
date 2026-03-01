/// Prompt for cross-device reading continuity.
///
/// When a user opens a book on a device, this prompt suggests resuming
/// from where they left off on another device (if cloud version is newer).
class ContinuityPrompt {
  ContinuityPrompt({
    required this.bookId,
    required this.deviceName,
    required this.position,
    required this.lastReadAt,
    required this.message,
  });

  final String bookId;
  final String deviceName; // e.g., "iPhone", "iPad"
  final String position; // CFI position
  final DateTime lastReadAt;
  final String message; // User-friendly prompt text
}
