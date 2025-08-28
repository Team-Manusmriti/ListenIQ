import 'package:flutter/material.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      label: json['label'],
      confidence: json['confidence'],
      boundingBox: Rect.fromLTWH(
        json['boundingBox']['left'],
        json['boundingBox']['top'],
        json['boundingBox']['width'],
        json['boundingBox']['height'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

class ActionResult {
  final String action;
  final double confidence;
  final DateTime timestamp;
  final List<String>? alternativeActions;
  final Map<String, dynamic>? metadata;

  ActionResult({
    required this.action,
    required this.confidence,
    required this.timestamp,
    this.alternativeActions,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'alternativeActions': alternativeActions,
      'metadata': metadata,
    };
  }

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      action: json['action'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      alternativeActions: json['alternativeActions']?.cast<String>(),
      metadata: json['metadata'],
    );
  }
}

class SpeechResult {
  final String text;
  final double confidence;
  final DateTime timestamp;
  final bool isFinal;
  final List<String>? alternatives;
  final String? language;

  SpeechResult({
    required this.text,
    required this.confidence,
    required this.timestamp,
    this.isFinal = true,
    this.alternatives,
    this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'isFinal': isFinal,
      'alternatives': alternatives,
      'language': language,
    };
  }

  factory SpeechResult.fromJson(Map<String, dynamic> json) {
    return SpeechResult(
      text: json['text'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      isFinal: json['isFinal'] ?? true,
      alternatives: json['alternatives']?.cast<String>(),
      language: json['language'],
    );
  }
}
