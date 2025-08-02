
import 'dart:typed_data';
import 'image_processing_plugin_platform_interface.dart';

class ImageProcessingPlugin {
  Future<String?> getPlatformVersion() {
    return ImageProcessingPluginPlatform.instance.getPlatformVersion();
  }

  Future<Uint8List> processYUVPlanes(
    Uint8List yuvBytes,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    return ImageProcessingPluginPlatform.instance.processYUVPlanes(
      yuvBytes,
      width,
      height,
      sensorOrientation,
    );
  }
}
