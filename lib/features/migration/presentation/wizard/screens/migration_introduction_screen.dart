import 'package:flutter/material.dart';

/// Introduction screen of the migration wizard (Screen 1).
///
/// Presented as a full-screen, non-dismissible modal. Shows:
/// - Heading: "Your library is getting an upgrade"
/// - Plain-language explanation of migration
/// - Note about bookmarks (some may restore to chapter level)
/// - Estimated time for migration
///
/// Actions:
/// - "Get started" button → proceed to screen 2 (or 3 if no cloud)
/// - "Remind me later" button → defer migration (only if < 3 deferrals)
///   - Hidden if deferral count >= 3
class MigrationIntroductionScreen extends StatelessWidget {
  /// Creates a MigrationIntroductionScreen.
  ///
  /// [onGetStarted] - callback when user taps "Get started"
  /// [onRemindLater] - callback when user taps "Remind me later"
  /// [canDefer] - whether to show "Remind me later" button
  const MigrationIntroductionScreen({
    required this.onGetStarted,
    required this.onRemindLater,
    required this.canDefer,
    Key? key,
  }) : super(key: key);

  /// Callback when "Get started" is tapped.
  final VoidCallback onGetStarted;

  /// Callback when "Remind me later" is tapped.
  final VoidCallback onRemindLater;

  /// Whether to show the "Remind me later" button.
  /// False if deferral count >= 3 (force migration).
  final bool canDefer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Your library is getting an upgrade',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We\'re reorganizing your books into a new structure '
                        'to unlock cloud sync and better performance.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'What this means:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your books stay in the app\n'
                        '• Reading positions and bookmarks are preserved\n'
                        '• Migration takes 2-5 minutes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bookmarks note:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Some bookmarks may be restored to chapter level '
                        'instead of exact position if this information wasn\'t '
                        'available in the backup.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onGetStarted,
                      child: const Text('Get started'),
                    ),
                  ),
                  if (canDefer) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onRemindLater,
                        child: const Text('Remind me later'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
