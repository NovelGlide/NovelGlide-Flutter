import 'package:flutter/material.dart';
import 'package:novel_glide/features/cloud/domain/repositories/book_cloud_sync_repository.dart';

/// Widget displaying sync status overlay for a book tile.
///
/// Shows visual indicators (icons, colors, animations) for the current
/// sync state of a book. Includes tap handlers for user actions.
class BookTileSyncStatusWidget extends StatelessWidget {
  const BookTileSyncStatusWidget({
    Key? key,
    required this.syncStatus,
    this.onRetryError,
    this.onDownload,
    this.onResolveConflict,
    this.onShowDetails,
  }) : super(key: key);

  final SyncStatus syncStatus;
  final VoidCallback? onRetryError;
  final VoidCallback? onDownload;
  final VoidCallback? onResolveConflict;
  final VoidCallback? onShowDetails;

  String _getIcon() {
    switch (syncStatus) {
      case SyncStatus.cloudOnly:
        return '☁️';
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.pending:
        return '⏳';
      case SyncStatus.conflict:
        return '⚠️';
      case SyncStatus.error:
        return '❌';
      case SyncStatus.localOnly:
        return '🔒';
    }
  }

  Color _getColor() {
    switch (syncStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.cloudOnly:
      case SyncStatus.pending:
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.error:
      case SyncStatus.conflict:
        return Colors.red;
      case SyncStatus.localOnly:
        return Colors.grey;
    }
  }

  String _getLabel() => syncStatus.toString().split('.').last;

  VoidCallback? _getTapHandler() {
    switch (syncStatus) {
      case SyncStatus.error:
        return onRetryError;
      case SyncStatus.cloudOnly:
        return onDownload;
      case SyncStatus.conflict:
        return onResolveConflict;
      default:
        return onShowDetails;
    }
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback? handler = _getTapHandler();

    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: handler,
        onLongPress: () {
          // Show tooltip on long press
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset position = box.localToGlobal(Offset.zero);

          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('Sync Status'),
              content: Text(_getLabel()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getColor().withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: syncStatus == SyncStatus.syncing
                ? _buildRotatingIcon()
                : Text(
                    _getIcon(),
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotatingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159),
      duration: Duration(seconds: 2),
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.rotate(
          angle: value,
          child: Text(_getIcon(), style: TextStyle(fontSize: 18)),
        );
      },
    );
  }
}
