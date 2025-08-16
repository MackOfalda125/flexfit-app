import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movenet_image_processor/movenet_image_processor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelMovenetImageProcessor();
  const channel = MethodChannel('movenet_image_processor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'initializeModel':
            return true;
          case 'isInitialized':
            return true;
          case 'closeModel':
            return null;
          case 'processFrame':
            return List.generate(17, (_) => [0.0, 0.0, 0.0]);
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('initialize/isInitialized/close', () async {
    expect(await platform.initializeModel(), true);
    expect(await platform.isInitialized(), true);
    await platform.closeModel();
  });

  test('processFrame', () async {
    final planes = <Uint8List>[Uint8List(10), Uint8List(5), Uint8List(5)];
    final out = await platform.processFrame(
      planes: planes,
      bytesPerRow: [10, 5, 5],
      bytesPerPixel: [1, 2, 2],
      width: 2,
      height: 2,
      sensorOrientation: 0,
    );
    expect(out.length, 17);
    expect(out[0].length, 3);
  });
}
