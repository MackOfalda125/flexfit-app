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

  /// Initialize the exercise-specific model.
  ///
  /// [exercise]: Exercise type ("squats", "bicep curls", "overhead presses").
  static Future<bool> initExerciseModel(String exercise) {
    return MovenetImageProcessor().initExerciseModel(exercise);
  }

  /// Returns whether the exercise model has been initialized.
  static Future<bool> isExerciseInitialized() {
    return MovenetImageProcessor().isExerciseInitialized();
  }

  /// Close the native interpreters and release resources.
  static Future<void> closeModel() {
    return MovenetImageProcessor().closeModel();
  }

  /// Processes a frame natively and returns keypoints, form score, and instruction ID.
  ///
  /// Returns a List<dynamic> containing:
  /// [0] = List<List<double>> keypoints (17 keypoints as [y, x, score])
  /// [1] = double formScore (exercise form quality score)
  /// [2] = int instructionId (exercise instruction identifier)
  ///
  /// [planeBytes]: YUV plane byte arrays.
  /// [bytesPerRow]: Bytes per row for each plane.
  /// [bytesPerPixel]: Bytes per pixel for each plane.
  /// [width], [height]: Image dimensions.
  /// [sensorOrientation]: Sensor orientation in degrees (0, 90, 180, 270).
  static Future<List<dynamic>> processFrame(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    return MovenetImageProcessor()
        .processFrame(
          planes: planeBytes,
          bytesPerRow: bytesPerRow,
          bytesPerPixel: bytesPerPixel,
          width: width,
          height: height,
          sensorOrientation: sensorOrientation,
        )
        .then((List<dynamic> res) {
          // Normalize platform channel payload to strong types
          final List<dynamic> rawKeypoints = res[0] as List<dynamic>;
          final keypoints = rawKeypoints
              .map<List<double>>(
                (row) => (row as List)
                    .map((v) => (v as num).toDouble())
                    .toList(growable: false),
              )
              .toList(growable: false);
          final formScore = (res[1] as num).toDouble();
          final instructionId = (res[2] as num).toInt();
          return <dynamic>[keypoints, formScore, instructionId];
        });
  }
}
