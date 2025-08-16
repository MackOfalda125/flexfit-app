import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'movenet_image_processor_platform_interface.dart';

class MethodChannelMovenetImageProcessor extends MovenetImageProcessorPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('movenet_image_processor');
  // Model lifecycle
  @override
  Future<bool> initializeModel() async {
    final ok = await methodChannel.invokeMethod<bool>('initializeModel');
    return ok ?? false;
  }

  @override
  Future<bool> isInitialized() async {
    final value = await methodChannel.invokeMethod<bool>('isInitialized');
    return value ?? false;
    
  }

  @override
  Future<void> closeModel() {
    return methodChannel.invokeMethod<void>('closeModel');
  }

  // Inference
  @override
  Future<List<List<double>>> processFrame({
    required List<Uint8List> planes,
    required List<int> bytesPerRow,
    required List<int> bytesPerPixel,
    required int width,
    required int height,
    required int sensorOrientation,
  }) async {
    final args = <String, dynamic>{
      'planes': planes,
      'bytesPerRow': bytesPerRow,
      'bytesPerPixel': bytesPerPixel,
      'width': width,
      'height': height,
      'sensorOrientation': sensorOrientation,
    };

    final dynamic res = await methodChannel.invokeMethod('processFrame', args);
    // Expecting List<List<double>>; perform a safe cast
    final list = (res as List)
        .map<List<double>>((e) => (e as List).map<double>((v) => (v as num).toDouble()).toList())
        .toList();
    return list;
  }
}
