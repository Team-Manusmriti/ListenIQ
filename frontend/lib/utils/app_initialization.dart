import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'permission_handler.dart';
import 'package:listen_iq/services/video/video_processing_service.dart';

class AppInitialization {
  static List<CameraDescription>? cameras;
  static bool _initialized = false;

  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize cameras
      cameras = await availableCameras();

      // Check and request permissions
      final hasCamera = await PermissionHelper.hasCameraPermission();
      final hasStorage = await PermissionHelper.hasStoragePermission();

      if (!hasCamera || !hasStorage) {
        await PermissionHelper.requestAllPermissions();
      }

      // Check backend service health
      bool serviceHealthy = true;
      try {
        // Replace with actual backend health check if available
        // serviceHealthy = await VideoProcessingService().checkBackendHealth();
        serviceHealthy =
            true; // Placeholder until health check method is implemented
      } catch (e) {
        debugPrint('Service health check failed: $e');
      }

      _initialized = true;
      return serviceHealthy;
    } catch (e) {
      debugPrint('Initialization error: $e');
      return false;
    }
  }

  static bool get isInitialized => _initialized;
}
