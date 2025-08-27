// models/detection_result.dart
class DetectionResult {
  final List<DetectedObject> objects;
  final String processingTime;
  final String status;
  final String? timestamp;
  final int? totalFrames;
  final VideoInfo? videoInfo;

  DetectionResult({
    required this.objects,
    required this.processingTime,
    required this.status,
    this.timestamp,
    this.totalFrames,
    this.videoInfo,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      objects:
          (json['objects'] as List<dynamic>?)
              ?.map((obj) => DetectedObject.fromJson(obj))
              .toList() ??
          [],
      processingTime: json['processingTime'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      timestamp: json['timestamp'],
      totalFrames: json['totalFrames'],
      videoInfo: json['videoInfo'] != null
          ? VideoInfo.fromJson(json['videoInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objects': objects.map((obj) => obj.toJson()).toList(),
      'processingTime': processingTime,
      'status': status,
      'timestamp': timestamp,
      'totalFrames': totalFrames,
      'videoInfo': videoInfo?.toJson(),
    };
  }
}

class DetectedObject {
  final String name;
  final String className;
  final double confidence;
  final List<int>? bbox;
  final List<int>? center;
  final List<int>? size;

  DetectedObject({
    required this.name,
    required this.className,
    required this.confidence,
    this.bbox,
    this.center,
    this.size,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      name: json['name'] ?? json['class'] ?? 'Unknown',
      className: json['class'] ?? json['name'] ?? 'Unknown',
      confidence: (json['confidence'] ?? json['score'] ?? 0.0).toDouble(),
      bbox: json['bbox'] != null ? List<int>.from(json['bbox']) : null,
      center: json['center'] != null ? List<int>.from(json['center']) : null,
      size: json['size'] != null ? List<int>.from(json['size']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'class': className,
      'confidence': confidence,
      'bbox': bbox,
      'center': center,
      'size': size,
    };
  }
}

class VideoInfo {
  final String originalName;
  final int size;
  final String duration;

  VideoInfo({
    required this.originalName,
    required this.size,
    required this.duration,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      originalName: json['originalName'] ?? 'Unknown',
      size: json['size'] ?? 0,
      duration: json['duration'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'originalName': originalName, 'size': size, 'duration': duration};
  }
}
