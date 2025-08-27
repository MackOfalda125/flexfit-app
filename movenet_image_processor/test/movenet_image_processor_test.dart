import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:movenet_image_processor/movenet_image_processor.dart';
import 'package:movenet_image_processor/movenet_image_processor_platform_interface.dart';
import 'package:movenet_image_processor/movenet_image_processor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMovenetImageProcessorPlatform
    with MockPlatformInterfaceMixin
    implements MovenetImageProcessorPlatform {

  @override
  Future<bool> initializeModel() async => true;

  @override
  Future<bool> isInitialized() async => true;

  // Exercise model lifecycle
  @override
  Future<bool> initExerciseModel(String exercise) async => true;

  @override
  Future<bool> isExerciseInitialized() async => true;

  @override
  Future<void> closeModel() async {}

  @override
  Future<List<dynamic>> processFrame({
    required List<Uint8List> planes,
    required List<int> bytesPerRow,
    required List<int> bytesPerPixel,
    required int width,
    required int height,
    required int sensorOrientation,
  }) async {
    // Return the new format: [keypoints, formScore, instructionId]
    final keypoints = List.generate(17, (_) => [0.0, 0.0, 0.0]);
    return [keypoints, 0.5, 1]; // [keypoints, formScore, instructionId]
  }
}

void main() {
  final MovenetImageProcessorPlatform initialPlatform = MovenetImageProcessorPlatform.instance;

  test('$MethodChannelMovenetImageProcessor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMovenetImageProcessor>());
  });

  test('lifecycle and processFrame', () async {
    final plugin = MovenetImageProcessor();
    final fakePlatform = MockMovenetImageProcessorPlatform();
    MovenetImageProcessorPlatform.instance = fakePlatform;

    expect(await plugin.initializeModel(), true);
    expect(await plugin.isInitialized(), true);

    // Test exercise model lifecycle
    expect(await plugin.initExerciseModel("squats"), true);
    expect(await plugin.isExerciseInitialized(), true);

    final planes = <Uint8List>[Uint8List(10), Uint8List(5), Uint8List(5)];
    final result = await plugin.processFrame(
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

    await plugin.closeModel();
  });
}
