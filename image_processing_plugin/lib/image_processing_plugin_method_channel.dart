import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_processing_plugin_platform_interface.dart';

/// An implementation of [ImageProcessingPluginPlatform] that uses method channels.
class MethodChannelImageProcessingPlugin extends ImageProcessingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_processing_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Uint8List> processYUVPlanes(
    Uint8List yuvBytes,
    int width,
    int height,
    List<List<double>>? previousKeypoints,
  ) async {
    final result = await methodChannel.invokeMethod<Uint8List>('processYUVPlanes', {
      'yuvBytes': yuvBytes,
      'width': width,
      'height': height,
      'previousKeypoints': previousKeypoints,
    });
    return result!;
  }
}
