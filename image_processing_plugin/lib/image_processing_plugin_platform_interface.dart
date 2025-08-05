import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_processing_plugin_method_channel.dart';

abstract class ImageProcessingPluginPlatform extends PlatformInterface {
  /// Constructs a ImageProcessingPluginPlatform.
  ImageProcessingPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImageProcessingPluginPlatform _instance = MethodChannelImageProcessingPlugin();

  /// The default instance of [ImageProcessingPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelImageProcessingPlugin].
  static ImageProcessingPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImageProcessingPluginPlatform] when
  /// they register themselves.
  static set instance(ImageProcessingPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<Uint8List> processYUVPlanesWithStride(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    throw UnimplementedError('processYUVPlanesWithStride() has not been implemented.');
  }
}
