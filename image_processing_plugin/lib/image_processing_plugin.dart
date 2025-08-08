import 'dart:typed_data';

import 'image_processing_plugin_platform_interface.dart';

class ImageProcessingPlugin {
  Future<String?> getPlatformVersion() {
    return ImageProcessingPluginPlatform.instance.getPlatformVersion();
  }

  Future<List<dynamic>> processYUVPlanesWithStride(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    return ImageProcessingPluginPlatform.instance.processYUVPlanesWithStride(
      planeBytes,
      bytesPerRow,
      bytesPerPixel,
      width,
      height,
      sensorOrientation,
    );
  }
}
