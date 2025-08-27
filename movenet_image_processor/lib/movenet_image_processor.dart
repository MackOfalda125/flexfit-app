import 'dart:typed_data';
import 'movenet_image_processor_platform_interface.dart';

class MovenetImageProcessor {
  // Model lifecycle
  Future<bool> initializeModel() =>
      MovenetImageProcessorPlatform.instance.initializeModel();

  Future<bool> isInitialized() =>
      MovenetImageProcessorPlatform.instance.isInitialized();

  // Exercise model lifecycle
  Future<bool> initExerciseModel(String exercise) =>
      MovenetImageProcessorPlatform.instance.initExerciseModel(exercise);

  Future<bool> isExerciseInitialized() =>
      MovenetImageProcessorPlatform.instance.isExerciseInitialized();

  Future<void> closeModel() =>
      MovenetImageProcessorPlatform.instance.closeModel();

  // Inference
  // Returns List<dynamic> where:
  // [0] = List<List<double>> keypoints
  // [1] = double formScore  
  // [2] = int instructionId
  Future<List<dynamic>> processFrame({
    required List<Uint8List> planes,
    required List<int> bytesPerRow,
    required List<int> bytesPerPixel,
    required int width,
    required int height,
    required int sensorOrientation,
  }) =>
      MovenetImageProcessorPlatform.instance.processFrame(
        planes: planes,
        bytesPerRow: bytesPerRow,
        bytesPerPixel: bytesPerPixel,
        width: width,
        height: height,
        sensorOrientation: sensorOrientation,
      );
}
