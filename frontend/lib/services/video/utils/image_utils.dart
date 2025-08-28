import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  // Convert CameraImage to img.Image
  static img.Image? convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      }
      return null;
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

        if (yIndex >= yPlane.bytes.length || uvIndex >= uPlane.bytes.length)
          continue;

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  static img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final bytes = cameraImage.planes[0].bytes;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = (y * width + x) * 4;
        if (index + 3 < bytes.length) {
          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];
          final a = bytes[index + 3];

          image.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }

    return image;
  }

  // Resize image maintaining aspect ratio
  static img.Image resizeImageMaintainAspectRatio(
    img.Image image,
    int targetWidth,
    int targetHeight, {
    img.Interpolation interpolation = img.Interpolation.linear,
  }) {
    final originalAspect = image.width / image.height;
    final targetAspect = targetWidth / targetHeight;

    int newWidth, newHeight;

    if (originalAspect > targetAspect) {
      // Image is wider
      newWidth = targetWidth;
      newHeight = (targetWidth / originalAspect).round();
    } else {
      // Image is taller or same aspect
      newHeight = targetHeight;
      newWidth = (targetHeight * originalAspect).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: interpolation,
    );
  }

  // Crop image to center
  static img.Image cropImageToCenter(
    img.Image image,
    int targetWidth,
    int targetHeight,
  ) {
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;

    final x = (centerX - targetWidth ~/ 2).clamp(0, image.width - targetWidth);
    final y = (centerY - targetHeight ~/ 2).clamp(
      0,
      image.height - targetHeight,
    );

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: targetWidth,
      height: targetHeight,
    );
  }

  // Convert image to CHW format (Channel, Height, Width)
  static Float32List imageToCHWFloat32List(
    img.Image image, {
    bool normalize = true,
    double mean = 0.0,
    double std = 1.0,
  }) {
    final pixels = Float32List(3 * image.height * image.width);
    final channelSize = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final pixelIndex = y * image.width + x;

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        if (normalize) {
          pixels[pixelIndex] = (r / 255.0 - mean) / std; // R channel
          pixels[pixelIndex + channelSize] =
              (g / 255.0 - mean) / std; // G channel
          pixels[pixelIndex + 2 * channelSize] =
              (b / 255.0 - mean) / std; // B channel
        } else {
          pixels[pixelIndex] = r;
          pixels[pixelIndex + channelSize] = g;
          pixels[pixelIndex + 2 * channelSize] = b;
        }
      }
    }

    return pixels;
  }

  // Apply image augmentations
  static img.Image applyAugmentations(
    img.Image image, {
    double? brightness,
    double? contrast,
    double? saturation,
    bool flipHorizontal = false,
    bool flipVertical = false,
    int? rotationDegrees,
  }) {
    img.Image result = image;

    // Apply brightness
    if (brightness != null) {
      result = img.adjustColor(result, brightness: brightness);
    }

    // Apply contrast
    if (contrast != null) {
      result = img.adjustColor(result, contrast: contrast);
    }

    // Apply saturation
    if (saturation != null) {
      result = img.adjustColor(result, saturation: saturation);
    }

    // Apply flips
    if (flipHorizontal) {
      result = img.flipHorizontal(result);
    }

    if (flipVertical) {
      result = img.flipVertical(result);
    }

    // Apply rotation
    if (rotationDegrees != null) {
      result = img.copyRotate(result, angle: rotationDegrees);
    }

    return result;
  }

  // Convert Uint8List to img.Image
  static img.Image? uint8ListToImage(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      print('Error decoding image: $e');
      return null;
    }
  }

  // Convert img.Image to Uint8List
  static Uint8List imageToUint8List(
    img.Image image, {
    img.ImageFormat format = img.ImageFormat.png,
  }) {
    switch (format) {
      case img.ImageFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case img.ImageFormat.jpg:
        return Uint8List.fromList(img.encodeJpg(image));
      default:
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  // Create thumbnail
  static img.Image createThumbnail(img.Image image, int size) {
    final smallerDimension = image.width < image.height
        ? image.width
        : image.height;
    final scale = size / smallerDimension;

    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  // Calculate image hash for similarity detection
  static String calculateImageHash(img.Image image) {
    // Simple hash based on average pixel values
    final resized = img.copyResize(image, width: 8, height: 8);
    final grayscale = img.grayscale(resized);

    int sum = 0;
    final pixels = <int>[];

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final pixel = grayscale.getPixel(x, y);
        final gray = pixel.r.toInt(); // Grayscale, so R=G=B
        pixels.add(gray);
        sum += gray;
      }
    }

    final average = sum / 64;
    String hash = '';

    for (final pixel in pixels) {
      hash += pixel > average ? '1' : '0';
    }

    return hash;
  }
}
