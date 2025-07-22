import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Converts a CameraImage (YUV420) to an img.Image (RGB).
img.Image cameraImageToImage(CameraImage image) {
  final img.Image rawImage = img.Image(
    width: image.width,
    height: image.height,
  );
  final uvRowStride = image.planes[1].bytesPerRow;
  final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
      final yVal = image.planes[0].bytes[y * image.width + x];
      final uVal = image.planes[1].bytes[uvIndex];
      final vVal = image.planes[2].bytes[uvIndex];
      final rgb = _yuv2rgb(yVal, uVal, vVal);
      rawImage.setPixelRgba(x, y, rgb[0], rgb[1], rgb[2], 255);
    }
  }
  // Adjust orientation and flip as needed for your use case
  return img.flipHorizontal(img.copyRotate(rawImage, angle: 270));
}

/// Converts an img.Image (RGB) to Uint8List in RGB order (no alpha).
Uint8List imageToUint8List(img.Image image) {
  final int width = image.width;
  final int height = image.height;
  final Uint8List bytes = Uint8List(width * height * 3);
  final pixels = image.getBytes(); // RGBA order
  int j = 0;
  for (int i = 0; i < pixels.length; i += 4) {
    bytes[j++] = pixels[i]; // R
    bytes[j++] = pixels[i + 1]; // G
    bytes[j++] = pixels[i + 2]; // B
    // skip A
  }
  return bytes;
}

List<int> _yuv2rgb(int y, int u, int v) {
  final int u1 = u - 128;
  final int v1 = v - 128;

  final int r = (y + ((1436 * v1) >> 10)).clamp(0, 255);
  final int g = (y - ((352 * u1 + 731 * v1) >> 10)).clamp(0, 255);
  final int b = (y + ((1815 * u1) >> 10)).clamp(0, 255);

  return [r, g, b];
}
