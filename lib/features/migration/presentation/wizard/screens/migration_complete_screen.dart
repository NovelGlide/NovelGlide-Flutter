import 'package:flutter/material.dart';

/// Completion screen of the migration wizard (Screen 4).
///
/// Presented as a full-screen, non-dismissible modal. Shows:
/// - Success heading: "Your library is ready"
/// - Confirmation message
/// - If skipped books: count and link to details
///
/// Actions:
/// - "Continue" button → close wizard and return to main app
class MigrationCompleteScreen extends StatelessWidget {
  /// Creates a MigrationCompleteScreen.
  ///
  /// [onContinue] - callback when user taps "Continue"
  /// [skippedBooksCount] - number of books that failed to migrate
  /// [onViewSkipped] - callback to view details of skipped books
  const MigrationCompleteScreen({
    required this.onContinue,
    this.skippedBooksCount = 0,
    this.onViewSkipped,
    Key? key,
  }) : super(key: key);

  /// Callback when "Continue" button is tapped.
  final VoidCallback onContinue;

  /// Number of books that could not be migrated.
  final int skippedBooksCount;

  /// Callback to view details of skipped books (optional).
  /// If null, the link is not shown.
  final VoidCallback? onViewSkipped;

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Your library is ready',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your books have been organized into the new structure '
                        'and are ready to use.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (skippedBooksCount > 0) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$skippedBooksCount book'
                                '${skippedBooksCount == 1 ? '' : 's'} '
                                'couldn\'t be migrated',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              if (onViewSkipped != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: onViewSkipped,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'View details',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
