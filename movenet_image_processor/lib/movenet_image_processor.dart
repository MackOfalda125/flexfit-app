import 'dart:typed_data';
import 'movenet_image_processor_platform_interface.dart';

class MovenetImageProcessor {
  // Model lifecycle
  Future<bool> initializeModel() =>
      MovenetImageProcessorPlatform.instance.initializeModel();

  Future<bool> isInitialized() =>
      MovenetImageProcessorPlatform.instance.isInitialized();

  Future<void> closeModel() =>
      MovenetImageProcessorPlatform.instance.closeModel();

  // Inference
  Future<List<List<double>>> processFrame({
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
