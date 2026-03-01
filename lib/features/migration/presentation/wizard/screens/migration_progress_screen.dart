import 'package:flutter/material.dart';

import '../../../domain/use_cases/migration_progress.dart';

/// Progress screen of the migration wizard (Screen 3).
///
/// Presented as a full-screen, non-dismissible modal. Shows:
/// - Animated progress bar (0-100%)
/// - Current step label (updates in real-time)
/// - Books progress counter (e.g., "Book 4 of 12")
/// - Estimated time remaining (if determinable)
///
/// Error states:
/// - Show error message
/// - "Retry" button to resume from last step
///
/// Low storage states:
/// - Show message: "Please free up space and tap Retry"
class MigrationProgressScreen extends StatefulWidget {
  /// Creates a MigrationProgressScreen.
  ///
  /// [progress] - current migration progress
  /// [onRetry] - callback when user taps "Retry" (after error)
  /// [error] - error exception if present
  const MigrationProgressScreen({
    required this.progress,
    required this.onRetry,
    this.error,
    Key? key,
  }) : super(key: key);

  /// Current migration progress.
  final MigrationProgress progress;

  /// Callback when "Retry" button is tapped after error.
  final VoidCallback onRetry;

  /// Error exception if migration failed, otherwise null.
  final Exception? error;

  @override
  State<MigrationProgressScreen> createState() =>
      _MigrationProgressScreenState();
}

class _MigrationProgressScreenState extends State<MigrationProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.progressPercent / 100.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(MigrationProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.progressPercent !=
        widget.progress.progressPercent) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress.progressPercent / 100.0,
        end: widget.progress.progressPercent / 100.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    if (hasError) {
      return _buildErrorState(context);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upgrading your library',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                widget.progress.currentLabel,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Book ${widget.progress.processedBooks} of '
                '${widget.progress.totalBooks}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.error?.toString() ??
                    'An error occurred during migration',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
