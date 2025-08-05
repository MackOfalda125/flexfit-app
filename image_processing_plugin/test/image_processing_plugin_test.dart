import 'package:flutter_test/flutter_test.dart';
import 'package:image_processing_plugin/image_processing_plugin.dart';
import 'package:image_processing_plugin/image_processing_plugin_platform_interface.dart';
import 'package:image_processing_plugin/image_processing_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';

class MockImageProcessingPluginPlatform
    with MockPlatformInterfaceMixin
    implements ImageProcessingPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List> processYUVPlanesWithStride(
    List<Uint8List> planeBytes,
    List<int> bytesPerRow,
    List<int> bytesPerPixel,
    int width,
    int height, [
    int sensorOrientation = 0,
  ]) {
    // Return a mock RGB byte array for testing
    return Future.value(Uint8List(width * height * 3));
  }
}

void main() {
  final ImageProcessingPluginPlatform initialPlatform = ImageProcessingPluginPlatform.instance;

  test('$MethodChannelImageProcessingPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImageProcessingPlugin>());
  });

  test('getPlatformVersion', () async {
    ImageProcessingPlugin imageProcessingPlugin = ImageProcessingPlugin();
    MockImageProcessingPluginPlatform fakePlatform = MockImageProcessingPluginPlatform();
    ImageProcessingPluginPlatform.instance = fakePlatform;

    expect(await imageProcessingPlugin.getPlatformVersion(), '42');
  });

  test('processYUVPlanesWithStride', () async {
    ImageProcessingPlugin imageProcessingPlugin = ImageProcessingPlugin();
    MockImageProcessingPluginPlatform fakePlatform = MockImageProcessingPluginPlatform();
    ImageProcessingPluginPlatform.instance = fakePlatform;

    final testPlaneBytes = [Uint8List(100), Uint8List(25), Uint8List(25)];
    final testBytesPerRow = [10, 5, 5];
    final testBytesPerPixel = [1, 1, 1];
    
    final result = await imageProcessingPlugin.processYUVPlanesWithStride(
      testPlaneBytes,
      testBytesPerRow,
      testBytesPerPixel,
      10,
      10,
    );

    expect(result, isA<Uint8List>());
    expect(result.length, 300); // 10x10x3 RGB bytes
  });
}
