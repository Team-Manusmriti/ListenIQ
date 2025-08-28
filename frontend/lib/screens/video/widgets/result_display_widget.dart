import 'package:flutter/material.dart';
import 'package:listen_iq/models/detection_result.dart';

class ResultDisplayWidget extends StatelessWidget {
  final List<DetectionResult> objects;
  final ActionResult? action;
  final SpeechResult? speech;
  final bool showObjectsOnly;
  final bool showTimestamps;

  const ResultDisplayWidget({
    Key? key,
    required this.objects,
    this.action,
    this.speech,
    this.showObjectsOnly = false,
    this.showTimestamps = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Objects section
          _buildObjectsSection(context),

          if (!showObjectsOnly) ...[
            SizedBox(height: 24),

            // Action section
            if (action != null) _buildActionSection(context),

            SizedBox(height: 24),

            // Speech section
            if (speech != null) _buildSpeechSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Objects Detected (${objects.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (objects.isNotEmpty)
            ...objects.asMap().entries.map((entry) {
              final index = entry.key;
              final obj = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForLabel(obj.label),
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(obj.label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence: ${(obj.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    Text(
                      'Size: ${obj.boundingBox.width.toStringAsFixed(0)} × ${obj.boundingBox.height.toStringAsFixed(0)}',
                    ),
                    if (showTimestamps)
                      Text('Time: ${_formatTimestamp(obj.timestamp)}'),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(obj.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getConfidenceLevel(obj.confidence),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList()
          else
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No objects detected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Current Action',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.accessibility_new, color: Colors.purple),
                  ),
                  title: Text(
                    action!.action.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence: ${(action!.confidence * 100).toStringAsFixed(1)}%',
                      ),
                      Text('Time: ${_formatTimestamp(action!.timestamp)}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.accessibility_new, color: Colors.purple),
                  ),
                ),
                SizedBox(height: 8),
                Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metadata: ${action!.metadata.toString()}'),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Confidence Level:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(_getConfidenceLevel(action!.confidence)),
                ),
                SizedBox(height: 8),
                Text(
                  'Action Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(action!.action.toString()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return 'High';
    if (confidence >= 0.7) return 'Medium';
    return 'Low';
  }

  Color _getColorForLabel(String label) {
    return Colors.primaries[label.hashCode % Colors.primaries.length];
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSpeechSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(Icons.mic, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Current Speech',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, color: Colors.orange),
            ),
            title: Text(
              speech!.text.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence: ${(speech!.confidence * 100).toStringAsFixed(1)}%',
                ),
                Text('Time: ${_formatTimestamp(speech!.timestamp)}'),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
