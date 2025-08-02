import 'dart:typed_data';
import 'package:image_processing_plugin/image_processing_plugin.dart';

class NativeImageProcessor {
  /// Processes the YUV image natively.
  /// [yuvBytes]: The raw YUV byte array from the camera.
  /// [width], [height]: The dimensions of the camera image.
  /// [sensorOrientation]: The sensor orientation in degrees (0, 90, 180, 270).
  static Future<Uint8List> processYUVPlanes(
    Uint8List yuvBytes,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) async {
    return await ImageProcessingPlugin().processYUVPlanes(
      yuvBytes,
      width,
      height,
      sensorOrientation,
    );
  }
}
