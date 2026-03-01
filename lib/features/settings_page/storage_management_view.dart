import 'package:flutter/material.dart';

/// View for managing cloud and local storage.
///
/// Displays storage breakdown by total local, total cloud, per-book details.
/// Allows sorting, bulk eviction, and sync settings configuration.
class StorageManagementView extends StatefulWidget {
  const StorageManagementView({Key? key}) : super(key: key);

  @override
  State<StorageManagementView> createState() => _StorageManagementViewState();
}

class _StorageManagementViewState extends State<StorageManagementView> {
  // Sorting option
  String _sortBy = 'size'; // size, status, name, lastSyncedAt
  bool _autoSync = true;
  int _heartbeatMinutes = 5;
  bool _wifiOnly = false;
  int _versionRetention = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Storage Management')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Storage breakdown
            _buildStorageBreakdown(),

            Divider(),

            // Per-book storage list
            _buildBookStorageList(),

            Divider(),

            // Sync settings
            _buildSyncSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBreakdown() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Storage Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.folder),
            title: Text('Local Storage'),
            subtitle: Text('2.5 GB'),
          ),
          ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Cloud Storage'),
            subtitle: Text('3.2 GB'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookStorageList() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Books',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButton<String>(
                value: _sortBy,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'size', child: Text('Size')),
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'lastSyncedAt', child: Text('Last Synced')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _sortBy = value ?? 'size';
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          // Placeholder for book list
          Container(
            height: 200,
            color: Colors.grey[100],
            child: Center(
              child: Text('Book list will be sorted by: $_sortBy'),
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // Bulk eviction
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Eviction not yet implemented')),
              );
            },
            icon: Icon(Icons.delete),
            label: Text('Evict Selected Local Copies'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettings() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Sync Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          SwitchListTile(
            title: Text('Auto-Sync'),
            subtitle: Text('Automatically sync changes to cloud'),
            value: _autoSync,
            onChanged: (bool value) {
              setState(() {
                _autoSync = value;
              });
            },
          ),
          ListTile(
            title: Text('Heartbeat Interval'),
            subtitle: Text('$_heartbeatMinutes minutes'),
            trailing: DropdownButton<int>(
              value: _heartbeatMinutes,
              items: <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 1, child: Text('1 min')),
                DropdownMenuItem(value: 5, child: Text('5 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
              ],
              onChanged: (int? value) {
                setState(() {
                  _heartbeatMinutes = value ?? 5;
                });
              },
            ),
          ),
          SwitchListTile(
            title: Text('WiFi Only'),
            subtitle: Text('Only sync on WiFi connections'),
            value: _wifiOnly,
            onChanged: (bool value) {
              setState(() {
                _wifiOnly = value;
              });
            },
          ),
          ListTile(
            title: Text('Version Retention'),
            subtitle: Text('Keep last $_versionRetention versions'),
            trailing: DropdownButton<int>(
              value: _versionRetention,
              items: <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 5, child: Text('5')),
              ],
              onChanged: (int? value) {
                setState(() {
                  _versionRetention = value ?? 3;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
