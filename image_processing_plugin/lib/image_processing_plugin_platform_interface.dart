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
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Uint8List> processYUVPlanes(
    Uint8List yuvBytes,
    int width,
    int height,
    List<List<double>>? previousKeypoints,
  ) {
    throw UnimplementedError('processYUVPlanes() has not been implemented.');
  }
}
