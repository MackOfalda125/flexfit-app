import 'dart:typed_data';

import 'package:movenet_image_processor/movenet_image_processor.dart';

class NativeInferenceChannel {
  /// Initialize the native MoveNet interpreter.
  static Future<bool> initializeModel() {
    return MovenetImageProcessor().initializeModel();
  }

  /// Returns whether the interpreter has been initialized.
  static Future<bool> isInitialized() {
    return MovenetImageProcessor().isInitialized();
  }

  /// Close the native interpreter and release resources.
  static Future<void> closeModel() {
    return MovenetImageProcessor().closeModel();
  }

  /// Processes a frame natively and returns 17 keypoints as [y, x, score].
  ///
  /// [planeBytes]: YUV plane byte arrays.
  /// [bytesPerRow]: Bytes per row for each plane.
  /// [bytesPerPixel]: Bytes per pixel for each plane.
  /// [width], [height]: Image dimensions.
  /// [sensorOrientation]: Sensor orientation in degrees (0, 90, 180, 270).
  static Future<List<List<double>>> processFrame(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    return MovenetImageProcessor().processFrame(
      planes: planeBytes,
      bytesPerRow: bytesPerRow,
      bytesPerPixel: bytesPerPixel,
      width: width,
      height: height,
      sensorOrientation: sensorOrientation,
    );
  }
}
