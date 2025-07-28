import 'dart:typed_data';
import 'package:image_processing_plugin/image_processing_plugin.dart';

class NativeImageProcessor {
  /// Processes the YUV image and crops it natively.
  /// [yuvBytes]: The raw YUV byte array from the camera.
  /// [width], [height]: The dimensions of the camera image.
  /// [previousKeypoints]: Previous keypoints for intelligent cropping [[x, y, confidence], ...].
  static Future<Uint8List> processYUVPlanes(
    Uint8List yuvBytes,
    int width,
    int height,
    List<List<double>>? previousKeypoints,
  ) async {
    return await ImageProcessingPlugin().processYUVPlanes(
      yuvBytes,
      width,
      height,
      previousKeypoints,
    );
  }
}
