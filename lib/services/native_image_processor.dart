import 'dart:typed_data';

import 'package:image_processing_plugin/image_processing_plugin.dart';

class NativeImageProcessor {
  /// Processes the YUV image natively with stride handling.
  /// [planeBytes]: List of YUV plane byte arrays.
  /// [bytesPerRow]: List of bytes per row for each plane.
  /// [bytesPerPixel]: List of bytes per pixel for each plane.
  /// [width], [height]: The dimensions of the camera image.
  /// [sensorOrientation]: The sensor orientation in degrees (0, 90, 180, 270).
  /// Returns: List containing [Uint8List imageData, double paddingRatio]
  static Future<List<dynamic>> processYUVPlanesWithStride(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) async {
    try {
      final result = await ImageProcessingPlugin().processYUVPlanesWithStride(
        planeBytes,
        bytesPerRow,
        bytesPerPixel,
        width,
        height,
        sensorOrientation,
      );
      
      // Convert the first element (ByteArray from Kotlin) to Uint8List
      if (result.isNotEmpty && result[0] != null) {
        final imageData = Uint8List.fromList(List<int>.from(result[0]));
        final paddingRatio = result[1] as double;
        return [imageData, paddingRatio];
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
