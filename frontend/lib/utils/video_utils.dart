// utils/video_utils.dart
import 'dart:io';
import 'package:path/path.dart' as path;

class VideoUtils {
  static const List<String> supportedExtensions = [
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.webm',
    '.flv',
    '.m4v',
    '.3gp',
  ];

  static bool isVideoFile(String filePath) {
    String extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  static String getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";

    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return "${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}";
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}
