import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioIntensityService {
  final AudioRecorder _record = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;

  // Public stream of normalized intensity [0..1]
  final _levelCtrl = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelCtrl.stream;

  // Exponential smoothing to reduce jitter
  double _smoothed = 0.0;
  final double _alpha = 0.25; // higher = snappier

  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    if (!await _ensurePermission()) return;

    // Get platform-safe temp directory
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp.aac';

    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: tempPath, // safe location
    );

    _ampSub = _record
        .onAmplitudeChanged(const Duration(milliseconds: 60))
        .listen((amp) {
          final normalized = _normalizeDb(amp.current, minDb: -60, maxDb: 0);
          _smoothed = _smoothed + _alpha * (normalized - _smoothed);
          _levelCtrl.add(_smoothed);
        });
  }

  Future<void> stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    if (await _record.isRecording()) {
      await _record.stop();
    }
    _smoothed = 0.0;
    _levelCtrl.add(0.0);
  }

  void dispose() {
    _ampSub?.cancel();
    _levelCtrl.close();
  }

  /// Converts dBFS (e.g., −60 .. 0) to 0..1
  double _normalizeDb(double db, {double minDb = -60, double maxDb = 0}) {
    // Handle unknown/positive values gracefully
    if (db.isNaN || db.isInfinite) return 0.0;
    final clamped = db.clamp(minDb, maxDb);
    final norm = (clamped - minDb) / (maxDb - minDb);
    return norm.toDouble().clamp(0.0, 1.0);
  }
}
