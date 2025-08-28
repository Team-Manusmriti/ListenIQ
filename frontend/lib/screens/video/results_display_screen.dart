import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listen_iq/screens/video/widgets/detection_overlay_widget.dart';
import '../../models/detection_result.dart';
// import '../../widgets/result_display_widget.dart'; // File not found
// import '../../utils/export_utils.dart'; // File not found

class ResultsDisplayScreen extends StatefulWidget {
  final List<DetectionResult> objects;
  final List<ActionResult> actions;
  final List<SpeechResult> speeches;

  const ResultsDisplayScreen({
    Key? key,
    required this.objects,
    required this.actions,
    required this.speeches,
  }) : super(key: key);

  @override
  _ResultsDisplayScreenState createState() => _ResultsDisplayScreenState();
}

class _ResultsDisplayScreenState extends State<ResultsDisplayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  bool showTimestamps = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detection Results'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {}, // TODO: Implement shareResults
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _isExporting
                ? null
                : () {}, // TODO: Implement exportResults
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {}, // TODO: Implement handleMenuAction
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(
              icon: Icon(Icons.visibility),
              text: 'Objects (${widget.objects.length})',
            ),
            Tab(
              icon: Icon(Icons.accessibility_new),
              text: 'Actions (${widget.actions.length})',
            ),
            Tab(
              icon: Icon(Icons.mic),
              text: 'Speech (${widget.speeches.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildObjectsTab(),
          _buildActionsTab(),
          // _buildSpeechTab(), // Method not found, comment out
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.camera_alt),
        label: Text('Back to Camera'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          SizedBox(height: 24),
          _buildRecentDetections(),
          SizedBox(height: 24),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Objects',
            widget.objects.length.toString(),
            Icons.visibility,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Actions',
            widget.actions.length.toString(),
            Icons.accessibility_new,
            Colors.purple,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Speech',
            widget.speeches.length.toString(),
            Icons.mic,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDetections() {
    final recentObjects = widget.objects.take(3).toList();
    final recentActions = widget.actions.take(3).toList();
    final recentSpeeches = widget.speeches.take(3).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Detections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            if (recentObjects.isNotEmpty) ...[
              Text(
                'Latest Objects:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...recentObjects.map(
                (obj) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: _getColorForLabel(obj.label),
                  ),
                  title: Text(obj.label),
                  subtitle: Text(
                    '${(obj.confidence * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(_formatTimestamp(obj.timestamp)),
                ),
              ),
            ],

            if (recentActions.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Latest Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...recentActions.map(
                (action) => ListTile(
                  dense: true,
                  leading: Icon(Icons.accessibility_new, color: Colors.purple),
                  title: Text(action.action),
                  subtitle: Text(
                    '${(action.confidence * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(_formatTimestamp(action.timestamp)),
                ),
              ),
            ],

            if (recentSpeeches.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Latest Speech:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...recentSpeeches.map(
                (speech) => ListTile(
                  dense: true,
                  leading: Icon(Icons.mic, color: Colors.orange),
                  title: Text(
                    speech.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(speech.confidence * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(_formatTimestamp(speech.timestamp)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    // Calculate statistics
    final objectCounts = <String, int>{};
    for (final obj in widget.objects) {
      objectCounts[obj.label] = (objectCounts[obj.label] ?? 0) + 1;
    }

    final actionCounts = <String, int>{};
    for (final action in widget.actions) {
      actionCounts[action.action] = (actionCounts[action.action] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),

            if (objectCounts.isNotEmpty) ...[
              Text(
                'Most Detected Objects:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(objectCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .take(5)
                  .map((entry) {
                    final percentage =
                        (entry.value / widget.objects.length * 100);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getColorForLabel(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text(entry.key)),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObjectsTab() {
    if (widget.objects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No objects detected yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: widget.objects.length,
      itemBuilder: (context, index) {
        final object = widget.objects[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorForLabel(object.label).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility,
                color: _getColorForLabel(object.label),
              ),
            ),
            title: Text(object.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence: ${(object.confidence * 100).toStringAsFixed(1)}%',
                ),
                Text('Time: ${_formatTimestamp(object.timestamp)}'),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getConfidenceColor(object.confidence),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getConfidenceLevel(object.confidence),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsTab() {
    if (widget.actions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.accessibility_new, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No actions detected yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: widget.actions.length,
      itemBuilder: (context, index) {
        final action = widget.actions[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.accessibility_new, color: Colors.purple),
            ),
            title: Text(action.action),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence: ${(action.confidence * 100).toStringAsFixed(1)}%',
                ),
                if (showTimestamps)
                  Text('Time: ${_formatTimestamp(action.timestamp)}'),
                if (action.alternativeActions?.isNotEmpty == true)
                  Text(
                    'Alternatives: ${action.alternativeActions!.join(", ")}',
                  ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getConfidenceColor(action.confidence),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getConfidenceLevel(action.confidence),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildSpeechSection(BuildContext context) {
  //   ...existing code...
  // }

  Color _getColorForLabel(String label) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.lime,
    ];
    return colors[label.hashCode.abs() % colors.length];
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence > 0.8) return 'HIGH';
    if (confidence > 0.6) return 'MED';
    return 'LOW';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
