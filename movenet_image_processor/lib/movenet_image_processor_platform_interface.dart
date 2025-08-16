import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'movenet_image_processor_method_channel.dart';

abstract class MovenetImageProcessorPlatform extends PlatformInterface {
  MovenetImageProcessorPlatform() : super(token: _token);

  static final Object _token = Object();

  static MovenetImageProcessorPlatform _instance = MethodChannelMovenetImageProcessor();

  static MovenetImageProcessorPlatform get instance => _instance;

  static set instance(MovenetImageProcessorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Model lifecycle
  Future<bool> initializeModel() {
    throw UnimplementedError('initializeModel() has not been implemented.');
  }

  Future<bool> isInitialized() {
    throw UnimplementedError('isInitialized() has not been implemented.');
  }

  Future<void> closeModel() {
    throw UnimplementedError('closeModel() has not been implemented.');
  }

  // Inference
  Future<List<List<double>>> processFrame({
    required List<Uint8List> planes,
    required List<int> bytesPerRow,
    required List<int> bytesPerPixel,
    required int width,
    required int height,
    required int sensorOrientation,
  }) {
    throw UnimplementedError('processFrame() has not been implemented.');
  }
}
