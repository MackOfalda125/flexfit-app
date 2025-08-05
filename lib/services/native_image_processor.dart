import 'dart:typed_data';
import 'package:image_processing_plugin/image_processing_plugin.dart';

class NativeImageProcessor {
  /// Processes the YUV image natively with stride handling.
  /// [planeBytes]: List of YUV plane byte arrays.
  /// [bytesPerRow]: List of bytes per row for each plane.
  /// [bytesPerPixel]: List of bytes per pixel for each plane.
  /// [width], [height]: The dimensions of the camera image.
  /// [sensorOrientation]: The sensor orientation in degrees (0, 90, 180, 270).
  static Future<Uint8List> processYUVPlanesWithStride(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) async {
    return await ImageProcessingPlugin().processYUVPlanesWithStride(
      planeBytes,
      bytesPerRow,
      bytesPerPixel,
      width,
      height,
      sensorOrientation,
    );
  }
}
