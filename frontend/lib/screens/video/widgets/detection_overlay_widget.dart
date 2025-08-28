// widgets/detection_overlay_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:listen_iq/models/detection_result.dart';

class DetectionOverlayWidget extends StatefulWidget {
  final List<DetectionResult> objects;
  final ActionResult? action;
  final SpeechResult? speech;
  final Size? cameraPreviewSize;
  final Size? screenSize;

  const DetectionOverlayWidget({
    Key? key,
    required this.objects,
    this.action,
    this.speech,
    this.cameraPreviewSize,
    this.screenSize,
  }) : super(key: key);

  @override
  _DetectionOverlayWidgetState createState() => _DetectionOverlayWidgetState();
}

class _DetectionOverlayWidgetState extends State<DetectionOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for bounding box pulse effect
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation for action/speech slide in effect
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(DetectionOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger slide animation when new action or speech is detected
    if ((widget.action != null && oldWidget.action == null) ||
        (widget.speech != null && oldWidget.speech == null)) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Object detection bounding boxes
        ...widget.objects.asMap().entries.map((entry) {
          final index = entry.key;
          final detection = entry.value;
          return _buildBoundingBox(detection, index);
        }).toList(),

        // Action detection display
        if (widget.action != null) _buildActionDisplay(widget.action!),

        // Speech recognition display (handled in main screen)

        // Detection statistics
        _buildStatsDisplay(),

        // Performance indicators
        _buildPerformanceIndicators(),
      ],
    );
  }

  Widget _buildBoundingBox(DetectionResult detection, int index) {
    final color = _getColorForLabel(detection.label);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Positioned(
          left: detection.boundingBox.left * (widget.screenSize?.width ?? 1),
          top: detection.boundingBox.top * (widget.screenSize?.height ?? 1),
          width: detection.boundingBox.width * (widget.screenSize?.width ?? 1),
          height:
              detection.boundingBox.height * (widget.screenSize?.height ?? 1),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Label background
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Corner indicators
                  ...List.generate(
                    4,
                    (cornerIndex) => _buildCornerIndicator(
                      cornerIndex,
                      detection.boundingBox.size,
                      color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerIndicator(int corner, Size boxSize, Color color) {
    late Alignment alignment;
    late BorderRadius borderRadius;

    switch (corner) {
      case 0: // Top-left
        alignment = Alignment.topLeft;
        borderRadius = BorderRadius.only(topLeft: Radius.circular(8));
        break;
      case 1: // Top-right
        alignment = Alignment.topRight;
        borderRadius = BorderRadius.only(topRight: Radius.circular(8));
        break;
      case 2: // Bottom-left
        alignment = Alignment.bottomLeft;
        borderRadius = BorderRadius.only(bottomLeft: Radius.circular(8));
        break;
      case 3: // Bottom-right
        alignment = Alignment.bottomRight;
        borderRadius = BorderRadius.only(bottomRight: Radius.circular(8));
        break;
    }

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        ),
      ),
    );
  }

  Widget _buildActionDisplay(ActionResult action) {
    return SlideTransition(
      position: _slideAnimation,
      child: Positioned(
        bottom: 120,
        left: 16,
        right: 16,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.9),
                Colors.deepPurple.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.accessibility_new,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Action Detected',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          action.action.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(action.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDisplay() {
    final objectCounts = <String, int>{};
    for (final obj in widget.objects) {
      objectCounts[obj.label] = (objectCounts[obj.label] ?? 0) + 1;
    }

    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Live Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Object counts
            if (objectCounts.isNotEmpty) ...[
              Text(
                'Objects (${widget.objects.length}):',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              ...objectCounts.entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getColorForLabel(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ] else ...[
              Text(
                'No objects detected',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],

            SizedBox(height: 4),

            // Action status
            Text(
              'Action: ${widget.action?.action ?? 'None'}',
              style: TextStyle(
                color: widget.action != null
                    ? Colors.purple[200]
                    : Colors.white70,
                fontSize: 11,
              ),
            ),

            // Speech status
            Text(
              'Speech: ${widget.speech != null ? 'Active' : 'Listening...'}',
              style: TextStyle(
                color: widget.speech != null
                    ? Colors.blue[200]
                    : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FPS indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4),

          // Model status indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModelStatusDot(
                'OBJ',
                widget.objects.isNotEmpty,
                Colors.blue,
              ),
              SizedBox(width: 4),
              _buildModelStatusDot('ACT', widget.action != null, Colors.purple),
              SizedBox(width: 4),
              _buildModelStatusDot('SPH', widget.speech != null, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusDot(String label, bool isActive, Color color) {
    return Container(
      width: 32,
      height: 16,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorForLabel(String label) {
    // Generate consistent colors for different object classes
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

    // Use hash code to get consistent color for each label
    final hash = label.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

// Enhanced Result Display Widget for detailed view
class ResultDisplayWidget extends StatelessWidget {
  final List<DetectionResult> objects;
  final ActionResult? action;
  final SpeechResult? speech;

  const ResultDisplayWidget({
    Key? key,
    required this.objects,
    this.action,
    this.speech,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Results',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          // Objects section
          _buildSection(
            'Objects Detected (${objects.length})',
            Icons.visibility,
            Colors.blue,
            objects
                .map(
                  (obj) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorForLabel(obj.label),
                      radius: 12,
                    ),
                    title: Text(obj.label),
                    subtitle: Text(
                      'Confidence: ${(obj.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: Text(
                      '${obj.boundingBox.width.toStringAsFixed(0)}×${obj.boundingBox.height.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                )
                .toList(),
          ),

          // Action section
          if (action != null)
            _buildSection(
              'Current Action',
              Icons.accessibility_new,
              Colors.purple,
              [
                ListTile(
                  title: Text(action!.action),
                  subtitle: Text(
                    'Confidence: ${(action!.confidence * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(
                    _formatTimestamp(action!.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),

          // Speech section
          if (speech != null)
            _buildSection('Speech Recognition', Icons.mic, Colors.orange, [
              ListTile(
                title: Text(speech!.text),
                subtitle: Text(
                  'Confidence: ${(speech!.confidence * 100).toStringAsFixed(1)}%',
                ),
                trailing: Text(
                  _formatTimestamp(speech!.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty)
            ...children
          else
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

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
    ];
    return colors[label.hashCode.abs() % colors.length];
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    return '${diff.inHours}h ago';
  }
}
