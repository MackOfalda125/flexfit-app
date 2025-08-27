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
          case 'initExerciseModel':
            return true;
          case 'isExerciseInitialized':
            return true;
          case 'closeModel':
            return null;
          case 'processFrame':
            // Return the new format: [keypoints, formScore, instructionId]
            final keypoints = List.generate(17, (_) => [0.0, 0.0, 0.0]);
            return [keypoints, 0.5, 1];
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

  test('exercise model lifecycle', () async {
    expect(await platform.initExerciseModel("squats"), true);
    expect(await platform.isExerciseInitialized(), true);
  });

  test('processFrame', () async {
    final planes = <Uint8List>[Uint8List(10), Uint8List(5), Uint8List(5)];
    final result = await platform.processFrame(
      planes: planes,
      bytesPerRow: [10, 5, 5],
      bytesPerPixel: [1, 2, 2],
      width: 2,
      height: 2,
      sensorOrientation: 0,
    );
    
    // Test the new return format: [keypoints, formScore, instructionId]
    expect(result.length, 3);
    
    final keypoints = result[0] as List<List<double>>;
    final formScore = result[1] as double;
    final instructionId = result[2] as int;
    
    expect(keypoints.length, 17);
    expect(keypoints[0].length, 3);
    expect(formScore, 0.5);
    expect(instructionId, 1);
  });
}
